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

\section{Wiktionary grammar provider}

This class implements the lookup of a word in wiktionary. Each word lookup is an instance of this class and this class may create other objects of itself as dependencies (i.e. for compound words).

\subsection{Interface}

@O ../src/grammarprovider_wiktionary_word.h -d
@{
@<Start of @'GRAMMARPROVIDER_WIKTIONARY_WORD@' header@>

#include <QString>
#include <QStateMachine>
#include <QQmlEngine>
#include <QJsonObject>
#include <QJsonDocument>
#include <QJsonArray>
#include "networkscheduler.h"
#include "database.h"

@<Start of class @'grammarprovider_wiktionary_word@'@>
public:
    enum class e_signalProcessing {
        NO_SIGNALS,
        ALL_SIGNALS,
        ONLY_FINISHED
    };
    enum class e_progressState {
        IDLE,
        GET_WORD_OVERVIEW,
        GET_REQUIRED_SECTIONS,
        PROCESS_REQUIRED_SECTIONS,
        GET_OPTIONAL_SECTIONS,
        GET_COMPOUNDFORM,
        FINISHED
    };
    Q_ENUM(e_progressState);
    Q_PROPERTY(e_progressState currentProgress MEMBER m_currentProgress);
    explicit grammarprovider_wiktionary_word(QString s_word, int li_language, e_signalProcessing e_signalHandling = e_signalProcessing::NO_SIGNALS, QObject *parent = nullptr);
signals:
    // For progress states:
    void sgi_lookupWord(void);
    void sgi_getRequiredSections(void);
    void sgi_processRequiredSections(void);
    void sgi_getOptionalSections(void);
    void sgi_getCompoundform(void);
    void sgi_progressFinished(void);
    // For network states:
    void sgi_networkError(void);
    void sgi_queryNetwork(void);
    void sgi_queryFinished(void);
private:
    QString s_word;
    e_progressState m_currentProgress;
    e_signalProcessing e_signalHandling;
    QStateMachine *psm_main;

    networkscheduler* m_networkscheduler;
    database* m_database;

    QString s_networkErrorReason;
    QString s_baseurl;
    int i_language;
    QString s_language;

    QString s_currentSection;

    struct t_sectionRequired {
        bool b_required;
        int i_requireGroup;
    };
    QMap<QString,t_sectionRequired> m_interestingSections;

    struct t_templateArguments {
        QMap<QString, QString> named;
        QList<QString> unnamed;
    };

    struct t_sectionData {
        t_sectionData() :
            b_available(false),
            b_processed(false){}
        t_sectionData(int sectionNumber) :
            i_sectionNumber(sectionNumber),
            b_available(false),
            b_processed(false){}
        int i_sectionNumber;
        bool b_available;
        QString s_content;
        bool b_processed;
        QList<t_templateArguments> l_templates;
    };
    QMap<QString,t_sectionData> m_collectedSectionData;

    
private slots:
    void sl_getSections(void);
    void sl_evaluateSections(QString s_reply, QObject* caller);
    void sl_getRequiredSections(void);
    void sl_obtainedSection(QString s_reply, QObject* caller, QString s_currentSection);
    void sl_processRequiredSections(void);
    t_templateArguments sl_parseTemplateArguments(QString s_templateString);
@<End of class and header @>
@}

\subsection{Implementation}

@O ../src/grammarprovider_wiktionary_word.cpp -d
@{
#include "grammarprovider_wiktionary_word.h"
@} 


