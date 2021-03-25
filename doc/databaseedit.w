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

\chapter{Database editing}
\section{Interface}

@o ../src/databaseedit.h -d
@{
@<Start of @'DATABASEEDIT@' header@>
#include <QQmlEngine>
#include "database.h"

@<Start of class @'databaseedit@'@>
public:
    explicit databaseedit(QObject *parent = nullptr);
private:
    database* m_database;
    QString m_dbversion;
signals:
@<End of class and header @>
@}

\section{Implementation}

@o ../src/databaseedit.cpp -d
@{
#include "databaseedit.h"

databaseedit::databaseedit(QObject *parent) : QObject(parent)
{
    QQmlEngine* engine = qobject_cast<QQmlEngine*>(parent);
    m_database = engine->singletonInstance<database*>(qmlTypeId("DatabaseLib", 1, 0, "Database"));
    m_dbversion = m_database->property("version").toString();
}
@}
