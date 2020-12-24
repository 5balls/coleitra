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
#include <QJsonArray>
#include <QFile>
#include <QQmlEngine>
#include <QMap>
#include <QMapIterator>
#include <QTextDocument>
#include <QThread>
#include "settings.h"
#include "database.h"
@<Start of class @'grammarprovider@'@>
    Q_PROPERTY(int language MEMBER m_language)
    Q_PROPERTY(QString word MEMBER m_word)
public:
    explicit grammarprovider(QObject *parent = nullptr);
    ~grammarprovider(void);
    struct tablecell {
        int row;
        int column;
        QString content;
    };
    enum lexemePartType {
        FORM,
        COMPOUNDFORM,
        SENTENCE,
    };
    enum lexemePartProcessInstruction {
        NOPROCESSING,
        SPLIT,
        LOOKUPFORM,
        LOOKUPFORM_LEXEME, // Match lexeme to current lexeme when looking up form
        ADDANDUSEFORM,
        IGNOREFORM,
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
    struct grammarform {
        grammarform(int y_index,
                int y_row,
                int y_column,
                QList<QList<QString> > y_grammarexpressions): 
            index(y_index), 
            row(y_row),
            column(y_column),
            grammarexpressions(y_grammarexpressions),
            type(FORM),
            processList({}){
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
            processList(y_processList){
            }

        int index;
        int row;
        int column;
        QList<QList<QString> > grammarexpressions;
        lexemePartType type;
        QList<lexemePartProcess> processList;
    };
    struct templatearguments {
        QMap<QString, QString> named;
        QList<QString> unnamed;
    };
public slots:
    Q_INVOKABLE void getWiktionarySections(QObject* caller);
    void getWiktionarySection(QNetworkReply* reply);
    void getWiktionaryTemplate(QNetworkReply* reply);
    void networkReplyErrorOccurred(QNetworkReply::NetworkError code);
    templatearguments parseTemplateArguments(QString templateString);
    void parseMediawikiTableToPlainText(QString wikitext, QList<grammarprovider::tablecell>& table);
    void parse_fi_verbs(QNetworkReply* reply);
    void parse_fi_nominals(QNetworkReply* reply);
    void parse_de_noun_n(QNetworkReply* reply);
    void parse_de_noun_m(QNetworkReply* reply);
    void parse_de_noun_f(QNetworkReply* reply);
    void parse_de_verb(QNetworkReply* reply);
    void process_grammar(QList<grammarform> grammarforms, QList<tablecell> parsedTable, QList<QList<QString> > additional_grammarforms = {});
    void getPlainTextTableFromReply(QNetworkReply* reply, QList<grammarprovider::tablecell>& parsedTable);
signals:
    void grammarobtained(QObject* caller, QStringList expressions, QList<QList<QList<QString> > > grammarexpressions);
private:
    int m_language;
    QString m_word;
    QString s_baseurl;
    QNetworkAccessManager* m_manager;
    QMetaObject::Connection m_tmp_connection;
    QList<QString> m_parsesections;
    settings* m_settings;
    database* m_database;
    QObject* m_caller;
    templatearguments m_currentarguments;
    QMap<QString, void (grammarprovider::*)(QNetworkReply*)> m_parser_map; 
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
    QQmlEngine* engine = qobject_cast<QQmlEngine*>(parent);
    m_settings = engine->singletonInstance<settings*>(qmlTypeId("SettingsLib", 1, 0, "Settings"));
    m_database = engine->singletonInstance<database*>(qmlTypeId("DatabaseLib", 1, 0, "Database"));
    m_parsesections.push_back("Conjugation");
    m_parsesections.push_back("Declension");
    m_parser_map["fi-conj-sanoa"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-muistaa"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-huutaa"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-soutaa"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-kaivaa"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-saartaa"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-laskea"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-tuntea"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-lähteä"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-sallia"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-voida"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-saada"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-juoda"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-käydä"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-rohkaista"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-tulla"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-tupakoida"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-valita"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-juosta"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-nähdä"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-vanheta"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-salata"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-katketa"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-selvitä"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-conj-taitaa"] = &grammarprovider::parse_fi_verbs;
    m_parser_map["fi-decl-valo"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-palvelu"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-valtio"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-laatikko"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-risti"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-paperi"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-ovi"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-nalle"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-kala"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-koira"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-omena"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-kulkija"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-katiska"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-solakka"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-korkea"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-vanhempi"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-vapaa"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-maa"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-suo"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-filee"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-rosé"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-parfait"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-tiili"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-uni"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-toimi"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-pieni"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-käsi"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-kynsi"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-lapsi"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-veitsi"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-kaksi"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-sisar"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-kytkin"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-onneton"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-lämmin"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-sisin"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-vasen"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-nainen"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-vastaus"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-kalleus"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-vieras"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-mies"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-ohut"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-kevät"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-kahdeksas"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-tuhat"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-kuollut"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["fi-decl-hame"] = &grammarprovider::parse_fi_nominals;
    m_parser_map["de-decl-noun-n"] = &grammarprovider::parse_de_noun_n;
    m_parser_map["de-decl-noun-m"] = &grammarprovider::parse_de_noun_m;
    m_parser_map["de-decl-noun-f"] = &grammarprovider::parse_de_noun_f;
    m_parser_map["de-conj-strong"] = &grammarprovider::parse_de_verb;
}

grammarprovider::~grammarprovider() {
    delete m_manager;
}

void grammarprovider::getWiktionarySections(QObject* caller){
    qDebug() << "getWiktionarySections enter";
    m_caller = caller;
    QUrl url(s_baseurl + "action=parse&page=" + m_word + "&prop=sections&format=json");
    QNetworkRequest request(url);
    request.setRawHeader("User-Agent", "Coleitra/0.1 (https://coleitra.org; fpesth@@gmx.de)");
    m_tmp_connection = connect(m_manager, &QNetworkAccessManager::finished,
        this, &grammarprovider::getWiktionarySection);
    QNetworkReply *reply = m_manager->get(request);
#if QT_VERSION >= 0x051500
    connect(reply, &QNetworkReply::errorOccurred, this,
                [reply](QNetworkReply::NetworkError) {
                qDebug() << "Error " << reply->errorString(); 
            });
#endif

    qDebug() << "getWiktionarySections exit";
}

void grammarprovider::getWiktionarySection(QNetworkReply* reply){
    qDebug() << "getWiktionarySection enter";
    QObject::disconnect(m_tmp_connection);
    QString s_reply = QString(reply->readAll());
    qDebug() << s_reply;
    reply->deleteLater();

    int languageid = m_language;
    QString language = m_database->languagenamefromid(languageid);

    QJsonDocument j_sectionsDocument = QJsonDocument::fromJson(s_reply.toUtf8());
    QJsonArray j_sections = j_sectionsDocument.object()["parse"].toObject()["sections"].toArray();
    bool found_language = false;
    int best_bet_for_section = 0;
    int section_level = 0;
    int language_section_level = 0;
    QString s_section;
    foreach(const QJsonValue& jv_section, j_sections){
        QJsonObject j_section = jv_section.toObject();
        s_section = j_section["line"].toString();
        section_level = j_section["level"].toString().toInt();
        if(section_level <= language_section_level) break;
        qDebug() << "Section" << s_section << "language" << language;
        if(s_section == language){
            found_language = true;
            best_bet_for_section = j_section["index"].toString().toInt();
            language_section_level = section_level;
        }
        else{
            if(found_language){
                foreach(const QString& parsesection, m_parsesections){
                    if(s_section == parsesection){
                        best_bet_for_section = j_section["index"].toString().toInt();
                        goto finished;
                    }
                }
            }
        }
    }
    finished:
    if(found_language){
        QUrl url(s_baseurl + "action=parse&page=" + m_word + "&section=" + QString::number(best_bet_for_section) + "&prop=wikitext&format=json");
        QNetworkRequest request(url);
        request.setRawHeader("User-Agent", "Coleitra/0.1 (https://coleitra.org; fpesth@@gmx.de)");
        m_tmp_connection = connect(m_manager, &QNetworkAccessManager::finished,
                this, &grammarprovider::getWiktionaryTemplate);
        QThread::msleep(200);
        QNetworkReply *reply = m_manager->get(request);
#if QT_VERSION >= 0x051500
        connect(reply, &QNetworkReply::errorOccurred, this,
                [reply](QNetworkReply::NetworkError) {
                qDebug() << "Error " << reply->errorString(); 
            });
#endif

    }
    else{
        qDebug() << "Could not find language";
    }
    qDebug() << "getWiktionarySection exit";
}

void grammarprovider::networkReplyErrorOccurred(QNetworkReply::NetworkError code){
//    qWarning() << "Error occured in network request in grammar provider:" << QIODevice::errorString();
}

grammarprovider::templatearguments grammarprovider::parseTemplateArguments(QString templateString){
    templateString = templateString.trimmed();
    templateString.remove(0,2);
    templateString.chop(2);
    QStringList args = templateString.split(QLatin1Char('|'));
    templatearguments parsed_args;
    foreach(const QString& arg, args){
        if(arg.contains(QLatin1Char('='))){
            QStringList keyval = arg.split(QLatin1Char('='));
            parsed_args.named[keyval.first()] = keyval.last();
            qDebug() << keyval.first() << "=" << keyval.last();
        }
        else {
            parsed_args.unnamed.push_back(arg);
            qDebug() << arg;
        }
    }
    return parsed_args;
}


void grammarprovider::getWiktionaryTemplate(QNetworkReply* reply){
    QObject::disconnect(m_tmp_connection);
    QString s_reply = QString(reply->readAll());
    reply->deleteLater();

    QJsonDocument j_document = QJsonDocument::fromJson(s_reply.toUtf8());
    QString wikitemplate_text = j_document.object()["parse"].toObject()["wikitext"].toObject()["*"].toString();
    QStringList wt_firsts = wikitemplate_text.split("{{");
    int i_first = 0;
    QStringList wt_opens;
    QStringList wt_finisheds;
    foreach(const QString& wt_first, wt_firsts){
        i_first++;
        if(i_first == 1){
            continue;
        }
        int ot_i1 = 0;
        wt_opens.push_back("");
        foreach(const QString& wt_open, wt_opens){
            if(!wt_first.contains("}}")){
                wt_opens[ot_i1] += "{{" + wt_first;
                ot_i1++;
            }
            else{
                wt_opens[ot_i1] += "{{";
                ot_i1++;
            }
        }
        QStringList wt_seconds = wt_first.split("}}");
        int i_second = 0;
        int i_second_max =  wt_seconds.size();
        foreach(const QString& wt_second, wt_seconds){
            i_second++;
            if(i_second == i_second_max){
                continue;
            }
            int ot_i = 0;
            foreach(const QString& wt_open, wt_opens){
                wt_opens[ot_i] += wt_second + "}}";
                ot_i++;
            }
            wt_finisheds.push_back(wt_opens.last());
            wt_opens.pop_back();
        }
    }
    QMapIterator<QString, void (grammarprovider::*)(QNetworkReply*)> parser(m_parser_map); 
    while (parser.hasNext()) {
        parser.next();
        foreach(const QString& wt_finished, wt_finisheds){
            if(wt_finished.startsWith("{{" + parser.key())){
                QUrl url(s_baseurl + "action=expandtemplates&text=" + wt_finished + "&title=" + m_word + "&prop=wikitext&format=json");
                m_currentarguments = parseTemplateArguments(wt_finished);
                qDebug() << url.toString();
                QNetworkRequest request(url);
                request.setRawHeader("User-Agent", "Coleitra/0.1 (https://coleitra.org; fpesth@@gmx.de)");
                m_tmp_connection = connect(m_manager, &QNetworkAccessManager::finished,
                        this, parser.value());
                m_manager->get(request);
                return;
            }
        }
    }
    qDebug() << "Template(s)" << wt_finisheds << "not supported!";
}

void grammarprovider::parseMediawikiTableToPlainText(QString wikitext, QList<grammarprovider::tablecell>& table){
    QStringList table_lines = wikitext.split("\n");
    int column=0;
    int row=0;
    int rowspan=0;
    foreach(QString table_line, table_lines){
        int columnspan = 0;
        auto process_line = [&columnspan,&rowspan](QString table_line){
            int colspan_i = table_line.indexOf("colspan=\"");
            if(colspan_i != -1){
                int colspan_j = table_line.indexOf("\"",colspan_i+9);
                columnspan += table_line.midRef(colspan_i+9,colspan_j-colspan_i-9).toInt()-1;
            }
            int rowspan_i = table_line.indexOf("rowspan=\"");
            if(rowspan_i != -1){
                int rowspan_j = table_line.indexOf("\"",rowspan_i+9);
                rowspan = table_line.midRef(rowspan_i+9,rowspan_j-rowspan_i-9).toInt()-1;
            }
            int formatting_i = table_line.indexOf("|");
            if(!table_line.left(formatting_i).contains("[[")){
                table_line.remove(0,formatting_i+1);
            }
	    table_line.replace(QString("<br/>"),QString(","));
            QStringList html_markupstrings = table_line.split("<");
            if(html_markupstrings.size() > 1){
                table_line = "";
                foreach(QString html_markupstring, html_markupstrings){
                    int tag_end = html_markupstring.indexOf(">");
                    html_markupstring.remove(0,tag_end+1);
                    table_line += html_markupstring;
                }
            }
            QStringList wiki_links = table_line.split("[[");
            if(wiki_links.size() > 1){
                table_line = "";
                foreach(QString wiki_link, wiki_links){
                    int tag_end = wiki_link.indexOf("]]");
                    if(tag_end != -1){
                        table_line += wiki_link.left(tag_end).split("|").last();
                        table_line += wiki_link.right(wiki_link.size()-tag_end-2);
                    }
                    else{
                        table_line += wiki_link;
                    }
                }
            }
            table_line = table_line.trimmed();
            QTextDocument text;
            text.setHtml(table_line);
            table_line = text.toPlainText();
            return table_line;
        };
        if(table_line.startsWith("|-")){
            row++;
            column=0;
            if(rowspan>0){
                column++;
                rowspan--;
            }
            continue;
        }
        if(table_line.startsWith("!")){
            table_line.remove(0,2);
            column++;
            table_line = process_line(table_line);
	    QStringList table_entries = table_line.split(QLatin1Char(','));
            foreach(QString table_entry, table_entries){
                table_entry = table_entry.trimmed();
                table.push_back({row,column,table_entry});
                qDebug() << row << column << table_entry;
            }
            column += columnspan;
            continue;
        }
        if(table_line.startsWith("|")){
            table_line.remove(0,2);
            column++;
            table_line = process_line(table_line);
	    QStringList table_entries = table_line.split(QLatin1Char(','));
            foreach(QString table_entry, table_entries){
                table_entry = table_entry.trimmed();
                table.push_back({row,column,table_entry});
                qDebug() << row << column << table_entry;
            }
            column += columnspan;
            continue;
        }
    }
}


void grammarprovider::process_grammar(QList<grammarform> grammarforms, QList<tablecell> parsedTable, QList<QList<QString> > additional_grammarforms){
    QStringList expressions;
    QList<QList<QList<QString> > > grammarexpressions;
    if(!parsedTable.isEmpty()){
        foreach(const grammarform& gf_expectedcell, grammarforms){
            tablecell tc_current = parsedTable.first();
            while(tc_current.row < gf_expectedcell.row){
                if(!parsedTable.isEmpty()){
                    parsedTable.pop_front();
                    if(!parsedTable.isEmpty())
                        tc_current = parsedTable.first();
                    else goto out;
                }
                else break;
            }
            if(tc_current.row == gf_expectedcell.row){
                while(tc_current.column < gf_expectedcell.column){
                    if(!parsedTable.isEmpty()){
                        parsedTable.pop_front();
                        tc_current = parsedTable.first();
                    }
                    else break;
                }
                if(tc_current.column == gf_expectedcell.column){
                    if(tc_current.content != "—"){
                        expressions.push_back(tc_current.content);
                        grammarexpressions.push_back(gf_expectedcell.grammarexpressions + additional_grammarforms);
                    }
                }
            }
        }
    }
out:
    qDebug() << "Got" << grammarexpressions.size() << "==" << expressions.size();
    emit grammarobtained(m_caller, expressions, grammarexpressions);
}

void grammarprovider::getPlainTextTableFromReply(QNetworkReply* reply, QList<grammarprovider::tablecell>& parsedTable){
    QObject::disconnect(m_tmp_connection);
    QString s_reply = QString(reply->readAll());
    reply->deleteLater();

    QJsonDocument j_document = QJsonDocument::fromJson(s_reply.toUtf8());
    QString wikitemplate_text = j_document.object()["expandtemplates"].toObject()["wikitext"].toString();
    parseMediawikiTableToPlainText(wikitemplate_text, parsedTable);
}

void grammarprovider::parse_fi_verbs(QNetworkReply* reply){
    QList<grammarprovider::tablecell> parsedTable;
    getPlainTextTableFromReply(reply, parsedTable);
    QList<grammarform> grammarforms {
        {1,5,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}}},
        {63,5,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {93,5,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {123,5,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {2,6,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}}},
        {64,6,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {94,6,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {124,6,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {3,7,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}}},
        {65,7,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {95,7,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {125,7,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {4,8,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}}},
        {66,8,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {96,8,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {126,8,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {5,9,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}}},
        {67,9,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {97,9,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {127,9,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {6,10,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}}},
        {68,10,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {98,10,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {128,10,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {7,11,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Voice","Passive"}}},
        {153,11,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}}}}},
        {158,11,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {163,11,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {8,14,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}}},
        {69,14,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {99,14,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {129,14,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {9,15,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}}},
        {70,15,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {100,15,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {130,15,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {10,16,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}}},
        {71,16,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {101,16,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {131,16,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {11,17,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}}},
        {72,17,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {102,17,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {132,17,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {12,18,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}}},
        {73,18,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {103,18,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {133,18,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {13,19,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}}},
        {74,19,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {104,19,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {134,19,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {14,20,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Voice","Passive"}}},
        {154,20,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {159,20,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {164,20,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {15,24,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}}},
        {75,24,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {105,24,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {135,24,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {16,25,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}}},
        {76,25,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {106,25,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {136,25,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {17,26,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}}},
        {77,26,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {107,26,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {137,26,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {18,27,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}}},
        {78,27,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {108,27,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {138,27,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {19,28,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}}},
        {79,28,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {109,28,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {139,28,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {20,29,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}}},
        {80,29,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {110,29,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {140,29,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {21,30,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Voice","Passive"}}},
        {155,30,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}}}}},
        {160,30,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {165,30,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {22,34,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}}},
        {81,34,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}}}}},
        {111,34,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {141,34,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {23,35,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}}},
        {82,35,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}}}}},
        {112,35,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {142,35,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {24,36,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}}},
        {83,36,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}}}}},
        {113,36,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {143,36,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {25,37,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}}},
        {84,37,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}}}}},
        {114,37,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {144,37,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {26,38,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}}},
        {85,38,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}}}}},
        {115,38,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {145,38,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {27,39,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}}},
        {86,39,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}}}}},
        {116,39,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {146,39,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {28,40,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Voice","Passive"}}},
        {156,40,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}}}}},
        {161,40,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {166,40,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {29,44,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}}},
        {87,44,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {117,44,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {147,44,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {30,45,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}}},
        {88,45,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {118,45,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {148,45,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {31,46,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}}},
        {89,46,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {119,46,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {149,46,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {32,47,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}}},
        {90,47,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {120,47,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {150,47,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {33,48,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}}},
        {91,48,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {121,48,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {151,48,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {34,49,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}}},
        {92,49,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {122,49,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {152,49,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {35,50,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Voice","Passive"}}},
        {157,50,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}}}}},
        {162,50,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {167,50,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {36,54,3,{{"Infinitive","First"},{"Voice","Active"}}},
        {37,54,6,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Present"}}},
        {38,54,7,{{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Present"}}},
        {39,55,3,{{"Infinitive","Long first"},{"Voice","Active"}}},
        {40,55,6,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}},
        {41,55,7,{{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}},
        {42,56,3,{{"Infinitive","Second"},{"Voice","Active"},{"Case","Inessive"}}},
        {43,56,4,{{"Infinitive","Second"},{"Voice","Passive"},{"Case","Inessive"}}},
        {44,56,6,{{"Verbform","Participle"},{"Voice","Active"},{"Tense","Agent"}}},
        {45,57,3,{{"Infinitive","Second"},{"Voice","Active"},{"Case","Instructive"}}},
        {46,57,4,{{"Infinitive","Second"},{"Voice","Passive"},{"Case","Instructive"}}},
        {47,57,6,{{"Verbform","Participle"},{"Voice","Active"},{"Polarity","Negative"}}},
        {48,58,3,{{"Infinitive","Third"},{"Voice","Active"},{"Case","Inessive"}}},
        {49,58,4,{{"Infinitive","Third"},{"Voice","Passive"},{"Case","Inessive"}}},
        {50,59,3,{{"Infinitive","Third"},{"Voice","Active"},{"Case","Elative"}}},
        {51,59,4,{{"Infinitive","Third"},{"Voice","Passive"},{"Case","Elative"}}},
        {52,60,3,{{"Infinitive","Third"},{"Voice","Active"},{"Case","Illative"}}},
        {53,60,4,{{"Infinitive","Third"},{"Voice","Passive"},{"Case","Illative"}}},
        {54,61,3,{{"Infinitive","Third"},{"Voice","Active"},{"Case","Adessive"}}},
        {55,61,4,{{"Infinitive","Third"},{"Voice","Passive"},{"Case","Adessive"}}},
        {56,62,3,{{"Infinitive","Third"},{"Voice","Active"},{"Case","Abessive"}}},
        {57,62,4,{{"Infinitive","Third"},{"Voice","Passive"},{"Case","Abessive"}}},
        {58,63,3,{{"Infinitive","Third"},{"Voice","Active"},{"Case","Instructive"}}},
        {59,63,4,{{"Infinitive","Third"},{"Voice","Passive"},{"Case","Instructive"}}},
        {60,64,3,{{"Infinitive","Fourth"},{"Voice","Active"},{"Case","Nominative"}}},
        {61,65,3,{{"Infinitive","Fourth"},{"Voice","Active"},{"Case","Partitive"}}},
        {62,66,3,{{"Infinitive","Fifth"},{"Voice","Active"}}},
    };
    process_grammar(grammarforms,parsedTable,{{"Part of speech","Verb"}});
}


void grammarprovider::parse_fi_nominals(QNetworkReply* reply){

    QList<grammarprovider::tablecell> parsedTable;
    getPlainTextTableFromReply(reply, parsedTable);

    QList<grammarform> grammarforms {
        {1,7,3,{{"Case","Nominative"},{"Number","Singular"}}},
        {2,7,4,{{"Case","Nominative"},{"Number","Plural"}}},
        {3,8,3,{{"Case","Accusative"},{"Case","Nominative"},{"Number","Singular"}}},
        {4,8,4,{{"Case","Accusative"},{"Case","Nominative"},{"Number","Plural"}}},
        {5,9,3,{{"Case","Accusative"},{"Case","Genitive"},{"Number","Singular"}}},
        {6,10,3,{{"Case","Genitive"},{"Number","Singular"}}},
        {7,10,4,{{"Case","Genitive"},{"Number","Plural"}}},
        {8,11,3,{{"Case","Partitive"},{"Number","Singular"}}},
        {9,11,4,{{"Case","Partitive"},{"Number","Plural"}}},
        {10,12,3,{{"Case","Inessive"},{"Number","Singular"}}},
        {11,12,4,{{"Case","Inessive"},{"Number","Plural"}}},
        {12,13,3,{{"Case","Elative"},{"Number","Singular"}}},
        {13,13,4,{{"Case","Elative"},{"Number","Plural"}}},
        {14,14,3,{{"Case","Illative"},{"Number","Singular"}}},
        {15,14,4,{{"Case","Illative"},{"Number","Plural"}}},
        {16,15,3,{{"Case","Adessive"},{"Number","Singular"}}},
        {17,15,4,{{"Case","Adessive"},{"Number","Plural"}}},
        {18,16,3,{{"Case","Ablative"},{"Number","Singular"}}},
        {19,16,4,{{"Case","Ablative"},{"Number","Plural"}}},
        {20,17,3,{{"Case","Allative"},{"Number","Singular"}}},
        {21,17,4,{{"Case","Allative"},{"Number","Plural"}}},
        {22,18,3,{{"Case","Essive"},{"Number","Singular"}}},
        {23,18,4,{{"Case","Essive"},{"Number","Plural"}}},
        {24,19,3,{{"Case","Translative"},{"Number","Singular"}}},
        {25,19,4,{{"Case","Translative"},{"Number","Plural"}}},
        {26,20,3,{{"Case","Instructive"},{"Number","Singular"}}},
        {27,20,4,{{"Case","Instructive"},{"Number","Plural"}}},
        {28,21,3,{{"Case","Abessive"},{"Number","Singular"}}},
        {29,21,4,{{"Case","Abessive"},{"Number","Plural"}}},
        {30,22,3,{{"Case","Comitative"},{"Number","Singular"}}},
        {31,22,4,{{"Case","Comitative"},{"Number","Plural"}}},
        {32,25,2,{{"Case","Possessive"},{"Number","Singular"},{"Person","First"}}},
        {33,25,3,{{"Case","Possessive"},{"Number","Plural"},{"Person","First"}}},
        {34,26,2,{{"Case","Possessive"},{"Number","Singular"},{"Person","Second"}}},
        {35,26,3,{{"Case","Possessive"},{"Number","Plural"},{"Person","Second"}}},
        {36,27,2,{{"Case","Possessive"},{"Number","Singular"},{"Number","Plural"},{"Person","Third"}}},
    };
    if(m_currentarguments.named["pos"] == "adj")
        process_grammar(grammarforms,parsedTable,{{"Part of speech","Adjective"}});
    else
        process_grammar(grammarforms,parsedTable,{{"Part of speech","Noun"}});
}

void grammarprovider::parse_de_noun_n(QNetworkReply* reply){
    QList<grammarprovider::tablecell> parsedTable;
    getPlainTextTableFromReply(reply, parsedTable);

    QList<grammarform> grammarforms {
        {1,2,4,{{"Gender","Neuter"},{"Case","Nominative"},{"Number","Singular"}}},
        {2,2,6,{{"Gender","Neuter"},{"Case","Nominative"},{"Number","Plural"}}},
        {3,3,4,{{"Gender","Neuter"},{"Case","Genitive"},{"Number","Singular"}}},
        {4,3,6,{{"Gender","Neuter"},{"Case","Genitive"},{"Number","Plural"}}},
        {5,4,4,{{"Gender","Neuter"},{"Case","Dative"},{"Number","Singular"}}},
        {6,4,6,{{"Gender","Neuter"},{"Case","Dative"},{"Number","Plural"}}},
        {7,5,4,{{"Gender","Neuter"},{"Case","Accusative"},{"Number","Singular"}}},
        {8,5,6,{{"Gender","Neuter"},{"Case","Accusative"},{"Number","Plural"}}},
    };
    process_grammar(grammarforms,parsedTable,{{"Part of speech","Noun"}});
}

void grammarprovider::parse_de_noun_m(QNetworkReply* reply){

    QList<grammarprovider::tablecell> parsedTable;
    getPlainTextTableFromReply(reply, parsedTable);

    QList<grammarform> grammarforms {
        {1,2,4,{{"Gender","Masculine"},{"Case","Nominative"},{"Number","Singular"}}},
        {2,2,6,{{"Gender","Masculine"},{"Case","Nominative"},{"Number","Plural"}}},
        {3,3,4,{{"Gender","Masculine"},{"Case","Genitive"},{"Number","Singular"}}},
        {4,3,6,{{"Gender","Masculine"},{"Case","Genitive"},{"Number","Plural"}}},
        {5,4,4,{{"Gender","Masculine"},{"Case","Dative"},{"Number","Singular"}}},
        {6,4,6,{{"Gender","Masculine"},{"Case","Dative"},{"Number","Plural"}}},
        {7,5,4,{{"Gender","Masculine"},{"Case","Accusative"},{"Number","Singular"}}},
        {8,5,6,{{"Gender","Masculine"},{"Case","Accusative"},{"Number","Plural"}}},
    };
    process_grammar(grammarforms,parsedTable,{{"Part of speech","Noun"}});
}

void grammarprovider::parse_de_noun_f(QNetworkReply* reply){

    QList<grammarprovider::tablecell> parsedTable;
    getPlainTextTableFromReply(reply, parsedTable);

    QList<grammarform> grammarforms {
        {1,2,4,{{"Gender","Feminine"},{"Case","Nominative"},{"Number","Singular"}}},
        {2,2,6,{{"Gender","Feminine"},{"Case","Nominative"},{"Number","Plural"}}},
        {3,3,4,{{"Gender","Feminine"},{"Case","Genitive"},{"Number","Singular"}}},
        {4,3,6,{{"Gender","Feminine"},{"Case","Genitive"},{"Number","Plural"}}},
        {5,4,4,{{"Gender","Feminine"},{"Case","Dative"},{"Number","Singular"}}},
        {6,4,6,{{"Gender","Feminine"},{"Case","Dative"},{"Number","Plural"}}},
        {7,5,4,{{"Gender","Feminine"},{"Case","Accusative"},{"Number","Singular"}}},
        {8,5,6,{{"Gender","Feminine"},{"Case","Accusative"},{"Number","Plural"}}},
    };
    process_grammar(grammarforms,parsedTable,{{"Part of speech","Noun"}});
}

void grammarprovider::parse_de_verb(QNetworkReply* reply){
    // Work in process....

    QList<grammarprovider::tablecell> parsedTable;
    getPlainTextTableFromReply(reply, parsedTable);
    QList<grammarform> grammarforms {
        {1,1,3,{{"Infinitive","First"}}},
        {2,2,3,{{"Verbform","Participle"},{"Tense","Present"}}},
        {3,3,3,{{"Verbform","Participle"},{"Tense","Past"}}},
        {4,4,3,{{"Verbform","Auxiliary"}}},
        {5,6,2,{{"Mood","Indicative"},{"Tense","Present"},{"Person","First"},{"Number","Singular"}}},
        {6,6,3,{{"Mood","Indicative"},{"Tense","Present"},{"Person","First"},{"Number","Plural"}}},
        {7,6,5,{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","First"},{"Number","Singular"}}},
        {8,6,6,{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","First"},{"Number","Plural"}}},
        {9,7,2,{{"Mood","Indicative"},{"Tense","Present"},{"Person","Second"},{"Number","Singular"}}},
        {10,7,3,{{"Mood","Indicative"},{"Tense","Present"},{"Person","Second"},{"Number","Plural"}}},
        {11,7,4,{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","Second"},{"Number","Singular"}}},
        {12,7,5,{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","Second"},{"Number","Plural"}}},
        {13,8,2,{{"Mood","Indicative"},{"Tense","Present"},{"Person","Third"},{"Number","Singular"}}},
        {14,8,3,{{"Mood","Indicative"},{"Tense","Present"},{"Person","Third"},{"Number","Plural"}}},
        {15,8,4,{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","Third"},{"Number","Singular"}}},
        {16,8,5,{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","Third"},{"Number","Plural"}}},
        {17,10,2,{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","First"},{"Number","Singular"}}},
        {18,10,3,{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","First"},{"Number","Plural"}}},
        {19,10,5,{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","First"},{"Number","Singular"}}},
        {20,10,6,{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","First"},{"Number","Plural"}}},
        {21,11,2,{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","Second"},{"Number","Singular"}}},
        {22,11,3,{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","Second"},{"Number","Plural"}}},
        {23,11,4,{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","Second"},{"Number","Singular"}}},
        {24,11,5,{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","Second"},{"Number","Plural"}}},
        {25,12,2,{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","Third"},{"Number","Singular"}}},
        {26,12,3,{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","Third"},{"Number","Plural"}}},
        {27,12,4,{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","Third"},{"Number","Singular"}}},
        {28,12,5,{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","Third"},{"Number","Plural"}}},
        {29,14,2,{{"Mood","Imperative"},{"Person","Second"},{"Number","Singular"}}},
        {30,14,3,{{"Mood","Imperative"},{"Person","Second"},{"Number","Plural"}}},
        {31,16,2,{{"Mood","Indicative"},{"Tense","Perfect"},{"Person","First"},{"Number","Singular"}}},
        {32,16,3,{{"Mood","Indicative"},{"Tense","Perfect"},{"Person","First"},{"Number","Plural"}}},
        {33,16,5,{{"Mood","Subjunctive"},{"Tense","Perfect"},{"Person","First"},{"Number","Singular"}}},
        {34,16,6,{{"Mood","Subjunctive"},{"Tense","Perfect"},{"Person","First"},{"Number","Plural"}}},
        {35,17,2,{{"Mood","Indicative"},{"Tense","Perfect"},{"Person","Second"},{"Number","Singular"}}},
        {36,17,3,{{"Mood","Indicative"},{"Tense","Perfect"},{"Person","Second"},{"Number","Plural"}}},
        {37,17,4,{{"Mood","Subjunctive"},{"Tense","Perfect"},{"Person","Second"},{"Number","Singular"}}},
        {38,17,5,{{"Mood","Subjunctive"},{"Tense","Perfect"},{"Person","Second"},{"Number","Plural"}}},
        {39,18,2,{{"Mood","Indicative"},{"Tense","Perfect"},{"Person","Third"},{"Number","Singular"}}},
        {40,18,3,{{"Mood","Indicative"},{"Tense","Perfect"},{"Person","Third"},{"Number","Plural"}}},
        {41,18,4,{{"Mood","Subjunctive"},{"Tense","Perfect"},{"Person","Third"},{"Number","Singular"}}},
        {42,18,5,{{"Mood","Subjunctive"},{"Tense","Perfect"},{"Person","Third"},{"Number","Plural"}}},
        {43,20,2,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Person","First"},{"Number","Singular"}}},
        {44,20,3,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Person","First"},{"Number","Plural"}}},
        {45,20,5,{{"Mood","Subjunctive"},{"Tense","Plusquamperfect"},{"Person","First"},{"Number","Singular"}}},
        {46,20,6,{{"Mood","Subjunctive"},{"Tense","Plusquamperfect"},{"Person","First"},{"Number","Plural"}}},
        {47,21,2,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Person","Second"},{"Number","Singular"}}},
        {48,21,3,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Person","Second"},{"Number","Plural"}}},
        {49,21,4,{{"Mood","Subjunctive"},{"Tense","Plusquamperfect"},{"Person","Second"},{"Number","Singular"}}},
        {50,21,5,{{"Mood","Subjunctive"},{"Tense","Plusquamperfect"},{"Person","Second"},{"Number","Plural"}}},
        {51,22,2,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Person","Third"},{"Number","Singular"}}},
        {52,22,3,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Person","Third"},{"Number","Plural"}}},
        {53,22,4,{{"Mood","Subjunctive"},{"Tense","Plusquamperfect"},{"Person","Third"},{"Number","Singular"}}},
        {54,22,5,{{"Mood","Subjunctive"},{"Tense","Plusquamperfect"},{"Person","Third"},{"Number","Plural"}}},
        {55,24,2,{{"Infinitive","First"},{"Tense","Future 1"},{"Person","Third"},{"Number","Plural"}}},
        {56,24,5,{{"Mood","Subjunctive 1"},{"Tense","Future 1"},{"Person","First"},{"Number","Singular"}}},
        {57,24,6,{{"Mood","Subjunctive 1"},{"Tense","Future 1"},{"Person","First"},{"Number","Plural"}}},
        {58,25,2,{{"Mood","Subjunctive 1"},{"Tense","Future 1"},{"Person","Second"},{"Number","Singular"}}},
        {59,25,3,{{"Mood","Subjunctive 1"},{"Tense","Future 1"},{"Person","Second"},{"Number","Plural"}}},
        {60,26,2,{{"Mood","Subjunctive 1"},{"Tense","Future 1"},{"Person","Third"},{"Number","Singular"}}},
        {61,26,3,{{"Mood","Subjunctive 1"},{"Tense","Future 1"},{"Person","Third"},{"Number","Plural"}}},
        {62,28,2,{{"Mood","Indicative"},{"Tense","Future 1"},{"Person","First"},{"Number","Singular"}}},
        {63,28,3,{{"Mood","Indicative"},{"Tense","Future 1"},{"Person","First"},{"Number","Plural"}}},
        {64,28,5,{{"Mood","Subjunctive 2"},{"Tense","Future 1"},{"Person","First"},{"Number","Singular"}}},
        {65,28,6,{{"Mood","Subjunctive 2"},{"Tense","Future 1"},{"Person","First"},{"Number","Plural"}}},
        {66,29,2,{{"Mood","Indicative"},{"Tense","Future 1"},{"Person","Second"},{"Number","Singular"}}},
        {67,29,3,{{"Mood","Indicative"},{"Tense","Future 1"},{"Person","Second"},{"Number","Plural"}}},
        {68,29,4,{{"Mood","Subjunctive 2"},{"Tense","Future 1"},{"Person","Second"},{"Number","Singular"}}},
        {69,29,5,{{"Mood","Subjunctive 2"},{"Tense","Future 1"},{"Person","Second"},{"Number","Plural"}}},
        {70,30,2,{{"Mood","Indicative"},{"Tense","Future 1"},{"Person","Third"},{"Number","Singular"}}},
        {71,30,3,{{"Mood","Indicative"},{"Tense","Future 1"},{"Person","Third"},{"Number","Plural"}}},
        {72,30,4,{{"Mood","Subjunctive 2"},{"Tense","Future 1"},{"Person","Third"},{"Number","Singular"}}},
        {73,30,5,{{"Mood","Subjunctive 2"},{"Tense","Future 1"},{"Person","Third"},{"Number","Plural"}}},
        {74,32,2,{{"Infinitive","First"},{"Tense","Future 2"},{"Person","Third"},{"Number","Plural"}}},
        {75,32,5,{{"Mood","Subjunctive 1"},{"Tense","Future 2"},{"Person","First"},{"Number","Singular"}}},
        {76,32,6,{{"Mood","Subjunctive 1"},{"Tense","Future 2"},{"Person","First"},{"Number","Plural"}}},
        {77,33,2,{{"Mood","Subjunctive 1"},{"Tense","Future 2"},{"Person","Second"},{"Number","Singular"}}},
        {78,33,3,{{"Mood","Subjunctive 1"},{"Tense","Future 2"},{"Person","Second"},{"Number","Plural"}}},
        {79,34,2,{{"Mood","Subjunctive 1"},{"Tense","Future 2"},{"Person","Third"},{"Number","Singular"}}},
        {80,34,3,{{"Mood","Subjunctive 1"},{"Tense","Future 2"},{"Person","Third"},{"Number","Plural"}}},
        {81,36,2,{{"Mood","Indicative"},{"Tense","Future 2"},{"Person","First"},{"Number","Singular"}}},
        {82,36,3,{{"Mood","Indicative"},{"Tense","Future 2"},{"Person","First"},{"Number","Plural"}}},
        {83,36,5,{{"Mood","Subjunctive 2"},{"Tense","Future 2"},{"Person","First"},{"Number","Singular"}}},
        {84,36,6,{{"Mood","Subjunctive 2"},{"Tense","Future 2"},{"Person","First"},{"Number","Plural"}}},
        {85,37,2,{{"Mood","Indicative"},{"Tense","Future 2"},{"Person","Second"},{"Number","Singular"}}},
        {86,37,3,{{"Mood","Indicative"},{"Tense","Future 2"},{"Person","Second"},{"Number","Plural"}}},
        {87,37,4,{{"Mood","Subjunctive 2"},{"Tense","Future 2"},{"Person","Second"},{"Number","Singular"}}},
        {88,37,5,{{"Mood","Subjunctive 2"},{"Tense","Future 2"},{"Person","Second"},{"Number","Plural"}}},
        {89,38,2,{{"Mood","Indicative"},{"Tense","Future 2"},{"Person","Third"},{"Number","Singular"}}},
        {90,38,3,{{"Mood","Indicative"},{"Tense","Future 2"},{"Person","Third"},{"Number","Plural"}}},
        {91,38,4,{{"Mood","Subjunctive 2"},{"Tense","Future 2"},{"Person","Third"},{"Number","Singular"}}},
        {92,38,5,{{"Mood","Subjunctive 2"},{"Tense","Future 2"},{"Person","Third"},{"Number","Plural"}}},
    };
    process_grammar(grammarforms,parsedTable,{{"Part of speech","Verb"}});
}
@}