[om]\subsubsection[grammarprovider]{grammarprovider}
@O ../src/grammarprovider_wiktionary_word.cpp -d
@{


grammarprovider_wiktionary_word::grammarprovider_wiktionary_word(QString ls_word, int li_language, grammarprovider_wiktionary_word::e_signalProcessing le_signalHandling, QObject *parent) : QObject(parent), s_word(ls_word), e_signalHandling(le_signalHandling), s_baseurl("https://en.wiktionary.org/w/api.php?"), i_language(li_language)
{
    m_interestingSections["Conjugation"] = {true,1};
    m_interestingSections["Declension"] = {true,1};
    m_interestingSections["Etymology"] = {false,0};

    QQmlEngine* engine = qobject_cast<QQmlEngine*>(parent);

    m_database = engine->singletonInstance<database*>(qmlTypeId("DatabaseLib", 1, 0, "Database"));
    s_language = m_database->languagenamefromid(i_language);

    m_networkscheduler = engine->singletonInstance<networkscheduler*>(qmlTypeId("NetworkSchedulerLib", 1, 0, "NetworkScheduler"));
    connect(m_networkscheduler, &networkscheduler::requestFailed,[&](QObject* caller, QString reason){
            if(caller == this)
            {
                s_networkErrorReason = reason;
                emit sgi_networkError();
            }
            }); 
    connect(m_networkscheduler, &networkscheduler::processingStart,[&](QObject* caller){
            if(caller == this)
            {
                emit sgi_queryNetwork();
            }
            }); 

    QVariant test = QVariant::fromValue(m_currentProgress);

    psm_main = new QStateMachine(this);
    QState* s_main = new QState(QState::ParallelStates);

    // Progress states:
    QState* s_progress = new QState(s_main);

    QState* s_idle = new QState(s_progress);
    s_idle->assignProperty(this,"currentProgress",QVariant::fromValue(e_progressState::IDLE));

    QState* s_getWordOverview = new QState(s_progress);
    s_idle->addTransition(this, &grammarprovider_wiktionary_word::sgi_lookupWord, s_getWordOverview);
    s_getWordOverview->assignProperty(this,"currentProgress",QVariant::fromValue(e_progressState::GET_WORD_OVERVIEW));
    connect(s_getWordOverview,&QState::entered,this,&grammarprovider_wiktionary_word::sl_getSections);

    QState* s_getRequiredSections = new QState(s_progress);
    s_getWordOverview->addTransition(this, &grammarprovider_wiktionary_word::sgi_getRequiredSections, s_getRequiredSections);
    s_getRequiredSections->assignProperty(this,"currentProgress",QVariant::fromValue(e_progressState::GET_REQUIRED_SECTIONS));

    QState* s_processRequiredSections = new QState(s_progress);
    s_getRequiredSections->addTransition(this, &grammarprovider_wiktionary_word::sgi_processRequiredSections, s_processRequiredSections);
    s_processRequiredSections->addTransition(this, &grammarprovider_wiktionary_word::sgi_getRequiredSections, s_getRequiredSections);
    s_processRequiredSections->assignProperty(this,"currentProgress",QVariant::fromValue(e_progressState::PROCESS_REQUIRED_SECTIONS));

    QState* s_getOptionalSections = new QState(s_progress);
    s_getRequiredSections->addTransition(this, &grammarprovider_wiktionary_word::sgi_getOptionalSections, s_getOptionalSections);
    s_getOptionalSections->assignProperty(this,"currentProgress",QVariant::fromValue(e_progressState::GET_OPTIONAL_SECTIONS));

    QState* s_getCompoundform = new QState(s_progress);
    s_getOptionalSections->addTransition(this, &grammarprovider_wiktionary_word::sgi_getCompoundform, s_getCompoundform);
    s_getCompoundform->assignProperty(this,"currentProgress",QVariant::fromValue(e_progressState::GET_COMPOUNDFORM));

    QState* s_finished = new QState(s_progress);
    s_getRequiredSections->addTransition(this, &grammarprovider_wiktionary_word::sgi_progressFinished, s_finished);
    s_getOptionalSections->addTransition(this, &grammarprovider_wiktionary_word::sgi_progressFinished, s_finished);
    s_getCompoundform->addTransition(this, &grammarprovider_wiktionary_word::sgi_progressFinished, s_finished);
    s_finished->assignProperty(this,"currentProgress",QVariant::fromValue(e_progressState::FINISHED));

    s_progress->setInitialState(s_idle);

    // Network states (no error recovery here, this is done on different levels above and below):
    QState* s_network = new QState(s_main);
    QState* s_networkIdle = new QState(s_network);

    QState* s_networkError = new QState(s_network);
    s_networkIdle->addTransition(this, &grammarprovider_wiktionary_word::sgi_networkError, s_networkError);

    QState* s_networkQueryActive = new QState(s_network);
    s_networkQueryActive->addTransition(this, &grammarprovider_wiktionary_word::sgi_networkError, s_networkError);
    s_networkIdle->addTransition(this, &grammarprovider_wiktionary_word::sgi_queryNetwork, s_networkQueryActive);
    s_networkQueryActive->addTransition(this, &grammarprovider_wiktionary_word::sgi_queryFinished, s_networkIdle);

    s_network->setInitialState(s_networkIdle);

    psm_main->addState(s_main);
    psm_main->start();
}
@}


\subsubsection{sl\_getSections}
@O ../src/grammarprovider_wiktionary_word.cpp -d
@{

void grammarprovider_wiktionary_word::sl_getSections(){
    m_networkscheduler->requestNetworkReply(this, s_baseurl + "action=parse&page=" + s_word + "&prop=sections&format=json", std::bind(&grammarprovider_wiktionary_word::sl_evaluateSections,this,std::placeholders::_1, this));
}
@}

