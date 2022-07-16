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

\section{Interface}
@o ../src/grammarconfiguration.h -d
@{
@<Start of @'GRAMMARCONFIGURATION@' header@>

#include <nlohmann/json-schema.hpp>
#include "database.h"

using nlohmann::json;
using nlohmann::json_schema::json_validator;

@<Start of class @'grammarconfiguration@'@>
public:
    // "version" and "base_url" required by schema:
    grammarconfiguration(QString s_fileName, database* lp_database);
    grammarconfiguration(int li_language_id, QString ls_base_url, database* lp_database); 
    enum class e_cellContentType {
        FORM,
        FORM_WITH_IGNORED_PARTS,
        COMPOUNDFORM,
        SENTENCE
    };
    enum class e_instructionType {
        IGNOREFORM,
        LOOKUPFORM,
        LOOKUPFORM_LEXEME,
        ADDANDUSEFORM,
        ADDANDIGNOREFORM
    };
    struct t_cellSource {
        t_cellSource() : i_row(-1), i_column(-1), s_xquery(){};
        int i_row;
        int i_column;
        QString s_xquery;
    };
    struct t_instruction {
        e_instructionType e_instruction;
        int i_grammarid;
    };
    struct t_grammarConfigurationInflectionTableForm {
        // "row", "column" and "grammarexpressions" required by schema
        t_grammarConfigurationInflectionTableForm(json j_ini, database* lp_database, int li_language_id);
        database* p_database;
        int i_language_id;
        int i_index;
        int i_grammarid;
        t_cellSource t_source;
        e_cellContentType e_content_type;
        QVector<t_instruction> t_instructions;
    };
    struct t_grammarConfigurationInflectionTable {
        // "tablename", "identifiers" and "cells" required by schema:
        t_grammarConfigurationInflectionTable(json j_ini, database* lp_database, int li_language_id);
        t_grammarConfigurationInflectionTable(int i_language_id, QString s_tablename, QVector<QString> l_identifiers, database* lp_database);
        database* p_database;
        int i_language_id;
        QString s_tablename;
        QVector<QString> l_identifiers;
        QVector<t_grammarConfigurationInflectionTableForm> l_grammar_forms;
    };
    void newInflectionTable(int i_language_id, QString s_tablename, QVector<QString> l_identifiers);
    bool tableHasIdentifier(QString s_tablename, QString s_identifier);
    QVector<QString> tableIdentifiers(QString s_tablename);
    json toJson(void);
private:
    int tableId(QString s_tablename);
    int i_language_id;
    QString s_version;
    QString s_base_url;
    QList<t_grammarConfigurationInflectionTable> l_inflection_tables;
    database* p_database;

@<End of class and header @>
@}

