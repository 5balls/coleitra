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

\chapter{Network scheduler}
This is a generic class for scheduling network requests.


\section{Interface}
@O ../src/networkscheduler.h -d
@{
@<Start of @'NETWORKSCHEDULER@' header@>

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>

@<Start of class @'networkscheduler@'@>
public:
    explicit networkscheduler(QObject *parent = nullptr);
    ~networkscheduler(void);
    enum networkRequestStatus {
        REQUEST_SUCCESFUL,
        RETRYING_REQUEST,
        PERMANENT_NETWORK_ERROR,
    };
public slots:
    QNetworkReply* requestNetworkReply(QString url, std::function<void(QString)> slot);
private slots:
    void processNetworkAnswer(QNetworkReply* reply);
    networkRequestStatus checkReplyAndRetryIfNecessary(QNetworkReply* reply, QString& s_reply);
    QNetworkReply* repeatLastNetworkRequest();
private:
    QNetworkReply* m_networkreply;
    QNetworkAccessManager* m_manager;
    QUrl m_last_request_url;
    QMetaObject::Connection m_tmp_connection;
    QString ms_last_network_answer;
    std::function<void(QString)>  m_last_connected_slot;
signals:
    void processingStop(void);
@<End of class and header @>
@}

\section{Implementation}
@O ../src/networkscheduler.cpp -d
@{
#include "networkscheduler.h"
@}

\cprotect\subsection{\verb#networkscheduler#}
@O ../src/networkscheduler.cpp -d
@{
networkscheduler::networkscheduler(QObject *parent) : QObject(parent)
{
    m_manager = new QNetworkAccessManager(this);
    m_manager->setTransferTimeout(1000);
    connect(m_manager, &QNetworkAccessManager::finished, this, &networkscheduler::processNetworkAnswer);
}
@}

\cprotect\subsection{\verb#~networkscheduler#}
@O ../src/networkscheduler.cpp -d
@{
networkscheduler::~networkscheduler() {
    disconnect(m_manager, &QNetworkAccessManager::finished, this, &networkscheduler::processNetworkAnswer);
    delete m_manager;
}
@}

\cprotect\subsection{\verb#processNetworkAnswer#}
@O ../src/grammarprovider.cpp -d
@{
void networkscheduler::processNetworkAnswer(QNetworkReply* reply){
    reply->deleteLater();
    ms_last_network_answer.clear();
    switch(checkReplyAndRetryIfNecessary(reply,ms_last_network_answer)){
        case REQUEST_SUCCESFUL:
            break;
        case RETRYING_REQUEST:
            return;
        case PERMANENT_NETWORK_ERROR:
            emit processingStop();
            return;
    }
    m_last_connected_slot(ms_last_network_answer);
}
@}


\cprotect\subsection{\verb#checkReplyAndRetryIfNecessary#}
@O ../src/grammarprovider.cpp -d
@{
networkscheduler::networkRequestStatus networkscheduler::checkReplyAndRetryIfNecessary(QNetworkReply* reply, QString& s_reply){
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


\cprotect\subsection{\verb#requestNetworkReply#}
@O ../src/networkscheduler.cpp -d
@{
QNetworkReply* networkscheduler::requestNetworkReply(QString url, std::function<void(QString)> slot){
    m_last_connected_slot = slot;
    m_last_request_url = QUrl(url);
    qDebug() << QTime::currentTime().toString() << "Request" << m_last_request_url.toString();
    QNetworkRequest request(m_last_request_url);
    request.setRawHeader("User-Agent", "Coleitra/0.1 (https://coleitra.org; fpesth@@gmx.de)");
    return m_manager->get(request);
}
@}


\cprotect\subsection{\verb#repeatLastNetworkRequest#}
@O ../src/networkscheduler.cpp -d
@{
QNetworkReply* networkscheduler::repeatLastNetworkRequest(){
    qDebug() << QTime::currentTime().toString() << "Repeated request" << m_last_request_url.toString();
    QNetworkRequest request(m_last_request_url);
    request.setRawHeader("User-Agent", "Coleitra/0.1 (https://coleitra.org; fpesth@@gmx.de)");
    return m_manager->get(request);
}
@}

