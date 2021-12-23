% Copyright 2020, 2021 Florian Pesth
%
% This file is part of coleitra.
%
% coleitra is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as
% published by the Free Software Foundation version 3 of the
% License.
%
% coleitra is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU Affero General Public License for more details.
%
% You should have received a copy of the GNU Affero General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

\chapter{Grammar provider}
This is an implementation of a grammar provider querying information from the API of \url{https://en.wiktionary.org}. There are other grammar providers planned later for obtaining grammar information from other sources but for now this is the only one.

@i grammarprovider_support_status.w

\section{Helper scripts}
\subsection{Get templates}

This helper script queries recursively for template pages and can be used to create the status lists for the various languages above. Executable flag needs to be set manually (nuweb does not seem to provide the option to set this flags in the source documentation).

@o ../src/scripts/get_templates.py
@{#!/usr/bin/python3

import sys
import requests

def get_categorymembers(categorytitle):
    session = requests.Session()
    cm_params = {
        "action": "query",
        "format": "json",
        "list": "categorymembers",
        "cmtitle": categorytitle,
        "cmlimit": 500
    }

    request = session.get(url="https://en.wiktionary.org/w/api.php", params=cm_params)
    data = request.json()
    categorymembers = data["query"]["categorymembers"]

    for page in categorymembers:
        pagetitle = page["title"]
        pagetitlesplit = pagetitle.split(":",1)
        if pagetitlesplit[0] == "Category":
            get_categorymembers(pagetitle)
        elif pagetitlesplit[0] == "Template":
            print(pagetitlesplit[1])


get_categorymembers("Category:" + str(sys.argv[1]))
@}

\subsection{Get examples}

This helper script get the first 10 pages using the template page. Executable flag needs to be set manually (nuweb does not seem to provide the option to set this flags in the source documentation).

@o ../src/scripts/get_examples.py
@{#!/usr/bin/python3

import sys
import requests

def get_examples(categorytitle):
    session = requests.Session()
    cm_params = {
        "action": "query",
        "format": "json",
        "list": "embeddedin",
        "eititle": categorytitle,
        "eilimit": 10
    }

    request = session.get(url="https://en.wiktionary.org/w/api.php", params=cm_params)
    data = request.json()
    embeddedin = data["query"]["embeddedin"]

    for page in embeddedin:
        pagetitle = page["title"]
        print(pagetitle)


get_examples("Template:" + str(sys.argv[1]))
@}

\section{Network queries}
The API of wiktionary is used to avoid unneccessary network traffic. We never ask for the whole page but only for the parts which we need for the information we desire.

First \verb#getWiktionarySections()# gets a json Object containing all the sections of the wiktionary page. This sections are searched for the current language, e.g. ``Finnish'' for example. Then this language section is searched for an etymology section. If this etymology section exists, we request this section with \verb#getWiktionarySection()# and check to see if it contains a compound template. If we find a compound template, depending on the status of the database we recursively request the words making up the compound (if the word is in the database already we link to it instead).

After the etymology section is parsed we look for flection sections, i.e. ``Conjugation'' or ``Declination''. Again we get the contents of this sections by calling \verb#getWiktionarySection()# and if we can identify a template we call additionaly \verb#getWiktionaryTemplate# to expand the template with the arguments we find (this will practically render the html form of this particular part of the webpage). We call the appropriate parsing function for this template and process the grammar information we obtain this way.

In the following sequence diagram error handling is not shown to keep it managable. Whenever there is a fatal error the appropriate signals are sent to the caller. Signals are also sent, whenever we can obtain a valid grammar object.

\begin{figure}
\centering
\begin{sequencediagram}
\newthread{sections}{getWiktionarySections()}
\newthread{section}{getWiktionarySection()}
\newthread{template}{getWiktionaryTemplate()}
\newthread{network}{Network Thread}
\newthread{parsetemplate}{Parse Template}
\mess{sections}{requestNetworkReply}{network}
\begin{call}{section}{possible retry}{section}{}
\end{call}
\mess{network}{success}{section}
\begin{sdblock}{Etymology}{Found section}
\begin{call}{section}{requestNetworkReply}{network}{blocking wait}
\begin{call}{template}{possible retry}{template}{}
\end{call}
\mess{network}{success}{template}
\begin{sdblock}{Compound}{Found compound}
\begin{call}{template}{}{sections}{\shortstack{This is a recursive call, so it starts again from the\\
beginning until unlocking the blocking wait}}
\postlevel
\end{call}
\end{sdblock}
\end{call}
\end{sdblock}
\begin{sdblock}{Flection}{Found section}
\mess{section}{requestNetworkReply}{network}
\begin{call}{template}{possible retry}{template}{}
\end{call}
\mess{network}{success}{template}
\mess{template}{requestNetworkReply}{network}
\mess{network}{success}{parsetemplate}
\end{sdblock}
\end{sequencediagram}
\caption{Network queries in grammar provider}
\end{figure}

\section{Interface}
@O ../src/grammarprovider.h -d
@{
@<Start of @'GRAMMARPROVIDER@' header@>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QFile>
#include <QQmlEngine>
#include <QMap>
#include <QMapIterator>
#include <QTextDocument>
#include <QThread>
#include <QEventLoop>
#include <QTime>
#include <QMetaMethod>
#include "settings.h"
#include "database.h"
#include "levenshteindistance.h"
@<Start of class @'grammarprovider@'@>
    Q_PROPERTY(int language MEMBER m_language)
    Q_PROPERTY(QString word MEMBER m_word)
public:
    explicit grammarprovider(QObject *parent = nullptr);
    ~grammarprovider(void);
    struct tablecell {
        int row;
        int column;
        QString content;
    };
    enum lexemePartType {
        FORM,
        FORM_WITH_IGNORED_PARTS,
        COMPOUNDFORM,
        SENTENCE,
    };
    enum lexemePartProcessInstruction {
        IGNOREFORM,
        LOOKUPFORM,
        LOOKUPFORM_LEXEME, // Match lexeme to current lexeme when looking up form
        ADDANDUSEFORM,
        ADDANDIGNOREFORM,
    };
    enum networkRequestStatus {
        REQUEST_SUCCESFUL,
        RETRYING_REQUEST,
        PERMANENT_NETWORK_ERROR,
    };
    struct lexemePartProcess {
        lexemePartProcess(lexemePartProcessInstruction y_instruction):
            instruction(y_instruction),
            grammarexpressions({}){
            }
        lexemePartProcess(lexemePartProcessInstruction y_instruction,
                QList<QList<QString> > y_grammarexpressions):
            instruction(y_instruction),
            grammarexpressions(y_grammarexpressions){
            }
        lexemePartProcessInstruction instruction;
        QList<QList<QString> > grammarexpressions;
    };
    struct grammarform {
        grammarform(int y_index,
                int y_row,
                int y_column,
                QList<QList<QString> > y_grammarexpressions): 
            index(y_index), 
            row(y_row),
            column(y_column),
            grammarexpressions(y_grammarexpressions),
            type(FORM),
            processList({}),
            string(""){
            }
	grammarform(int y_index,
                int y_row,
                int y_column,
                QList<QList<QString> > y_grammarexpressions,
		lexemePartType y_type,
		QList<lexemePartProcess> y_processList): 
            index(y_index), 
            row(y_row),
            column(y_column),
            grammarexpressions(y_grammarexpressions),
            type(y_type),
            processList(y_processList),
            string(""){
            }
        int index;
        int row;
        int column;
        QString string;
        QList<QList<QString> > grammarexpressions;
        lexemePartType type;
        QList<lexemePartProcess> processList;
    };
    struct templatearguments {
        QMap<QString, QString> named;
        QList<QString> unnamed;
    };
    struct scheduled_lookup {
        QObject* m_caller;
        int m_languageid;
        QString m_word;
    };
    struct compoundPart {
        int id;
        bool capitalized;
        QString string;
    };
public slots:
    Q_INVOKABLE void getGrammarInfoForWord(QObject* caller, int languageid, QString word);
    Q_INVOKABLE void getNextGrammarObject(QObject* caller);
    Q_INVOKABLE void getNextSentencePart(QObject* caller);
    Q_INVOKABLE QList<grammarprovider::compoundPart> getGrammarCompoundFormParts(QString compoundword, QList<QString> compoundstrings, int id_language);
private slots:
    void getWiktionarySections();
    void getWiktionarySection(QNetworkReply* reply);
    void getWiktionaryTemplate(QNetworkReply* reply);
    void networkReplyErrorOccurred(QNetworkReply::NetworkError code);
    templatearguments parseTemplateArguments(QString templateString);
    void parseMediawikiTableToPlainText(QString wikitext, QList<grammarprovider::tablecell>& table);
    void parse_compoundform(QNetworkReply* reply);
    QList<QPair<QString,int> > fi_compound_parser(QObject* caller, int fi_id, int lexeme_id, QList<int> compound_lexemes);
    void fi_requirements(QObject* caller, int fi_id);
    void parse_fi_verbs(QNetworkReply* reply);
    void parse_fi_nominals(QNetworkReply* reply);
    void de_requirements(QObject* caller, int de_id);
    void parse_de_noun_n(QNetworkReply* reply);
    void parse_de_noun_m(QNetworkReply* reply);
    void parse_de_noun_f(QNetworkReply* reply);
    void parse_de_verb(QNetworkReply* reply);
    void process_grammar(QList<grammarform> grammarforms, QList<tablecell> parsedTable, QList<QList<QString> > additional_grammarforms = {});
    void getPlainTextTableFromReply(QNetworkReply* reply, QList<grammarprovider::tablecell>& parsedTable);
signals:
    void processingStart(const QString& waitingstring);
    void processingStop(void);
    void networkError(QObject* caller, bool silent);
    void grammarInfoAvailable(QObject* caller, int numberOfObjects, bool silent);
    void grammarInfoNotAvailable(QObject* caller, bool silent);
    void formObtained(QObject* caller, QString form, QList<QList<QString> > grammarexpressions, bool silent, QList<QString> compoundforms);
    void compoundFormObtained(QObject* caller, QString form, bool silent);
    void sentenceAvailable(QObject* caller, int parts, bool silent);
    void sentenceLookupForm(QObject* caller, QString form, QList<QList<QString> > grammarexpressions, bool silent);
    void sentenceLookupFormLexeme(QObject* caller, QString form, QList<QList<QString> > grammarexpressions, bool silent);
    void sentenceAddAndUseForm(QObject* caller, QString form, QList<QList<QString> > grammarexpressions, bool silent);
    void sentenceAddAndIgnoreForm(QObject* caller, QString form, QList<QList<QString> > grammarexpressions, bool silent);
    void sentenceComplete(QObject* caller, QList<QList<QString> > grammarexpressions, bool silent);
    void grammarInfoComplete(QObject* caller, bool silent);
    //void grammarobtained(QObject* caller, QStringList expressions, QList<QList<QList<QString> > > grammarexpressions);
private:
    QNetworkReply* requestNetworkReply(QString url);
    QNetworkReply* repeatLastNetworkRequest();
    networkRequestStatus checkReplyAndRetryIfNecessary(QNetworkReply* reply, QString& s_reply);
    void connectReplyFinishedToSlot(void(grammarprovider::* method)(QNetworkReply*) );
    void reconnectLastReplyFinishedToSlot();
    QUrl m_last_request_url;
    void(grammarprovider::* m_last_connected_slot)(QNetworkReply*);
    int m_language;
    bool m_silent;
    bool m_busy;
    bool m_found_compoundform;
    QList<QString> m_current_compoundforms;
    QString m_word;
    QString s_baseurl;
    QNetworkAccessManager* m_manager;
    QMetaObject::Connection m_tmp_connection;
    QMetaObject::Connection m_tmp_error_connection;
    QNetworkReply* m_networkreply;
    QList<QString> m_parsesections;
    settings* m_settings;
    database* m_database;
    levenshteindistance* m_levenshteindistance;
    QObject* m_caller;
    templatearguments m_currentarguments;
    QList<grammarform> m_grammarforms;
    QList<scheduled_lookup> m_scheduled_lookups;
    QMap<int, void (grammarprovider::*)(QObject*,int)> m_requirements_map;
    QMap<int, QList<QPair<QString,int> > (grammarprovider::*)(QObject* caller, int id, int lexeme_id, QList<int> compound_lexemes)> m_compound_parser_map;
    QMap<QString, void (grammarprovider::*)(QNetworkReply*)> m_parser_map; 
    struct context {
        grammarprovider* l_parent;
        int l_language;
        bool l_silent;
        bool l_busy;
        bool l_found_compoundform;
        QString l_word;
        QMetaObject::Connection l_tmp_connection;
        QMetaObject::Connection l_tmp_error_connection;
        QNetworkReply* l_networkreply;
        QObject* l_caller;
        templatearguments l_currentarguments;
        QList<QString> l_current_compoundforms;
        context(grammarprovider* parent) :
            l_parent(parent),
            l_language(parent->m_language),
            l_silent(parent->m_silent),
            l_busy(parent->m_busy),
            l_word(parent->m_word),
            l_found_compoundform(parent->m_found_compoundform),
            l_tmp_connection(parent->m_tmp_connection),
            l_tmp_error_connection(parent->m_tmp_error_connection),
            l_networkreply(parent->m_networkreply),
            l_caller(parent->m_caller),
            l_currentarguments(parent->m_currentarguments),
            l_current_compoundforms(parent->m_current_compoundforms){
            }
        ~context(){
            l_parent->m_language = l_language;
            l_parent->m_silent = l_silent;
            l_parent->m_busy = l_busy;
            l_parent->m_word = l_word;
            l_parent->m_found_compoundform = l_found_compoundform;
            l_parent->m_tmp_connection = l_tmp_connection;
            l_parent->m_tmp_error_connection = l_tmp_error_connection;
            l_parent->m_networkreply = l_networkreply;
            l_parent->m_caller = l_caller;
            l_parent->m_currentarguments = l_currentarguments;
            l_parent->m_current_compoundforms = l_current_compoundforms;
        }
    };

@<End of class and header @>
@}

\section{Implementation}
@O ../src/grammarprovider.cpp -d
@{
#include "grammarprovider.h"
@}

\cprotect[om]\subsection[grammarprovider]{\verb#grammarprovider#}
@O ../src/grammarprovider.cpp -d
@{
grammarprovider::grammarprovider(QObject *parent) : QObject(parent), m_busy(false)
{
    m_manager = new QNetworkAccessManager(this);
    m_manager->setTransferTimeout(1000);
    s_baseurl = "https://en.wiktionary.org/w/api.php?";
    QQmlEngine* engine = qobject_cast<QQmlEngine*>(parent);
    m_settings = engine->singletonInstance<settings*>(qmlTypeId("SettingsLib", 1, 0, "Settings"));
    m_database = engine->singletonInstance<database*>(qmlTypeId("DatabaseLib", 1, 0, "Database"));
    m_levenshteindistance = engine->singletonInstance<levenshteindistance*>(qmlTypeId("LevenshteinDistanceLib", 1, 0, "LevenshteinDistance"));
    m_parsesections.push_back("Conjugation");
    m_parsesections.push_back("Declension");
    int fi_id = m_database->idfromlanguagename("Finnish");
    m_requirements_map[fi_id] = &grammarprovider::fi_requirements;
    m_compound_parser_map[fi_id] = &grammarprovider::fi_compound_parser;
    int de_id = m_database->idfromlanguagename("German");
    m_requirements_map[de_id] = &grammarprovider::de_requirements;
    m_parser_map["compound"] = &grammarprovider::parse_compoundform;
    m_parser_map["fi-conj-sanoa"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-muistaa"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-huutaa"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-soutaa"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-kaivaa"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-saartaa"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-laskea"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-tuntea"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-lähteä"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-sallia"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-voida"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-saada"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-juoda"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-käydä"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-rohkaista"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-tulla"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-tupakoida"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-valita"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-juosta"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-nähdä"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-vanheta"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-salata"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-katketa"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-selvitä"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-taitaa"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-olla"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-decl-valo"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-palvelu"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-valtio"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-laatikko"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-risti"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-paperi"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-ovi"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-nalle"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-kala"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-koira"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-omena"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-kulkija"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-katiska"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-solakka"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-korkea"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-vanhempi"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-vapaa"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-maa"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-suo"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-filee"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-rosé"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-parfait"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-tiili"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-uni"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-toimi"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-pieni"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-käsi"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-kynsi"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-lapsi"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-veitsi"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-kaksi"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-sisar"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-kytkin"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-onneton"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-lämmin"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-sisin"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-vasen"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-nainen"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-vastaus"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-kalleus"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-vieras"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-mies"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-ohut"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-kevät"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-kahdeksas"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-tuhat"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-kuollut"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-hame"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["de-decl-noun-n"] = &grammarprovider::parse_de_noun_n;
    m_parser_map["de-decl-noun-m"] = &grammarprovider::parse_de_noun_m;
    m_parser_map["de-decl-noun-f"] = &grammarprovider::parse_de_noun_f;
    m_parser_map["de-conj"] = &grammarprovider::parse_de_verb;
}
@}

\cprotect\subsection{\verb#~grammarprovider#}
@O ../src/grammarprovider.cpp -d
@{
grammarprovider::~grammarprovider() {
    delete m_manager;
}
@}

\cprotect\subsection{\verb#getGrammarInfoForWord#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getGrammarInfoForWord(QObject* caller, int languageid, QString word){
    if(m_busy == true){
        m_scheduled_lookups.push_back({caller,languageid,word});
        qDebug() << "Grammarprovider is busy... " + QString::number(m_scheduled_lookups.size()) + " requests waiting";
        return;
    }
    m_busy = true;
    // TODO: Add timeout in case lookup is not successfull
    // Check requirements:
    m_found_compoundform = false;
    if(m_requirements_map.contains(languageid))
        (this->*(m_requirements_map[languageid]))(caller,languageid);
    qDebug() << "...requirements done";
    m_caller = caller;
    m_language = languageid;
    m_word = word;
    m_silent = false;
    m_found_compoundform = false;
    getWiktionarySections();
}
@}

\cprotect\subsection{\verb#requestNetworkReply#}
@O ../src/grammarprovider.cpp -d
@{
QNetworkReply* grammarprovider::requestNetworkReply(QString url){
    m_last_request_url = QUrl(url);
    qDebug() << QTime::currentTime().toString() << "Request" << m_last_request_url.toString();
    QNetworkRequest request(m_last_request_url);
    request.setRawHeader("User-Agent", "Coleitra/0.1 (https://coleitra.org; fpesth@@gmx.de)");
    return m_manager->get(request);
}

QNetworkReply* grammarprovider::repeatLastNetworkRequest(){
    qDebug() << QTime::currentTime().toString() << "Repeated request" << m_last_request_url.toString();
    QNetworkRequest request(m_last_request_url);
    request.setRawHeader("User-Agent", "Coleitra/0.1 (https://coleitra.org; fpesth@@gmx.de)");
    reconnectLastReplyFinishedToSlot();
    return m_manager->get(request);
}
@}

\cprotect\subsection{\verb#getWiktionarySections#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getWiktionarySections(){
    static int numberofcalls=0;
    qDebug() << "---- getWiktionarySections number of calls" << numberofcalls++;
    //qDebug() << "getWiktionarySections enter";
    emit processingStart("Querying en.wiktionary for word \"" + m_word + "\"...");
    connectReplyFinishedToSlot(&grammarprovider::getWiktionarySection);
    QNetworkReply *reply = requestNetworkReply(s_baseurl + "action=parse&page=" + m_word + "&prop=sections&format=json");

#if QT_VERSION >= 0x051500
    m_tmp_error_connection = connect(reply, &QNetworkReply::errorOccurred, this,
                [reply](QNetworkReply::NetworkError) {
                m_busy = false;
                emit processingStop();
                emit networkError(m_caller, m_silent);
                qDebug() << "Error " << reply->errorString(); 
            });
#endif

    //qDebug() << "getWiktionarySections exit";
}
@}

\cprotect\subsection{\verb#connectReplyFinishedToSlot#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::connectReplyFinishedToSlot(void(grammarprovider::* slot)(QNetworkReply*) ){
    m_last_connected_slot = slot;
    m_tmp_connection = connect(m_manager, &QNetworkAccessManager::finished, this, m_last_connected_slot);
}
@}

\cprotect\subsection{\verb#reconnectLastReplyFinishedToSlot#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::reconnectLastReplyFinishedToSlot(){
    m_tmp_connection = connect(m_manager, &QNetworkAccessManager::finished, this, m_last_connected_slot);
}
@}

\cprotect\subsection{\verb#checkReplyAndRetryIfNecessary#}
@O ../src/grammarprovider.cpp -d
@{
grammarprovider::networkRequestStatus grammarprovider::checkReplyAndRetryIfNecessary(QNetworkReply* reply, QString& s_reply){
    static int retrycount = 0;
    const int max_retries = 5;
    if(!reply->isOpen()){
        qDebug() << "Closed reply, error state " << reply->error();
        retrycount++;
        if(retrycount < max_retries){
            qDebug() <<  "Closed reply, retrying" << retrycount;
            m_manager->setTransferTimeout(1000+1000*retrycount);
            repeatLastNetworkRequest();
            return RETRYING_REQUEST;
        }
        else goto giveup;    
    }
    if(reply->error()!=QNetworkReply::NoError){
        qDebug() << "Network error " << reply->error();
        retrycount++;
        if(retrycount < max_retries){
            qDebug() << "Network error, retrying" << retrycount;
            m_manager->setTransferTimeout(1000+1000*retrycount);
            repeatLastNetworkRequest();
            return RETRYING_REQUEST;
        }
        else goto giveup;
    }
    else{
        qDebug() << "No network error";
    }
    if(reply->isReadable()){
        s_reply = QString(reply->readAll());
    }
    else {
        qDebug() << "Empty reply with error" << reply->error();
        retrycount++;
        if(retrycount < max_retries){
            qDebug() << "Empty reply, retrying" << retrycount;
            m_manager->setTransferTimeout(1000+1000*retrycount);
            repeatLastNetworkRequest();
            return RETRYING_REQUEST;
        }
        else goto giveup;
    }
    qDebug() << "Could read reply as" << s_reply;
    retrycount = 0;
    m_manager->setTransferTimeout(1000);
    return REQUEST_SUCCESFUL;
giveup:
    qDebug() << "Tried " + QString::number(retrycount) + " times, giving up with error" << reply->error() << "...";
    retrycount = 0;
    m_manager->setTransferTimeout(1000);
    return PERMANENT_NETWORK_ERROR;
}
@}

\cprotect\subsection{\verb#getWiktionarySection#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getWiktionarySection(QNetworkReply* reply){
    //qDebug() << "getWiktionarySection enter";

    QObject::disconnect(m_tmp_connection);
    reply->deleteLater();
    QString s_reply;
    switch(checkReplyAndRetryIfNecessary(reply,s_reply)){
        case REQUEST_SUCCESFUL:
            break;
        case RETRYING_REQUEST:
            return;
        case PERMANENT_NETWORK_ERROR:
            m_busy = false;
            emit processingStop();
            emit networkError(m_caller, m_silent);
            return;
    }
    
    //qDebug() << s_reply;

    int languageid = m_language;
    QString language = m_database->languagenamefromid(languageid);

    QJsonDocument j_sectionsDocument = QJsonDocument::fromJson(s_reply.toUtf8());
    QJsonArray j_sections = j_sectionsDocument.object()["parse"].toObject()["sections"].toArray();
    bool found_language = false;
    int best_bet_for_section = 0;
    int section_level = 0;
    int language_section_level = 0;
    QString s_section;
    foreach(const QJsonValue& jv_section, j_sections){
        QJsonObject j_section = jv_section.toObject();
        s_section = j_section["line"].toString();
        section_level = j_section["level"].toString().toInt();
        if(section_level <= language_section_level) break;
        //qDebug() << "Section" << s_section << "language" << language;
        if(s_section == language){
            found_language = true;
            best_bet_for_section = j_section["index"].toString().toInt();
            language_section_level = section_level;
        }
        else{
            if(found_language){
                int l_found_compoundform = m_found_compoundform;
                templatearguments l_currentarguments = m_currentarguments;
                QList<QString> l_current_compoundforms = m_current_compoundforms;
                if(s_section == "Etymology"){
                    qDebug() << "Found etymology section";
                    // Check, if this is a compund word
                    /* Store state (restored at end of scope): */
                    context save_state(this);
                    /* If there is any compound part it should be
                       added silently. */
                    m_silent = true;
                    /* Block this function until we have figured out
                       that either this is not a compound word or we
                       have obtained all compound forms */
                    QEventLoop waitloop;
                    qDebug() << __FILE__ << __FUNCTION__ << __LINE__ << &waitloop;
                    m_caller = &waitloop;
                    /* We have to check for the caller pointer because
                       this might get recursive */
                    QMetaObject::Connection gic_con;
                    QMetaObject::Connection gina_con;
                    gic_con = connect(this, &grammarprovider::grammarInfoComplete,
                            [&](QObject* caller, bool silent){
                                if(caller == &waitloop){
                                    qDebug() << "Got grammarInfoComplete signal in lambda function for etymology section" << m_word << m_caller;
                                    disconnect(gic_con);
                                    disconnect(gina_con);
                                    waitloop.quit();
                                }
                            });
                    gina_con = connect(this, &grammarprovider::grammarInfoNotAvailable,
                            [&](QObject* caller, bool silent){
                                if(caller == &waitloop){
                                    qDebug() << "Got grammarInfoNotComplete signal in lambda function for etymology section" << m_word << m_caller;
                                    disconnect(gic_con);
                                    disconnect(gina_con);
                                    waitloop.quit();
                                }
                            });
                    best_bet_for_section = j_section["index"].toString().toInt();
                    connectReplyFinishedToSlot(&grammarprovider::getWiktionaryTemplate);
                    QNetworkReply *reply = requestNetworkReply(s_baseurl + "action=parse&page=" + m_word + "&section=" + QString::number(best_bet_for_section) + "&prop=wikitext&format=json");
                    qDebug() << "Blocking waitloop for" << m_word << "...";
                    waitloop.exec();
                    qDebug() << "... blocking waitloop for" << m_word << "finished.";
                    l_found_compoundform = m_found_compoundform;
                    l_currentarguments = m_currentarguments;
                    foreach(QString arg, l_currentarguments.unnamed){
                        qDebug() << "Blocking loop came back with arg" << arg;
                    }
                    l_current_compoundforms = m_current_compoundforms;
                }
                m_found_compoundform = l_found_compoundform;
                m_currentarguments = l_currentarguments;
                m_current_compoundforms = l_current_compoundforms;
                foreach(const QString& parsesection, m_parsesections){
                    if(s_section == parsesection){
                        best_bet_for_section = j_section["index"].toString().toInt();
                        goto finished;
                    }
                }
            }
        }
    }
    finished:
    if(found_language){
        //qDebug() << "Found language section \"" + language + "\" for word \"" + m_word + "\"";
        connectReplyFinishedToSlot(&grammarprovider::getWiktionaryTemplate);
        QNetworkReply *reply = requestNetworkReply(s_baseurl + "action=parse&page=" + m_word + "&section=" + QString::number(best_bet_for_section) + "&prop=wikitext&format=json");
#if QT_VERSION >= 0x051500
        connect(reply, &QNetworkReply::errorOccurred, this,
                [reply](QNetworkReply::NetworkError) {
                emit processingStop();
                emit networkError(m_caller, m_silent);
                qDebug() << "Error " << reply->errorString(); 
            });
#endif

    }
    else{
        qDebug() << "Could not find language section \"" + language + "\" for word \"" + m_word + "\"";
        m_busy = false;
        emit processingStop();
        emit grammarInfoNotAvailable(m_caller, m_silent);
        return;
    }
    //qDebug() << "getWiktionarySection exit";
}
@}

\cprotect\subsection{\verb#networkReplyErrorOccurred#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::networkReplyErrorOccurred(QNetworkReply::NetworkError code){
    emit processingStop();
    //qDebug() << "Error occured in network request in grammar provider:" << QIODevice::errorString();
}
@}

