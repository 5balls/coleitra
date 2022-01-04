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

\chapter{Network scheduler}
This is a generic class for scheduling network requests.

\section{Error handling}

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
public slots:
    QNetworkReply* requestNetworkReply(QObject* caller, QString url, std::function<void(QString)> slot);
private:
    enum networkRequestStatus {
        REQUEST_SUCCESFUL,
        RETRYING_REQUEST,
        PERMANENT_NETWORK_ERROR,
    };
    struct requestData {
        std::function<void(QString)> f_callback;
        QString s_answer;
        QObject* caller;
    };
    QMap<QUrl, requestData> m_request_list;
    QNetworkAccessManager* m_manager;
    QMetaObject::Connection m_tmp_error_connection;
private slots:
    void processNetworkAnswer(QNetworkReply* reply);
    networkRequestStatus checkReplyAndRetryIfNecessary(QNetworkReply* reply, QString& s_reply);
    QNetworkReply* repeatNetworkRequest(QUrl url);
signals:
    void processingStart(void);
    void replyError(QNetworkReply::NetworkError error);
    void requestFailed(QObject* caller, QString s_reason);
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
    QUrl url_request = reply->request().url();
    QString ms_network_answer;
    switch(checkReplyAndRetryIfNecessary(reply,ms_network_answer)){
        case REQUEST_SUCCESFUL:
            break;
        case RETRYING_REQUEST:
            return;
        case PERMANENT_NETWORK_ERROR:
            emit processingStop();
            return;
    }
    m_request_list[url_request].s_answer = ms_network_answer;
    emit processingStop();
    (m_request_list[url_request].f_callback)(ms_network_answer);
}
@}


\cprotect\subsection{\verb#checkReplyAndRetryIfNecessary#}
@O ../src/grammarprovider.cpp -d
@{
networkscheduler::networkRequestStatus networkscheduler::checkReplyAndRetryIfNecessary(QNetworkReply* reply, QString& s_reply){
    static int retrycount = 0;
    const int max_retries = 5;
    QString s_failure_reason;
    if(reply->error() != QNetworkReply::NoError){
        switch(reply->error()){
            // Not possible but for compiler warning:
            case QNetworkReply::NoError:
            // We should give up in case of this errors:
            case QNetworkReply::ConnectionRefusedError:
            case QNetworkReply::OperationCanceledError:
            case QNetworkReply::SslHandshakeFailedError:
            case QNetworkReply::BackgroundRequestNotAllowedError:
            case QNetworkReply::TooManyRedirectsError:
            case QNetworkReply::InsecureRedirectError:
            case QNetworkReply::ProxyConnectionRefusedError:
            case QNetworkReply::ProxyAuthenticationRequiredError:
            case QNetworkReply::ContentAccessDenied:
            case QNetworkReply::ContentOperationNotPermittedError:
            case QNetworkReply::ContentNotFoundError:
            case QNetworkReply::AuthenticationRequiredError:
            case QNetworkReply::ContentReSendError:
            case QNetworkReply::ContentConflictError:
            case QNetworkReply::ContentGoneError:
            case QNetworkReply::OperationNotImplementedError:
            case QNetworkReply::ProtocolUnknownError:
            case QNetworkReply::ProtocolInvalidOperationError:
            case QNetworkReply::ProtocolFailure:
                s_failure_reason = "Network reply got error which lead to directly giving up: " + QVariant::fromValue(reply->error()).toString();
                goto giveup;
                break;
            // In case of this errors it may be worth to try again:
            case QNetworkReply::RemoteHostClosedError:
            case QNetworkReply::HostNotFoundError:
            case QNetworkReply::TimeoutError:
            case QNetworkReply::TemporaryNetworkFailureError:
            case QNetworkReply::NetworkSessionFailedError:
            case QNetworkReply::ProxyConnectionClosedError:
            case QNetworkReply::ProxyNotFoundError:
            case QNetworkReply::ProxyTimeoutError:
            case QNetworkReply::InternalServerError:
            case QNetworkReply::ServiceUnavailableError:
            case QNetworkReply::UnknownNetworkError:
            case QNetworkReply::UnknownProxyError:
            case QNetworkReply::UnknownContentError:
            case QNetworkReply::UnknownServerError:
                s_failure_reason = "Network reply got error which lead to giving up after " + QString::number(max_retries) + " retries:" + QString(reply->error());
                retrycount++;
                if(retrycount < max_retries){
                    m_manager->setTransferTimeout(1000+1000*retrycount);
                    repeatNetworkRequest(reply->request().url());
                    reply->deleteLater();
                    return RETRYING_REQUEST;
                }
                else goto giveup;
                break;
        }
    }
    /*if(!reply->isOpen()){
        qDebug() << "Closed reply";
        retrycount++;
        if(retrycount < max_retries){
            qDebug() <<  "Closed reply, retrying" << retrycount;
            m_manager->setTransferTimeout(1000+1000*retrycount);
            repeatNetworkRequest(reply->request().url());
            reply->deleteLater();
            return RETRYING_REQUEST;
        }
        else goto giveup;    
    }*/
    if(reply->isReadable()){
        s_reply = QString(reply->readAll());
    }
    else {
        s_failure_reason = "Network reply could not be read, giving up.";
        retrycount++;
        if(retrycount < max_retries){
            m_manager->setTransferTimeout(1000+1000*retrycount);
            repeatNetworkRequest(reply->request().url());
            reply->deleteLater();
            return RETRYING_REQUEST;
        }
        else goto giveup;
    }
    retrycount = 0;
    m_manager->setTransferTimeout(1000);

#if QT_VERSION >= 0x051500
    disconnect(m_tmp_error_connection);
 #endif
    reply->deleteLater();
    return REQUEST_SUCCESFUL;
giveup:
    retrycount = 0;
    m_manager->setTransferTimeout(1000);
#if QT_VERSION >= 0x051500
    disconnect(m_tmp_error_connection);
 #endif
    QUrl url = reply->request().url();
    reply->deleteLater();
    emit requestFailed(m_request_list[url].caller, s_failure_reason);
    return PERMANENT_NETWORK_ERROR;
}
@}


\cprotect\subsection{\verb#requestNetworkReply#}
@O ../src/networkscheduler.cpp -d
@{
QNetworkReply* networkscheduler::requestNetworkReply(QObject* caller, QString s_url, std::function<void(QString)> slot){
    emit processingStart();
    QUrl url = QUrl(s_url);
    m_request_list[url] = {slot,"",caller};
    QNetworkRequest request(url);
    request.setRawHeader("User-Agent", "Coleitra/0.1 (https://coleitra.org; fpesth@@gmx.de)");
    QNetworkReply* reply = m_manager->get(request);

#if QT_VERSION >= 0x051500
    m_tmp_error_connection = connect(reply, &QNetworkReply::errorOccurred, this, &networkscheduler::replyError);
 #endif
    return reply;
}
@}


\cprotect\subsection{\verb#repeatNetworkRequest#}
@O ../src/networkscheduler.cpp -d
@{
QNetworkReply* networkscheduler::repeatNetworkRequest(QUrl url){
    QNetworkRequest request(url);
    request.setRawHeader("User-Agent", "Coleitra/0.1 (https://coleitra.org; fpesth@@gmx.de)");
    return m_manager->get(request);
}
@}

