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

\subsection{grammarconfiguration}
@o ../src/grammarconfiguration.cpp -d
@{
#include "grammarconfiguration.h"

grammarconfiguration::grammarconfiguration(QString s_fileName, database* lp_database) :
    p_database(lp_database), b_valid(false)
{
    QString s_gpFilePath;
#ifdef Q_OS_ANDROID
    s_gpFilePath = QStandardPaths::standardLocations(QStandardPaths::AppDataLocation).at(1) + "/grammarprovider";
#else
    s_gpFilePath = QStandardPaths::standardLocations(QStandardPaths::HomeLocation).at(0) + "/.coleitra/grammarprovider";
#endif

    {
        if(!QDir(s_gpFilePath).exists()){
            QDir().mkdir(s_gpFilePath);
        }
    }

#ifdef Q_OS_ANDROID
    // In case of android copy over files from assets to directory:
    QDirIterator it_assetFiles("assets:/grammarprovider",QDirIterator::Subdirectories);
    while(it_assetFiles.hasNext()){
        QFile f_currentFile(it_assetFiles.next());
        QFileInfo fi_currentFile(f_currentFile);
        if(!fi_currentFile.filePath().isEmpty()){
            QString s_relativePath = fi_currentFile.filePath().remove("assets:/grammarprovider");
            QString s_gpDFilePath = s_gpFilePath + "/" + s_relativePath;
            if(fi_currentFile.isDir()){
                if(!QDir(s_gpDFilePath).exists()){
                    QDir().mkdir(s_gpDFilePath);
                }
            }
            else{
                if(!QFile(s_gpDFilePath).exists()){
                    f_currentFile.copy(s_gpDFilePath);
                }
                else{
                    s_gpDFilePath = s_gpFilePath + "/" + fi_currentFile.dir().path().remove("assets:/grammarprovider") + "/" + fi_currentFile.baseName() + ".coleitra." + QString::fromStdString(TOSTRING(COLEITRA_VERSION)) + "." + fi_currentFile.completeSuffix();
                    if(!QFile(s_gpDFilePath).exists()){
                        f_currentFile.copy(s_gpDFilePath);
                    }
                }
            }
        }
    }
#endif

    json j_grammarProviderSchema;

    QFile f_grammarProviderSchema(s_gpFilePath + "/schemas/main.json");
    if(f_grammarProviderSchema.open(QIODevice::ReadOnly)) {
        try {
            j_grammarProviderSchema = json::parse(f_grammarProviderSchema.readAll().toStdString());
        }
        catch (const std::exception &e) {
            qDebug() << "grammarconfiguration: Parsing the root schema failed, here is why: " << e.what();
            return;
        }
        f_grammarProviderSchema.close();
    }

    json j_ini;
    QFile f_language(s_fileName);

    if(f_language.open(QIODevice::ReadOnly)) {
        j_ini = json::parse(f_language.readAll().toStdString());
        f_language.close();
    }

    json_validator validator;
    try {
        validator.set_root_schema(j_grammarProviderSchema);
    }
    catch (const std::exception &e) {
        qDebug() << "grammarconfiguration: Setting the root schema failed, here is why: " << e.what();
        qDebug() << QString::fromStdString(j_grammarProviderSchema.dump());
        return;
    }
    catch (...){
        qDebug() << "grammarconfiguration: Setting the root schema failed.";
    }

    try {
        validator.validate(j_ini);
    }
    catch (const std::exception &e) {
        qDebug() << "grammarconfiguration: Validation failed, here is why: " << e.what();
        return;
    }
    catch (...) {
        qDebug() << "grammarconfiguration: Validation failed.";
        return;
    }
    s_version = QString::fromStdString(j_ini["version"]);
    s_base_url = QString::fromStdString(j_ini["base_url"]);
    if(j_ini.contains("language") && j_ini["language"].is_string())
        i_language_id = p_database->idfromlanguagename(QString::fromStdString(j_ini["language"]));
    // Fill inflection tables if they are given:
    if(j_ini.contains("inflectiontables") && j_ini["inflectiontables"].is_array()){
        for(auto& j_inflectiontable: j_ini["inflectiontables"]){
            t_grammarConfigurationInflectionTable t_inflectiontable(j_inflectiontable,p_database,i_language_id);
            l_inflection_tables.push_back(t_inflectiontable);
        }
    }
    if(j_ini.contains("default_lexemes") && j_ini["default_lexemes"].is_array())
        for(const auto& j_lexeme: j_ini["default_lexemes"])
            if(j_lexeme.contains("forms") && j_lexeme["forms"].is_array()){
                QList<t_formAndGrammarId> lexeme_forms;
                for(const auto& j_form: j_lexeme["forms"])
                    lexeme_forms.push_back(t_formAndGrammarId(j_form,p_database,i_language_id));
                l_default_lexemes.push_back(lexeme_forms);
            }
    if(j_ini.contains("lookup_forms") && j_ini["lookup_forms"].is_array())
        for(const auto& j_form: j_ini["lookup_forms"])
            l_lookup_forms.push_back(t_formAndGrammarId(j_form,p_database,i_language_id));
    qDebug() << "Summary:" << l_inflection_tables.size() << "inflection tables" << l_default_lexemes.size() << "default lexemes and" << l_lookup_forms.size() << "lookup forms";
    b_valid = true;
}
@}