\cprotect\subsection{\verb#parseTemplateArguments#}
@O ../src/grammarprovider.cpp -d
@{
grammarprovider::templatearguments grammarprovider::parseTemplateArguments(QString templateString){
    templateString = templateString.trimmed();
    templateString.remove(0,2);
    templateString.chop(2);
    QStringList args = templateString.split(QLatin1Char('|'));
    templatearguments parsed_args;
    foreach(const QString& arg, args){
        if(arg.contains(QLatin1Char('='))){
            QStringList keyval = arg.split(QLatin1Char('='));
            parsed_args.named[keyval.first()] = keyval.last();
            //qDebug() << keyval.first() << "=" << keyval.last();
        }
        else {
            parsed_args.unnamed.push_back(arg);
            //qDebug() << arg;
        }
    }
    return parsed_args;
}
@}

\cprotect\subsection{\verb#getWiktionaryTemplate#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getWiktionaryTemplate(QNetworkReply* reply){
    QObject::disconnect(m_tmp_connection);
    reply->deleteLater();
    QString s_reply;
    switch(checkReplyAndRetryIfNecessary(reply,s_reply)){
        case REQUEST_SUCCESFUL:
            break;
        case RETRYING_REQUEST:
            return;
        case PERMANENT_NETWORK_ERROR:
            m_busy = false;
            emit processingStop();
            emit networkError(m_caller, m_silent);
            return;
    }

    QJsonDocument j_document = QJsonDocument::fromJson(s_reply.toUtf8());
    QString wikitemplate_text = j_document.object()["parse"].toObject()["wikitext"].toObject()["*"].toString();
    QStringList wt_firsts = wikitemplate_text.split("{{");
    int i_first = 0;
    QStringList wt_opens;
    QStringList wt_finisheds;
    foreach(const QString& wt_first, wt_firsts){
        i_first++;
        if(i_first == 1){
            continue;
        }
        int ot_i1 = 0;
        wt_opens.push_back("");
        foreach(const QString& wt_open, wt_opens){
            if(!wt_first.contains("}}")){
                wt_opens[ot_i1] += "{{" + wt_first;
                ot_i1++;
            }
            else{
                wt_opens[ot_i1] += "{{";
                ot_i1++;
            }
        }
        QStringList wt_seconds = wt_first.split("}}");
        int i_second = 0;
        int i_second_max =  wt_seconds.size();
        foreach(const QString& wt_second, wt_seconds){
            i_second++;
            if(i_second == i_second_max){
                continue;
            }
            int ot_i = 0;
            foreach(const QString& wt_open, wt_opens){
                wt_opens[ot_i] += wt_second + "}}";
                ot_i++;
            }
            wt_finisheds.push_back(wt_opens.last());
            wt_opens.pop_back();
        }
    }
    QMapIterator<QString, void (grammarprovider::*)(QNetworkReply*)> parser(m_parser_map); 
    while (parser.hasNext()) {
        parser.next();
        foreach(const QString& wt_finished, wt_finisheds){
            if(wt_finished.startsWith("{{" + parser.key())){
                if(parser.key() == "compound"){
                    m_currentarguments = parseTemplateArguments(wt_finished);
                    emit processingStop();
                    emit processingStart("Parsing wiktionary compound form data...");
                    m_found_compoundform = true;
                    parse_compoundform(nullptr);
                    return;
                }
                m_currentarguments = parseTemplateArguments(wt_finished);
                connectReplyFinishedToSlot(parser.value());
                emit processingStop();
                emit processingStart("Parsing wiktionary data...");
                requestNetworkReply(s_baseurl + "action=expandtemplates&text=" + QUrl::toPercentEncoding(wt_finished) + "&title=" + m_word + "&prop=wikitext&format=json");
                return;
            }
        }
    }
    qDebug() << "Template(s)" << wt_finisheds << "not supported!";
    emit processingStop();
    emit grammarInfoNotAvailable(m_caller, m_silent);
}
@}

