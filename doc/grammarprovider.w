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
#include <QJsonArray>
#include <QFile>
#include <QQmlEngine>
#include <QMap>
#include <QMapIterator>
#include <QTextDocument>
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
public slots:
    Q_INVOKABLE void getWiktionarySections();
    void getWiktionarySection(QNetworkReply* reply);
    void getWiktionaryTemplate(QNetworkReply* reply);
    void parseMediawikiTableToPlainText(QString wikitext, QList<grammarprovider::tablecell>& table);
    void parse_fi_verbs(QNetworkReply* reply);
    void parse_fi_nominals(QNetworkReply* reply);
private:
    int m_language;
    QString m_word;
    QString s_baseurl;
    QNetworkAccessManager* m_manager;
    QMetaObject::Connection m_tmp_connection;
    QList<QString> m_parsesections;
    settings* m_settings;
    database* m_database;
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
}

grammarprovider::~grammarprovider() {
    delete m_manager;
}

void grammarprovider::getWiktionarySections(){
    QUrl url(s_baseurl + "action=parse&page=" + m_word + "&prop=sections&format=json");
    QNetworkRequest request(url);
    request.setRawHeader("User-Agent", "Coleitra/0.1 (https://coleitra.org; fpesth@@gmx.de)");
    m_tmp_connection = connect(m_manager, &QNetworkAccessManager::finished,
        this, &grammarprovider::getWiktionarySection);
    m_manager->get(request);
}

void grammarprovider::getWiktionarySection(QNetworkReply* reply){
    QObject::disconnect(m_tmp_connection);
    QString s_reply = QString(reply->readAll());
    reply->deleteLater();

    /*QFile file("debug.json");
    file.open(QFile::ReadOnly);
    QString s_reply = file.readAll();
    file.close();*/

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
        m_manager->get(request);
    }
/*    QFile file("debug.json");
    file.open(QFile::WriteOnly);
    file.write(j_sectionsDocument.toJson());
    file.close();*/
}


void grammarprovider::getWiktionaryTemplate(QNetworkReply* reply){

/*    QFile file("debug_template.json");
    file.open(QFile::ReadOnly);
    QString s_reply = file.readAll();
    file.close();*/

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
            qDebug() << parser.key() << wt_finished;
            if(wt_finished.startsWith("{{" + parser.key())){
                QUrl url(s_baseurl + "action=expandtemplates&text=" + wt_finished + "&prop=wikitext&format=json");
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
/*    QFile file("debug_template.json");
    file.open(QFile::WriteOnly);
    file.write(j_document.toJson());
    file.close();*/

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
            table.push_back({row,column,table_line});
            column += columnspan;
            continue;
        }
        if(table_line.startsWith("|")){
            table_line.remove(0,2);
            column++;
            table_line = process_line(table_line);
            table.push_back({row,column,table_line});
            column += columnspan;
            continue;
        }

    }
}