@o ../src/grammarprovider.h -d
@{
@<Start of @'GRAMMARPROVIDER@' header@>
#include <sstream>
#include <iostream>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QFile>
#include <QQmlEngine>
#include <QMap>
#include <QMapIterator>
#include <QTextDocument>
#include <QThread>
#include <QEventLoop>
#include <QTime>
#include <QMetaMethod>
#include <QDirIterator>
#include <QAbstractTableModel>
#include <nlohmann/json-schema.hpp>
#include "settings.h"
#include "database.h"
#include "levenshteindistance.h"
#include "networkscheduler.h"
#include "grammarconfiguration.h"

#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)

using nlohmann::json;
using nlohmann::json_schema::json_validator;



@<Start of class @'grammarprovider@'@>
    Q_PROPERTY(int language MEMBER m_language)
    Q_PROPERTY(QString word MEMBER m_word)
public:
    explicit grammarprovider(QObject *parent = nullptr);
    ~grammarprovider(void);
    @<Id property @'lexeme@'@>
    @<Id property @'form@'@>
// Another public needed as Id property messes with public and private:
public:
    struct tablecell {
        int row;
        int column;
        QString content;
    };
    enum lexemePartType {
        FORM,
        FORM_WITH_IGNORED_PARTS,
        COMPOUNDFORM,
        SENTENCE,
    };
    enum lexemePartProcessInstruction {
        IGNOREFORM,
        LOOKUPFORM,
        LOOKUPFORM_LEXEME, // Match lexeme to current lexeme when looking up form
        ADDANDUSEFORM,
        ADDANDIGNOREFORM,
    };
    struct lexemePartProcess {
        lexemePartProcess(lexemePartProcessInstruction y_instruction):
            instruction(y_instruction),
            grammarexpressions({}){
            }
        lexemePartProcess(lexemePartProcessInstruction y_instruction,
                QList<QList<QString> > y_grammarexpressions):
            instruction(y_instruction),
            grammarexpressions(y_grammarexpressions){
            }
        lexemePartProcessInstruction instruction;
        QList<QList<QString> > grammarexpressions;
    };
    struct compoundPart {
        int id;
        bool capitalized;
        QString string;
    };
    struct grammarform {
        grammarform(){
        }
        grammarform(int y_index,
                int y_row,
                int y_column,
                QList<QList<QString> > y_grammarexpressions): 
            index(y_index), 
            row(y_row),
            column(y_column),
            grammarexpressions(y_grammarexpressions),
            type(FORM),
            processList({}),
            string(""){
            }
	grammarform(int y_index,
                int y_row,
                int y_column,
                QList<QList<QString> > y_grammarexpressions,
		lexemePartType y_type,
		QList<lexemePartProcess> y_processList): 
            index(y_index), 
            row(y_row),
            column(y_column),
            grammarexpressions(y_grammarexpressions),
            type(y_type),
            processList(y_processList),
            string(""){
            }
        int id;
        int index;
        int row;
        int column;
        QString string;
        QList<QList<QString> > grammarexpressions;
        lexemePartType type;
        QList<lexemePartProcess> processList;
        QList<compoundPart> compounds;
        int lexeme_id; // used internal in grammarprovider class only
        int language_id;
        bool b_silent;
    };
    struct templatearguments {
        QMap<QString, QString> named;
        QList<QString> unnamed;
    };
    struct scheduled_lookup {
        QObject* m_caller;
        int m_languageid;
        QString m_word;
    };
    

    enum class e_wiktionaryRequestPurpose {
        FLECTION,
        ETYMOLOGY
    };
public slots:
    Q_INVOKABLE void getGrammarInfoForWord(QObject* caller, int languageid, QString word);
    Q_INVOKABLE void getNextGrammarObject(QObject* caller);
    Q_INVOKABLE void getNextSentencePart(QObject* caller);
    Q_INVOKABLE void getNextPossibleTemplate(QObject* caller);
private slots:
    QList<grammarprovider::compoundPart> getGrammarCompoundFormParts(QString compoundword, QList<QString> compoundstrings, int id_language);
    void getWiktionarySections(QObject *caller);
    void getWiktionarySection(QString reply, QObject* caller);
    void getWiktionaryTemplate(QString reply, QObject* caller, e_wiktionaryRequestPurpose purpose);
    templatearguments parseTemplateArguments(QString templateString);
    void parseMediawikiTableToPlainText(QString wikitext, QList<grammarprovider::tablecell>& table);
    void parse_compoundform(QString reply, QObject* caller);
    QList<QPair<QString,int> > fi_compound_parser(QObject* caller, int fi_id, int lexeme_id, QList<int> compound_lexemes);
    void fi_requirements(QObject* caller, int fi_id);
    void parse_fi_verbs(QString reply, QObject* caller);
    void parse_fi_nominals(QString reply, QObject* caller);
    void de_requirements(QObject* caller, int de_id);
    void parse_de_noun_n(QString reply, QObject* caller);
    void parse_de_noun_m(QString reply, QObject* caller);
    void parse_de_noun_f(QString reply, QObject* caller);
    void parse_de_verb(QString reply, QObject* caller);
    void process_grammar(QObject* caller, QList<grammarform> grammarforms, QList<tablecell> parsedTable, QList<QList<QString> > additional_grammarforms = {});
    void getPlainTextTableFromReply(QString reply, QList<grammarprovider::tablecell>& parsedTable);
    void processNetworkError(QObject* caller, QString s_failure_reason);
signals:
    //void processingStart(const QString& waitingstring);
    //void processingStop(void);
    void processingUpdate(const QString& waitingstring);
    void networkError(QObject* caller, bool silent, QString s_failure_reason);

    void grammarInfoAvailable(QObject* caller, int numberOfObjects, bool silent);
    void grammarInfoNotAvailable(QObject* caller, bool silent);
    void possibleTemplateAvailable(QObject* caller, int numberOfObjects, bool silent);
    void possibleTemplateFinished(QObject* caller);
    void possibleTemplate(QObject* caller, bool silent, grammarprovider::templatearguments arguments, QObject* tableView);
    void etymologyInfoNotAvailable(QObject* caller, bool silent);
    void gotGrammarInfoForWord(QObject* caller, int numberOfObjects, bool silent);
    void noGrammarInfoForWord(QObject* caller, bool silent);
    void formObtained(QObject* caller, bool silent, grammarform form);
    void compoundFormObtained(QObject* caller, QString form, bool silent);
    void sentenceAvailable(QObject* caller, int parts, bool silent);
    void sentenceLookupForm(QObject* caller, QString form, QList<QList<QString> > grammarexpressions, bool silent);
    void sentenceLookupFormLexeme(QObject* caller, QString form, QList<QList<QString> > grammarexpressions, bool silent);
    void sentenceAddAndUseForm(QObject* caller, QString form, QList<QList<QString> > grammarexpressions, bool silent);
    void sentenceAddAndIgnoreForm(QObject* caller, QString form, QList<QList<QString> > grammarexpressions, bool silent);
    void sentenceComplete(QObject* caller, QList<QList<QString> > grammarexpressions, bool silent);
    
    void processedGrammar(QObject* caller, bool silent);
    void grammarInfoComplete(QObject* caller, bool silent);
    //void grammarobtained(QObject* caller, QStringList expressions, QList<QList<QList<QString> > > grammarexpressions);
public:
private:
    json j_grammarProviderSchema;
    QString s_gpFilePath;
    int m_language;
    bool m_silent;
    bool m_busy;
    bool m_found_compoundform;
    QList<QString> m_current_compoundforms;
    QString ms_current_section;
    QMap<QString, void (grammarprovider::*)(QString, QObject*)> m_parser_map; 
    QString m_word;
    QString s_baseurl;
    QNetworkAccessManager* m_manager;
    QList<QString> m_parsesections;
    settings* m_settings;
    database* m_database;
    levenshteindistance* m_levenshteindistance;
    networkscheduler* m_networkscheduler;
    templatearguments m_currentarguments;
    QList<grammarform> m_grammarforms;
    QList<grammarform> mi_grammarforms;
    QList<grammarconfiguration> m_grammarConfigurations;
    QList<scheduled_lookup> m_scheduled_lookups;
    QMap<int, void (grammarprovider::*)(QObject*,int)> m_requirements_map;
    QMap<int, QList<QPair<QString,int> > (grammarprovider::*)(QObject* caller, int id, int lexeme_id, QList<int> compound_lexemes)> m_compound_parser_map;
    struct context {
        grammarprovider* l_parent;
        int l_language;
        bool l_silent;
        bool l_busy;
        bool l_found_compoundform;
        QString l_word;
        QMetaObject::Connection l_tmp_connection;
        QMetaObject::Connection l_tmp_error_connection;
        QObject* l_caller;
        templatearguments l_currentarguments;
        QList<QString> l_current_compoundforms;
        context(grammarprovider* parent) :
            l_parent(parent),
            l_language(parent->m_language),
            l_silent(parent->m_silent),
            l_busy(parent->m_busy),
            l_word(parent->m_word),
            l_found_compoundform(parent->m_found_compoundform),
            l_currentarguments(parent->m_currentarguments),
            l_current_compoundforms(parent->m_current_compoundforms){
            }
        ~context(){
            l_parent->m_language = l_language;
            l_parent->m_silent = l_silent;
            l_parent->m_busy = l_busy;
            l_parent->m_word = l_word;
            l_parent->m_found_compoundform = l_found_compoundform;
            l_parent->m_currentarguments = l_currentarguments;
            l_parent->m_current_compoundforms = l_current_compoundforms;
        }
    };
    QStringList ms_possibleTemplates;
    void processUnknownTemplate(QString s_reply, QObject* caller, grammarprovider::templatearguments arguments);
};

