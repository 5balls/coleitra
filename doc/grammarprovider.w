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
public slots:
    Q_INVOKABLE void getWiktionarySections();
    void getWiktionarySection(QNetworkReply* reply);
    void getWiktionaryTemplate(QNetworkReply* reply);
    void parse_fi_conj(QNetworkReply* reply);
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
    m_parser_map["fi-conj"] = &grammarprovider::parse_fi_conj;
}

grammarprovider::~grammarprovider() {
    delete m_manager;
}

void grammarprovider::getWiktionarySections(){
  /*
    QUrl url(s_baseurl + "action=parse&page=" + m_word + "&prop=sections&format=json");
    QNetworkRequest request(url);
    request.setRawHeader("User-Agent", "Coleitra/0.1 (https://coleitra.org; fpesth@@gmx.de)");
    m_tmp_connection = connect(m_manager, &QNetworkAccessManager::finished,
        this, &grammarprovider::getWiktionarySection);
    m_manager->get(request);*/
    qDebug() << "Read from file";
    parse_fi_conj(nullptr);// FIXME remove after debugging
}

void grammarprovider::getWiktionarySection(QNetworkReply* reply){
    QObject::disconnect(m_tmp_connection);
    QString s_reply = QString(reply->readAll());

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


void grammarprovider::parse_fi_conj(QNetworkReply* reply){

    QFile file("debug_table.json");
    file.open(QFile::ReadOnly);
    QString s_reply = file.readAll();
    file.close();


/*    QObject::disconnect(m_tmp_connection);
    QString s_reply = QString(reply->readAll());*/
    qDebug() << s_reply;
    QJsonDocument j_document = QJsonDocument::fromJson(s_reply.toUtf8());
    QString wikitemplate_text = j_document.object()["expandtemplates"].toObject()["wikitext"].toString();

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
        {10,3,{"Indicative mood","Present tense","Positive","First person","Plural"}},
        {10,4,{"Indicative mood","Present tense","Negative","First person","Plural"}},
        {10,6,{"Indicative mood","Perfect tense","Positive","First person","Plural"}},
        {10,7,{"Indicative mood","Perfect tense","Negative","First person","Plural"}},
        {11,3,{"Indicative mood","Present tense","Positive","Second person","Plural"}},
        {11,4,{"Indicative mood","Present tense","Negative","Second person","Plural"}},
        {11,6,{"Indicative mood","Perfect tense","Positive","Second person","Plural"}},
        {11,7,{"Indicative mood","Perfect tense","Negative","Second person","Plural"}},
        {12,3,{"Indicative mood","Present tense","Positive","Third person","Plural"}},
        {12,4,{"Indicative mood","Present tense","Negative","Third person","Plural"}},
        {12,6,{"Indicative mood","Perfect tense","Positive","Third person","Plural"}},
        {12,7,{"Indicative mood","Perfect tense","Negative","Third person","Plural"}},
        {100,100,{}}
    };

    QStringList table_lines = wikitemplate_text.split("\n");
    int column=0;
    int row=0;
    foreach(QString table_line, table_lines){
        grammarform current_grammarform = grammarforms.first();
        int columnspan = 0;
        auto process_line = [&columnspan](QString table_line){
            int colspan_i = table_line.indexOf("colspan=\"");
            if(colspan_i != -1){
                int colspan_j = table_line.indexOf("\"",colspan_i+9);
                columnspan += table_line.midRef(colspan_i+9,colspan_j-colspan_i-9).toInt()-1;
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
                        table_line += wiki_link.right(wiki_link.size()-tag_end);
                        table_line = table_line.left(table_line.size()-2);
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
            while(current_grammarform.row<row){
                if(!grammarforms.isEmpty()){
                    grammarforms.pop_front();
                    if(!grammarforms.isEmpty()){
                        current_grammarform = grammarforms.first();
                    }
                }
                else
                    break;
            }
            column=0;
            continue;
        }
        if(table_line.startsWith("!")){
            table_line.remove(0,2);
            column++;
            if(current_grammarform.row == row){
                while(current_grammarform.column<column){
                    if(!grammarforms.isEmpty()){
                        grammarforms.pop_front();
                        if(!grammarforms.isEmpty()){
                            current_grammarform = grammarforms.first();
                        }
                    }
                    else
                        break;
                }
            }
            table_line = process_line(table_line);
            if((current_grammarform.row == row)&&(current_grammarform.column == column)){
                foreach(const QString& grammarexpression, current_grammarform.grammarexpressions){

                    qDebug() << row << column << grammarexpression;
                }
            }
            qDebug() << "H" << row << column << table_line;
            column += columnspan;
            continue;
        }
        if(table_line.startsWith("|")){
            table_line.remove(0,2);
            column++;
            if(current_grammarform.row == row){
                while(current_grammarform.column<column){
                    if(!grammarforms.isEmpty()){
                        grammarforms.pop_front();
                        if(!grammarforms.isEmpty()){
                            current_grammarform = grammarforms.first();
                        }
                    }
                    else
                        break;
                }
            }
            table_line = process_line(table_line);
            if((current_grammarform.row == row)&&(current_grammarform.column == column)){
                foreach(const QString& grammarexpression, current_grammarform.grammarexpressions){

                    qDebug() << row << column << grammarexpression;
                }
            }
            qDebug() << "C" << row << column << table_line;
            column += columnspan;
            continue;
        }

    }
    qDebug() << "Read" << column << "lines";
/*    QFile file("debug_table.json");
    file.open(QFile::WriteOnly);
    file.write(j_document.toJson());
    file.close();*/
}

@}
