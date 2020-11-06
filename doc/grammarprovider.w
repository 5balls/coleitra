% Copyright 2020 Florian Pesth
%
% This file is part of coleitra.
%
% coleitra is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% coleitra is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with coleitra.  If not, see <https://www.gnu.org/licenses/>.

\chapter{Grammar provider}
\section{Interface}
@o ../src/grammarprovider.h -d
@{
@<Start of @'GRAMMARPROVIDER@' header@>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
@<Start of class @'grammarprovider@'@>
    Q_PROPERTY(QString language MEMBER m_language)
public:
    explicit grammarprovider(QObject *parent = nullptr);
    ~grammarprovider(void);
public slots:
    Q_INVOKABLE void getWiktionarySections(QString word);
    void getWiktionarySection(QNetworkReply* reply);
private:
    QString m_language;
    QString s_baseurl;
    QNetworkAccessManager* m_manager;
    QMetaObject::Connection m_tmp_connection;
signals:

@<End of class and header @>
@}

\section{Implementation}
@o ../src/grammarprovider.cpp -d
@{
#include "grammarprovider.h"


grammarprovider::grammarprovider(QObject *parent) : QObject(parent)
{
    m_manager = new QNetworkAccessManager(this);
    s_baseurl = "https://en.wiktionary.org/w/api.php?";
}

grammarprovider::~grammarprovider() {
    delete m_manager;
}

void grammarprovider::getWiktionarySections(QString word){
    QNetworkRequest request;
    QUrl url(s_baseurl + "action=parse&page=" + word + "&prop=sections&format=json");
    request.setUrl(url);
    request.setRawHeader("User-Agent", "Coleitra/0.1 (https://coleitra.org; fpesth@@gmx.de)");
    m_tmp_connection = connect(m_manager, &QNetworkAccessManager::finished,
        this, &grammarprovider::getWiktionarySection);
    m_manager->get(request);
}

void grammarprovider::getWiktionarySection(QNetworkReply* reply){
    QObject::disconnect(m_tmp_connection);
    QString s_reply = QString(reply->readAll());
    QJsonDocument jsonSections = QJsonDocument::fromJson(s_reply.toUtf8());
    QJsonObject jsonSectionsObject = jsonSections.object();
    qDebug() << s_reply;
//    QNetworkRequest request(QUrl("https://en.wiktionary.org/w/api.php?action=parse&page=" + word + "&section=" + section + "&prop=wikitext"));
}
@}