\cprotect\subsection{\verb#parseMediawikiTableToPlainText#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::parseMediawikiTableToPlainText(QString wikitext, QList<grammarprovider::tablecell>& table){
    QStringList table_lines = wikitext.split("\n");
    int column=0;
    int row=0;
    int rowspan=0;
    foreach(QString table_line, table_lines){
        int columnspan = 0;
        auto process_line = [&columnspan,&rowspan](QString table_line){
            //qDebug() << "__P 0 (input)" << table_line;
            int colspan_i = table_line.indexOf("colspan=\"");
            if(colspan_i != -1){
                int colspan_j = table_line.indexOf("\"",colspan_i+9);
                columnspan += table_line.midRef(colspan_i+9,colspan_j-colspan_i-9).toInt()-1;
            }
            int rowspan_i = table_line.indexOf("rowspan=\"");
            if(rowspan_i != -1){
                int rowspan_j = table_line.indexOf("\"",rowspan_i+9);
                rowspan = table_line.midRef(rowspan_i+9,rowspan_j-rowspan_i-9).toInt()-1;
            }
            int formatting_i = table_line.indexOf("|");
            if(!table_line.left(formatting_i).contains("[[")){
                table_line.remove(0,formatting_i+1);
            }
            //qDebug() << "__P 1 (removed wiki braces)" << table_line;
            table_line.remove(QRegularExpression("<sup.*?<\\/sup>"));
            //qDebug() << "__P 2 (removed sup)" << table_line;
	    table_line.replace(QString("<br/>"),QString(","));
	    table_line.replace(QString("<br />"),QString(","));
            //qDebug() << "__P 3" << table_line;
            QStringList html_markupstrings = table_line.split("<");
            if(html_markupstrings.size() > 1){
                table_line = "";
                foreach(QString html_markupstring, html_markupstrings){
                    int tag_end = html_markupstring.indexOf(">");
                    html_markupstring.remove(0,tag_end+1);
                    table_line += html_markupstring;
                }
            }
            //qDebug() << "__P 4" << table_line;
            QStringList wiki_links = table_line.split("[[");
            if(wiki_links.size() > 1){
                table_line = "";
                foreach(QString wiki_link, wiki_links){
                    int tag_end = wiki_link.indexOf("]]");
                    if(tag_end != -1){
                        table_line += wiki_link.left(tag_end).split("|").last();
                        table_line += wiki_link.right(wiki_link.size()-tag_end-2);
                    }
                    else{
                        table_line += wiki_link;
                    }
                }
            }
            //qDebug() << "__P 6" << table_line;
            table_line.remove("(");
            table_line.remove(")");
            //qDebug() << "__P 7" << table_line;
            table_line = table_line.trimmed();
            //qDebug() << "__P 8" << table_line;
            QTextDocument text;
            text.setHtml(table_line);
            table_line = text.toPlainText();
            //qDebug() << "__P 9" << table_line;
            return table_line;
        };
        if(table_line.startsWith("|-")){
            row++;
            column=0;
            if(rowspan>0){
                column++;
                rowspan--;
            }
            continue;
        }
        if(table_line.startsWith("!")){
            table_line.remove(0,2);
            column++;
            table_line = process_line(table_line);
	    QStringList table_entries = table_line.split(QLatin1Char(','));
            //qDebug() << "__P 10" << table_entries;
            foreach(QString table_entry, table_entries){
                table_entry = table_entry.trimmed();
                if(!table_entry.isEmpty())
                    table.push_back({row,column,table_entry});
                //qDebug() << row << column << table_entry;
            }
            column += columnspan;
            continue;
        }
        if(table_line.startsWith("|")){
            table_line.remove(0,2);
            column++;
            table_line = process_line(table_line);
	    QStringList table_entries = table_line.split(QLatin1Char(','));
            //qDebug() << "__P 10" << table_entries;
            foreach(QString table_entry, table_entries){
                table_entry = table_entry.trimmed();
                if(!table_entry.isEmpty())
                    table.push_back({row,column,table_entry});
                //qDebug() << row << column << table_entry;
            }
            column += columnspan;
            continue;
        }
    }
}
@}