class grammarTableView : public QAbstractTableModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_ADDED_IN_MINOR_VERSION(1)
private:
    int maxRows;
    int maxColumns;
    QStringList** tableContent;
    QVector<QVector<QString> >** grammarContent;
public:
    grammarTableView(const QList<grammarprovider::tablecell> &parsedTable, QObject *parent = nullptr) : QAbstractTableModel(parent){
        maxRows = 0;
        maxColumns = 0;
        for(auto & tableCell: parsedTable){
            if(tableCell.row+1>maxRows) maxRows = tableCell.row+1;
            if(tableCell.column+1>maxColumns) maxColumns = tableCell.column+1;
        }
        tableContent = new QStringList*[maxRows];
        grammarContent = new QVector<QVector<QString> >*[maxRows];
        for(int i = 0; i < maxRows; ++i){
            tableContent[i] = new QStringList[maxColumns];
            grammarContent[i] = new QVector<QVector<QString> >[maxColumns];
        }
        for(auto & tableCell: parsedTable){
            //qDebug() << "Cellcontent[" << tableCell.row << "][" << tableCell.column << "]:" << tableCell.content;
            tableContent[tableCell.row][tableCell.column].push_back(tableCell.content);
        }
        //qDebug() << "Got" << parsedTable.length() << "cells in constructor of grammarTableView (" << maxColumns << "x" << maxRows << ")";
    }

    int rowCount(const QModelIndex & = QModelIndex()) const override
    {
        return maxRows;
    }

    int columnCount(const QModelIndex & = QModelIndex()) const override
    {
        return maxColumns;
    }

    QVariant data(const QModelIndex &index, int role) const override
    {
        //qDebug() << "Ask for data for column" << index.column() << "and row" << index.row() << "(max" << maxRows << ")role" << role;
        if((index.row() < maxRows) && (role < maxColumns))
            return tableContent[index.row()][role];
        else
            return QStringList();
    }

    Q_INVOKABLE QVector<QVector<QString> > grammar(const QModelIndex &index, int role){
        return grammarContent[index.row()][role];
    }

    Q_INVOKABLE void setGrammar(const QModelIndex &index, int role, QVector<QVector<QString> > grammarForms){
        grammarContent[index.row()][role] = grammarForms;
    }

    QHash<int, QByteArray> roleNames() const override
    {
        QHash<int,QByteArray> l_roleNames;
        for(int i=0; i<maxColumns+1; i++)
            l_roleNames[i] = (QString("col") + QString::number(i)).toUtf8();
        return l_roleNames;
    }

@<End of class and header @>
@}

