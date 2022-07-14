% Copyright 2020, 2021, 2022 Florian Pesth
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

@i grammarprovider_json.w

@i grammarprovider_support_status.w

@i grammarprovider_wiktionary_word.w

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

@i grammarprovider_networkqueries.w

@i grammarprovider_interface.w

\section{Implementation}
@O ../src/grammarprovider.cpp -d
@{
#include "grammarprovider.h"


@}

\subsection[grammarprovider]{grammarprovider}
@O ../src/grammarprovider.cpp -d
@{
grammarprovider::grammarprovider(QObject *parent) : QObject(parent), m_busy(false)
{

#ifdef Q_OS_ANDROID
    s_gpFilePath = QStandardPaths::standardLocations(QStandardPaths::AppDataLocation).at(1) + "/grammarprovider";
#else
    s_gpFilePath = QStandardPaths::standardLocations(QStandardPaths::HomeLocation).at(0) + "/.coleitra/grammarprovider";
#endif

    {
        if(!QDir(s_gpFilePath).exists()){
            QDir().mkdir(s_gpFilePath);
        }
    }

#ifdef Q_OS_ANDROID
    // In case of android copy over files from assets to directory:
    QDirIterator it_assetFiles("assets:/grammarprovider",QDirIterator::Subdirectories);
    while(it_assetFiles.hasNext()){
        QFile f_currentFile(it_assetFiles.next());
        QFileInfo fi_currentFile(f_currentFile);
        if(!fi_currentFile.filePath().isEmpty()){
            QString s_relativePath = fi_currentFile.filePath().remove("assets:/grammarprovider");
            QString s_gpDFilePath = s_gpFilePath + "/" + s_relativePath;
            if(fi_currentFile.isDir()){
                if(!QDir(s_gpDFilePath).exists()){
                    QDir().mkdir(s_gpDFilePath);
                }
            }
            else{
                if(!QFile(s_gpDFilePath).exists()){
                    f_currentFile.copy(s_gpDFilePath);
                }
                else{
                    s_gpDFilePath = s_gpFilePath + "/" + fi_currentFile.dir().path().remove("assets:/grammarprovider") + "/" + fi_currentFile.baseName() + ".coleitra." + QString::fromStdString(TOSTRING(COLEITRA_VERSION)) + "." + fi_currentFile.completeSuffix();
                    if(!QFile(s_gpDFilePath).exists()){
                        f_currentFile.copy(s_gpDFilePath);
                    }
                }
            }
        }
    }
#endif

    QFile f_grammarProviderSchema(s_gpFilePath + "/schemas/main.json");
    if(f_grammarProviderSchema.open(QIODevice::ReadOnly)) {
        j_grammarProviderSchema = json::parse(f_grammarProviderSchema.readAll().toStdString());
        f_grammarProviderSchema.close();
    }
    
    s_baseurl = "https://en.wiktionary.org/w/api.php?";
    QQmlEngine* engine = qobject_cast<QQmlEngine*>(parent);
    m_settings = engine->singletonInstance<settings*>(qmlTypeId("SettingsLib", 1, 0, "Settings"));
    m_database = engine->singletonInstance<database*>(qmlTypeId("DatabaseLib", 1, 0, "Database"));
    m_levenshteindistance = engine->singletonInstance<levenshteindistance*>(qmlTypeId("LevenshteinDistanceLib", 1, 0, "LevenshteinDistance"));
    m_networkscheduler = engine->singletonInstance<networkscheduler*>(qmlTypeId("NetworkSchedulerLib", 1, 0, "NetworkScheduler"));
    connect(m_networkscheduler, &networkscheduler::requestFailed, this, &grammarprovider::processNetworkError);
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

\subsection{\~{}grammarprovider}
@O ../src/grammarprovider.cpp -d
@{
grammarprovider::~grammarprovider() {
}
@}

\subsection{readGrammarConfiguration}
@O ../src/grammarprovider.cpp -d
@{
bool grammarprovider::readGrammarConfiguration(QString s_fileName, grammarconfiguration& t_config)
{
    json j_language;
    QFile f_language(s_fileName);

    if(f_language.open(QIODevice::ReadOnly)) {
        j_language = json::parse(f_language.readAll().toStdString());
        f_language.close();
    }

    json_validator validator;
    try {
        validator.set_root_schema(j_grammarProviderSchema);
    }
    catch (const std::exception &e) {
        qDebug() << "Setting the root schema failed, here is why: " << e.what();
        std::cout << j_grammarProviderSchema.dump();
        return false;
    }
    catch (...){
        qDebug() << "Setting the root schema failed.";
    }

    try {
        validator.validate(j_language);
        std::cout << "Validation succeeded\n";
        return false;
    }
    catch (const std::exception &e) {
        qDebug() << "Validation failed, here is why: " << e.what();
        return false;
    }
    catch (...) {
        qDebug() << "Validation failed.";
        return false;
    }
    t_config = grammarconfiguration(j_language,m_database);
}
@}

\subsection{getGrammarInfoForWord}
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
    emit processingUpdate("Checking requirements for language " + QString::number(languageid));
    if(m_requirements_map.contains(languageid))
        (this->*(m_requirements_map[languageid]))(caller,languageid);
    //qDebug() << "...requirements done";
    m_language = languageid;
    m_word = word;
    m_silent = false;
    m_found_compoundform = false;
    /* We block here with an event loop, because we want to send an signal,
       when we are finished */
    QEventLoop waitloop;
    QMetaObject::Connection gia_con;
    QMetaObject::Connection gina_con;
    QMetaObject::Connection ne_con;
    QMetaObject::Connection temp_con;
    gia_con = connect(this, &grammarprovider::grammarInfoAvailable,
            [&](QObject* caller, int size, bool silent){
            if(caller == &waitloop){
            //qDebug() << "Got grammarInfoComplete signal in lambda function for getGrammarInfoForWord" << m_word << caller;
            disconnect(gia_con);
            disconnect(gina_con);
            disconnect(ne_con);
            waitloop.quit();
            }
            });
    gina_con = connect(this, &grammarprovider::grammarInfoNotAvailable,
            [&](QObject* caller, bool silent){
            if(caller == &waitloop){
            //qDebug() << "Got grammarInfoNotComplete signal in lambda function for getGrammarInfoForWord" << m_word << caller;
            // FIXME handling of unknown templates
            disconnect(gia_con);
            disconnect(gina_con);
            disconnect(ne_con);
            emit noGrammarInfoForWord(caller, m_silent);
            waitloop.quit();
            }
            });
    temp_con = connect(this, &grammarprovider::possibleTemplate,
            [&](QObject* caller, bool silent, templatearguments arguments, QObject* tableView){
            });
    ne_con = connect(m_networkscheduler, &networkscheduler::requestFailed,
            [&](QObject* caller, QString s_reason){
            if(caller == &waitloop){
            //qDebug() << "Got requestFailed signal" << s_reason << "in lambda function for getGrammarInfoForWord" << m_word << caller;
            disconnect(gia_con);
            disconnect(gina_con);
            disconnect(ne_con);
            emit noGrammarInfoForWord(caller, m_silent);
            waitloop.quit();
            }
            });

    getWiktionarySections(&waitloop);

    //qDebug() << "Blocking waitloop" << &waitloop << "for getGrammarInfoForWord" << m_word << "...";
    waitloop.exec();
    //qDebug() << "... blocking waitloop for" << m_word << "finished.";
    /* This doesn't work here, don't know why:
       emit processingUpdate("Processing " + QString::number(m_grammarforms.size()) + " grammar forms...");
     */
    emit gotGrammarInfoForWord(caller, m_grammarforms.size(), m_silent);
    //qDebug() << "getGrammarInfoForWord finished!";
}
@}

