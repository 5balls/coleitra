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

\chapter{Errorhandling}
@o ../src/error.h -d
@{
@<Start of @'ERROR@' header@>
enum class sql_error {
    create_table,
    insert_record,
    update_record,
    delete_record,
    select_empty,
    select,
};
@<End of header@>
@}

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
    databasetable* getTableByName(QString name);
    Q_PROPERTY(QString version MEMBER m_version NOTIFY versionChanged);
    Q_INVOKABLE QStringList languagenames();
    Q_INVOKABLE int idfromlanguagename(QString languagename);
    Q_INVOKABLE QString languagenamefromid(int id);
    Q_INVOKABLE int alphabeticidfromlanguagename(QString languagename);
    Q_INVOKABLE int alphabeticidfromlanguageid(int languageid);
private:
    QSqlDatabase vocableDatabase;
    QList < databasetable* > tables;
    QString m_version;
signals:
    void versionChanged(const QString &newVersion);
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

        auto d = [this](QString name, QList<databasefield*> fields){
            databasetable* table = new databasetable(name,fields);
            tables.push_back(table);
            return table;
        };
        auto f = [](const QString& fieldname,
                QVariant::Type type){
            return new databasefield(fieldname, type);};
        auto fc = [](const QString& fieldname,
                QVariant::Type type,
                QList<QVariant*> constraints = {}){
            return new databasefield(fieldname, type, constraints);};

        auto c_nn = [](){
            QVariant* variant = new QVariant();
            variant->setValue(databasefield_constraint_not_null());
            return variant;
        };
        auto c_u = [](){
            QVariant* variant = new QVariant();
            variant->setValue(databasefield_constraint_unique());
            return variant;
        };
        auto c_pk = [](){
            QVariant* variant = new QVariant();
            variant->setValue(databasefield_constraint_primary_key());
            return variant;
        };
        auto c_fk = [](databasetable* fKT,
                QString fFN){
            QVariant* variant = new QVariant();
            variant->setValue(databasefield_constraint_foreign_key(fKT,fFN));
            return variant;
        };
        bool database_is_empty = false;

        databasetable* dbversiontable = d("dbversion",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("version",QVariant::String,{c_u()})});
        {
            QList<QString> selection;
            selection.push_back("id");
            selection.push_back("version");
            QSqlQuery result = dbversiontable->select(selection);
            int oldid = 0;
            while(result.next()){
                if(result.value("id").toInt() > oldid){
                    m_version = result.value("version").toString();
                }
            }
        }

        if(m_version.isEmpty()){
            m_version = "0.1";
            QMap<QString,QVariant> insert;
            insert["version"] = QVariant(m_version);
            dbversiontable->insertRecord(insert);
            database_is_empty = true;
        }

	databasetable* categorytable = d("category",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("name",QVariant::String,{c_u()})});
        databasetable* categoryselectiontable = d("categoryselection",
                {fc("id",QVariant::Int,{c_pk(),c_nn()})});
        databasetable* categoryselectionparttable = d("categoryselectionpart",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("category",QVariant::Int,{c_fk(categorytable,"id")})});

        databasetable* languagetable = d("language",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("locale",QVariant::String,{c_u()})});
        databasetable* languagenametable = d("languagename",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("language",QVariant::Int,{c_fk(languagetable,"id")}),
                f("name",QVariant::String),
                fc("nameisinlanguage",QVariant::Int,{c_fk(languagetable,"id")})});
        if(database_is_empty){
            QMap<QString,QVariant> add_language;
            QMap<QString,QVariant> add_language_name;
            QList< QList< QString> > languages = {
                {"cmn","Mandarin Chinese"},
                {"hi","Hindi"},
                {"es","Spanish"},
                {"fr","French"},
                {"arb","Standard Arabic"},
                {"bn","Bengali"},
                {"ru","Russian"},
                {"pt","Portuguese"},
                {"id","Indonesian"},
                {"ur","Urdu"},
                {"de","German"},
                {"ja","Japanese"},
                {"sw","Swahili"},
                {"mr","Marathi"},
                {"te","Telugu"},
                {"tr","Turkish"},
                {"yue","Yue Chinese"},
                {"ta","Tamil"},
                {"pa","Punjabi"},
                {"wuu","Wu Chinese"},
                {"ko","Korean"},
                {"vi","Vietnamese"},
                {"ha","Hausa"},
                {"jv","Javanese"},
                {"arz","Egyptian Arabic"},
                {"it","Italian"},
                {"th","Thai"},
                {"gu","Gujarati"},
                {"kn","Kannada"},
                {"fa","Persian"},
                {"bho","Bhojpuri"},
                {"nan","Southern Min"},
                {"fil","Filipino"},
                {"nl","Dutch"},
                {"da","Danish"},
                {"el","Greek"},
                {"fi","Finnish"},
                {"sv","Swedish"},
                {"cs","Czech"},
                {"et","Estonian"},
                {"hu","Hungarian"},
                {"lv","Latvian"},
                {"lt","Lithuanian"},
                {"mt","Maltese"},
                {"pl","Polish"},
                {"sk","Slovak"},
                {"sl","Slovene"},
                {"bg","Bulgarian"},
                {"ga","Irish"},
                {"ro","Romanian"},
                {"hr","Croatian"}
            };
            add_language["locale"] = QVariant("en");
            int en_id = languagetable->insertRecord(add_language);
            add_language_name["language"] = QVariant(en_id);
            add_language_name["name"] = QVariant("English");
            add_language_name["nameisinlanguage"] = QVariant(en_id);
            languagenametable->insertRecord(add_language_name);
            QList<QString> language;
            foreach(language, languages){
                add_language["locale"] = QVariant(language.first());
                int language_id = languagetable->insertRecord(add_language);
                add_language_name["language"] = QVariant(language_id);
                add_language_name["name"] = QVariant(language.last());
                add_language_name["nameisinlanguage"] = QVariant(en_id);
                languagenametable->insertRecord(add_language_name);
            }
        }


        databasetable* lexemetable = d("lexeme",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("language",QVariant::Int,{c_fk(languagetable,"id")})});

        databasetable* lexemetranslationtable = d("lexemetranslation",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("lexeme1",QVariant::Int,{c_fk(lexemetable,"id")}),
                fc("lexeme2",QVariant::Int,{c_fk(lexemetable,"id")})});

        databasetable* grammarexpressiontable = d("grammarexpression",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                f("string",QVariant::String)});

        if(database_is_empty){
            QList<QString> grammarexpressions = {
                "Ablative",
                "Accusative",
                "Abessive",
                "Adessive",
                "Allative",
                "Causal-final",
                "Comitative",
                "Dative",
                "Delative",
                "Elative",
                "Essive",
                "External",
                "General",
                "Genitive",
                "Illative",
                "Inessive",
                "Instructive",
                "Instrumental",
                "Internal",
                "Locative",
                "Nominative",
                "Partitive",
                "Plural",
                "Prolative",
                "Singular",
                "Sociative",
                "Sublative",
                "Superessive",
                "Temporal",
                "Terminative",
                "Translative",
                "Vocative",
            };
            QMap<QString,QVariant> add_ge;
            foreach(const QString& grammarexpression, grammarexpressions){
                add_ge["string"] = grammarexpression;
                grammarexpressiontable->insertRecord(add_ge);
            }
        }

        databasetable* grammarformtable = d("grammarform",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")})});
        databasetable* grammarformcomponenttable = d("grammarformcomponent",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("grammarform",QVariant::Int,{c_fk(grammarformtable,"id")}),
                fc("grammarexpression",QVariant::Int,{c_fk(grammarexpressiontable,"id")})});

        databasetable* formtable = d("form",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("lexeme",QVariant::Int,{c_fk(lexemetable,"id")}),
                fc("grammarform",QVariant::Int,{c_fk(grammarformtable,"id")}),
                f("string",QVariant::String)});

        databasetable* compoundformtable = d("compoundform",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("lexeme",QVariant::Int,{c_fk(lexemetable,"id")}),
                fc("grammarform",QVariant::Int,{c_fk(grammarformtable,"id")})});
        databasetable* compoundformparttable = d("compoundformpart",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("compoundform",QVariant::Int,{c_fk(compoundformtable,"id")}),
                f("part",QVariant::Int),
                fc("form",QVariant::Int,{c_fk(formtable,"id")})});

        databasetable* sentencetable = d("sentence",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")})});
        databasetable* punctuationmarktable = d("punctuationmark",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                f("string",QVariant::String)});
        databasetable* sentenceparttable = d("sentencepart",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("sentence",QVariant::Int,{c_fk(sentencetable,"id")}),
                f("part",QVariant::Int),
                f("capialized",QVariant::Bool),
                fc("form",QVariant::Int,{c_fk(formtable,"id")}),
                fc("compoundform",QVariant::Int,{c_fk(compoundformtable,"id")}),
                fc("punctuationmark",QVariant::Int,{c_fk(punctuationmarktable,"id")})});

        databasetable* sentencetranslationtable = d("sentencetranslation",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("sentence1",QVariant::Int,{c_fk(sentencetable,"id")}),
                fc("sentence2",QVariant::Int,{c_fk(sentencetable,"id")})});

        databasetable* programminglanguagetable = d("programminglanguage",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                f("language",QVariant::String)});

        databasetable* trainingmodetable = d("trainingmode",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("programminglanguage",QVariant::Int,{c_fk(programminglanguagetable,"id")}),
                fc("description",QVariant::String,{c_u()}),
                f("frontcardcode",QVariant::String),
                f("backcardcode",QVariant::String)});
        databasetable* trainingdatumtable = d("trainingdatum",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("trainingmode",QVariant::Int,{c_fk(trainingmodetable,"id")}),
                f("timestamp_shown",QVariant::Int),
                f("timestamp_answered",QVariant::Int),
                f("knowledgesteps",QVariant::Int),
                f("knowledge",QVariant::Double)});
        databasetable* trainingaffecteddatatable = d("trainingaffecteddata",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("trainingdatum",QVariant::Int,{c_fk(trainingdatumtable,"id")}),
                fc("lexeme",QVariant::Int,{c_fk(lexemetable,"id")}),
                fc("grammarform",QVariant::Int,{c_fk(grammarformtable,"id")})});

    }
}