@o ../src/grammarconfiguration.cpp -d
@{
grammarconfiguration::t_formAndGrammarId::t_formAndGrammarId(json j_form, database* p_database, int i_language_id){
    if(j_form.contains("content") && j_form["content"].is_string())
        s_form = QString::fromStdString(j_form["content"]);
    i_grammarid = getGrammarIdFromJson(j_form,p_database,i_language_id);
}
@}

@o ../src/grammarconfiguration.cpp -d
@{

grammarconfiguration::grammarconfiguration(int li_language_id, QString ls_base_url, database* lp_database) :
    i_language_id(li_language_id),
    s_version("0.1"),
    s_base_url(ls_base_url),
    p_database(lp_database)
{
}
@}

\subsection{getGrammarIdFromJson}
@o ../src/grammarconfiguration.cpp -d
@{
int grammarconfiguration::getGrammarIdFromJson(json j_input, database* p_database, int i_language_id){
    if(j_input.contains("grammarexpressions") 
            && j_input["grammarexpressions"].is_object()
            && j_input["grammarexpressions"].contains("format")
            && j_input["grammarexpressions"]["format"].is_string()
            && j_input["grammarexpressions"].contains("version")
            && j_input["grammarexpressions"]["version"].is_string()
            && j_input["grammarexpressions"].contains("tags")
            && j_input["grammarexpressions"]["tags"].is_object()){
        QString s_format = QString::fromStdString(j_input["grammarexpressions"]["format"]);
        QString s_version = QString::fromStdString(j_input["grammarexpressions"]["version"]);
        QList<QList<QString> > lls_grammarform;
        for(auto& [j_key, j_value] : j_input["grammarexpressions"]["tags"].items())
            if(j_value.is_string())
                lls_grammarform.push_back({QString::fromStdString(j_key),QString::fromStdString(j_value)});
        return p_database->grammarFormIdFromStrings(i_language_id,lls_grammarform);
    }
    return -1;
}
@}