\subsection{getWiktionarySections}

\tododocument{Error handling for network requests}

\codecpp
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getWiktionarySections(QObject* caller){
    static int numberofcalls=0;
    emit processingUpdate("Lookup word " + m_word + " on en.wiktionary.org");
    //qDebug() << "---- getWiktionarySections number of calls" << numberofcalls++;
    //qDebug() << "getWiktionarySections enter";
    /* I suspect it doesn't hurt to get a new lexeme id here - as any group of
       forms belonging together will have to pass through here and it won't
       hurt to skip a few id's here. */
    lexemeId();
    m_networkscheduler->requestNetworkReply(caller, s_baseurl + "action=parse&page=" + m_word + "&prop=sections&format=json", std::bind(&grammarprovider::getWiktionarySection,this,std::placeholders::_1, caller));

    //qDebug() << "getWiktionarySections exit";
}
@}

\subsection{getWiktionarySection}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getWiktionarySection(QString s_reply, QObject* caller){
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
        ms_current_section = s_section;
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
                    //qDebug() << "Found etymology section";
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
                    //qDebug() << __FILE__ << __FUNCTION__ << __LINE__ << &waitloop;
                    /* We have to check for the caller pointer because
                       this might get recursive */
                    QMetaObject::Connection gic_con;
                    QMetaObject::Connection gina_con;
                    QMetaObject::Connection ne_con;
                    gic_con = connect(this, &grammarprovider::grammarInfoComplete,
                            [&](QObject* caller, bool silent){
                                if(caller == &waitloop){
                                    //qDebug() << "Got grammarInfoComplete signal in lambda function for etymology section" << m_word << caller;
                                    disconnect(gic_con);
                                    disconnect(gina_con);
                                    disconnect(ne_con);
                                    waitloop.quit();
                                }
                            });
                    gina_con = connect(this, &grammarprovider::etymologyInfoNotAvailable,
                            [&](QObject* caller, bool silent){
                                if(caller == &waitloop){
                                    //qDebug() << "Got etymologyInfoNotAvailable signal in lambda function for etymology section" << m_word << caller;
                                    disconnect(gic_con);
                                    disconnect(gina_con);
                                    disconnect(ne_con);
                                    waitloop.quit();
                                }
                            });
                    ne_con = connect(m_networkscheduler, &networkscheduler::requestFailed,
                            [&](QObject* caller, QString s_reason){
                                if(caller == &waitloop){
                                    //qDebug() << "Got requestFailed signal" << s_reason << "in lambda function for etymology section" << m_word << caller;
                                    disconnect(gic_con);
                                    disconnect(gina_con);
                                    disconnect(ne_con);
                                    waitloop.quit();
                                }
                            });
                    best_bet_for_section = j_section["index"].toString().toInt();
                    m_networkscheduler->requestNetworkReply(&waitloop,s_baseurl + "action=parse&page=" + m_word + "&section=" + QString::number(best_bet_for_section) + "&prop=wikitext&format=json", std::bind(&grammarprovider::getWiktionaryTemplate,this,std::placeholders::_1,&waitloop,e_wiktionaryRequestPurpose::ETYMOLOGY));
                    //qDebug() << "Blocking waitloop for" << m_word << "...";
                    waitloop.exec();
                    //qDebug() << "... blocking waitloop for" << m_word << "finished.";
                    l_found_compoundform = m_found_compoundform;
                    l_currentarguments = m_currentarguments;
                    foreach(QString arg, l_currentarguments.unnamed){
                        //qDebug() << "Blocking loop came back with arg" << arg;
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
        m_networkscheduler->requestNetworkReply(caller,s_baseurl + "action=parse&page=" + m_word + "&section=" + QString::number(best_bet_for_section) + "&prop=wikitext&format=json", std::bind(&grammarprovider::getWiktionaryTemplate,this,std::placeholders::_1,caller,e_wiktionaryRequestPurpose::FLECTION));
    }
    else{
        //qDebug() << "Could not find language section \"" + language + "\" for word \"" + m_word + "\"";
        m_busy = false;
        emit grammarInfoNotAvailable(caller, m_silent);
        return;
    }
    //qDebug() << "getWiktionarySection exit";
}
@}

