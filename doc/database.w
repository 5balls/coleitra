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

\chapter{Database}
\index{Database}
\section{Interface}
The database class defines an interface for creating the different database connections used at other places in the code.

@o ../src/database.h -d
@{
@<Start of @'DATABASE@' header@>
#include <QSqlDatabase>
#include <QStandardPaths>
#include <QDir>
#include <QFileInfo>
#include <QSqlField>
#include "databasetable.h"
@<Start of class @'database@'@>
public:
    explicit database(QObject *parent = nullptr);
private:
    QSqlDatabase vocableDatabase;
    QList < databasetable* > tables;
@<End of class and header @>
@}

@o ../src/database.cpp -d
@{
#include "database.h"
@}

\section{Constructor}

We set the \lstinline{QObject} parent by the constructor.

@o ../src/database.cpp -d
@{
database::database(QObject *parent) : QObject(parent)
{
@}

We try to use an Sqlite\index{Sqlite} driver and check if it is available.

@o ../src/database.cpp -d
@{
    if(!QSqlDatabase::isDriverAvailable("QSQLITE")){
        qDebug("Driver \"QSQLITE\" is not available!");
    }
@}

\index{Database!Path|(}The path of the database file is architecture dependant, for the desktop version we follow the linux convention of using a hidden directory with the programs name in the users home directory.

@o ../src/database.cpp -d
@{
#ifdef Q_OS_ANDROID
    QString dbFileName = QStandardPaths::standardLocations(QStandardPaths::AppDataLocation).at(1) + "/vocables.sqlite";
#else
    QString dbFileName = QStandardPaths::standardLocations(QStandardPaths::HomeLocation).at(0) + "/.coleitra/vocables.sqlite";
#endif
@}

If the path for the database file does not exist, we create it first.

@o ../src/database.cpp -d
@{
    {
        QFileInfo fileName(dbFileName);
        if(!QDir(fileName.absolutePath()).exists()){
            QDir().mkdir(fileName.absolutePath());
        }
    }
@}\index{Database!Path|)}

Now we can create a connection for the database and open the database file.

@o ../src/database.cpp -d
@{
    vocableDatabase = QSqlDatabase::addDatabase("QSQLITE", "vocableDatabase");
    vocableDatabase.setDatabaseName(dbFileName);
    if(!vocableDatabase.open()){
        qDebug("Could not open database file!");
    }
@}

Finally we create our tables if they don't exist already:

@o ../src/database.cpp -d
@{
    {
        databasetable* languagetable = new databasetable("language",{new databasefield("id",QVariant::Int),new databasefield("locale",QVariant::String)});
        tables.push_back(languagetable);
        QVariant* lexemtable_fk = new QVariant();
        lexemtable_fk->setValue(databasefield_constraint_foreign_key(languagetable,"id"));
        databasetable* lexemtable = new databasetable("lexem",
                {new databasefield("id",QVariant::Int),
                new databasefield("language",QVariant::Int,
                        {lexemtable_fk})});
        tables.push_back(lexemtable);
        QVariant* formtable_fk = new QVariant();
        formtable_fk->setValue(databasefield_constraint_foreign_key(lexemtable,"id"));
        databasetable* formtable = new databasetable("form",
                {new databasefield("id",QVariant::Int),
                new databasefield("lexem",QVariant::Int,
                        {formtable_fk})});
        tables.push_back(formtable);
    }
}
@}

\section{Field}
\subsection{Interface}
@o ../src/databasefield.h -d
@{
@<Start of @'DATABASEFIELD@' header@>
#include <QSqlField>
@}

We need to predeclare databasetable, because we have a circular dependency between databasefield and databasetable here:

@o ../src/databasefield.h -d
@{
class databasetable;
@}

Constrains on the column of a database table are handled as QVariant. The basis to make such a QVariant is defined by the fragments for the constraint classes.

@o ../src/databasefield.h -d
@{
@<Valueless db constraint class @'databasefield_constraint_not_null@' @>
@<Valueless db constraint class @'databasefield_constraint_unique@' @>
@<Valueless db constraint class @'databasefield_constraint_primary_key@' @>

@<Start of db constraint class @'databasefield_constraint_foreign_key@' @>
public:
    databasefield_constraint_foreign_key(databasetable* fKT, QString fFN) : m_foreignKeyTable(fKT), m_foreignFieldName(fFN){};
    databasetable* foreignKeyTable(){return m_foreignKeyTable;};
    QString foreignFieldName(){return m_foreignFieldName;};
private:
    databasetable* m_foreignKeyTable;
    QString m_foreignFieldName;
@<End of db constraint class @'databasefield_constraint_foreign_key@' @>

class databasefield 
{
public:
    explicit databasefield(const QString& fieldname,
            QVariant::Type type,
            QList<QVariant*> constraints = {});

private:
    QSqlField m_field;
    QList<QVariant*> m_constraints;
@<End of class and header@>
@}

\subsection{Implementation}
@o ../src/databasefield.cpp -d
@{
#include "databasefield.h"

databasefield::databasefield(const QString& fieldname,
        QVariant::Type type,
        QList<QVariant*> constraints) : m_field(fieldname, type), m_constraints(constraints){
}
@}

\section{Table}
\subsection{Interface}
@o ../src/databasetable.h -d
@{
@<Start of @'DATABASETABLE@' header@>
#include <QSqlRecord>
#include <QSqlField>
#include <QString>
#include <QSqlDatabase>
#include <QDebug>
#include "databasefield.h"

class databasetable : public QObject, QSqlRecord
{
    Q_OBJECT
public:
    explicit databasetable(QString name = "", QList<databasefield*> fields = {});
    bool tableWasNewlyCreated;
private:
    QSqlDatabase* vocableDatabase;
@<End of class and header@>
@}

\subsection{Implementation}
@o ../src/databasetable.cpp -d
@{
#include "databasetable.h"
databasetable::databasetable(QString name, QList<databasefield*> fields) : tableWasNewlyCreated(false){
    qDebug() << name;
}

@}
