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
        GET_FLECTION,
        GET_ETYMOLOGY,
        GET_COMPOUNDFORM,
        FINISHED
    };
    Q_ENUM(e_progressState);
    Q_PROPERTY(e_progressState currentProgress MEMBER m_currentProgress);
    explicit grammarprovider_wiktionary_word(QString s_word, int li_language, e_signalProcessing e_signalHandling = e_signalProcessing::NO_SIGNALS, QObject *parent = nullptr);
signals:
    // For progress states:
    void sgi_lookupWord(void);
    void sgi_getFlection(void);
    void sgi_getEtymology(void);
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

    struct t_sectionRequired {
        bool b_required;
        int i_requireGroup;
    };

    QMap<QString,t_sectionRequired> m_interestingSections;

    QMap<QString,int> m_foundSections;
private slots:
    void sl_getSections(void);
    void sl_evaluateSections(QString s_reply, QObject* caller);
@<End of class and header @>
@}

\subsection{Implementation}

@O ../src/grammarprovider_wiktionary_word.cpp -d
@{
#include "grammarprovider_wiktionary_word.h"
@} 


\cprotect[om]\subsubsection[grammarprovider]{\verb#grammarprovider#}
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

    QState* s_getFlection = new QState(s_progress);
    s_getWordOverview->addTransition(this, &grammarprovider_wiktionary_word::sgi_getFlection, s_getFlection);
    s_getFlection->assignProperty(this,"currentProgress",QVariant::fromValue(e_progressState::GET_FLECTION));

    QState* s_getEtymology = new QState(s_progress);
    s_getFlection->addTransition(this, &grammarprovider_wiktionary_word::sgi_getEtymology, s_getEtymology);
    s_getEtymology->assignProperty(this,"currentProgress",QVariant::fromValue(e_progressState::GET_ETYMOLOGY));

    QState* s_getCompoundform = new QState(s_progress);
    s_getEtymology->addTransition(this, &grammarprovider_wiktionary_word::sgi_getCompoundform, s_getCompoundform);
    s_getCompoundform->assignProperty(this,"currentProgress",QVariant::fromValue(e_progressState::GET_COMPOUNDFORM));

    QState* s_finished = new QState(s_progress);
    s_getFlection->addTransition(this, &grammarprovider_wiktionary_word::sgi_progressFinished, s_finished);
    s_getEtymology->addTransition(this, &grammarprovider_wiktionary_word::sgi_progressFinished, s_finished);
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


\cprotect\subsubsection{\verb#sl_getSections#}
@O ../src/grammarprovider_wiktionary_word.cpp -d
@{

void grammarprovider_wiktionary_word::sl_getSections(){
    m_networkscheduler->requestNetworkReply(this, s_baseurl + "action=parse&page=" + s_word + "&prop=sections&format=json", std::bind(&grammarprovider_wiktionary_word::sl_evaluateSections,this,std::placeholders::_1, this));
}
@}

\cprotect\subsection{\verb#sl_evaluateSections#}
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
        else{
            if(b_found_language){
                if(m_interestingSections.contains(s_section)){
                    m_foundSections[s_section] = j_section["index"].toString().toInt();
                    if(m_foundSections.size() == m_interestingSections.size())
                        goto finished;
                    //m_networkscheduler->requestNetworkReply(&waitloop,s_baseurl + "action=parse&page=" + m_word + "&section=" + QString::number(best_bet_for_section) + "&prop=wikitext&format=json", std::bind(&grammarprovider::getWiktionaryTemplate,this,std::placeholders::_1,&waitloop,e_wiktionaryRequestPurpose::ETYMOLOGY));
                }
            }
        }
    }
    finished:
    return;
        //m_networkscheduler->requestNetworkReply(caller,s_baseurl + "action=parse&page=" + m_word + "&section=" + QString::number(best_bet_for_section) + "&prop=wikitext&format=json", std::bind(&grammarprovider::getWiktionaryTemplate,this,std::placeholders::_1,caller,e_wiktionaryRequestPurpose::FLECTION));
}
@}