\subsection{parseTemplateArguments}
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

\subsection{processUnknownTemplate}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::processUnknownTemplate(QString s_reply, QObject* caller, grammarprovider::templatearguments arguments){
    QList<grammarprovider::tablecell> parsedTable;
    getPlainTextTableFromReply(s_reply, parsedTable);
    if(parsedTable.length() > 0){
        grammarTableView* m_view = new grammarTableView(parsedTable);
        emit possibleTemplate(caller, m_silent, arguments, m_view);
    }
    else{
        getNextPossibleTemplate(caller);
    }
    //qDebug() << s_reply;
    /*qDebug() << "I got the following named template arguments";
    for(const auto& named_argument : arguments.named.toStdMap()){
        qDebug() << named_argument.first << named_argument.second;
    }
    qDebug() << "and this unnamed arguments:";
    for(const auto& unnamed_argument : arguments.unnamed){
        qDebug() << unnamed_argument;
    }*/
}
@}

\subsection{getWiktionaryTemplate}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getWiktionaryTemplate(QString s_reply, QObject* caller, grammarprovider::e_wiktionaryRequestPurpose purpose){
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
    QMapIterator<QString, void (grammarprovider::*)(QString, QObject*)> parser(m_parser_map); 
    while (parser.hasNext()) {
        parser.next();
        foreach(const QString& wt_finished, wt_finisheds){
            if(wt_finished.startsWith("{{" + parser.key())){
                if(parser.key() == "compound"){
                    m_currentarguments = parseTemplateArguments(wt_finished);
                    m_found_compoundform = true;
                    parse_compoundform("",caller);
                }
                else{
                    m_currentarguments = parseTemplateArguments(wt_finished);
                    m_networkscheduler->requestNetworkReply(caller,s_baseurl + "action=expandtemplates&text=" + QUrl::toPercentEncoding(wt_finished) + "&title=" + m_word + "&prop=wikitext&format=json", std::bind(parser.value(),this,std::placeholders::_1,caller));
                }
                return;
            }
            else{
                // This template does not match this parser but it might match a different one
            }
        }
    }
    // Ask the user to create template schema:
    ms_possibleTemplates += wt_finisheds;
    emit possibleTemplateAvailable(caller, wt_finisheds.length(), m_silent);
    // TODO Check if we have a valid json config here
    for(auto& grammarConfiguration: m_grammarConfigurations){
/*
        for(auto& inflectionTable: grammarConfiguration.l_inflection_tables){
            for(auto& s_identifier: inflectionTable.l_identifiers){
                for(auto& wt_finished: wt_finisheds){
                    //FIXME
                }
            }
        }*/
    }
    switch(purpose){
        case e_wiktionaryRequestPurpose::FLECTION:
            emit grammarInfoNotAvailable(caller, m_silent);
            qDebug() << "Template(s) for flection section " << wt_finisheds << "not supported!";
            break;
        case e_wiktionaryRequestPurpose::ETYMOLOGY:
            emit etymologyInfoNotAvailable(caller, m_silent);
            qDebug() << "Template(s) for etymology section " << wt_finisheds << "not supported!";
            break;
    }
}
@}