\subsection{t\_grammarConfigurationInflectionTableCell}
@o ../src/grammarconfiguration.cpp -d
@{
grammarconfiguration::t_grammarConfigurationInflectionTableForm::t_grammarConfigurationInflectionTableForm(json j_ini, database* lp_database, int li_language_id) :
    p_database(lp_database),
    i_language_id(li_language_id)
{
    // "index", "content_type" and "process" are optional
    if(j_ini.contains("index") && j_ini["index"].is_number()){
        i_index = j_ini["index"];
    }
    i_grammarid = getGrammarIdFromJson(j_ini, p_database, i_language_id);
    if(j_ini.contains("index") && j_ini["index"].is_object()){
        if(j_ini["index"].contains("row") && j_ini["index"]["row"].is_number())
            t_source.i_row = j_ini["index"]["row"];
        if(j_ini["index"].contains("column") && j_ini["index"]["column"].is_number())
            t_source.i_column = j_ini["index"]["column"];
        if(j_ini["index"].contains("xquery") && j_ini["index"]["xquery"].is_string())
            t_source.s_xquery = QString::fromStdString(j_ini["index"]["xquery"]);
    }
    if(j_ini.contains("content_type") && j_ini["content_type"].is_string()){
        QMap<QString, e_cellContentType> m_cellContentType = {
            {"FORM",e_cellContentType::FORM},
            {"FORM_WITH_IGNORED_PARTS",e_cellContentType::FORM_WITH_IGNORED_PARTS},
            {"COMPOUNDFORM",e_cellContentType::COMPOUNDFORM},
            {"SENTENCE",e_cellContentType::SENTENCE}
        };
        e_content_type = m_cellContentType[QString::fromStdString(j_ini["content_type"])];
    }
    if(j_ini.contains("process") && j_ini["process"].is_array()){
        for(auto& j_process: j_ini["process"]){
            if(j_process.is_object()){
                t_instruction t_currentInstruction;
                if(j_process.contains("instruction") && j_process["instruction"].is_string()){
                    QMap<QString, e_instructionType> m_instructionType = {
                        {"IGNOREFORM",e_instructionType::IGNOREFORM},
                        {"LOOKUPFORM",e_instructionType::LOOKUPFORM},
                        {"LOOKUPFORM_LEXEME",e_instructionType::LOOKUPFORM_LEXEME},
                        {"ADDANDUSEFORM",e_instructionType::ADDANDUSEFORM},
                        {"ADDANDIGNOREFORM",e_instructionType::ADDANDIGNOREFORM}
                    };
                    t_currentInstruction.e_instruction = m_instructionType[QString::fromStdString(j_process["instruction"])];
                }
                t_currentInstruction.i_grammarid = getGrammarIdFromJson(j_process, p_database, i_language_id);
                t_instructions.push_back(t_currentInstruction);
            }
        }
    }
}

@}

\subsection{t\_grammarConfigurationInflectionTable}
@o ../src/grammarconfiguration.cpp -d
@{
grammarconfiguration::t_grammarConfigurationInflectionTable::t_grammarConfigurationInflectionTable(json j_ini, database* lp_database, int li_language_id) :
    s_tablename(QString::fromStdString(j_ini["tablename"])),
    p_database(lp_database),
    i_language_id(li_language_id)
{
    // We don't strictly need to check for existance here but do it anyway for robustness:
    if(j_ini.contains("identifiers") && j_ini["identifiers"].is_array()){
        for(auto& j_identifier: j_ini["identifiers"]){
            if(j_identifier.is_string()){
                QString s_identifier = QString::fromStdString(j_identifier);
                l_identifiers.push_back(s_identifier);
            }
        }
    }
    // We don't strictly need to check for existance here but do it anyway for robustness:
    if(j_ini.contains("forms") && j_ini["forms"].is_array()){
        for(auto& j_form: j_ini["forms"]){
            t_grammarConfigurationInflectionTableForm t_form(j_form,p_database,i_language_id);
            l_grammar_forms.push_back(t_form);
        }
    }
}
@}

@o ../src/grammarconfiguration.cpp -d
@{
grammarconfiguration::t_grammarConfigurationInflectionTable::t_grammarConfigurationInflectionTable(int li_language_id, QString ls_tablename, QVector<QString> ll_identifiers, database* lp_database) :
    i_language_id(li_language_id),
    s_tablename(ls_tablename),
    l_identifiers(ll_identifiers),
    p_database(lp_database)
{
}
@}

\subsection{newInflectionTable}
@o ../src/grammarconfiguration.cpp -d
@{
void grammarconfiguration::newInflectionTable(int i_language_id, QString s_tablename, QVector<QString> l_identifiers){
    t_grammarConfigurationInflectionTable newTable(i_language_id, s_tablename, l_identifiers, p_database);
    l_inflection_tables.push_back(newTable);
}
@}

\subsection{tableHasIdentifier}
@o ../src/grammarconfiguration.cpp -d
@{
bool grammarconfiguration::tableHasIdentifier(QString s_tablename, QString s_identifier){
    return tableIdentifiers(s_tablename).contains(s_identifier);
}
@}

\subsection{tableIdentifiers}
@o ../src/grammarconfiguration.cpp -d
@{
QVector<QString> grammarconfiguration::tableIdentifiers(QString s_tablename){
    int id = tableId(s_tablename); 
    if(id>-1)
        return l_inflection_tables.at(id).l_identifiers;
    else
        return {};
}
@}

