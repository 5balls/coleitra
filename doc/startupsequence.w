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

\chapter{Startup sequence}
This are actions executed during the controlled startup sequence.

\section{Interface}
@O ../src/startupsequence.h -d
@{
@<Start of @'STARTUPSEQUENCE@' header@>

#include <QTimer>
#include <QQmlEngine>
#include "database.h"
#include "grammarprovider.h"

@<Start of class @'startupsequence@'@>
public:
    explicit startupsequence(QObject *parent = nullptr);
    Q_INVOKABLE void prepareDatabase(void);
    Q_INVOKABLE void prepareGrammarprovider(void);
signals:
    void databaseReady(void);
    void grammarproviderReady(void);

private slots:
    void databasePreparation(void);
    void grammarproviderPreparation(void);
private:
    QQmlEngine* m_engine;
    database* m_database;
    grammarprovider* m_grammarprovider;
@<End of class and header @>
@}

\section{Implementation}

@O ../src/startupsequence.cpp -d
@{
#include "startupsequence.h"

startupsequence::startupsequence(QObject *parent) : QObject(parent)
{
    m_engine = qobject_cast<QQmlEngine*>(parent);
}
@}

@O ../src/startupsequence.cpp -d
@{

void startupsequence::prepareDatabase(void){
    QTimer::singleShot(100, this, SLOT(databasePreparation()));
}

void startupsequence::databasePreparation(void){
    m_database = m_engine->singletonInstance<database*>(qmlTypeId("DatabaseLib", 1, 0, "Database"));
    qDebug() << "Database version: " + m_database->property("version").toString();
    emit databaseReady();
}


void startupsequence::prepareGrammarprovider(void){
    QTimer::singleShot(0, this, SLOT(grammarproviderPreparation()));
}

void startupsequence::grammarproviderPreparation(void){
    m_grammarprovider = m_engine->singletonInstance<grammarprovider*>(qmlTypeId("GrammarProviderLib", 1, 0, "GrammarProvider"));
    emit grammarproviderReady();
}
@}