\subsection{getNextPossibleTemplate}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getNextPossibleTemplate(QObject* caller){
    if(!ms_possibleTemplates.isEmpty()){
        QString s_possibleTemplate = ms_possibleTemplates.first();
        ms_possibleTemplates.removeFirst();
        m_currentarguments = parseTemplateArguments(s_possibleTemplate);
        m_networkscheduler->requestNetworkReply(caller,s_baseurl + "action=expandtemplates&text=" + QUrl::toPercentEncoding(s_possibleTemplate) + "&title=" + m_word + "&prop=wikitext&format=json", std::bind(&grammarprovider::processUnknownTemplate,this,std::placeholders::_1,caller,m_currentarguments));
    }
    else {
        emit possibleTemplateFinished(caller);
    }
}
@}

\subsection{parseMediawikiTableToPlainText}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::parseMediawikiTableToPlainText(QString wikitext, QList<grammarprovider::tablecell>& table){
    QStringList table_lines = wikitext.split("\n");
    struct t_spanBlock {
        int row1;
        int column1;
        int row2;
        int column2;
    };
    QList<t_spanBlock> span_blocks;
    int column=0;
    int row=0;
    foreach(QString table_line, table_lines){
        auto process_line = [&row,&column,&span_blocks](QString table_line){
            //qDebug() << "__P 0 (input)" << table_line;
            {
                int columnspan=1, rowspan=1;
                int colspan_i = table_line.indexOf("colspan=\"");
                if(colspan_i != -1){
                    int colspan_j = table_line.indexOf("\"",colspan_i+9);
                    columnspan = table_line.midRef(colspan_i+9,colspan_j-colspan_i-9).toInt();
                }
                int rowspan_i = table_line.indexOf("rowspan=\"");
                if(rowspan_i != -1){
                    int rowspan_j = table_line.indexOf("\"",rowspan_i+9);
                    rowspan = table_line.midRef(rowspan_i+9,rowspan_j-rowspan_i-9).toInt();
                }
                if((columnspan>1)||(rowspan>1)){
                    span_blocks.push_back({row,column,row+rowspan-1,column+columnspan-1});
                }
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
        if(table_line.startsWith("<div class=\"NavContent")){
            // Clear span blocks if a new <table> starts
            span_blocks.clear();
        }
        if(table_line.startsWith("|-")){
            row++;
            column=0;
            continue;
        }
        if(table_line.startsWith("!")){
            bool b_forwardJump = false;
            do {
                b_forwardJump = false;
                for(const auto& span_block: span_blocks){
                    if(row>=span_block.row1 && row<=span_block.row2
                            && column >= span_block.column1 && column <= span_block.column2){
                        if(row>span_block.row1 || column>span_block.column1){
                            // We are not in the top left corner of the block,
                            // so it has already been processed and we go to
                            // the next block
                            column = span_block.column2+1;
                            b_forwardJump = true;
                        }
                    }
                }
            } while(b_forwardJump);
            table_line.remove(0,2);
            table_line = process_line(table_line);
	    QStringList table_entries = table_line.split(QLatin1Char(','));
            //qDebug() << "__P 10" << table_entries;
            foreach(QString table_entry, table_entries){
                table_entry = table_entry.trimmed();
                if(!table_entry.isEmpty())
                    table.push_back({row,column,table_entry});
                //qDebug() << row << column << table_entry;
            }
            column++;
            continue;
        }
        if(table_line.startsWith("|")){
            bool b_forwardJump = false;
            do {
                b_forwardJump = false;
                for(const auto& span_block: span_blocks){
                    //qDebug() << "?[" << span_block.row1 << span_block.column1 << "] [" << row << column << "] [" << span_block.row2 << span_block.column2 << "]";
                    if(row>=span_block.row1 && row<=span_block.row2
                            && column >= span_block.column1 && column <= span_block.column2){
                        if(row>span_block.row1 || column>span_block.column1){
                            // We are not in the top left corner of the block,
                            // so it has already been processed and we go to
                            // the next block
                            //qDebug() << "[" << span_block.row1 << span_block.column1 << "] [" << row << column << "] [" << span_block.row2 << span_block.column2 << "]";
                            column = span_block.column2+1;
                            //qDebug() << ">[" << span_block.row1 << span_block.column1 << "] [" << row << column << "] [" << span_block.row2 << span_block.column2 << "]";
                            b_forwardJump = true;
                        }
                    }
                }
            } while(b_forwardJump);
            //qDebug() << "We are in row" << row << "column" << column;
            table_line.remove(0,2);
            table_line = process_line(table_line);
	    QStringList table_entries = table_line.split(QLatin1Char(','));
            //qDebug() << "__P 10" << table_entries;
            foreach(QString table_entry, table_entries){
                table_entry = table_entry.trimmed();
                if(!table_entry.isEmpty())
                    table.push_back({row,column,table_entry});
                //qDebug() << row << column << table_entry;
            }
            column++;
            continue;
        }
    }
}
@}

\subsection{process\_grammar}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::process_grammar(QObject* caller, QList<grammarform> grammarforms, QList<tablecell> parsedTable, QList<QList<QString> > additional_grammarforms){
    QList<grammarform> l_grammarforms;
    lexemeId();
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
                        currentGrammarForm.language_id = m_language;
                        currentGrammarForm.b_silent = m_silent;
                        if(m_found_compoundform){
                            currentGrammarForm.compounds = getGrammarCompoundFormParts(currentGrammarForm.string, m_current_compoundforms, m_language);
                        }
                        currentGrammarForm.id = formId();
                        currentGrammarForm.lexeme_id = m_lexemeId;
                        l_grammarforms.push_back(currentGrammarForm);
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
    std::sort(l_grammarforms.begin(), l_grammarforms.end(), [](grammarform a, grammarform b) {
        return a.index < b.index;
    });
    m_grammarforms += l_grammarforms;
    mi_grammarforms += l_grammarforms;
    //qDebug() << "Got" << m_grammarforms.size();

    emit processedGrammar(caller,m_silent);
    emit grammarInfoAvailable(caller, m_grammarforms.size(), m_silent);
    //emit grammarobtained(m_caller, expressions, grammarexpressions);
}
@}