\subsection{toJson}
@o ../src/grammarconfiguration.cpp -d
@{
json grammarconfiguration::toJson(void){
    json j_gc;
    j_gc["language"] = p_database->languagenamefromid(i_language_id).toStdString();
    j_gc["version"] = s_version.toStdString();
    j_gc["base_url"] = s_base_url.toStdString();
    for(const auto& l_inflection_table: l_inflection_tables){
        json j_inflectiontable;
        j_inflectiontable["tablename"] = l_inflection_table.s_tablename.toStdString();
        for(const auto& l_identifier: l_inflection_table.l_identifiers)
            j_inflectiontable["identifiers"] += l_identifier.toStdString();
        for(const auto& l_grammar_form: l_inflection_table.l_grammar_forms){
            json j_grammar_form;
            j_grammar_form["index"] = l_grammar_form.i_index;
            json j_source;
            if(l_grammar_form.t_source.i_row>-1)
                j_source["row"] = l_grammar_form.t_source.i_row;
            if(l_grammar_form.t_source.i_column>-1)
                j_source["column"] = l_grammar_form.t_source.i_column;
            if(!l_grammar_form.t_source.s_xquery.isEmpty())
                j_source["xquery"] = l_grammar_form.t_source.s_xquery.toStdString();
            j_grammar_form["source"] = j_source;
            {
                json j_grammarexpressions;
                j_grammarexpressions["format"] = "coleitra";
                j_grammarexpressions["version"] = "0.1";
                json j_grammarexpressions_tags;
                QVector<QPair<QString,QString> > grammar_tags = p_database->getGrammarStringPairsFromGrammarFormId(l_grammar_form.i_grammarid);
                for(const auto& grammar_tag: grammar_tags){
                    j_grammarexpressions_tags[grammar_tag.first.toStdString()] = grammar_tag.second.toStdString();
                }
                j_grammarexpressions["tags"] = j_grammarexpressions_tags;
                j_grammar_form["grammarexpressions"] = j_grammarexpressions;
            }
            QMap<e_cellContentType,QString> m_cellContentType = {
                {e_cellContentType::FORM,"FORM"},
                {e_cellContentType::FORM_WITH_IGNORED_PARTS,"FORM_WITH_IGNORED_PARTS"},
                {e_cellContentType::COMPOUNDFORM,"COMPOUNDFORM"},
                {e_cellContentType::SENTENCE,"SENTENCE"}
            };
            j_grammar_form["content_type"] = m_cellContentType[l_grammar_form.e_content_type].toStdString();
            QMap<e_instructionType,QString> m_instructionType = {
                {e_instructionType::IGNOREFORM,"IGNOREFORM"},
                {e_instructionType::LOOKUPFORM,"LOOKUPFORM"},
                {e_instructionType::LOOKUPFORM_LEXEME,"LOOKUPFORM_LEXEME"},
                {e_instructionType::ADDANDUSEFORM,"ADDANDUSEFORM"},
                {e_instructionType::ADDANDIGNOREFORM,"ADDANDIGNOREFORM"}
            };
            for(const auto& lt_instruction: l_grammar_form.t_instructions){
                json j_instruction;
                j_instruction["instruction"] = m_instructionType[lt_instruction.e_instruction].toStdString();
                json j_grammarexpressions;
                j_grammarexpressions["format"] = "coleitra";
                j_grammarexpressions["version"] = "0.1";
                json j_grammarexpressions_tags;
                QVector<QPair<QString,QString> > grammar_tags = p_database->getGrammarStringPairsFromGrammarFormId(lt_instruction.i_grammarid);
                for(const auto& grammar_tag: grammar_tags){
                    j_grammarexpressions_tags[grammar_tag.first.toStdString()] = grammar_tag.second.toStdString();
                }
                j_grammarexpressions["tags"] = j_grammarexpressions_tags;
                j_instruction["grammarexpressions"] = j_grammarexpressions;
                j_inflectiontable["process"] += j_instruction;
            }
            j_inflectiontable["forms"] += j_grammar_form;
        }
        j_gc["inflectiontables"] += j_inflectiontable;
    }
    return j_gc;
}
@}


\subsection{tableId}
@o ../src/grammarconfiguration.cpp -d
@{
int grammarconfiguration::tableId(QString s_tablename){
    int id=-1;
    for(const auto& inflectionTable: l_inflection_tables){
        id++;
        if(inflectionTable.s_tablename == s_tablename) break;
    }
    return id;
}
@}