\cprotect\subsection{\verb#process_grammar#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::process_grammar(QList<grammarform> grammarforms, QList<tablecell> parsedTable, QList<QList<QString> > additional_grammarforms){
    if(!parsedTable.isEmpty()){
        foreach(const grammarform& gf_expectedcell, grammarforms){
            tablecell tc_current = parsedTable.first();
            //qDebug() << "__PG 0" << tc_current.row << tc_current.column << tc_current.content << "exp:" << gf_expectedcell.row << gf_expectedcell.column;
            while(tc_current.row < gf_expectedcell.row){
                if(!parsedTable.isEmpty()){
                    parsedTable.pop_front();
                    if(!parsedTable.isEmpty()){
                        tc_current = parsedTable.first();
                        //qDebug() << "__PG 1" << tc_current.row << tc_current.column << tc_current.content << "exp:" << gf_expectedcell.row << gf_expectedcell.column;
                    }
                    else goto out;
                }
                else break;
            }
            if(tc_current.row == gf_expectedcell.row){
                while(tc_current.column < gf_expectedcell.column){
                    if(!parsedTable.isEmpty()){
                        parsedTable.pop_front();
                        if(!parsedTable.isEmpty()){
                            tc_current = parsedTable.first();
                            //qDebug() << "__PG 2" << tc_current.row << tc_current.column << tc_current.content << "exp:" << gf_expectedcell.row << gf_expectedcell.column;
                        }
                        else goto out;
                    }
                    else break;
                }
                if(tc_current.column == gf_expectedcell.column){
matching_form:
                    if(tc_current.content != "—"){
                        //qDebug() << "__PG A" << tc_current.row << tc_current.column << tc_current.content << "exp:" << gf_expectedcell.row << gf_expectedcell.column;
                        grammarform currentGrammarForm = gf_expectedcell;
                        currentGrammarForm.string = tc_current.content;
                        currentGrammarForm.grammarexpressions += additional_grammarforms;
                        m_grammarforms.push_back(currentGrammarForm);
                        // There may be more than one:
                        parsedTable.pop_front();
                        if(!parsedTable.isEmpty()){
                            tc_current = parsedTable.first();
                            //qDebug() << "__PG 3" << tc_current.row << tc_current.column << tc_current.content << "exp:" << gf_expectedcell.row << gf_expectedcell.column;
                        }
                        else goto out;
                        // A "while" would be worse than this "goto" as it would
                        // have to include or treat the column search again.
                        if(tc_current.row == gf_expectedcell.row)
                            if(tc_current.column == gf_expectedcell.column){
                                //qDebug() << "__PG E going back...";
                                goto matching_form;
                            }
                        //qDebug() << "__PG E not going back!";
                    }
                }
            }
        }
    }
out:
    std::sort(m_grammarforms.begin(), m_grammarforms.end(), [](grammarform a, grammarform b) {
        return a.index < b.index;
    });
    //qDebug() << "Got" << m_grammarforms.size();

    emit processingStop();
    emit grammarInfoAvailable(m_caller, m_grammarforms.size(), m_silent);
    //emit grammarobtained(m_caller, expressions, grammarexpressions);
}
@}