\subsection{getNextGrammarObject}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getNextGrammarObject(QObject* caller){
    //qDebug() << "grammarprovider::getNextGrammarObject enter";
    if(m_grammarforms.isEmpty()){
        //qDebug() << __FUNCTION__ << __LINE__ << "*** grammarInfoComplete EMIT ***";
        emit grammarInfoComplete(caller,m_silent);
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
    }
    else{
        QMutableListIterator<grammarform> grammarFormI(m_grammarforms);
        grammarform& form = grammarFormI.next();
        grammarform form2 = form;
        //qDebug() << "form.string" << form.string;
        switch(form.type){
            case FORM:
                {
                    //qDebug() << form.index << form.string << "FORM" << form.grammarexpressions;
                    if(!m_grammarforms.isEmpty())
                        m_grammarforms.removeFirst();
                    else 
                        qDebug() << "ERROR m_grammarforms is empty!" << __LINE__;
                    {
                       // qDebug() << __FUNCTION__ << __LINE__ << "*** formObtained EMIT ***";
                        emit formObtained(caller, form2.b_silent, form2);
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
                                        //qDebug() << __FUNCTION__ << __LINE__ << "*** formObtained EMIT ***";
                                        grammarform formpart_form = form2;
                                        formpart_form.string = formpart;
                                        emit formObtained(caller, formpart_form.b_silent, formpart_form);
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
                //qDebug() << __FILE__ << __LINE__ << __FUNCTION__;
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
                                //qDebug() << "----- formObtained" << caller << sentenceparts.at(sentencepartid) << currentProcess.grammarexpressions << m_silent << m_found_compoundform;
                                //qDebug() << __FUNCTION__ << __LINE__ << "*** formObtained EMIT ***";
                                grammarform sentencepart_form = form;
                                sentencepart_form.string = sentenceparts.at(sentencepartid);
                                sentencepart_form.grammarexpressions = currentProcess.grammarexpressions;
                                emit formObtained(caller, sentencepart_form.b_silent, sentencepart_form);
                                //qDebug() << "grammarprovider::getNextGrammarObject exit" << __LINE__;
                                return;
                            }
                            sentencepartid++;
                        }
                        emit sentenceAvailable(caller, form.processList.size(), form.b_silent);
                    }
                    else {
                        qDebug() << "Process list size (=" + QString::number(form.processList.size()) +  ") does not match number of sentence parts (=" + sentenceparts.size() + ")!";
                    }
                }
                break;
            default:
                //qDebug() << form.index << form.string << "unknown form!" << form.grammarexpressions;
                break;
        }
    }
    //qDebug() << "grammarprovider::getNextGrammarObject exit" << __LINE__;
}
@}

