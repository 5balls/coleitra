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

public slots:
    QNetworkReply* requestNetworkReply(QString url);
    QNetworkReply* repeatLastNetworkRequest();
    void reconnectLastReplyFinishedToSlot();
private:
    QNetworkAccessManager* m_manager;
    QUrl m_last_request_url;
    QMetaObject::Connection m_tmp_connection;
    void(networkscheduler::* m_last_connected_slot)(QNetworkReply*);

@<End of class and header @>
@}

\section{Implementation}
@O ../src/networkscheduler.cpp -d
@{
#include "networkscheduler.h"
@}

\cprotect\subsection{\verb#requestNetworkReply#}
@O ../src/networkscheduler.cpp -d
@{
QNetworkReply* networkscheduler::requestNetworkReply(QString url){
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
    reconnectLastReplyFinishedToSlot();
    return m_manager->get(request);
}
@}

\cprotect\subsection{\verb#reconnectLastReplyFinishedToSlot#}
@O ../src/networkscheduler.cpp -d
@{
void networkscheduler::reconnectLastReplyFinishedToSlot(){
    m_tmp_connection = connect(m_manager, &QNetworkAccessManager::finished, this, m_last_connected_slot);
}
@}