\cprotect\subsection{\verb#getNextGrammarObject#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getNextGrammarObject(QObject* caller){
    qDebug() << "grammarprovider::getNextGrammarObject enter";
    m_caller = caller;
    if(m_grammarforms.isEmpty()){
        qDebug() << __FUNCTION__ << __LINE__ << "*** grammarInfoComplete EMIT ***";
        emit grammarInfoComplete(m_caller,m_silent);
        if(!m_scheduled_lookups.isEmpty()){
            scheduled_lookup next_lookup = m_scheduled_lookups.first();
            m_scheduled_lookups.removeFirst();
            m_busy = false;
            getGrammarInfoForWord(next_lookup.m_caller, next_lookup.m_languageid, next_lookup.m_word);
        }
        else {
            m_busy = false;
        }
        //qDebug() << "grammarprovider::getNextGrammarObject exit" << __LINE__;
        return;
    }
    QMutableListIterator<grammarform> grammarFormI(m_grammarforms);
    grammarform& form = grammarFormI.next();
    //qDebug() << "form.string" << form.string;
    switch(form.type){
        case FORM:
            {
                //qDebug() << form.index << form.string << "FORM" << form.grammarexpressions;
                QString string = form.string;
                QList<QList<QString > > ge = form.grammarexpressions;
                if(!m_grammarforms.isEmpty())
                    m_grammarforms.removeFirst();
                else 
                    qDebug() << "ERROR m_grammarforms is empty!" << __LINE__;
                {
                    qDebug() << "----- formObtained" << m_caller << string << ge << m_silent << m_found_compoundform << m_current_compoundforms;
                    qDebug() << __FUNCTION__ << __LINE__ << "*** formObtained EMIT ***";
                    if(m_found_compoundform)
                        emit formObtained(m_caller, string, ge, m_silent, m_current_compoundforms);
                    else
                        emit formObtained(m_caller, string, ge, m_silent, {});
                }
                //qDebug() << "grammarprovider::getNextGrammarObject exit" << __LINE__;
                return;
            }
            break;
        case FORM_WITH_IGNORED_PARTS:
            {
                QList<QList<QString > > ge = form.grammarexpressions;
                QStringList formparts = form.string.split(QLatin1Char(' '));
                if(formparts.size() == form.processList.size()){
                    int formparti = 0;
                    foreach(const QString& formpart, formparts){
                        switch(form.processList.at(formparti).instruction){
                            case IGNOREFORM:
                                //qDebug() << "IGNOREFORM" << formpart;
                                break;
                            case LOOKUPFORM:
                                //qDebug() << "LOOKUPFORM" << formpart;
                                break;
                            case LOOKUPFORM_LEXEME:
                                //qDebug() << "LOOKUPFORM_LEXEME" << formpart;
                                break;
                            case ADDANDUSEFORM:
                                //qDebug() << "ADDANDUSEFORM" << formpart;
                                if(!m_grammarforms.isEmpty())
                                    m_grammarforms.removeFirst();
                                else 
                                    qDebug() << "ERROR m_grammarforms is empty!" << __LINE__;
                                {
                                    qDebug() << "----- formObtained" << m_caller << formpart << ge << m_silent << m_found_compoundform << m_current_compoundforms;
                                    qDebug() << __FUNCTION__ << __LINE__ << "*** formObtained EMIT ***";
                                    if(m_found_compoundform)
                                        emit formObtained(m_caller, formpart, ge, m_silent, m_current_compoundforms);
                                    else
                                        emit formObtained(m_caller, formpart, ge, m_silent, {});
                                }
                                // return needed here to be reentrant:
                                return;
                                break;
                            case ADDANDIGNOREFORM:
                                break;
                        }
                        formparti++;
                    }
                }
                else {
                    qDebug() << "Process list size (=" + QString::number(form.processList.size()) +  ") does not match number of form parts (=" + formparts.size() + ")!";
                }
            }
            break;
        case COMPOUNDFORM:
            //qDebug() << form.index << form.string << "COMPOUNDFORM" << form.grammarexpressions;
            break;
        case SENTENCE:
            //qDebug() << form.index << form.string << "SENTENCE" << form.grammarexpressions;
            {
                QStringList sentenceparts = form.string.split(QLatin1Char(' '));
                if(sentenceparts.size() == form.processList.size()){
                    //Preprocess sentence:
                    QMutableListIterator<lexemePartProcess> lexemeProcessI(form.processList);
                    int sentencepartid = 0;
                    while(lexemeProcessI.hasNext()){
                        lexemePartProcess& currentProcess = lexemeProcessI.next();
                        if(currentProcess.instruction == ADDANDUSEFORM){
                            //qDebug() << "ADDANDUSEFORM for part" << sentenceparts.at(sentencepartid) << sentencepartid << currentProcess.grammarexpressions;
                            currentProcess.instruction = LOOKUPFORM_LEXEME;
                            qDebug() << "----- formObtained" << m_caller << sentenceparts.at(sentencepartid) << currentProcess.grammarexpressions << m_silent << m_found_compoundform;
                            qDebug() << __FUNCTION__ << __LINE__ << "*** formObtained EMIT ***";
                            if(m_found_compoundform)
                                emit formObtained(m_caller, sentenceparts.at(sentencepartid), currentProcess.grammarexpressions, m_silent, m_current_compoundforms);
                            else
                                emit formObtained(m_caller, sentenceparts.at(sentencepartid), currentProcess.grammarexpressions, m_silent, {});
                            //qDebug() << "grammarprovider::getNextGrammarObject exit" << __LINE__;
                            return;
                        }
                        sentencepartid++;
                    }
                    emit sentenceAvailable(m_caller, form.processList.size(), m_silent);
                }
                else {
                    qDebug() << "Process list size (=" + QString::number(form.processList.size()) +  ") does not match number of sentence parts (=" + sentenceparts.size() + ")!";
                }
            }
            break;
        default:
            qDebug() << form.index << form.string << "unknown form!" << form.grammarexpressions;
            break;
    }
    //qDebug() << "grammarprovider::getNextGrammarObject exit" << __LINE__;
}
@}

\cprotect\subsection{\verb#getNextSentencePart#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getNextSentencePart(QObject* caller){
    m_caller = caller;
    if(m_grammarforms.isEmpty()){
        qDebug() << "getNextSentencePart is called with no grammar objects remaining!";
        return;
    }
    grammarform form = m_grammarforms.first();
    // We modify m_grammarforms, so we remove it always and add it back
    // later:
    m_grammarforms.removeFirst();
    // Check that there is still stuff to process:
    if(form.processList.isEmpty()){
        QList<QList<QString > > ge = form.grammarexpressions;
        emit sentenceComplete(m_caller,ge,m_silent);
        return;
    }
    // Process sentence parts:
    lexemePartProcess process = form.processList.first();
    form.processList.removeFirst();
    QStringList sentenceparts = form.string.split(QLatin1Char(' '));
    if(sentenceparts.size() > 1)
        form.string.remove(0,sentenceparts.at(0).size()+1);
    m_grammarforms.push_front(form);
    switch(process.instruction){
        case IGNOREFORM:
            getNextSentencePart(m_caller);
            break;
        case LOOKUPFORM:
            //qDebug() << sentenceparts.at(0) << "LOOKUPFORM" << process.grammarexpressions;
            emit sentenceLookupForm(m_caller,sentenceparts.at(0),process.grammarexpressions, m_silent);
            break;
        case LOOKUPFORM_LEXEME:
            //qDebug() << sentenceparts.at(0) << "LOOKUPFORM_LEXEME" << process.grammarexpressions;
            emit sentenceLookupFormLexeme(m_caller,sentenceparts.at(0),process.grammarexpressions, m_silent);
            break;
        case ADDANDUSEFORM:
            //qDebug() << sentenceparts.at(0) << "ADDANDUSEFORM" << process.grammarexpressions;
            emit sentenceAddAndUseForm(m_caller,sentenceparts.at(0),process.grammarexpressions, m_silent);
            break;
        case ADDANDIGNOREFORM:
            //qDebug() << sentenceparts.at(0) << "ADDANDIGNOREFORM" << process.grammarexpressions;
            emit sentenceAddAndIgnoreForm(m_caller,sentenceparts.at(0),process.grammarexpressions, m_silent);
            break;
        default:
            //qDebug() << "Unknown processing instruction... ignoring!";
            getNextSentencePart(m_caller);
            break;
    }
}
@}