databasetable* database::getTableByName(QString name){
    foreach(databasetable* table, tables){
        if(table->name() == name) return table;
    }
    return nullptr;
}

QStringList database::languagenames()
{
    databasetable* languagenametable = getTableByName("languagename");

    QList<QString> selection;
    selection.push_back("name");
    QSqlQuery result = languagenametable->select(selection, qMakePair(QString("nameisinlanguage"),QVariant(1)));

    QStringList languages;
    while(result.next()){
        QString language = result.value("name").toString();
        languages.push_back(language);
    }
    languages.sort();
    return languages;
}

int database::alphabeticidfromlanguagename(QString languagename){
    return languagenames().indexOf(QStringView(languagename));
}

int database::alphabeticidfromlanguageid(int languageid){
    return alphabeticidfromlanguagename(languagenamefromid(languageid));
}

QString database::languagenamefromid(int id){
    databasetable* languagenametable = getTableByName("languagename");
    QList<QString> selection;
    selection.push_back("name");
    QList< QPair< QString, QVariant > > wheres;
    wheres.push_back(qMakePair(QString("nameisinlanguage"),QVariant(1)));
    wheres.push_back(qMakePair(QString("language"),QVariant(id)));
    QSqlQuery result = languagenametable->select(selection, wheres);
    if(!result.next()) throw sql_error::select_empty;
    return result.value("name").toString();

}

