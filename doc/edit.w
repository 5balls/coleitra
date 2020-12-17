% Copyright 2020 Florian Pesth
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

\chapter{Editing}
\section{Interface}

@d Id property @'idname@'
@{
public:
    Q_PROPERTY(int @1Id READ @1Id CONSTANT)
    int @1Id()
    {
        return m_@1Id--;
    }
private:
    int m_@1Id = -1;
@}

@o ../src/edit.h -d
@{
@<Start of @'EDIT@' header@>
#include <QQmlEngine>
#include "database.h"


@<Start of class @'edit@'@>
public:
    explicit edit(QObject *parent = nullptr);
    Q_PROPERTY(QString dbversion MEMBER m_dbversion NOTIFY dbversionChanged);
    @<Id property @'translation@' @>
    @<Id property @'lexeme@' @>
    @<Id property @'sentence@' @>
    @<Id property @'form@' @>
    @<Id property @'compoundForm@' @>
    @<Id property @'grammarForm@' @>
    @<Id property @'grammarFormComponent@' @>
private:
    struct form {
        QString string;
        QList<int> grammarexpressions;
    };
    struct lexeme {
        QList<form> forms;
    };
    QList<lexeme> lexemes;
    database* m_database;
    QString m_dbversion;
signals:
    void dbversionChanged(const QString &newVersion);
@<End of class and header @>
@}

\section{Implementation}

@o ../src/edit.cpp -d
@{
#include "edit.h"

edit::edit(QObject *parent) : QObject(parent)
{

    QQmlEngine* engine = qobject_cast<QQmlEngine*>(parent);
    m_database = engine->singletonInstance<database*>(qmlTypeId("DatabaseLib", 1, 0, "Database"));
    m_dbversion = m_database->property("version").toString();
}

@}