\cprotect\subsection{\verb#getPlainTextTableFromReply#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getPlainTextTableFromReply(QNetworkReply* reply, QList<grammarprovider::tablecell>& parsedTable){
    QObject::disconnect(m_tmp_connection);
    reply->deleteLater();
    QString s_reply;
    switch(checkReplyAndRetryIfNecessary(reply,s_reply)){
        case REQUEST_SUCCESFUL:
            break;
        case RETRYING_REQUEST:
            return;
        case PERMANENT_NETWORK_ERROR:
            m_busy = false;
            emit processingStop();
            emit networkError(m_caller, m_silent);
            return;
    }

    QObject::disconnect(m_tmp_connection);
    reply->deleteLater();

    QJsonDocument j_document = QJsonDocument::fromJson(s_reply.toUtf8());
    QString wikitemplate_text = j_document.object()["expandtemplates"].toObject()["wikitext"].toString();
    parseMediawikiTableToPlainText(wikitemplate_text, parsedTable);
}
@}

\cprotect\subsection{\verb#getGrammarCompoundFormParts#}
@O ../src/grammarprovider.cpp -d
@{
QList<grammarprovider::compoundPart> grammarprovider::getGrammarCompoundFormParts(QString compoundword, QList<QString> compoundstrings, int id_language){
    // Forms are saved strictly sequential, so all
    // needed forms should be in the database already
    bool found_all_lexemes = true;
    QList<QList<QPair<QString,int> > > compoundformpart_candidates;
    foreach(QString compoundform, compoundstrings){
        QList<int> possible_lexemes = m_database->searchLexemes(compoundform, true);
        int found_lexeme = 0;
        foreach(int possible_lexeme, possible_lexemes){
            if(m_database->languageOfLexeme(possible_lexeme) == id_language){
                found_lexeme = possible_lexeme;
                break;
            }
        }
        if(found_lexeme > 0){
            QList<QPair<QString,int> > forms = m_database->listFormsOfLexeme(found_lexeme);
            compoundformpart_candidates.push_back(forms);
        }
        else{
            found_all_lexemes = false;
            break;
        }
    }
    qDebug() << "Found all lexemes:" << found_all_lexemes;
    QList<levenshteindistance::compoundpart> compoundparts = m_levenshteindistance->stringdivision(compoundformpart_candidates,compoundword);
    levenshteindistance::compoundpart m_compoundpart;
    QList<compoundPart> compoundpartsgrammar;
    foreach(m_compoundpart, compoundparts){
        compoundpartsgrammar.push_back({m_compoundpart.id,m_compoundpart.capitalized,m_compoundpart.string});
        qDebug() << "Compound part" << m_compoundpart.division << m_compoundpart.id << m_compoundpart.capitalized << m_compoundpart.string;
    }
    return compoundpartsgrammar;
}
@}

\cprotect\subsection{\verb#parse_compoundform#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::parse_compoundform(QNetworkReply* reply){
    qDebug() << "Got compound form";
    int argnumber=0;
    m_current_compoundforms.clear();
    foreach(const QString& arg, m_currentarguments.unnamed){
        argnumber++;
        if(argnumber>2){
            bool found_form = false;
            QList<int> compoundpart_forms = m_database->searchForms(arg,true);
            foreach(int compoundpart_form, compoundpart_forms){
                int grammarform = m_database->grammarFormFromFormId(compoundpart_form);
                int languageid = m_database->languageIdFromGrammarFormId(grammarform);
                if(languageid == m_language){
                    found_form = true;
                    qDebug() << "Found form" << arg;
                    break;
                }
            }
            if(!found_form){
                qDebug() << "Could not find form" << arg << ", looking it up...";
                context save_state(this);
                QEventLoop waitloop;
                qDebug() << __FILE__ << __FUNCTION__ << __LINE__ << &waitloop;
                m_caller = &waitloop;
                m_word = arg;
                m_silent = true;
                m_found_compoundform = false;
                QMetaObject::Connection gic_con;
                QMetaObject::Connection gina_con;
                gic_con = connect(this, &grammarprovider::grammarInfoComplete,
                        [&](QObject* caller, bool silent){
                            if(caller == &waitloop){
                                qDebug() << "Got grammarInfoComplete signal in lambda function for compoundform search" << m_word << m_caller;
                                disconnect(gic_con);
                                disconnect(gina_con);
                                waitloop.quit();
                            }
                        });
                gina_con = connect(this, &grammarprovider::grammarInfoNotAvailable,
                        [&](QObject* caller, bool silent){
                            if(caller == &waitloop){
                                qDebug() << "Got grammarInfoNotComplete signal in lambda function for compoundform search" << m_word << m_caller;
                                disconnect(gic_con);
                                disconnect(gina_con);
                                waitloop.quit();
                            }
                        });
                getWiktionarySections();
                qDebug() << "Blocking waitloop for compoundform" << m_word << "...";
                waitloop.exec();
                qDebug() << "... blocking waitloop for compoundform" << m_word << "finished.";
            }
            m_current_compoundforms += arg;
        }
    }
    qDebug() << __FUNCTION__ << __LINE__ << "*** grammarInfoComplete EMIT ***";
    emit grammarInfoComplete(m_caller, m_silent);
}
@}

\section{Language specific implementations}
\subsection{Finnish}

\cprotect\subsubsection{\verb#fi_requirements#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::fi_requirements(QObject* caller, int fi_id){
    QList<int> olla_forms = m_database->searchForms("olla",true);
    int expected_grammarform = m_database->grammarFormIdFromStrings(fi_id,{{"Infinitive","First"},{"Voice","Active"},{"Part of speech","Verb"}});
    bool found_form = false;
    foreach(int olla_form, olla_forms){
        int grammarform = m_database->grammarFormFromFormId(olla_form);
        if(grammarform == expected_grammarform){
            found_form = true;
            break;
        }
    }
    if(!found_form){
        m_caller = caller;
        m_language = fi_id;
        m_word = "olla";
        m_silent = true;
        QEventLoop waitloop;
        connect( this, &grammarprovider::grammarInfoComplete, &waitloop, &QEventLoop::quit );
        getWiktionarySections();
        waitloop.exec();
    }
}
@}