void grammarprovider::parse_fi_verbs(QNetworkReply* reply){

    /*QFile file("debug_table.json");
    file.open(QFile::ReadOnly);
    QString s_reply = file.readAll();
    file.close();*/


    QObject::disconnect(m_tmp_connection);
    QString s_reply = QString(reply->readAll());
    reply->deleteLater();

    QJsonDocument j_document = QJsonDocument::fromJson(s_reply.toUtf8());
    QString wikitemplate_text = j_document.object()["expandtemplates"].toObject()["wikitext"].toString();
    QList<grammarprovider::tablecell> parsedTable;
    parseMediawikiTableToPlainText(wikitemplate_text, parsedTable);

    struct grammarform {
        int row;
        int column;
        QList<QString> grammarexpressions;
    };
    QList<grammarform> grammarforms {
        {5,3,{"Indicative mood","Present tense","Positive","First person","Singular"}},
        {5,4,{"Indicative mood","Present tense","Negative","First person","Singular"}},
        {5,6,{"Indicative mood","Perfect tense","Positive","First person","Singular"}},
        {5,7,{"Indicative mood","Perfect tense","Negative","First person","Singular"}},
        {6,3,{"Indicative mood","Present tense","Positive","Second person","Singular"}},
        {6,4,{"Indicative mood","Present tense","Negative","Second person","Singular"}},
        {6,6,{"Indicative mood","Perfect tense","Positive","Second person","Singular"}},
        {6,7,{"Indicative mood","Perfect tense","Negative","Second person","Singular"}},
        {7,3,{"Indicative mood","Present tense","Positive","Third person","Singular"}},
        {7,4,{"Indicative mood","Present tense","Negative","Third person","Singular"}},
        {7,6,{"Indicative mood","Perfect tense","Positive","Third person","Singular"}},
        {7,7,{"Indicative mood","Perfect tense","Negative","Third person","Singular"}},
        {8,3,{"Indicative mood","Present tense","Positive","First person","Plural"}},
        {8,4,{"Indicative mood","Present tense","Negative","First person","Plural"}},
        {8,6,{"Indicative mood","Perfect tense","Positive","First person","Plural"}},
        {8,7,{"Indicative mood","Perfect tense","Negative","First person","Plural"}},
        {9,3,{"Indicative mood","Present tense","Positive","Second person","Plural"}},
        {9,4,{"Indicative mood","Present tense","Negative","Second person","Plural"}},
        {9,6,{"Indicative mood","Perfect tense","Positive","Second person","Plural"}},
        {9,7,{"Indicative mood","Perfect tense","Negative","Second person","Plural"}},
        {10,3,{"Indicative mood","Present tense","Positive","Third person","Plural"}},
        {10,4,{"Indicative mood","Present tense","Negative","Third person","Plural"}},
        {10,6,{"Indicative mood","Perfect tense","Positive","Third person","Plural"}},
        {10,7,{"Indicative mood","Perfect tense","Negative","Third person","Plural"}},
        {11,3,{"Indicative mood","Present tense","Positive","Passive"}},
        {11,4,{"Indicative mood","Present tense","Negative","Passive"}},
        {11,6,{"Indicative mood","Perfect tense","Positive","Passive"}},
        {11,7,{"Indicative mood","Perfect tense","Negative","Passive"}},
        {14,3,{"Indicative mood","Past tense","Positive","First person","Singular"}},
        {14,4,{"Indicative mood","Past tense","Negative","First person","Singular"}},
        {14,6,{"Indicative mood","Plusquamperfekt tense","Positive","First person","Singular"}},
        {14,7,{"Indicative mood","Plusquamperfekt tense","Negative","First person","Singular"}},
        {15,3,{"Indicative mood","Past tense","Positive","Second person","Singular"}},
        {15,4,{"Indicative mood","Past tense","Negative","Second person","Singular"}},
        {15,6,{"Indicative mood","Plusquamperfekt tense","Positive","Second person","Singular"}},
        {15,7,{"Indicative mood","Plusquamperfekt tense","Negative","Second person","Singular"}},
        {16,3,{"Indicative mood","Past tense","Positive","Third person","Singular"}},
        {16,4,{"Indicative mood","Past tense","Negative","Third person","Singular"}},
        {16,6,{"Indicative mood","Plusquamperfekt tense","Positive","Third person","Singular"}},
        {16,7,{"Indicative mood","Plusquamperfekt tense","Negative","Third person","Singular"}},
        {17,3,{"Indicative mood","Past tense","Positive","First person","Plural"}},
        {17,4,{"Indicative mood","Past tense","Negative","First person","Plural"}},
        {17,6,{"Indicative mood","Plusquamperfekt tense","Positive","First person","Plural"}},
        {17,7,{"Indicative mood","Plusquamperfekt tense","Negative","First person","Plural"}},
        {18,3,{"Indicative mood","Past tense","Positive","Second person","Plural"}},
        {18,4,{"Indicative mood","Past tense","Negative","Second person","Plural"}},
        {18,6,{"Indicative mood","Plusquamperfekt tense","Positive","Second person","Plural"}},
        {18,7,{"Indicative mood","Plusquamperfekt tense","Negative","Second person","Plural"}},
        {19,3,{"Indicative mood","Past tense","Positive","Third person","Plural"}},
        {19,4,{"Indicative mood","Past tense","Negative","Third person","Plural"}},
        {19,6,{"Indicative mood","Plusquamperfekt tense","Positive","Third person","Plural"}},
        {19,7,{"Indicative mood","Plusquamperfekt tense","Negative","Third person","Plural"}},
        {20,3,{"Indicative mood","Past tense","Positive","Passive"}},
        {20,4,{"Indicative mood","Past tense","Negative","Passive"}},
        {20,6,{"Indicative mood","Plusquamperfekt tense","Positive","Passive"}},
        {20,7,{"Indicative mood","Plusquamperfekt tense","Negative","Passive"}},
        {24,3,{"Conditional mood","Present tense","Positive","First person","Singular"}},
        {24,4,{"Conditional mood","Present tense","Negative","First person","Singular"}},
        {24,6,{"Conditional mood","Perfect tense","Positive","First person","Singular"}},
        {24,7,{"Conditional mood","Perfect tense","Negative","First person","Singular"}},
        {25,3,{"Conditional mood","Present tense","Positive","Second person","Singular"}},
        {25,4,{"Conditional mood","Present tense","Negative","Second person","Singular"}},
        {25,6,{"Conditional mood","Perfect tense","Positive","Second person","Singular"}},
        {25,7,{"Conditional mood","Perfect tense","Negative","Second person","Singular"}},
        {26,3,{"Conditional mood","Present tense","Positive","Third person","Singular"}},
        {26,4,{"Conditional mood","Present tense","Negative","Third person","Singular"}},
        {26,6,{"Conditional mood","Perfect tense","Positive","Third person","Singular"}},
        {26,7,{"Conditional mood","Perfect tense","Negative","Third person","Singular"}},
        {27,3,{"Conditional mood","Present tense","Positive","First person","Plural"}},
        {27,4,{"Conditional mood","Present tense","Negative","First person","Plural"}},
        {27,6,{"Conditional mood","Perfect tense","Positive","First person","Plural"}},
        {27,7,{"Conditional mood","Perfect tense","Negative","First person","Plural"}},
        {28,3,{"Conditional mood","Present tense","Positive","Second person","Plural"}},
        {28,4,{"Conditional mood","Present tense","Negative","Second person","Plural"}},
        {28,6,{"Conditional mood","Perfect tense","Positive","Second person","Plural"}},
        {28,7,{"Conditional mood","Perfect tense","Negative","Second person","Plural"}},
        {29,3,{"Conditional mood","Present tense","Positive","Third person","Plural"}},
        {29,4,{"Conditional mood","Present tense","Negative","Third person","Plural"}},
        {29,6,{"Conditional mood","Perfect tense","Positive","Third person","Plural"}},
        {29,7,{"Conditional mood","Perfect tense","Negative","Third person","Plural"}},
        {30,3,{"Conditional mood","Present tense","Positive","Passive"}},
        {30,4,{"Conditional mood","Present tense","Negative","Passive"}},
        {30,6,{"Conditional mood","Perfect tense","Positive","Passive"}},
        {30,7,{"Conditional mood","Perfect tense","Negative","Passive"}},
        {34,3,{"Imperative mood","Present tense","Positive","First person","Singular"}},
        {34,4,{"Imperative mood","Present tense","Negative","First person","Singular"}},
        {34,6,{"Imperative mood","Perfect tense","Positive","First person","Singular"}},
        {34,7,{"Imperative mood","Perfect tense","Negative","First person","Singular"}},
        {35,3,{"Imperative mood","Present tense","Positive","Second person","Singular"}},
        {35,4,{"Imperative mood","Present tense","Negative","Second person","Singular"}},
        {35,6,{"Imperative mood","Perfect tense","Positive","Second person","Singular"}},
        {35,7,{"Imperative mood","Perfect tense","Negative","Second person","Singular"}},
        {36,3,{"Imperative mood","Present tense","Positive","Third person","Singular"}},
        {36,4,{"Imperative mood","Present tense","Negative","Third person","Singular"}},
        {36,6,{"Imperative mood","Perfect tense","Positive","Third person","Singular"}},
        {36,7,{"Imperative mood","Perfect tense","Negative","Third person","Singular"}},
        {37,3,{"Imperative mood","Present tense","Positive","First person","Plural"}},
        {37,4,{"Imperative mood","Present tense","Negative","First person","Plural"}},
        {37,6,{"Imperative mood","Perfect tense","Positive","First person","Plural"}},
        {37,7,{"Imperative mood","Perfect tense","Negative","First person","Plural"}},
        {38,3,{"Imperative mood","Present tense","Positive","Second person","Plural"}},
        {38,4,{"Imperative mood","Present tense","Negative","Second person","Plural"}},
        {38,6,{"Imperative mood","Perfect tense","Positive","Second person","Plural"}},
        {38,7,{"Imperative mood","Perfect tense","Negative","Second person","Plural"}},
        {39,3,{"Imperative mood","Present tense","Positive","Third person","Plural"}},
        {39,4,{"Imperative mood","Present tense","Negative","Third person","Plural"}},
        {39,6,{"Imperative mood","Perfect tense","Positive","Third person","Plural"}},
        {39,7,{"Imperative mood","Perfect tense","Negative","Third person","Plural"}},
        {40,3,{"Imperative mood","Present tense","Positive","Passive"}},
        {40,4,{"Imperative mood","Present tense","Negative","Passive"}},
        {40,6,{"Imperative mood","Perfect tense","Positive","Passive"}},
        {40,7,{"Imperative mood","Perfect tense","Negative","Passive"}},
        {44,3,{"Potential mood","Present tense","Positive","First person","Singular"}},
        {44,4,{"Potential mood","Present tense","Negative","First person","Singular"}},
        {44,6,{"Potential mood","Perfect tense","Positive","First person","Singular"}},
        {44,7,{"Potential mood","Perfect tense","Negative","First person","Singular"}},
        {45,3,{"Potential mood","Present tense","Positive","Second person","Singular"}},
        {45,4,{"Potential mood","Present tense","Negative","Second person","Singular"}},
        {45,6,{"Potential mood","Perfect tense","Positive","Second person","Singular"}},
        {45,7,{"Potential mood","Perfect tense","Negative","Second person","Singular"}},
        {46,3,{"Potential mood","Present tense","Positive","Third person","Singular"}},
        {46,4,{"Potential mood","Present tense","Negative","Third person","Singular"}},
        {46,6,{"Potential mood","Perfect tense","Positive","Third person","Singular"}},
        {46,7,{"Potential mood","Perfect tense","Negative","Third person","Singular"}},
        {47,3,{"Potential mood","Present tense","Positive","First person","Plural"}},
        {47,4,{"Potential mood","Present tense","Negative","First person","Plural"}},
        {47,6,{"Potential mood","Perfect tense","Positive","First person","Plural"}},
        {47,7,{"Potential mood","Perfect tense","Negative","First person","Plural"}},
        {48,3,{"Potential mood","Present tense","Positive","Second person","Plural"}},
        {48,4,{"Potential mood","Present tense","Negative","Second person","Plural"}},
        {48,6,{"Potential mood","Perfect tense","Positive","Second person","Plural"}},
        {48,7,{"Potential mood","Perfect tense","Negative","Second person","Plural"}},
        {49,3,{"Potential mood","Present tense","Positive","Third person","Plural"}},
        {49,4,{"Potential mood","Present tense","Negative","Third person","Plural"}},
        {49,6,{"Potential mood","Perfect tense","Positive","Third person","Plural"}},
        {49,7,{"Potential mood","Perfect tense","Negative","Third person","Plural"}},
        {50,3,{"Potential mood","Present tense","Positive","Passive"}},
        {50,4,{"Potential mood","Present tense","Negative","Passive"}},
        {50,6,{"Potential mood","Perfect tense","Positive","Passive"}},
        {50,7,{"Potential mood","Perfect tense","Negative","Passive"}},
        {54,3,{"Nominal form","Infinitive","Active","First"}},
        {54,6,{"Nominal form","Participle","Active","Present tense"}},
        {54,7,{"Nominal form","Participle","Passive","Present tense"}},
        {55,3,{"Nominal form","Infinitive","Active","Long first"}},
        {55,6,{"Nominal form","Participle","Active","Past tense"}},
        {55,7,{"Nominal form","Participle","Passive","Past tense"}},
        {56,3,{"Nominal form","Infinitive","Active","Second","Inessive"}},
        {56,4,{"Nominal form","Infinitive","Passive","Second","Inessive"}},
        {56,6,{"Nominal form","Participle","Active","Agent"}},
        {57,3,{"Nominal form","Infinitive","Active","Second","Instructive"}},
        {57,4,{"Nominal form","Infinitive","Passive","Second","Instructive"}},
        {57,6,{"Nominal form","Participle","Active","Negative"}},
        {58,3,{"Nominal form","Infinitive","Active","Third","Inessive"}},
        {58,4,{"Nominal form","Infinitive","Passive","Third","Inessive"}},
        {59,3,{"Nominal form","Infinitive","Active","Third","Elative"}},
        {59,4,{"Nominal form","Infinitive","Passive","Third","Elative"}},
        {60,3,{"Nominal form","Infinitive","Active","Third","Illative"}},
        {60,4,{"Nominal form","Infinitive","Passive","Third","Illative"}},
        {61,3,{"Nominal form","Infinitive","Active","Third","Adessive"}},
        {61,4,{"Nominal form","Infinitive","Passive","Third","Adessive"}},
        {62,3,{"Nominal form","Infinitive","Active","Third","Abessive"}},
        {62,4,{"Nominal form","Infinitive","Passive","Third","Abessive"}},
        {63,3,{"Nominal form","Infinitive","Active","Third","Instructive"}},
        {63,4,{"Nominal form","Infinitive","Passive","Third","Instructive"}},
        {64,3,{"Nominal form","Infinitive","Active","Fourth","Nominative"}},
        {65,3,{"Nominal form","Infinitive","Active","Fourth","Partitive"}},
        {66,3,{"Nominal form","Infinitive","Active","Fifth"}},
    };

    if(!parsedTable.isEmpty()){
        foreach(const grammarform& gf_expectedcell, grammarforms){
            tablecell tc_current = parsedTable.first();
            while(tc_current.row < gf_expectedcell.row){
                if(!parsedTable.isEmpty()){
                    parsedTable.pop_front();
                    tc_current = parsedTable.first();
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
                    qDebug() << tc_current.content << gf_expectedcell.grammarexpressions;
                }
            }
        }
    }


/*    QFile file("debug_table.json");
    file.open(QFile::WriteOnly);
    file.write(j_document.toJson());
    file.close();*/
}


