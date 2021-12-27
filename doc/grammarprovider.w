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
\todorefactor{Seperate class networkscheduler for network functionality in grammarprovider}
@O ../src/grammarprovider.h -d
@{
@<Start of @'GRAMMARPROVIDER@' header@>
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
#include "networkscheduler.h"

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
    void getWiktionarySection(QString reply);
    void getWiktionaryTemplate(QString reply);
    templatearguments parseTemplateArguments(QString templateString);
    void parseMediawikiTableToPlainText(QString wikitext, QList<grammarprovider::tablecell>& table);
    void parse_compoundform(QString reply);
    QList<QPair<QString,int> > fi_compound_parser(QObject* caller, int fi_id, int lexeme_id, QList<int> compound_lexemes);
    void fi_requirements(QObject* caller, int fi_id);
    void parse_fi_verbs(QString reply);
    void parse_fi_nominals(QString reply);
    void de_requirements(QObject* caller, int de_id);
    void parse_de_noun_n(QString reply);
    void parse_de_noun_m(QString reply);
    void parse_de_noun_f(QString reply);
    void parse_de_verb(QString reply);
    void process_grammar(QList<grammarform> grammarforms, QList<tablecell> parsedTable, QList<QList<QString> > additional_grammarforms = {});
    void getPlainTextTableFromReply(QString reply, QList<grammarprovider::tablecell>& parsedTable);
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
public:
private:
    int m_language;
    bool m_silent;
    bool m_busy;
    bool m_found_compoundform;
    QList<QString> m_current_compoundforms;
    QMap<QString, void (grammarprovider::*)(QString)> m_parser_map; 
    QString m_word;
    QString s_baseurl;
    QNetworkAccessManager* m_manager;
    QList<QString> m_parsesections;
    settings* m_settings;
    database* m_database;
    levenshteindistance* m_levenshteindistance;
    networkscheduler* m_networkscheduler;
    QObject* m_caller;
    templatearguments m_currentarguments;
    QList<grammarform> m_grammarforms;
    QList<scheduled_lookup> m_scheduled_lookups;
    QMap<int, void (grammarprovider::*)(QObject*,int)> m_requirements_map;
    QMap<int, QList<QPair<QString,int> > (grammarprovider::*)(QObject* caller, int id, int lexeme_id, QList<int> compound_lexemes)> m_compound_parser_map;
    struct context {
        grammarprovider* l_parent;
        int l_language;
        bool l_silent;
        bool l_busy;
        bool l_found_compoundform;
        QString l_word;
        QMetaObject::Connection l_tmp_connection;
        QMetaObject::Connection l_tmp_error_connection;
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
#include <sstream>
#include <iostream>
@}

\cprotect[om]\subsection[grammarprovider]{\verb#grammarprovider#}
@O ../src/grammarprovider.cpp -d
@{
grammarprovider::grammarprovider(QObject *parent) : QObject(parent), m_busy(false)
{
    s_baseurl = "https://en.wiktionary.org/w/api.php?";
    QQmlEngine* engine = qobject_cast<QQmlEngine*>(parent);
    m_settings = engine->singletonInstance<settings*>(qmlTypeId("SettingsLib", 1, 0, "Settings"));
    m_database = engine->singletonInstance<database*>(qmlTypeId("DatabaseLib", 1, 0, "Database"));
    m_levenshteindistance = engine->singletonInstance<levenshteindistance*>(qmlTypeId("LevenshteinDistanceLib", 1, 0, "LevenshteinDistance"));
    m_networkscheduler = engine->singletonInstance<networkscheduler*>(qmlTypeId("NetworkSchedulerLib", 1, 0, "NetworkScheduler"));
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

\cprotect\subsection{\verb#getWiktionarySections#}

\tododocument{Error handling for network requests}

\codecpp
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getWiktionarySections(){
    static int numberofcalls=0;
    qDebug() << "---- getWiktionarySections number of calls" << numberofcalls++;
    //qDebug() << "getWiktionarySections enter";
    emit processingStart("Querying en.wiktionary for word \"" + m_word + "\"...");
    m_networkscheduler->requestNetworkReply(s_baseurl + "action=parse&page=" + m_word + "&prop=sections&format=json", std::bind(&grammarprovider::getWiktionarySection,this,std::placeholders::_1));

    //qDebug() << "getWiktionarySections exit";
}
@}

\cprotect\subsection{\verb#getWiktionarySection#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getWiktionarySection(QString s_reply){
    //qDebug() << "getWiktionarySection enter";
        
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
                    m_networkscheduler->requestNetworkReply(s_baseurl + "action=parse&page=" + m_word + "&section=" + QString::number(best_bet_for_section) + "&prop=wikitext&format=json", std::bind(&grammarprovider::getWiktionaryTemplate,this,std::placeholders::_1));
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
        m_networkscheduler->requestNetworkReply(s_baseurl + "action=parse&page=" + m_word + "&section=" + QString::number(best_bet_for_section) + "&prop=wikitext&format=json", std::bind(&grammarprovider::getWiktionaryTemplate,this,std::placeholders::_1));
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
void grammarprovider::getWiktionaryTemplate(QString s_reply){
 
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
    QMapIterator<QString, void (grammarprovider::*)(QString)> parser(m_parser_map); 
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
                emit processingStop();
                emit processingStart("Parsing wiktionary data...");
                m_networkscheduler->requestNetworkReply(s_baseurl + "action=expandtemplates&text=" + QUrl::toPercentEncoding(wt_finished) + "&title=" + m_word + "&prop=wikitext&format=json", std::bind(parser.value(),this,std::placeholders::_1));
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
void grammarprovider::getPlainTextTableFromReply(QString s_reply, QList<grammarprovider::tablecell>& parsedTable){
    
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
void grammarprovider::parse_compoundform(QString s_reply){
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

@i grammarprovider_language_specific.w