\cprotect\subsubsection{\verb#fi_compound_parser#}
@O ../src/grammarprovider.cpp -d
@{
QList<QPair<QString,int> > grammarprovider::fi_compound_parser(QObject* caller, int fi_id, int lexeme_id, QList<int> compound_lexemes){
}
@}

\cprotect\subsubsection{\verb#parse_fi_verbs#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::parse_fi_verbs(QNetworkReply* reply){
    QList<grammarprovider::tablecell> parsedTable;
    getPlainTextTableFromReply(reply, parsedTable);
    QList<grammarform> grammarforms {
        {1,5,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}}},
        {63,5,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {93,5,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {123,5,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {2,6,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}}},
        {64,6,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {94,6,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {124,6,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {3,7,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}}},
        {65,7,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {95,7,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {125,7,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {4,8,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}}},
        {66,8,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {96,8,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {126,8,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {5,9,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}}},
        {67,9,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {97,9,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {127,9,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {6,10,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}}},
        {68,10,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {98,10,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {128,10,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {7,11,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Voice","Passive"}}},
        {153,11,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}}}}},
        {158,11,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {163,11,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {8,14,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}}},
        {69,14,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {99,14,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {129,14,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {9,15,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}}},
        {70,15,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {100,15,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {130,15,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {10,16,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}}},
        {71,16,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {101,16,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {131,16,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {11,17,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}}},
        {72,17,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {102,17,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {132,17,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {12,18,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}}},
        {73,18,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {103,18,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {133,18,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {13,19,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}}},
        {74,19,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {104,19,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {134,19,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {14,20,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Voice","Passive"}}},
        {154,20,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {159,20,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {164,20,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {15,24,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}}},
        {75,24,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {105,24,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {135,24,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {16,25,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}}},
        {76,25,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {106,25,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {136,25,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {17,26,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}}},
        {77,26,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {107,26,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {137,26,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {18,27,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}}},
        {78,27,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {108,27,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {138,27,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {19,28,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}}},
        {79,28,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {109,28,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {139,28,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {20,29,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}}},
        {80,29,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {110,29,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {140,29,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {21,30,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Voice","Passive"}}},
        {155,30,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}}}}},
        {160,30,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {165,30,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {22,34,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}}},
        {81,34,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}}}}},
        {111,34,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {141,34,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {23,35,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}}},
        {82,35,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}}}}},
        {112,35,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {142,35,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {24,36,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}}},
        {83,36,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}}}}},
        {113,36,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {143,36,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {25,37,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}}},
        {84,37,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}}}}},
        {114,37,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {144,37,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {26,38,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}}},
        {85,38,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}}}}},
        {115,38,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {145,38,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {27,39,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}}},
        {86,39,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}}}}},
        {116,39,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {146,39,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {28,40,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Voice","Passive"}}},
        {156,40,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}}}}},
        {161,40,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {166,40,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {29,44,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}}},
        {87,44,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {117,44,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {147,44,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {30,45,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}}},
        {88,45,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {118,45,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {148,45,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {31,46,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}}},
        {89,46,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {119,46,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {149,46,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {32,47,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}}},
        {90,47,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {120,47,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {150,47,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {33,48,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}}},
        {91,48,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {121,48,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {151,48,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {34,49,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}}},
        {92,49,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {122,49,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {152,49,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {35,50,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Voice","Passive"}}},
        {157,50,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}}}}},
        {162,50,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {167,50,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {36,54,3,{{"Infinitive","First"},{"Voice","Active"}}},
        {37,54,6,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Present"}}},
        {38,54,7,{{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Present"}}},
        {39,55,3,{{"Infinitive","Long first"},{"Voice","Active"}}},
        {40,55,6,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}},
        {41,55,7,{{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}},
        {42,56,3,{{"Infinitive","Second"},{"Voice","Active"},{"Case","Inessive"}}},
        {43,56,4,{{"Infinitive","Second"},{"Voice","Passive"},{"Case","Inessive"}}},
        {44,56,6,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Agent"}}},
        {45,57,3,{{"Infinitive","Second"},{"Voice","Active"},{"Case","Instructive"}}},
        {46,57,4,{{"Infinitive","Second"},{"Voice","Passive"},{"Case","Instructive"}}},
        {47,57,6,{{"Verbform","Participle"},{"Voice","Active"},{"Polarity","Negative"}}},
        {48,58,3,{{"Infinitive","Third"},{"Voice","Active"},{"Case","Inessive"}}},
        {49,58,4,{{"Infinitive","Third"},{"Voice","Passive"},{"Case","Inessive"}}},
        {50,59,3,{{"Infinitive","Third"},{"Voice","Active"},{"Case","Elative"}}},
        {51,59,4,{{"Infinitive","Third"},{"Voice","Passive"},{"Case","Elative"}}},
        {52,60,3,{{"Infinitive","Third"},{"Voice","Active"},{"Case","Illative"}}},
        {53,60,4,{{"Infinitive","Third"},{"Voice","Passive"},{"Case","Illative"}}},
        {54,61,3,{{"Infinitive","Third"},{"Voice","Active"},{"Case","Adessive"}}},
        {55,61,4,{{"Infinitive","Third"},{"Voice","Passive"},{"Case","Adessive"}}},
        {56,62,3,{{"Infinitive","Third"},{"Voice","Active"},{"Case","Abessive"}}},
        {57,62,4,{{"Infinitive","Third"},{"Voice","Passive"},{"Case","Abessive"}}},
        {58,63,3,{{"Infinitive","Third"},{"Voice","Active"},{"Case","Instructive"}}},
        {59,63,4,{{"Infinitive","Third"},{"Voice","Passive"},{"Case","Instructive"}}},
        {60,64,4,{{"Infinitive","Fourth"},{"Voice","Active"},{"Case","Nominative"}}},
        {61,65,3,{{"Infinitive","Fourth"},{"Voice","Active"},{"Case","Partitive"}}},
        {62,66,3,{{"Infinitive","Fifth"},{"Voice","Active"}}},
    };
    process_grammar(grammarforms,parsedTable,{{"Part of speech","Verb"}});
}
@}

\cprotect\subsubsection{\verb#parse_fi_nominals#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::parse_fi_nominals(QNetworkReply* reply){

    QList<grammarprovider::tablecell> parsedTable;
    getPlainTextTableFromReply(reply, parsedTable);

    QList<grammarform> grammarforms {
        {1,7,3,{{"Case","Nominative"},{"Number","Singular"}}},
        {2,7,4,{{"Case","Nominative"},{"Number","Plural"}}},
        {3,8,3,{{"Case","Accusative"},{"Case","Nominative"},{"Number","Singular"}}},
        {4,8,4,{{"Case","Accusative"},{"Case","Nominative"},{"Number","Plural"}}},
        {5,9,3,{{"Case","Accusative"},{"Case","Genitive"},{"Number","Singular"}}},
        {6,10,3,{{"Case","Genitive"},{"Number","Singular"}}},
        {7,10,4,{{"Case","Genitive"},{"Number","Plural"}}},
        {8,11,3,{{"Case","Partitive"},{"Number","Singular"}}},
        {9,11,4,{{"Case","Partitive"},{"Number","Plural"}}},
        {10,12,3,{{"Case","Inessive"},{"Number","Singular"}}},
        {11,12,4,{{"Case","Inessive"},{"Number","Plural"}}},
        {12,13,3,{{"Case","Elative"},{"Number","Singular"}}},
        {13,13,4,{{"Case","Elative"},{"Number","Plural"}}},
        {14,14,3,{{"Case","Illative"},{"Number","Singular"}}},
        {15,14,4,{{"Case","Illative"},{"Number","Plural"}}},
        {16,15,3,{{"Case","Adessive"},{"Number","Singular"}}},
        {17,15,4,{{"Case","Adessive"},{"Number","Plural"}}},
        {18,16,3,{{"Case","Ablative"},{"Number","Singular"}}},
        {19,16,4,{{"Case","Ablative"},{"Number","Plural"}}},
        {20,17,3,{{"Case","Allative"},{"Number","Singular"}}},
        {21,17,4,{{"Case","Allative"},{"Number","Plural"}}},
        {22,18,3,{{"Case","Essive"},{"Number","Singular"}}},
        {23,18,4,{{"Case","Essive"},{"Number","Plural"}}},
        {24,19,3,{{"Case","Translative"},{"Number","Singular"}}},
        {25,19,4,{{"Case","Translative"},{"Number","Plural"}}},
        {26,20,3,{{"Case","Instructive"},{"Number","Singular"}}},
        {27,20,4,{{"Case","Instructive"},{"Number","Plural"}}},
        {28,21,3,{{"Case","Abessive"},{"Number","Singular"}}},
        {29,21,4,{{"Case","Abessive"},{"Number","Plural"}}},
        {30,22,3,{{"Case","Comitative"},{"Number","Singular"}}},
        {31,22,4,{{"Case","Comitative"},{"Number","Plural"}}},
        {32,25,2,{{"Case","Possessive"},{"Number","Singular"},{"Person","First"}}},
        {33,25,3,{{"Case","Possessive"},{"Number","Plural"},{"Person","First"}}},
        {34,26,2,{{"Case","Possessive"},{"Number","Singular"},{"Person","Second"}}},
        {35,26,3,{{"Case","Possessive"},{"Number","Plural"},{"Person","Second"}}},
        {36,27,2,{{"Case","Possessive"},{"Number","Singular"},{"Number","Plural"},{"Person","Third"}}},
    };
    if(m_currentarguments.named["pos"] == "adj")
        process_grammar(grammarforms,parsedTable,{{"Part of speech","Adjective"}});
    else
        process_grammar(grammarforms,parsedTable,{{"Part of speech","Noun"}});
}
@}

\subsection{German}

\cprotect\subsubsection{\verb#de_requirements#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::de_requirements(QObject* caller, int de_id){
    QList<int> sein_forms = m_database->searchForms("sein",true);
    int expected_grammarform = m_database->grammarFormIdFromStrings(de_id,{{"Infinitive","First"},{"Part of speech","Verb"}});
    bool found_form = false;
    foreach(int sein_form, sein_forms){
        int grammarform = m_database->grammarFormFromFormId(sein_form);
        if(grammarform == expected_grammarform){
            found_form = true;
            break;
        }
    }
    if(!found_form){
        m_caller = caller;
        m_language = de_id;
        m_word = "sein";
        m_silent = true;
        QEventLoop waitloop;
        connect( this, &grammarprovider::grammarInfoComplete, &waitloop, &QEventLoop::quit );
        getWiktionarySections();
        waitloop.exec();
    }
}
@}

\cprotect\subsubsection{\verb#parse_de_noun_n#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::parse_de_noun_n(QNetworkReply* reply){
    QList<grammarprovider::tablecell> parsedTable;
    getPlainTextTableFromReply(reply, parsedTable);

    QList<grammarform> grammarforms {
        {1,2,4,{{"Gender","Neuter"},{"Case","Nominative"},{"Number","Singular"}}},
        {2,2,6,{{"Gender","Neuter"},{"Case","Nominative"},{"Number","Plural"}}},
        {3,3,4,{{"Gender","Neuter"},{"Case","Genitive"},{"Number","Singular"}}},
        {4,3,6,{{"Gender","Neuter"},{"Case","Genitive"},{"Number","Plural"}}},
        {5,4,4,{{"Gender","Neuter"},{"Case","Dative"},{"Number","Singular"}}},
        {6,4,6,{{"Gender","Neuter"},{"Case","Dative"},{"Number","Plural"}}},
        {7,5,4,{{"Gender","Neuter"},{"Case","Accusative"},{"Number","Singular"}}},
        {8,5,6,{{"Gender","Neuter"},{"Case","Accusative"},{"Number","Plural"}}},
    };
    process_grammar(grammarforms,parsedTable,{{"Part of speech","Noun"}});
}
@}

\cprotect\subsubsection{\verb#parse_de_noun_m#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::parse_de_noun_m(QNetworkReply* reply){

    QList<grammarprovider::tablecell> parsedTable;
    getPlainTextTableFromReply(reply, parsedTable);

    QList<grammarform> grammarforms {
        {1,2,4,{{"Gender","Masculine"},{"Case","Nominative"},{"Number","Singular"}}},
        {2,2,6,{{"Gender","Masculine"},{"Case","Nominative"},{"Number","Plural"}}},
        {3,3,4,{{"Gender","Masculine"},{"Case","Genitive"},{"Number","Singular"}}},
        {4,3,6,{{"Gender","Masculine"},{"Case","Genitive"},{"Number","Plural"}}},
        {5,4,4,{{"Gender","Masculine"},{"Case","Dative"},{"Number","Singular"}}},
        {6,4,6,{{"Gender","Masculine"},{"Case","Dative"},{"Number","Plural"}}},
        {7,5,4,{{"Gender","Masculine"},{"Case","Accusative"},{"Number","Singular"}}},
        {8,5,6,{{"Gender","Masculine"},{"Case","Accusative"},{"Number","Plural"}}},
    };
    process_grammar(grammarforms,parsedTable,{{"Part of speech","Noun"}});
}
@}

\cprotect\subsubsection{\verb#parse_de_noun_f#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::parse_de_noun_f(QNetworkReply* reply){

    QList<grammarprovider::tablecell> parsedTable;
    getPlainTextTableFromReply(reply, parsedTable);

    QList<grammarform> grammarforms {
        {1,2,4,{{"Gender","Feminine"},{"Case","Nominative"},{"Number","Singular"}}},
        {2,2,6,{{"Gender","Feminine"},{"Case","Nominative"},{"Number","Plural"}}},
        {3,3,4,{{"Gender","Feminine"},{"Case","Genitive"},{"Number","Singular"}}},
        {4,3,6,{{"Gender","Feminine"},{"Case","Genitive"},{"Number","Plural"}}},
        {5,4,4,{{"Gender","Feminine"},{"Case","Dative"},{"Number","Singular"}}},
        {6,4,6,{{"Gender","Feminine"},{"Case","Dative"},{"Number","Plural"}}},
        {7,5,4,{{"Gender","Feminine"},{"Case","Accusative"},{"Number","Singular"}}},
        {8,5,6,{{"Gender","Feminine"},{"Case","Accusative"},{"Number","Plural"}}},
    };
    process_grammar(grammarforms,parsedTable,{{"Part of speech","Noun"}});
}
@}

\cprotect\subsubsection{\verb#parse_de_verb#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::parse_de_verb(QNetworkReply* reply){
    // Work in process....

    QList<grammarprovider::tablecell> parsedTable;
    getPlainTextTableFromReply(reply, parsedTable);
    QList<grammarform> grammarforms {
        {1,1,3,{{"Infinitive","First"}}},
        {2,2,3,{{"Verbform","Participle"},{"Tense","Present"}}},
        {3,3,3,{{"Verbform","Participle"},{"Tense","Past"}}},
        {4,4,3,{{"Verbform","Auxiliary"}}},
        {5,6,2,{{"Mood","Indicative"},{"Tense","Present"},{"Person","First"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {6,6,3,{{"Mood","Indicative"},{"Tense","Present"},{"Person","First"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {7,6,5,{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","First"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {8,6,6,{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","First"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {9,7,2,{{"Mood","Indicative"},{"Tense","Present"},{"Person","Second"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {10,7,3,{{"Mood","Indicative"},{"Tense","Present"},{"Person","Second"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {11,7,4,{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","Second"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {12,7,5,{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","Second"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {13,8,2,{{"Mood","Indicative"},{"Tense","Present"},{"Person","Third"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {14,8,3,{{"Mood","Indicative"},{"Tense","Present"},{"Person","Third"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {15,8,4,{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","Third"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {16,8,5,{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","Third"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {17,10,2,{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","First"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {18,10,3,{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","First"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {19,10,5,{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","First"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {20,10,6,{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","First"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {21,11,2,{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","Second"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {22,11,3,{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","Second"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {23,11,4,{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","Second"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {24,11,5,{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","Second"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {25,12,2,{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","Third"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {26,12,3,{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","Third"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {27,12,4,{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","Third"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {28,12,5,{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","Third"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {29,14,2,{{"Mood","Imperative"},{"Person","Second"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {ADDANDUSEFORM, IGNOREFORM}},
        {30,14,3,{{"Mood","Imperative"},{"Person","Second"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {ADDANDUSEFORM, IGNOREFORM}},
        {31,16,2,{{"Mood","Indicative"},{"Tense","Perfect"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {32,16,3,{{"Mood","Indicative"},{"Tense","Perfect"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {33,16,5,{{"Mood","Subjunctive"},{"Tense","Perfect"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {34,16,6,{{"Mood","Subjunctive"},{"Tense","Perfect"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {35,17,2,{{"Mood","Indicative"},{"Tense","Perfect"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {36,17,3,{{"Mood","Indicative"},{"Tense","Perfect"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {37,17,4,{{"Mood","Subjunctive"},{"Tense","Perfect"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {38,17,5,{{"Mood","Subjunctive"},{"Tense","Perfect"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {39,18,2,{{"Mood","Indicative"},{"Tense","Perfect"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {40,18,3,{{"Mood","Indicative"},{"Tense","Perfect"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {41,18,4,{{"Mood","Subjunctive"},{"Tense","Perfect"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {42,18,5,{{"Mood","Subjunctive"},{"Tense","Perfect"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {43,20,2,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {44,20,3,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {45,20,5,{{"Mood","Subjunctive"},{"Tense","Plusquamperfect"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {46,20,6,{{"Mood","Subjunctive"},{"Tense","Plusquamperfect"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {47,21,2,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {48,21,3,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {49,21,4,{{"Mood","Subjunctive"},{"Tense","Plusquamperfect"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {50,21,5,{{"Mood","Subjunctive"},{"Tense","Plusquamperfect"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {51,22,2,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {52,22,3,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {53,22,4,{{"Mood","Subjunctive"},{"Tense","Plusquamperfect"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {54,22,5,{{"Mood","Subjunctive"},{"Tense","Plusquamperfect"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {55,24,2,{{"Infinitive","First"},{"Tense","Future 1"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {56,24,5,{{"Mood","Subjunctive 1"},{"Tense","Future 1"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {57,24,6,{{"Mood","Subjunctive 1"},{"Tense","Future 1"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {58,25,2,{{"Mood","Subjunctive 1"},{"Tense","Future 1"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {59,25,3,{{"Mood","Subjunctive 1"},{"Tense","Future 1"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {60,26,2,{{"Mood","Subjunctive 1"},{"Tense","Future 1"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {61,26,3,{{"Mood","Subjunctive 1"},{"Tense","Future 1"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {62,28,2,{{"Mood","Indicative"},{"Tense","Future 1"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {63,28,3,{{"Mood","Indicative"},{"Tense","Future 1"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {64,28,5,{{"Mood","Subjunctive 2"},{"Tense","Future 1"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {65,28,6,{{"Mood","Subjunctive 2"},{"Tense","Future 1"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {66,29,2,{{"Mood","Indicative"},{"Tense","Future 1"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {67,29,3,{{"Mood","Indicative"},{"Tense","Future 1"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {68,29,4,{{"Mood","Subjunctive 2"},{"Tense","Future 1"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {69,29,5,{{"Mood","Subjunctive 2"},{"Tense","Future 1"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {70,30,2,{{"Mood","Indicative"},{"Tense","Future 1"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {71,30,3,{{"Mood","Indicative"},{"Tense","Future 1"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {72,30,4,{{"Mood","Subjunctive 2"},{"Tense","Future 1"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {73,30,5,{{"Mood","Subjunctive 2"},{"Tense","Future 1"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {74,32,2,{{"Infinitive","First"},{"Tense","Future 2"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM,LOOKUPFORM}},
        {75,32,5,{{"Mood","Subjunctive 1"},{"Tense","Future 2"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {76,32,6,{{"Mood","Subjunctive 1"},{"Tense","Future 2"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {77,33,2,{{"Mood","Subjunctive 1"},{"Tense","Future 2"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {78,33,3,{{"Mood","Subjunctive 1"},{"Tense","Future 2"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {79,34,2,{{"Mood","Subjunctive 1"},{"Tense","Future 2"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {80,34,3,{{"Mood","Subjunctive 1"},{"Tense","Future 2"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {81,36,2,{{"Mood","Indicative"},{"Tense","Future 2"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {82,36,3,{{"Mood","Indicative"},{"Tense","Future 2"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {83,36,5,{{"Mood","Subjunctive 2"},{"Tense","Future 2"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {84,36,6,{{"Mood","Subjunctive 2"},{"Tense","Future 2"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {85,37,2,{{"Mood","Indicative"},{"Tense","Future 2"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {86,37,3,{{"Mood","Indicative"},{"Tense","Future 2"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {87,37,4,{{"Mood","Subjunctive 2"},{"Tense","Future 2"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {88,37,5,{{"Mood","Subjunctive 2"},{"Tense","Future 2"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {89,38,2,{{"Mood","Indicative"},{"Tense","Future 2"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {90,38,3,{{"Mood","Indicative"},{"Tense","Future 2"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {91,38,4,{{"Mood","Subjunctive 2"},{"Tense","Future 2"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {92,38,5,{{"Mood","Subjunctive 2"},{"Tense","Future 2"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
    };
    process_grammar(grammarforms,parsedTable,{{"Part of speech","Verb"}});
}
@}