void grammarprovider::parse_fi_nominals(QNetworkReply* reply){
    QObject::disconnect(m_tmp_connection);
    QString s_reply = QString(reply->readAll());
    reply->deleteLater();

    QJsonDocument j_document = QJsonDocument::fromJson(s_reply.toUtf8());
    QString wikitemplate_text = j_document.object()["expandtemplates"].toObject()["wikitext"].toString();
    QList<grammarprovider::tablecell> parsedTable;
    parseMediawikiTableToPlainText(wikitemplate_text, parsedTable);

    struct grammarform {
        int row;
        int column;
        QList<QString> grammarexpressions;
    };
    QList<grammarform> grammarforms {
        {7,3,{"Nominative","Singular"}},
        {7,4,{"Nominative","Plural"}},
        {8,3,{"Accusative","Nominative","Singular"}},
        {8,4,{"Accusative","Nominative","Plural"}},
        {9,3,{"Accusative","Genitive","Singular"}},
        {10,3,{"Genitive","Singular"}},
        {10,4,{"Genitive","Plural"}},
        {11,3,{"Partitive","Singular"}},
        {11,4,{"Partitive","Plural"}},
        {12,3,{"Inessive","Singular"}},
        {12,4,{"Inessive","Plural"}},
        {13,3,{"Elative","Singular"}},
        {13,4,{"Elative","Plural"}},
        {14,3,{"Illative","Singular"}},
        {14,4,{"Illative","Plural"}},
        {15,3,{"Adessive","Singular"}},
        {15,4,{"Adessive","Plural"}},
        {16,3,{"Ablative","Singular"}},
        {16,4,{"Ablative","Plural"}},
        {17,3,{"Allative","Singular"}},
        {17,4,{"Allative","Plural"}},
        {18,3,{"Essive","Singular"}},
        {18,4,{"Essive","Plural"}},
        {19,3,{"Translative","Singular"}},
        {19,4,{"Translative","Plural"}},
        {20,3,{"Instructive","Singular"}},
        {20,4,{"Instructive","Plural"}},
        {21,3,{"Abessive","Singular"}},
        {21,4,{"Abessive","Plural"}},
        {22,3,{"Comitative","Singular"}},
        {22,4,{"Comitative","Plural"}},
        {25,2,{"Possessive","Singular","First person"}},
        {25,3,{"Possessive","Plural","First person"}},
        {26,2,{"Possessive","Singular","Second person"}},
        {26,3,{"Possessive","Plural","Second person"}},
        {27,2,{"Possessive","Singular","Plural","Third person"}},
    };
    if(!parsedTable.isEmpty()){
        foreach(const grammarform& gf_expectedcell, grammarforms){
            tablecell tc_current = parsedTable.first();
            while(tc_current.row < gf_expectedcell.row){
                if(!parsedTable.isEmpty()){
                    parsedTable.pop_front();
                    tc_current = parsedTable.first();
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
                    qDebug() << tc_current.content << gf_expectedcell.grammarexpressions;
                }
            }
        }
    }
}

@}