int database::idfromlanguagename(QString languagename){
    databasetable* languagenametable = getTableByName("languagename");
    QList<QString> selection;
    selection.push_back("language");
    QList< QPair< QString, QVariant > > wheres;
    wheres.push_back(qMakePair(QString("nameisinlanguage"),QVariant(1)));
    wheres.push_back(qMakePair(QString("name"),QVariant(languagename)));
    QSqlQuery result = languagenametable->select(selection, wheres);
    if(!result.next()) throw sql_error::select_empty;
    return result.value("language").toInt();
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
    QSqlField field(){return m_field;};
    QList<QVariant*> constraints(){return m_constraints;};
    QString sqLiteType();
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

QString databasefield::sqLiteType(void){
    switch(m_field.type()){
        case QVariant::Int:
        case QVariant::Bool:
            return "INTEGER";
        case QVariant::String:
            return "TEXT";
    }
    return "";
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
#include <QSqlQuery>
#include <QDebug>
#include <QMap>
#include <QSqlError>
#include "databasefield.h"
#include "error.h"

class databasetable : public QObject, QSqlRecord
{
    Q_OBJECT
public:
    explicit databasetable(QString name = "", QList<databasefield*> fields = {});
    int insertRecord(const QMap<QString, QVariant>& fields);
    int updateRecord(const QPair<QString, QVariant>& id, const QMap<QString, QVariant>& fields);
    int deleteRecord(const QPair<QString, QVariant>& id);
    QSqlQuery select(const QList<QString>& selection, const QPair<QString, QVariant>& where = qMakePair(QString(),QVariant(0)));
    QSqlQuery select(const QList<QString>& selection, const QList< QPair<QString, QVariant> >& where);
    QString name(){return m_name;};
private:
    QString m_name;
    QSqlDatabase m_vocableDatabase;
    QList<databasefield*> m_fields;
    QString s_databasefield_constraint_not_null;
    QString s_databasefield_constraint_unique;
    QString s_databasefield_constraint_primary_key;
    QString s_databasefield_constraint_foreign_key;
@<End of class and header@>
@}

\subsection{Implementation}
@o ../src/databasetable.cpp -d
@{
#include "databasetable.h"
databasetable::databasetable(QString name, QList<databasefield*> fields) : m_name(name),
    m_fields(fields),
    s_databasefield_constraint_not_null("databasefield_constraint_not_null"),
    s_databasefield_constraint_unique("databasefield_constraint_unique"),
    s_databasefield_constraint_primary_key("databasefield_constraint_primary_key"),
    s_databasefield_constraint_foreign_key("databasefield_constraint_foreign_key")
    {
    m_vocableDatabase = QSqlDatabase::database("vocableDatabase");
    if(!m_vocableDatabase.isValid()){
        qDebug() << "No valid database connection!";
        return;
    }
    QString sqlString = "CREATE TABLE IF NOT EXISTS `" + m_name + "` (";
    QString sqlStringForeignKeys;
    foreach(databasefield* field, m_fields){
      sqlString += "`" + field->field().name() + "` " + field->sqLiteType();
      foreach(QVariant* constraint, field->constraints()){
          QString constraintType = constraint->typeName();
          if(constraintType == s_databasefield_constraint_not_null)
              sqlString += " NOT NULL";
          if(constraintType == s_databasefield_constraint_unique)
              sqlString += " UNIQUE";
          if(constraintType == s_databasefield_constraint_primary_key)
              sqlString += " PRIMARY KEY";
          if(constraintType == s_databasefield_constraint_foreign_key){
              databasefield_constraint_foreign_key fk_constraint =
                  qvariant_cast<databasefield_constraint_foreign_key>(*constraint);
              sqlStringForeignKeys += "FOREIGN KEY ("
                  + field->field().name()
                  + ") REFERENCES "
                  + fk_constraint.foreignKeyTable()->name()
                  + "("
                  + fk_constraint.foreignFieldName()
                  + "), ";
          }
      }
      sqlString += ", ";
    }
    sqlString += sqlStringForeignKeys;
    sqlString.truncate(sqlString.size()-2);
    sqlString += ")";
    QSqlQuery sqlQuery(m_vocableDatabase);
    bool querySuccessful = sqlQuery.exec(sqlString);
}

int databasetable::insertRecord(const QMap<QString, QVariant>& fields){
    QList < QPair < QString, QVariant > > accepted_fields;
    QString sqlString = "INSERT INTO " + m_name + " (";
    QString sqlStringValues = "VALUES (";
    foreach(databasefield* field, m_fields){
        bool skip_column = false;
        QString fieldname = field->field().name();
        if(fields.contains(fieldname)){
            foreach(QVariant* constraint, field->constraints()){
                QString constraintType = constraint->typeName();
                if(constraintType == s_databasefield_constraint_primary_key){
                    skip_column = true;
                    break;
                }
            }
            if(skip_column) continue;
            sqlString += fieldname + ", ";
            sqlStringValues += ":" + fieldname + ", ";
            accepted_fields.push_back(qMakePair(fieldname,fields[fieldname]));
        }
    }
    sqlString.truncate(sqlString.size()-2);
    sqlString += ") ";
    sqlStringValues.truncate(sqlStringValues.size()-2);
    sqlStringValues += ")";
    sqlString += sqlStringValues;

    QSqlQuery sqlQuery(m_vocableDatabase);
    sqlQuery.prepare(sqlString);
    QPair<QString, QVariant> accepted_field;
    foreach(accepted_field, accepted_fields){
        sqlQuery.bindValue(":" + accepted_field.first, accepted_field.second);
    }
    if(!sqlQuery.exec()) throw sql_error::insert_record;
    if(!sqlQuery.exec("select last_insert_rowid();")) throw sql_error::select;
    if(!sqlQuery.first()) throw sql_error::select_empty;
    return sqlQuery.value(0).toInt();
}

int databasetable::updateRecord(const QPair<QString, QVariant>& id, const QMap<QString, QVariant>& fields){
    QList < QPair < QString, QVariant > > accepted_fields;
    QString sqlString = "UPDATE " + m_name + " SET ";
    foreach(databasefield* field, m_fields){
        bool skip_column = false;
        QString fieldname = field->field().name();
        if(fields.contains(fieldname)){
            foreach(QVariant* constraint, field->constraints()){
                QString constraintType = constraint->typeName();
                if(constraintType == s_databasefield_constraint_primary_key){
                    skip_column = true;
                    break;
                }
            }
            if(skip_column) continue;
            sqlString += fieldname + "=:" + fieldname + ", ";
            accepted_fields.push_back(qMakePair(fieldname,fields[fieldname]));
        }
    }
    sqlString.truncate(sqlString.size()-2);
    sqlString += " WHERE " + id.first + "=:" + id.first;

    QSqlQuery sqlQuery(m_vocableDatabase);
    sqlQuery.prepare(sqlString);
    QPair<QString, QVariant> accepted_field;
    foreach(accepted_field, accepted_fields){
        sqlQuery.bindValue(":" + accepted_field.first, accepted_field.second);
    }
    sqlQuery.bindValue(":" + id.first, id.second);
    if(!sqlQuery.exec()){
        QSqlError error = sqlQuery.lastError();
        qDebug() << error.databaseText();
        qDebug() << error.driverText();
        throw sql_error::update_record;
    }
    return id.second.toInt();
}

int databasetable::deleteRecord(const QPair<QString, QVariant>& id){
    QString sqlString = "DELETE FROM " + m_name + " WHERE " + id.first + "=:" + id.first;
    
    QSqlQuery sqlQuery(m_vocableDatabase);
    sqlQuery.prepare(sqlString);
    sqlQuery.bindValue(":" + id.first, id.second);
    if(!sqlQuery.exec()){
        QSqlError error = sqlQuery.lastError();
        qDebug() << error.databaseText();
        qDebug() << error.driverText();
        throw sql_error::delete_record;
    }
    return id.second.toInt();
}

QSqlQuery databasetable::select(const QList<QString>& selection, const QPair<QString, QVariant>& where){
    QString sqlString = "SELECT ";
    foreach(databasefield* field, m_fields){
        QString fieldname = field->field().name();
        if(selection.contains(fieldname)){
            sqlString += fieldname + ", ";
        }
    }
    sqlString.truncate(sqlString.size()-2);
    sqlString += " FROM " + m_name; 
    QSqlQuery sqlQuery(m_vocableDatabase);
    if(!where.first.isEmpty()){
        sqlString += " WHERE " + where.first + "=:" + where.first;
    }
    sqlQuery.prepare(sqlString);
    if(!where.first.isEmpty()){
        sqlQuery.bindValue(":" + where.first, where.second);
    }
    if(!sqlQuery.exec()){
        QSqlError error = sqlQuery.lastError();
        qDebug() << sqlString;
        qDebug() << error.databaseText();
        qDebug() << error.driverText();
        throw sql_error::select;
    }
    return sqlQuery;
}

QSqlQuery databasetable::select(const QList<QString>& selection, const QList< QPair<QString, QVariant> >& wheres){
    QString sqlString = "SELECT ";
    foreach(databasefield* field, m_fields){
        QString fieldname = field->field().name();
        if(selection.contains(fieldname)){
            sqlString += fieldname + ", ";
        }
    }
    sqlString.truncate(sqlString.size()-2);
    sqlString += " FROM " + m_name; 
    QSqlQuery sqlQuery(m_vocableDatabase);
    QPair<QString, QVariant> where;
    foreach(where, wheres){
        if(where == wheres.first()) sqlString += " WHERE";
        sqlString += " " + where.first + "=:" + where.first + " AND";
    }
    sqlString.truncate(sqlString.size()-4);
    sqlQuery.prepare(sqlString);
    foreach(where, wheres){
        sqlQuery.bindValue(":" + where.first, where.second);
    }
    if(!sqlQuery.exec()){
        QSqlError error = sqlQuery.lastError();
        qDebug() << sqlString;
        qDebug() << error.databaseText();
        qDebug() << error.driverText();
        throw sql_error::select;
    }
    return sqlQuery;

}

@}