\subsection{sl\_evaluateSections}
@O ../src/grammarprovider_wiktionary_word.cpp -d
@{
void grammarprovider_wiktionary_word::sl_evaluateSections(QString s_reply, QObject* caller){
    if(caller != this)
        return;
    QJsonDocument j_sectionsDocument = QJsonDocument::fromJson(s_reply.toUtf8());
    QJsonArray j_sections = j_sectionsDocument.object()["parse"].toObject()["sections"].toArray();
    bool b_found_language = false;
    int section_level = 0;
    int language_section_level = 0;
    QString s_section;
    foreach(const QJsonValue& jv_section, j_sections){
        QJsonObject j_section = jv_section.toObject();
        QString s_section = j_section["line"].toString();
        int section_level = j_section["level"].toString().toInt();
        if(section_level <= language_section_level) break;
        if(s_section == s_language){
            b_found_language = true;
            language_section_level = section_level;
        }
        else
            if(b_found_language && m_interestingSections.contains(s_section)){
                m_collectedSectionData[s_section] = j_section["index"].toString().toInt();
                if(m_collectedSectionData.size() == m_interestingSections.size())
                    goto finished;
                //m_networkscheduler->requestNetworkReply(&waitloop,s_baseurl + "action=parse&page=" + m_word + "&section=" + QString::number(best_bet_for_section) + "&prop=wikitext&format=json", std::bind(&grammarprovider::getWiktionaryTemplate,this,std::placeholders::_1,&waitloop,e_wiktionaryRequestPurpose::ETYMOLOGY));
            }
    }
    finished:
    // Check if we got required sections:
    QMap<int,bool> m_requiredGroupOk;
    for(const auto& interestingSection: m_interestingSections.keys())
        if(m_interestingSections[interestingSection].b_required){
            int i_requireGroup = m_interestingSections[interestingSection].i_requireGroup;
            if(!m_requiredGroupOk.contains(i_requireGroup))
                m_requiredGroupOk[i_requireGroup] = false;
            else
                if(m_collectedSectionData.contains(interestingSection))
                    m_requiredGroupOk[i_requireGroup] = true;
        }
    for(const auto& requiredGroupOk: m_requiredGroupOk)
        if(!requiredGroupOk) return;
    emit sgi_getRequiredSections();
        //m_networkscheduler->requestNetworkReply(caller,s_baseurl + "action=parse&page=" + m_word + "&section=" + QString::number(best_bet_for_section) + "&prop=wikitext&format=json", std::bind(&grammarprovider::getWiktionaryTemplate,this,std::placeholders::_1,caller,e_wiktionaryRequestPurpose::FLECTION));
}
@}

\subsection{sl\_getRequiredSections}
@O ../src/grammarprovider_wiktionary_word.cpp -d
@{
void grammarprovider_wiktionary_word::sl_getRequiredSections(void){
    for(const auto& currentSection: m_collectedSectionData.keys()){
        if(m_interestingSections[currentSection].b_required &&
                !m_collectedSectionData[currentSection].b_available){
            m_networkscheduler->requestNetworkReply(this,s_baseurl + "action=parse&page=" + s_word + "&section=" + QString::number(m_collectedSectionData[currentSection].i_sectionNumber) + "&prop=wikitext&format=json", std::bind(&grammarprovider_wiktionary_word::sl_obtainedSection,this,std::placeholders::_1,this,currentSection));
            return;
        }
    }
    emit sgi_getOptionalSections();
}
@}

\subsection{sl\_networkQueryForRequiredSection}
@O ../src/grammarprovider_wiktionary_word.cpp -d
@{
void grammarprovider_wiktionary_word::sl_obtainedSection(QString s_reply, QObject* caller, QString s_currentSection){
    if(caller != this) return;
    m_collectedSectionData[s_currentSection].b_available = true;
    m_collectedSectionData[s_currentSection].s_content = s_reply;
    emit sgi_processRequiredSections();
}
@}

\subsection{sl\_processRequiredSections}
@O ../src/grammarprovider_wiktionary_word.cpp -d
@{
void grammarprovider_wiktionary_word::sl_processRequiredSections(void){
    bool b_foundSectionToProcess = false;
    QString s_section;
    for(const auto& currentSection: m_collectedSectionData.keys())
        if(m_interestingSections[currentSection].b_required &&
                m_collectedSectionData[currentSection].b_available &&
                !m_collectedSectionData[currentSection].b_processed){
            b_foundSectionToProcess = true;
            s_section = currentSection;
            break;
        }
    if(!b_foundSectionToProcess) return;
    QJsonDocument j_document = QJsonDocument::fromJson(m_collectedSectionData[s_section].s_content.toUtf8());
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
    foreach(const QString& wt_finished, wt_finisheds)
        m_collectedSectionData[s_section].l_templates.push_back(sl_parseTemplateArguments(wt_finished));
}
@}

\subsection{sl\_processRequiredSections}
@O ../src/grammarprovider_wiktionary_word.cpp -d
@{
grammarprovider_wiktionary_word::t_templateArguments grammarprovider_wiktionary_word::sl_parseTemplateArguments(QString s_templateString){
    s_templateString = s_templateString.trimmed();
    s_templateString.remove(0,2);
    s_templateString.chop(2);
    QStringList args = s_templateString.split(QLatin1Char('|'));
    t_templateArguments parsed_args;
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