\subsection{getNextSentencePart}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getNextSentencePart(QObject* caller){
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
        emit sentenceComplete(caller,ge,form.b_silent);
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
            getNextSentencePart(caller);
            break;
        case LOOKUPFORM:
            //qDebug() << sentenceparts.at(0) << "LOOKUPFORM" << process.grammarexpressions;
            emit sentenceLookupForm(caller,sentenceparts.at(0),process.grammarexpressions, form.b_silent);
            break;
        case LOOKUPFORM_LEXEME:
            //qDebug() << sentenceparts.at(0) << "LOOKUPFORM_LEXEME" << process.grammarexpressions;
            emit sentenceLookupFormLexeme(caller,sentenceparts.at(0),process.grammarexpressions, form.b_silent);
            break;
        case ADDANDUSEFORM:
            //qDebug() << sentenceparts.at(0) << "ADDANDUSEFORM" << process.grammarexpressions;
            emit sentenceAddAndUseForm(caller,sentenceparts.at(0),process.grammarexpressions, form.b_silent);
            break;
        case ADDANDIGNOREFORM:
            //qDebug() << sentenceparts.at(0) << "ADDANDIGNOREFORM" << process.grammarexpressions;
            emit sentenceAddAndIgnoreForm(caller,sentenceparts.at(0),process.grammarexpressions, form.b_silent);
            break;
        default:
            //qDebug() << "Unknown processing instruction... ignoring!";
            getNextSentencePart(caller);
            break;
    }
}
@}

\subsection{getPlainTextTableFromReply}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getPlainTextTableFromReply(QString s_reply, QList<grammarprovider::tablecell>& parsedTable){
    
    QJsonDocument j_document = QJsonDocument::fromJson(s_reply.toUtf8());
    QString wikitemplate_text = j_document.object()["expandtemplates"].toObject()["wikitext"].toString();
    parseMediawikiTableToPlainText(wikitemplate_text, parsedTable);
}
@}

\subsection{processNetworkError}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::processNetworkError(QObject* caller, QString s_failure_reason){
    emit networkError(caller, m_silent, s_failure_reason);
}
@}

\subsection{getGrammarCompoundFormParts}
@O ../src/grammarprovider.cpp -d
@{
QList<grammarprovider::compoundPart> grammarprovider::getGrammarCompoundFormParts(QString compoundword, QList<QString> compoundstrings, int id_language){
    //qDebug() << __FILE__ << __FUNCTION__ << __LINE__ << compoundword << compoundstrings << id_language;
    /* The previous assumption, that all forms are in the database already does
       not work anymore after a refactoring. */
    bool found_all_lexemes = true;
    QList<QList<QPair<QString,int> > > compoundformpart_candidates;
    QString m_debug_compoundparts;
    foreach(QString compoundform, compoundstrings){
        // First check database:
        QList<int> possible_lexemes = m_database->searchLexemes(compoundform, true);
        int found_lexeme = 0;
        foreach(int possible_lexeme, possible_lexemes){
            if(m_database->languageOfLexeme(possible_lexeme) == id_language){
                found_lexeme = possible_lexeme;
                break;
            }
        }
        if(found_lexeme > 0){
            // Collect all form candidates:
            QList<QPair<QString,int> > forms = m_database->listFormsOfLexeme(found_lexeme);
            compoundformpart_candidates.push_back(forms);
        }
        else{
            // We have not found any matching lexeme in database, let's check our memory:
            grammarform form;
            found_lexeme = 0;
            //qDebug() << __FILE__ << __FUNCTION__ << __LINE__ << mi_grammarforms.size();
            foreach(form, mi_grammarforms){
                if((form.string == compoundform) && (form.language_id == id_language)){
                    found_lexeme = form.lexeme_id;
                    break;
                }
            }
            if(found_lexeme != 0){
                // Collect all form candidates:
                QList<QPair<QString,int> > forms;
                foreach(form, mi_grammarforms){
                    if(form.lexeme_id == found_lexeme){
                        forms.push_back({form.string,form.id});
                        m_debug_compoundparts += form.string + " ";
                    }
                }
                compoundformpart_candidates.push_back(forms);
                continue;
            }
            found_all_lexemes = false;
            break;
        }
    }
    //qDebug() << "Found all lexemes:" << found_all_lexemes << m_debug_compoundparts;
    levenshteindistance local_levenshteindistance;
    QList<levenshteindistance::compoundpart> compoundparts = local_levenshteindistance.stringdivision(compoundformpart_candidates,compoundword);
    levenshteindistance::compoundpart m_compoundpart;
    QList<compoundPart> compoundpartsgrammar;
    foreach(m_compoundpart, compoundparts){
        if(m_compoundpart.id != 0){
            m_debug_compoundparts += QString::number(m_compoundpart.id) + " ";
        }
        else{
            m_debug_compoundparts += m_compoundpart.string;
        }
        compoundpartsgrammar.push_back({m_compoundpart.id,m_compoundpart.capitalized,m_compoundpart.string});
        //qDebug() << "Compound part" << m_compoundpart.division << m_compoundpart.id << m_compoundpart.capitalized << m_compoundpart.string;
    }
    //qDebug() << "Compound parts:" << m_debug_compoundparts;
    return compoundpartsgrammar;
}
@}

\subsection{parse\_compoundform}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::parse_compoundform(QString s_reply, QObject* caller){
    //qDebug() << "Got compound form";
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
                    //qDebug() << "Found form" << arg;
                    break;
                }
            }
            if(!found_form){
                //qDebug() << "Could not find form" << arg << ", looking it up...";
                context save_state(this);
                QEventLoop waitloop;
                //qDebug() << __FILE__ << __FUNCTION__ << __LINE__ << &waitloop;
                m_word = arg;
                m_silent = true;
                m_found_compoundform = false;
                QMetaObject::Connection gic_con;
                QMetaObject::Connection gia_con;
                QMetaObject::Connection gina_con;
                QMetaObject::Connection ne_con;
                gic_con = connect(this, &grammarprovider::grammarInfoComplete,
                        [&](QObject* caller, bool silent){
                            if(caller == &waitloop){
                                //qDebug() << "Got grammarInfoComplete signal in lambda function for compoundform search" << m_word << caller;
                                disconnect(gic_con);
                                disconnect(gia_con);
                                disconnect(gina_con);
                                disconnect(ne_con);
                                waitloop.quit();
                            }
                        });
                gia_con = connect(this, &grammarprovider::grammarInfoAvailable,
                        [&](QObject* caller, bool silent){
                            if(caller == &waitloop){
                                //qDebug() << "Got grammarInfoAvailable signal in lambda function for compoundform search" << m_word << caller;
                                disconnect(gic_con);
                                disconnect(gia_con);
                                disconnect(gina_con);
                                disconnect(ne_con);
                                waitloop.quit();
                            }
                        });
                gina_con = connect(this, &grammarprovider::grammarInfoNotAvailable,
                        [&](QObject* caller, bool silent){
                            if(caller == &waitloop){
                                //qDebug() << "Got grammarInfoNotComplete signal in lambda function for compoundform search" << m_word << caller;
                                disconnect(gic_con);
                                disconnect(gia_con);
                                disconnect(gina_con);
                                disconnect(ne_con);
                                waitloop.quit();
                            }
                        });
                ne_con = connect(m_networkscheduler, &networkscheduler::requestFailed,
                        [&](QObject* caller, QString s_reason){
                            if(caller == &waitloop){
                                //qDebug() << "Got requestFailed signal" << s_reason << "in lambda function for compoundform search" << m_word << caller;
                                disconnect(gic_con);
                                disconnect(gia_con);
                                disconnect(gina_con);
                                disconnect(ne_con);
                                waitloop.quit();
                            }
                        });
                getWiktionarySections(&waitloop);
                //qDebug() << "Blocking waitloop" << &waitloop << "for compoundform" << m_word << "...";
                waitloop.exec();
                //qDebug() << "... blocking waitloop" << &waitloop << "for compoundform" << m_word << "finished.";
            }
            m_current_compoundforms += arg;
        }
    }
    emit grammarInfoComplete(caller,m_silent);
}
@}

@i grammarprovider_language_specific.w
