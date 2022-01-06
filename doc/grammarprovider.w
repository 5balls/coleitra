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

\chapter{Grammar provider}
This is an implementation of a grammar provider querying information from the API of \url{https://en.wiktionary.org}. There are other grammar providers planned later for obtaining grammar information from other sources but for now this is the only one.

\section{Schema file}
The definitions in the grammarprovider class are currently hardcoded. To make them better configurable and to give the user a possibility to extend the definitions (which is crucial) we define a JSON Schema file for configuration files.

@o ../src/grammarprovider_schema.json
@{
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "$id": "http://coleitra.org/schemas/grammarprovider",
  "title": "coleitra grammarprovider file format",
  "description": "A schema describing files for configuring the grammarprovider functionality for one language in the coleitra vocabletrainer program.",
  "type": "object",
  "additionalProperties": false,
  "properties": {
    "version": {
      "description": "Version number of the schema",
      "type": "string",
      "enum": [
        "0.1"
      ]
    },
    "base_url": {
      "description": "URL to base queries on",
      "type": "string",
      "default": "https://en.wiktionary.org/w/api.php?"
    },
    "inflectiontables": {
      "description": "List of inflection tables to assign grammar tags to specific forms of a word",
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "additionalProperties": false,
        "properties": {
          "tablename": {
            "description": "Unique name defining this table (used in coleitra program for quick selection.",
            "type": "string"
          },
          "identifiers": {
            "description": "Ídentifier for table required for obtaining it. In case of en.wiktionary.org this is the mediawiki template name of the inflection table.",
            "type": "array",
            "items": {
              "type": "string"
            },
            "minItems": 1
          },
          "cells": {
            "description": "Array of instructions how to parse cells in table",
            "type": "array",
            "items": {
              "description": "How to parse this particular cell",
              "type": "object",
              "additionalProperties": false,
              "properties": {
                "index": {
                  "description": "Index of cell, i.e. to describe in which order the forms are going to be processed. This is important if some cells depent on other cells in the same table. If no index is given, the next free index - starting from 1 is used which may not be what you want. Unless you don't do any reordering (in which case you can omit all indices) you should probably give all cells indices.",
                  "type": "number"
                },
                "row": {
                  "description": "Row of cell in table",
                  "type": "number"
                },
                "column": {
                  "description": "Column of cell in table",
                  "type": "number"
                },
                "grammarexpressions": {
                  "$ref": "#/$defs/grammarexpressions"
                },
                "content_type": {
                  "description": "Describes content type of this cell. This is only necessary to give, if the contents of this cell shall be further processed, for example if the cell contains multiple words.",
                  "type": "string",
                  "enum": [
                    "FORM",
                    "FORM_WITH_IGNORED_PARTS",
                    "COMPOUNDFORM",
                    "SENTENCE"
                  ]
                },
                "process": {
                  "description": "List of instructions how to process contents of this cell. If given, content_type also is required.",
                  "type": "array",
                  "minItems": 1,
                  "items": {
                    "type": "object",
                    "additionalProperties": false,
                    "properties": {
                      "instruction": {
                        "description": "Instruction, how to interpret and what to do with the contents of the cell",
                        "type": "string",
                        "enum": [
                          "IGNOREFORM",
                          "LOOKUPFORM",
                          "LOOKUPFORM_LEXEME",
                          "ADDANDUSEFORM",
                          "ADDANDIGNOREFORM"
                        ]
                      },
                      "grammarexpressions": {
                        "$ref": "#/$defs/grammarexpressions"
                      }
                    },
                    "required": [
                      "instruction"
                    ]
                  }
                }
              },
              "required": [
                "row",
                "column",
                "grammarexpressions"
              ]
            },
            "minItems": 1
          }
        },
        "minItems": 1,
        "required": [
          "tablename",
          "identifiers",
          "cells"
        ]
      }
    }
  },
  "required": [
    "version",
    "base_url"
  ],
  "$defs": {
    "grammarexpressions": {
      "description": "Grammar expressions which fit the cell",
      "type": "object",
      "properties": {
        "format": {
          "type": "string",
          "enum": [
            "coleitra",
            "Universal Dependencies"
          ]
        },
        "version": {
          "type": "string"
        },
        "tags": {
          "type": "object"
        }
      },
      "allOf": [
        {
          "if": {
            "properties": {
              "format": {
                "const": "coleitra"
              }
            }
          },
          "then": {
            "properties": {
              "version": {
                "enum": [
                  "0.1"
                ]
              }
            },
            "if": {
              "properties": {
                "version": {
                  "const": "0.1"
                }
              }
            },
            "then": {
              "properties": {
                "tags": {
                  "additionalProperties": false,
                  "properties": {
                    "Case": {
                      "type": "string",
                      "enum": [
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
                        "Genitive",
                        "Illative",
                        "Inessive",
                        "Infinitive",
                        "Instructive",
                        "Instrumental",
                        "Locative",
                        "Nominative",
                        "Partitive",
                        "Possessive",
                        "Prolative",
                        "Sociative",
                        "Sublative",
                        "Superessive",
                        "Terminative",
                        "Translative",
                        "Vocative"
                      ]
                    },
                    "Voice": {
                      "type": "string",
                      "enum": [
                        "Active",
                        "Passive"
                      ]
                    },
                    "Gender": {
                      "type": "string",
                      "enum": [
                        "Feminine",
                        "Masculine",
                        "Neuter"
                      ]
                    },
                    "Number": {
                      "type": "string",
                      "enum": [
                        "Singular",
                        "Plural"
                      ]
                    },
                    "Tense": {
                      "type": "string",
                      "enum": [
                        "Future",
                        "Future 1",
                        "Future 2",
                        "Past",
                        "Perfect",
                        "Plusquamperfect",
                        "Present",
                        "Preterite",
                        "Agent"
                      ]
                    },
                    "Mood": {
                      "type": "string",
                      "enum": [
                        "Imperative",
                        "Indicative",
                        "Potential",
                        "Subjunctive",
                        "Subjunctive 1",
                        "Subjunctive 2",
                        "Optative"
                      ]
                    },
                    "Part of speech": {
                      "type": "string",
                      "enum": [
                        "Noun",
                        "Verb",
                        "Adjective",
                        "Adverb",
                        "Pronoun",
                        "Preposition",
                        "Conjunction",
                        "Interjection",
                        "Numeral",
                        "Article",
                        "Determiner",
                        "Postposition"
                      ]
                    },
                    "Person": {
                      "type": "string",
                      "enum": [
                        "First",
                        "Second",
                        "Third"
                      ]
                    },
                    "Polarity": {
                      "type": "string",
                      "enum": [
                        "Negative",
                        "Positive"
                      ]
                    },
                    "Infinitive": {
                      "type": "string",
                      "enum": [
                        "First",
                        "Long first",
                        "Second",
                        "Third",
                        "Fourth",
                        "Fifth"
                      ]
                    },
                    "Verbform": {
                      "type": "string",
                      "enum": [
                        "Participle",
                        "Auxiliary",
                        "Connegative"
                      ]
                    }
                  }
                }
              }
            }
          }
        },
        {
          "if": {
            "properties": {
              "format": {
                "const": "Universal Dependencies"
              }
            }
          },
          "then": {
            "properties": {
              "version": {
                "enum": [
                  "2"
                ]
              }
            }
          }
        }
      ],
      "additionalProperties": false
    }
  }
}
@}

@i grammarprovider_support_status.w

\section{Helper scripts}
\subsection{Get templates}

This helper script queries recursively for template pages and can be used to create the status lists for the various languages above. Executable flag needs to be set manually (nuweb does not seem to provide the option to set this flags in the source documentation).

@o ../src/scripts/get_templates.py
@{#!/usr/bin/python3

import sys
import requests

def get_categorymembers(categorytitle):
    session = requests.Session()
    cm_params = {
        "action": "query",
        "format": "json",
        "list": "categorymembers",
        "cmtitle": categorytitle,
        "cmlimit": 500
    }

    request = session.get(url="https://en.wiktionary.org/w/api.php", params=cm_params)
    data = request.json()
    categorymembers = data["query"]["categorymembers"]

    for page in categorymembers:
        pagetitle = page["title"]
        pagetitlesplit = pagetitle.split(":",1)
        if pagetitlesplit[0] == "Category":
            get_categorymembers(pagetitle)
        elif pagetitlesplit[0] == "Template":
            print(pagetitlesplit[1])


get_categorymembers("Category:" + str(sys.argv[1]))
@}

\subsection{Get examples}

This helper script get the first 10 pages using the template page. Executable flag needs to be set manually (nuweb does not seem to provide the option to set this flags in the source documentation).

@o ../src/scripts/get_examples.py
@{#!/usr/bin/python3

import sys
import requests

def get_examples(categorytitle):
    session = requests.Session()
    cm_params = {
        "action": "query",
        "format": "json",
        "list": "embeddedin",
        "eititle": categorytitle,
        "eilimit": 10
    }

    request = session.get(url="https://en.wiktionary.org/w/api.php", params=cm_params)
    data = request.json()
    embeddedin = data["query"]["embeddedin"]

    for page in embeddedin:
        pagetitle = page["title"]
        print(pagetitle)


get_examples("Template:" + str(sys.argv[1]))
@}

\section{Network queries}
The API of wiktionary is used to avoid unneccessary network traffic. We never ask for the whole page but only for the parts which we need for the information we desire.

First \verb#getWiktionarySections()# gets a json Object containing all the sections of the wiktionary page. This sections are searched for the current language, e.g. ``Finnish'' for example. Then this language section is searched for an etymology section. If this etymology section exists, we request this section with \verb#getWiktionarySection()# and check to see if it contains a compound template. If we find a compound template, depending on the status of the database we recursively request the words making up the compound (if the word is in the database already we link to it instead).

After the etymology section is parsed we look for flection sections, i.e. ``Conjugation'' or ``Declination''. Again we get the contents of this sections by calling \verb#getWiktionarySection()# and if we can identify a template we call additionaly \verb#getWiktionaryTemplate# to expand the template with the arguments we find (this will practically render the html form of this particular part of the webpage). We call the appropriate parsing function for this template and process the grammar information we obtain this way.

In the following sequence diagram error handling is not shown to keep it managable. Whenever there is a fatal error the appropriate signals are sent to the caller. Signals are also sent, whenever we can obtain a valid grammar object.

\begin{figure}
\centering
\begin{sequencediagram}
\newthread{sections}{getWiktionarySections()}
\newthread{section}{getWiktionarySection()}
\newthread{template}{getWiktionaryTemplate()}
\newthread{network}{Network Thread}
\newthread{parsetemplate}{Parse Template}
\mess{sections}{requestNetworkReply}{network}
\begin{call}{section}{possible retry}{section}{}
\end{call}
\mess{network}{success}{section}
\begin{sdblock}{Etymology}{Found section}
\begin{call}{section}{requestNetworkReply}{network}{blocking wait}
\begin{call}{template}{possible retry}{template}{}
\end{call}
\mess{network}{success}{template}
\begin{sdblock}{Compound}{Found compound}
\begin{call}{template}{}{sections}{\shortstack{This is a recursive call, so it starts again from the\\
beginning until unlocking the blocking wait}}
\postlevel
\end{call}
\end{sdblock}
\end{call}
\end{sdblock}
\begin{sdblock}{Flection}{Found section}
\mess{section}{requestNetworkReply}{network}
\begin{call}{template}{possible retry}{template}{}
\end{call}
\mess{network}{success}{template}
\mess{template}{requestNetworkReply}{network}
\mess{network}{success}{parsetemplate}
\end{sdblock}
\end{sequencediagram}
\caption{Network queries in grammar provider}
\end{figure}

\begin{figure}
\centering
\begin{tikzpicture}
\tikzflowchart
\node [proc, start chain=1, fill=white] (p1) {getGrammarInfoForWord};
\node [term, join] (p2) {getWiktionarySections};
\node [term, join=by sig, right=of p2] (p3) {getWiktionarySection};
\node [test, join] (p4) {Etymology?};
\node [term, join=by sig, right=of p4] (p5) {getWiktionaryTemplate};
\node [test, join, fill=white] (p5a) {Found template?};
\node [test, join, below=18ex of p5a, fill=white] (p6) {Compoundform?};
\node [term, join, below=18ex of p6, fill=white] (p7) {parse\_compoundform};
\node [wait, join, text width=5cm, fill=white] (p8) {Wait for grammarInfoComplete or grammarInfoNotAvailable};
\node [emit, join, fill=yellow!40] (p9) {emit grammarInfoComplete};
\node [term, below=2cm of p9] (p19) {Template not supported};
\node [emit, join, fill=red!40] (p21) {emit grammarInfoNotAvailable};
\node [left=0.75cm of p6] {no};
\node [right=0.75cm of p5a] {no};
\node [term, left=of p7, text width=4cm] (p14) {\ldots continue getWiktionaryTemplate};
\node [term, join=by sig, left=of p14, text width=4cm] (p15) {Language specific parse function};
\node [term, join] (p16) {process\_grammar};
\node [emit, join, fill=orange!40] (p17a) {emit processedGrammar};
\node [emit, join, fill=green!40] (p18) {emit grammarInfoAvailable};
\node [wait, below=of p4, left=of p5a, text width=5cm, fill=white] (p10) {Wait for grammarInfoComplete or grammarInfoNotAvailable};
\draw [->, norm] (p4) to (p10);
\node [test, below=14ex of p10, join] (p11) {Found language?};
\node [emit, join, fill=red!40] (p13) {emit grammarInfoNotAvailable};
\begin{pgfonlayer}{bg} 
    \draw [->, sig] (p11.east) to [out=0, in=-90] node[above, rotate=45] {yes}  (p5.200);
    \draw [->, norm] (p6.west) to [out=180, in=90] (p14.north);
    \draw [->, norm] (p5a.east) to [out=0, in=90] (p19.north);
    \draw [->, norm] (p7.east) to [out=0, in=0] ($(p2)+(10cm,1cm)$) to [out=180, in=45] (p2.45);
    \draw [draw=none] (p4) to node[above] {yes} node[var,below=0.2cm] {m\_caller \nodepart{second} waitloop} (p5);
    \draw [draw=none] (p4) to node[right] {yes} (p10);
    \draw [->, norm] (p4.west) to [out=180, in=180] node[left] {no} (p11.west);
    \draw [draw=none] (p11) to node[right] {no} (p13);
    \draw [draw=none] (p6) to node[right] {yes} (p7);
    \draw [draw=none] (p5a) to node[right] {yes} (p6);
\end{pgfonlayer}
\end{tikzpicture}
\caption{Flow chart of inner workings of grammarprovider class}
\end{figure}

\section{Interface}
@O ../src/grammarprovider.h -d
@{
@<Start of @'GRAMMARPROVIDER@' header@>
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
#include "settings.h"
#include "database.h"
#include "levenshteindistance.h"
#include "networkscheduler.h"

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
public slots:
    Q_INVOKABLE void getGrammarInfoForWord(QObject* caller, int languageid, QString word);
    Q_INVOKABLE void getNextGrammarObject(QObject* caller);
    Q_INVOKABLE void getNextSentencePart(QObject* caller);
private slots:
    QList<grammarprovider::compoundPart> getGrammarCompoundFormParts(QString compoundword, QList<QString> compoundstrings, int id_language);
    void getWiktionarySections(QObject *caller);
    void getWiktionarySection(QString reply, QObject* caller);
    void getWiktionaryTemplate(QString reply, QObject* caller);
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

@<End of class and header @>
@}

\section{Implementation}
@O ../src/grammarprovider.cpp -d
@{
#include "grammarprovider.h"
#include <sstream>
#include <iostream>
@}

\cprotect[om]\subsection[grammarprovider]{\verb#grammarprovider#}
@O ../src/grammarprovider.cpp -d
@{
grammarprovider::grammarprovider(QObject *parent) : QObject(parent), m_busy(false)
{
    s_baseurl = "https://en.wiktionary.org/w/api.php?";
    QQmlEngine* engine = qobject_cast<QQmlEngine*>(parent);
    m_settings = engine->singletonInstance<settings*>(qmlTypeId("SettingsLib", 1, 0, "Settings"));
    m_database = engine->singletonInstance<database*>(qmlTypeId("DatabaseLib", 1, 0, "Database"));
    m_levenshteindistance = engine->singletonInstance<levenshteindistance*>(qmlTypeId("LevenshteinDistanceLib", 1, 0, "LevenshteinDistance"));
    m_networkscheduler = engine->singletonInstance<networkscheduler*>(qmlTypeId("NetworkSchedulerLib", 1, 0, "NetworkScheduler"));
    connect(m_networkscheduler, &networkscheduler::requestFailed, this, &grammarprovider::processNetworkError);
    m_parsesections.push_back("Conjugation");
    m_parsesections.push_back("Declension");
    int fi_id = m_database->idfromlanguagename("Finnish");
    m_requirements_map[fi_id] = &grammarprovider::fi_requirements;
    m_compound_parser_map[fi_id] = &grammarprovider::fi_compound_parser;
    int de_id = m_database->idfromlanguagename("German");
    m_requirements_map[de_id] = &grammarprovider::de_requirements;
    m_parser_map["compound"] = &grammarprovider::parse_compoundform;
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
    m_parser_map["fi-conj-olla"] = &grammarprovider::parse_fi_verbs;
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
    m_parser_map["de-conj"] = &grammarprovider::parse_de_verb;
}
@}

\cprotect\subsection{\verb#~grammarprovider#}
@O ../src/grammarprovider.cpp -d
@{
grammarprovider::~grammarprovider() {
}
@}

\cprotect\subsection{\verb#getGrammarInfoForWord#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getGrammarInfoForWord(QObject* caller, int languageid, QString word){
    if(m_busy == true){
        m_scheduled_lookups.push_back({caller,languageid,word});
        qDebug() << "Grammarprovider is busy... " + QString::number(m_scheduled_lookups.size()) + " requests waiting";
        return;
    }
    m_busy = true;
    // TODO: Add timeout in case lookup is not successfull
    // Check requirements:
    m_found_compoundform = false;
    emit processingUpdate("Checking requirements for language " + QString::number(languageid));
    if(m_requirements_map.contains(languageid))
        (this->*(m_requirements_map[languageid]))(caller,languageid);
    //qDebug() << "...requirements done";
    m_language = languageid;
    m_word = word;
    m_silent = false;
    m_found_compoundform = false;
    /* We block here with an event loop, because we want to send an signal,
       when we are finished */
    QEventLoop waitloop;
    QMetaObject::Connection gia_con;
    QMetaObject::Connection gina_con;
    QMetaObject::Connection ne_con;
    gia_con = connect(this, &grammarprovider::grammarInfoAvailable,
            [&](QObject* caller, int size, bool silent){
            if(caller == &waitloop){
            //qDebug() << "Got grammarInfoComplete signal in lambda function for getGrammarInfoForWord" << m_word << caller;
            disconnect(gia_con);
            disconnect(gina_con);
            disconnect(ne_con);
            waitloop.quit();
            }
            });
    gina_con = connect(this, &grammarprovider::grammarInfoNotAvailable,
            [&](QObject* caller, bool silent){
            if(caller == &waitloop){
            //qDebug() << "Got grammarInfoNotComplete signal in lambda function for getGrammarInfoForWord" << m_word << caller;
            disconnect(gia_con);
            disconnect(gina_con);
            disconnect(ne_con);
            emit noGrammarInfoForWord(caller, m_silent);
            waitloop.quit();
            }
            });
    ne_con = connect(m_networkscheduler, &networkscheduler::requestFailed,
            [&](QObject* caller, QString s_reason){
            if(caller == &waitloop){
            //qDebug() << "Got requestFailed signal" << s_reason << "in lambda function for getGrammarInfoForWord" << m_word << caller;
            disconnect(gia_con);
            disconnect(gina_con);
            disconnect(ne_con);
            emit noGrammarInfoForWord(caller, m_silent);
            waitloop.quit();
            }
            });

    getWiktionarySections(&waitloop);

    //qDebug() << "Blocking waitloop" << &waitloop << "for getGrammarInfoForWord" << m_word << "...";
    waitloop.exec();
    //qDebug() << "... blocking waitloop for" << m_word << "finished.";
    /* This doesn't work here, don't know why:
       emit processingUpdate("Processing " + QString::number(m_grammarforms.size()) + " grammar forms...");
     */
    emit gotGrammarInfoForWord(caller, m_grammarforms.size(), m_silent);
    //qDebug() << "getGrammarInfoForWord finished!";
}
@}

\cprotect\subsection{\verb#getWiktionarySections#}

\tododocument{Error handling for network requests}

\codecpp
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getWiktionarySections(QObject* caller){
    static int numberofcalls=0;
    emit processingUpdate("Lookup word " + m_word + " on en.wiktionary.org");
    //qDebug() << "---- getWiktionarySections number of calls" << numberofcalls++;
    //qDebug() << "getWiktionarySections enter";
    /* I suspect it doesn't hurt to get a new lexeme id here - as any group of
       forms belonging together will have to pass through here and it won't
       hurt to skip a few id's here. */
    lexemeId();
    m_networkscheduler->requestNetworkReply(caller, s_baseurl + "action=parse&page=" + m_word + "&prop=sections&format=json", std::bind(&grammarprovider::getWiktionarySection,this,std::placeholders::_1, caller));

    //qDebug() << "getWiktionarySections exit";
}
@}

\cprotect\subsection{\verb#getWiktionarySection#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getWiktionarySection(QString s_reply, QObject* caller){
    //qDebug() << "getWiktionarySection enter";
        
    //qDebug() << s_reply;

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
        ms_current_section = s_section;
        section_level = j_section["level"].toString().toInt();
        if(section_level <= language_section_level) break;
        //qDebug() << "Section" << s_section << "language" << language;
        if(s_section == language){
            found_language = true;
            best_bet_for_section = j_section["index"].toString().toInt();
            language_section_level = section_level;
        }
        else{
            if(found_language){
                int l_found_compoundform = m_found_compoundform;
                templatearguments l_currentarguments = m_currentarguments;
                QList<QString> l_current_compoundforms = m_current_compoundforms;
                if(s_section == "Etymology"){
                    //qDebug() << "Found etymology section";
                    // Check, if this is a compund word
                    /* Store state (restored at end of scope): */
                    context save_state(this);
                    /* If there is any compound part it should be
                       added silently. */
                    m_silent = true;
                    /* Block this function until we have figured out
                       that either this is not a compound word or we
                       have obtained all compound forms */
                    QEventLoop waitloop;
                    //qDebug() << __FILE__ << __FUNCTION__ << __LINE__ << &waitloop;
                    /* We have to check for the caller pointer because
                       this might get recursive */
                    QMetaObject::Connection gic_con;
                    QMetaObject::Connection gina_con;
                    QMetaObject::Connection ne_con;
                    gic_con = connect(this, &grammarprovider::grammarInfoComplete,
                            [&](QObject* caller, bool silent){
                                if(caller == &waitloop){
                                    //qDebug() << "Got grammarInfoComplete signal in lambda function for etymology section" << m_word << caller;
                                    disconnect(gic_con);
                                    disconnect(gina_con);
                                    disconnect(ne_con);
                                    waitloop.quit();
                                }
                            });
                    gina_con = connect(this, &grammarprovider::grammarInfoNotAvailable,
                            [&](QObject* caller, bool silent){
                                if(caller == &waitloop){
                                    //qDebug() << "Got grammarInfoNotAvailable signal in lambda function for etymology section" << m_word << caller;
                                    disconnect(gic_con);
                                    disconnect(gina_con);
                                    disconnect(ne_con);
                                    waitloop.quit();
                                }
                            });
                    ne_con = connect(m_networkscheduler, &networkscheduler::requestFailed,
                            [&](QObject* caller, QString s_reason){
                                if(caller == &waitloop){
                                    //qDebug() << "Got requestFailed signal" << s_reason << "in lambda function for etymology section" << m_word << caller;
                                    disconnect(gic_con);
                                    disconnect(gina_con);
                                    disconnect(ne_con);
                                    waitloop.quit();
                                }
                            });
                    best_bet_for_section = j_section["index"].toString().toInt();
                    m_networkscheduler->requestNetworkReply(&waitloop,s_baseurl + "action=parse&page=" + m_word + "&section=" + QString::number(best_bet_for_section) + "&prop=wikitext&format=json", std::bind(&grammarprovider::getWiktionaryTemplate,this,std::placeholders::_1,&waitloop));
                    //qDebug() << "Blocking waitloop for" << m_word << "...";
                    waitloop.exec();
                    //qDebug() << "... blocking waitloop for" << m_word << "finished.";
                    l_found_compoundform = m_found_compoundform;
                    l_currentarguments = m_currentarguments;
                    foreach(QString arg, l_currentarguments.unnamed){
                        //qDebug() << "Blocking loop came back with arg" << arg;
                    }
                    l_current_compoundforms = m_current_compoundforms;
                }
                m_found_compoundform = l_found_compoundform;
                m_currentarguments = l_currentarguments;
                m_current_compoundforms = l_current_compoundforms;
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
        //qDebug() << "Found language section \"" + language + "\" for word \"" + m_word + "\"";
        m_networkscheduler->requestNetworkReply(caller,s_baseurl + "action=parse&page=" + m_word + "&section=" + QString::number(best_bet_for_section) + "&prop=wikitext&format=json", std::bind(&grammarprovider::getWiktionaryTemplate,this,std::placeholders::_1,caller));
    }
    else{
        //qDebug() << "Could not find language section \"" + language + "\" for word \"" + m_word + "\"";
        m_busy = false;
        emit grammarInfoNotAvailable(caller, m_silent);
        return;
    }
    //qDebug() << "getWiktionarySection exit";
}
@}

\cprotect\subsection{\verb#parseTemplateArguments#}
@O ../src/grammarprovider.cpp -d
@{
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
            //qDebug() << keyval.first() << "=" << keyval.last();
        }
        else {
            parsed_args.unnamed.push_back(arg);
            //qDebug() << arg;
        }
    }
    return parsed_args;
}
@}

\cprotect\subsection{\verb#getWiktionaryTemplate#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getWiktionaryTemplate(QString s_reply, QObject* caller){
 
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
    QMapIterator<QString, void (grammarprovider::*)(QString, QObject*)> parser(m_parser_map); 
    while (parser.hasNext()) {
        parser.next();
        foreach(const QString& wt_finished, wt_finisheds){
            if(wt_finished.startsWith("{{" + parser.key())){
                if(parser.key() == "compound"){
                    m_currentarguments = parseTemplateArguments(wt_finished);
                    m_found_compoundform = true;
                    parse_compoundform("",caller);
                }
                else{
                    m_currentarguments = parseTemplateArguments(wt_finished);
                    m_networkscheduler->requestNetworkReply(caller,s_baseurl + "action=expandtemplates&text=" + QUrl::toPercentEncoding(wt_finished) + "&title=" + m_word + "&prop=wikitext&format=json", std::bind(parser.value(),this,std::placeholders::_1,caller));
                }
                return;
            }
        }
    }
    //qDebug() << "Template(s)" << wt_finisheds << "not supported!";
    emit grammarInfoNotAvailable(caller, m_silent);
}
@}

\cprotect\subsection{\verb#parseMediawikiTableToPlainText#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::parseMediawikiTableToPlainText(QString wikitext, QList<grammarprovider::tablecell>& table){
    QStringList table_lines = wikitext.split("\n");
    int column=0;
    int row=0;
    int rowspan=0;
    foreach(QString table_line, table_lines){
        int columnspan = 0;
        auto process_line = [&columnspan,&rowspan](QString table_line){
            //qDebug() << "__P 0 (input)" << table_line;
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
            //qDebug() << "__P 1 (removed wiki braces)" << table_line;
            table_line.remove(QRegularExpression("<sup.*?<\\/sup>"));
            //qDebug() << "__P 2 (removed sup)" << table_line;
	    table_line.replace(QString("<br/>"),QString(","));
	    table_line.replace(QString("<br />"),QString(","));
            //qDebug() << "__P 3" << table_line;
            QStringList html_markupstrings = table_line.split("<");
            if(html_markupstrings.size() > 1){
                table_line = "";
                foreach(QString html_markupstring, html_markupstrings){
                    int tag_end = html_markupstring.indexOf(">");
                    html_markupstring.remove(0,tag_end+1);
                    table_line += html_markupstring;
                }
            }
            //qDebug() << "__P 4" << table_line;
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
            //qDebug() << "__P 6" << table_line;
            table_line.remove("(");
            table_line.remove(")");
            //qDebug() << "__P 7" << table_line;
            table_line = table_line.trimmed();
            //qDebug() << "__P 8" << table_line;
            QTextDocument text;
            text.setHtml(table_line);
            table_line = text.toPlainText();
            //qDebug() << "__P 9" << table_line;
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
            //qDebug() << "__P 10" << table_entries;
            foreach(QString table_entry, table_entries){
                table_entry = table_entry.trimmed();
                if(!table_entry.isEmpty())
                    table.push_back({row,column,table_entry});
                //qDebug() << row << column << table_entry;
            }
            column += columnspan;
            continue;
        }
        if(table_line.startsWith("|")){
            table_line.remove(0,2);
            column++;
            table_line = process_line(table_line);
	    QStringList table_entries = table_line.split(QLatin1Char(','));
            //qDebug() << "__P 10" << table_entries;
            foreach(QString table_entry, table_entries){
                table_entry = table_entry.trimmed();
                if(!table_entry.isEmpty())
                    table.push_back({row,column,table_entry});
                //qDebug() << row << column << table_entry;
            }
            column += columnspan;
            continue;
        }
    }
}
@}

\cprotect\subsection{\verb#process_grammar#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::process_grammar(QObject* caller, QList<grammarform> grammarforms, QList<tablecell> parsedTable, QList<QList<QString> > additional_grammarforms){
    QList<grammarform> l_grammarforms;
    lexemeId();
    if(!parsedTable.isEmpty()){
        foreach(const grammarform& gf_expectedcell, grammarforms){
            tablecell tc_current = parsedTable.first();
            //qDebug() << "__PG 0" << tc_current.row << tc_current.column << tc_current.content << "exp:" << gf_expectedcell.row << gf_expectedcell.column;
            while(tc_current.row < gf_expectedcell.row){
                if(!parsedTable.isEmpty()){
                    parsedTable.pop_front();
                    if(!parsedTable.isEmpty()){
                        tc_current = parsedTable.first();
                        //qDebug() << "__PG 1" << tc_current.row << tc_current.column << tc_current.content << "exp:" << gf_expectedcell.row << gf_expectedcell.column;
                    }
                    else goto out;
                }
                else break;
            }
            if(tc_current.row == gf_expectedcell.row){
                while(tc_current.column < gf_expectedcell.column){
                    if(!parsedTable.isEmpty()){
                        parsedTable.pop_front();
                        if(!parsedTable.isEmpty()){
                            tc_current = parsedTable.first();
                            //qDebug() << "__PG 2" << tc_current.row << tc_current.column << tc_current.content << "exp:" << gf_expectedcell.row << gf_expectedcell.column;
                        }
                        else goto out;
                    }
                    else break;
                }
                if(tc_current.column == gf_expectedcell.column){
matching_form:
                    if(tc_current.content != "—"){
                        //qDebug() << "__PG A" << tc_current.row << tc_current.column << tc_current.content << "exp:" << gf_expectedcell.row << gf_expectedcell.column;
                        grammarform currentGrammarForm = gf_expectedcell;
                        currentGrammarForm.string = tc_current.content;
                        currentGrammarForm.grammarexpressions += additional_grammarforms;
                        currentGrammarForm.language_id = m_language;
                        currentGrammarForm.b_silent = m_silent;
                        if(m_found_compoundform){
                            currentGrammarForm.compounds = getGrammarCompoundFormParts(currentGrammarForm.string, m_current_compoundforms, m_language);
                        }
                        currentGrammarForm.id = formId();
                        currentGrammarForm.lexeme_id = m_lexemeId;
                        l_grammarforms.push_back(currentGrammarForm);
                        // There may be more than one:
                        parsedTable.pop_front();
                        if(!parsedTable.isEmpty()){
                            tc_current = parsedTable.first();
                            //qDebug() << "__PG 3" << tc_current.row << tc_current.column << tc_current.content << "exp:" << gf_expectedcell.row << gf_expectedcell.column;
                        }
                        else goto out;
                        // A "while" would be worse than this "goto" as it would
                        // have to include or treat the column search again.
                        if(tc_current.row == gf_expectedcell.row)
                            if(tc_current.column == gf_expectedcell.column){
                                //qDebug() << "__PG E going back...";
                                goto matching_form;
                            }
                        //qDebug() << "__PG E not going back!";
                    }
                }
            }
        }
    }
out:
    std::sort(l_grammarforms.begin(), l_grammarforms.end(), [](grammarform a, grammarform b) {
        return a.index < b.index;
    });
    m_grammarforms += l_grammarforms;
    mi_grammarforms += l_grammarforms;
    //qDebug() << "Got" << m_grammarforms.size();

    emit processedGrammar(caller,m_silent);
    emit grammarInfoAvailable(caller, m_grammarforms.size(), m_silent);
    //emit grammarobtained(m_caller, expressions, grammarexpressions);
}
@}

\cprotect\subsection{\verb#getNextGrammarObject#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getNextGrammarObject(QObject* caller){
    //qDebug() << "grammarprovider::getNextGrammarObject enter";
    if(m_grammarforms.isEmpty()){
        //qDebug() << __FUNCTION__ << __LINE__ << "*** grammarInfoComplete EMIT ***";
        emit grammarInfoComplete(caller,m_silent);
        if(!m_scheduled_lookups.isEmpty()){
            scheduled_lookup next_lookup = m_scheduled_lookups.first();
            m_scheduled_lookups.removeFirst();
            m_busy = false;
            getGrammarInfoForWord(next_lookup.m_caller, next_lookup.m_languageid, next_lookup.m_word);
        }
        else {
            m_busy = false;
        }
        //qDebug() << "grammarprovider::getNextGrammarObject exit" << __LINE__;
    }
    else{
        QMutableListIterator<grammarform> grammarFormI(m_grammarforms);
        grammarform& form = grammarFormI.next();
        grammarform form2 = form;
        //qDebug() << "form.string" << form.string;
        switch(form.type){
            case FORM:
                {
                    //qDebug() << form.index << form.string << "FORM" << form.grammarexpressions;
                    if(!m_grammarforms.isEmpty())
                        m_grammarforms.removeFirst();
                    else 
                        qDebug() << "ERROR m_grammarforms is empty!" << __LINE__;
                    {
                       // qDebug() << __FUNCTION__ << __LINE__ << "*** formObtained EMIT ***";
                        emit formObtained(caller, form2.b_silent, form2);
                    }
                    //qDebug() << "grammarprovider::getNextGrammarObject exit" << __LINE__;
                    return;
                }
                break;
            case FORM_WITH_IGNORED_PARTS:
                {
                    QList<QList<QString > > ge = form.grammarexpressions;
                    QStringList formparts = form.string.split(QLatin1Char(' '));
                    if(formparts.size() == form.processList.size()){
                        int formparti = 0;
                        foreach(const QString& formpart, formparts){
                            switch(form.processList.at(formparti).instruction){
                                case IGNOREFORM:
                                    //qDebug() << "IGNOREFORM" << formpart;
                                    break;
                                case LOOKUPFORM:
                                    //qDebug() << "LOOKUPFORM" << formpart;
                                    break;
                                case LOOKUPFORM_LEXEME:
                                    //qDebug() << "LOOKUPFORM_LEXEME" << formpart;
                                    break;
                                case ADDANDUSEFORM:
                                    //qDebug() << "ADDANDUSEFORM" << formpart;
                                    if(!m_grammarforms.isEmpty())
                                        m_grammarforms.removeFirst();
                                    else 
                                        qDebug() << "ERROR m_grammarforms is empty!" << __LINE__;
                                    {
                                        //qDebug() << __FUNCTION__ << __LINE__ << "*** formObtained EMIT ***";
                                        grammarform formpart_form = form2;
                                        formpart_form.string = formpart;
                                        emit formObtained(caller, formpart_form.b_silent, formpart_form);
                                    }
                                    // return needed here to be reentrant:
                                    return;
                                    break;
                                case ADDANDIGNOREFORM:
                                    break;
                            }
                            formparti++;
                        }
                    }
                    else {
                        qDebug() << "Process list size (=" + QString::number(form.processList.size()) +  ") does not match number of form parts (=" + formparts.size() + ")!";
                    }
                }
                break;
            case COMPOUNDFORM:
                //qDebug() << __FILE__ << __LINE__ << __FUNCTION__;
                //qDebug() << form.index << form.string << "COMPOUNDFORM" << form.grammarexpressions;
                break;
            case SENTENCE:
                //qDebug() << form.index << form.string << "SENTENCE" << form.grammarexpressions;
                {
                    QStringList sentenceparts = form.string.split(QLatin1Char(' '));
                    if(sentenceparts.size() == form.processList.size()){
                        //Preprocess sentence:
                        QMutableListIterator<lexemePartProcess> lexemeProcessI(form.processList);
                        int sentencepartid = 0;
                        while(lexemeProcessI.hasNext()){
                            lexemePartProcess& currentProcess = lexemeProcessI.next();
                            if(currentProcess.instruction == ADDANDUSEFORM){
                                //qDebug() << "ADDANDUSEFORM for part" << sentenceparts.at(sentencepartid) << sentencepartid << currentProcess.grammarexpressions;
                                currentProcess.instruction = LOOKUPFORM_LEXEME;
                                //qDebug() << "----- formObtained" << caller << sentenceparts.at(sentencepartid) << currentProcess.grammarexpressions << m_silent << m_found_compoundform;
                                //qDebug() << __FUNCTION__ << __LINE__ << "*** formObtained EMIT ***";
                                grammarform sentencepart_form = form;
                                sentencepart_form.string = sentenceparts.at(sentencepartid);
                                sentencepart_form.grammarexpressions = currentProcess.grammarexpressions;
                                emit formObtained(caller, sentencepart_form.b_silent, sentencepart_form);
                                //qDebug() << "grammarprovider::getNextGrammarObject exit" << __LINE__;
                                return;
                            }
                            sentencepartid++;
                        }
                        emit sentenceAvailable(caller, form.processList.size(), form.b_silent);
                    }
                    else {
                        qDebug() << "Process list size (=" + QString::number(form.processList.size()) +  ") does not match number of sentence parts (=" + sentenceparts.size() + ")!";
                    }
                }
                break;
            default:
                //qDebug() << form.index << form.string << "unknown form!" << form.grammarexpressions;
                break;
        }
    }
    //qDebug() << "grammarprovider::getNextGrammarObject exit" << __LINE__;
}
@}

\cprotect\subsection{\verb#getNextSentencePart#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getNextSentencePart(QObject* caller){
    if(m_grammarforms.isEmpty()){
        qDebug() << "getNextSentencePart is called with no grammar objects remaining!";
        return;
    }
    grammarform form = m_grammarforms.first();
    // We modify m_grammarforms, so we remove it always and add it back
    // later:
    m_grammarforms.removeFirst();
    // Check that there is still stuff to process:
    if(form.processList.isEmpty()){
        QList<QList<QString > > ge = form.grammarexpressions;
        emit sentenceComplete(caller,ge,form.b_silent);
        return;
    }
    // Process sentence parts:
    lexemePartProcess process = form.processList.first();
    form.processList.removeFirst();
    QStringList sentenceparts = form.string.split(QLatin1Char(' '));
    if(sentenceparts.size() > 1)
        form.string.remove(0,sentenceparts.at(0).size()+1);
    m_grammarforms.push_front(form);
    switch(process.instruction){
        case IGNOREFORM:
            getNextSentencePart(caller);
            break;
        case LOOKUPFORM:
            //qDebug() << sentenceparts.at(0) << "LOOKUPFORM" << process.grammarexpressions;
            emit sentenceLookupForm(caller,sentenceparts.at(0),process.grammarexpressions, form.b_silent);
            break;
        case LOOKUPFORM_LEXEME:
            //qDebug() << sentenceparts.at(0) << "LOOKUPFORM_LEXEME" << process.grammarexpressions;
            emit sentenceLookupFormLexeme(caller,sentenceparts.at(0),process.grammarexpressions, form.b_silent);
            break;
        case ADDANDUSEFORM:
            //qDebug() << sentenceparts.at(0) << "ADDANDUSEFORM" << process.grammarexpressions;
            emit sentenceAddAndUseForm(caller,sentenceparts.at(0),process.grammarexpressions, form.b_silent);
            break;
        case ADDANDIGNOREFORM:
            //qDebug() << sentenceparts.at(0) << "ADDANDIGNOREFORM" << process.grammarexpressions;
            emit sentenceAddAndIgnoreForm(caller,sentenceparts.at(0),process.grammarexpressions, form.b_silent);
            break;
        default:
            //qDebug() << "Unknown processing instruction... ignoring!";
            getNextSentencePart(caller);
            break;
    }
}
@}

\cprotect\subsection{\verb#getPlainTextTableFromReply#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::getPlainTextTableFromReply(QString s_reply, QList<grammarprovider::tablecell>& parsedTable){
    
    QJsonDocument j_document = QJsonDocument::fromJson(s_reply.toUtf8());
    QString wikitemplate_text = j_document.object()["expandtemplates"].toObject()["wikitext"].toString();
    parseMediawikiTableToPlainText(wikitemplate_text, parsedTable);
}
@}

\cprotect\subsection{\verb#getPlainTextTableFromReply#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::processNetworkError(QObject* caller, QString s_failure_reason){
    emit networkError(caller, m_silent, s_failure_reason);
}
@}

\cprotect\subsection{\verb#getGrammarCompoundFormParts#}
@O ../src/grammarprovider.cpp -d
@{
QList<grammarprovider::compoundPart> grammarprovider::getGrammarCompoundFormParts(QString compoundword, QList<QString> compoundstrings, int id_language){
    //qDebug() << __FILE__ << __FUNCTION__ << __LINE__ << compoundword << compoundstrings << id_language;
    /* The previous assumption, that all forms are in the database already does
       not work anymore after a refactoring. */
    bool found_all_lexemes = true;
    QList<QList<QPair<QString,int> > > compoundformpart_candidates;
    QString m_debug_compoundparts;
    foreach(QString compoundform, compoundstrings){
        // First check database:
        QList<int> possible_lexemes = m_database->searchLexemes(compoundform, true);
        int found_lexeme = 0;
        foreach(int possible_lexeme, possible_lexemes){
            if(m_database->languageOfLexeme(possible_lexeme) == id_language){
                found_lexeme = possible_lexeme;
                break;
            }
        }
        if(found_lexeme > 0){
            // Collect all form candidates:
            QList<QPair<QString,int> > forms = m_database->listFormsOfLexeme(found_lexeme);
            compoundformpart_candidates.push_back(forms);
        }
        else{
            // We have not found any matching lexeme in database, let's check our memory:
            grammarform form;
            found_lexeme = 0;
            //qDebug() << __FILE__ << __FUNCTION__ << __LINE__ << mi_grammarforms.size();
            foreach(form, mi_grammarforms){
                if((form.string == compoundform) && (form.language_id == id_language)){
                    found_lexeme = form.lexeme_id;
                    break;
                }
            }
            if(found_lexeme != 0){
                // Collect all form candidates:
                QList<QPair<QString,int> > forms;
                foreach(form, mi_grammarforms){
                    if(form.lexeme_id == found_lexeme){
                        forms.push_back({form.string,form.id});
                        m_debug_compoundparts += form.string + " ";
                    }
                }
                compoundformpart_candidates.push_back(forms);
                continue;
            }
            found_all_lexemes = false;
            break;
        }
    }
    //qDebug() << "Found all lexemes:" << found_all_lexemes << m_debug_compoundparts;
    levenshteindistance local_levenshteindistance;
    QList<levenshteindistance::compoundpart> compoundparts = local_levenshteindistance.stringdivision(compoundformpart_candidates,compoundword);
    levenshteindistance::compoundpart m_compoundpart;
    QList<compoundPart> compoundpartsgrammar;
    foreach(m_compoundpart, compoundparts){
        if(m_compoundpart.id != 0){
            m_debug_compoundparts += QString::number(m_compoundpart.id) + " ";
        }
        else{
            m_debug_compoundparts += m_compoundpart.string;
        }
        compoundpartsgrammar.push_back({m_compoundpart.id,m_compoundpart.capitalized,m_compoundpart.string});
        //qDebug() << "Compound part" << m_compoundpart.division << m_compoundpart.id << m_compoundpart.capitalized << m_compoundpart.string;
    }
    //qDebug() << "Compound parts:" << m_debug_compoundparts;
    return compoundpartsgrammar;
}
@}

\cprotect\subsection{\verb#parse_compoundform#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::parse_compoundform(QString s_reply, QObject* caller){
    //qDebug() << "Got compound form";
    int argnumber=0;
    m_current_compoundforms.clear();
    foreach(const QString& arg, m_currentarguments.unnamed){
        argnumber++;
        if(argnumber>2){
            bool found_form = false;
            QList<int> compoundpart_forms = m_database->searchForms(arg,true);
            foreach(int compoundpart_form, compoundpart_forms){
                int grammarform = m_database->grammarFormFromFormId(compoundpart_form);
                int languageid = m_database->languageIdFromGrammarFormId(grammarform);
                if(languageid == m_language){
                    found_form = true;
                    //qDebug() << "Found form" << arg;
                    break;
                }
            }
            if(!found_form){
                //qDebug() << "Could not find form" << arg << ", looking it up...";
                context save_state(this);
                QEventLoop waitloop;
                //qDebug() << __FILE__ << __FUNCTION__ << __LINE__ << &waitloop;
                m_word = arg;
                m_silent = true;
                m_found_compoundform = false;
                QMetaObject::Connection gic_con;
                QMetaObject::Connection gia_con;
                QMetaObject::Connection gina_con;
                QMetaObject::Connection ne_con;
                gic_con = connect(this, &grammarprovider::grammarInfoComplete,
                        [&](QObject* caller, bool silent){
                            if(caller == &waitloop){
                                //qDebug() << "Got grammarInfoComplete signal in lambda function for compoundform search" << m_word << caller;
                                disconnect(gic_con);
                                disconnect(gia_con);
                                disconnect(gina_con);
                                disconnect(ne_con);
                                waitloop.quit();
                            }
                        });
                gia_con = connect(this, &grammarprovider::grammarInfoAvailable,
                        [&](QObject* caller, bool silent){
                            if(caller == &waitloop){
                                //qDebug() << "Got grammarInfoAvailable signal in lambda function for compoundform search" << m_word << caller;
                                disconnect(gic_con);
                                disconnect(gia_con);
                                disconnect(gina_con);
                                disconnect(ne_con);
                                waitloop.quit();
                            }
                        });
                gina_con = connect(this, &grammarprovider::grammarInfoNotAvailable,
                        [&](QObject* caller, bool silent){
                            if(caller == &waitloop){
                                //qDebug() << "Got grammarInfoNotComplete signal in lambda function for compoundform search" << m_word << caller;
                                disconnect(gic_con);
                                disconnect(gia_con);
                                disconnect(gina_con);
                                disconnect(ne_con);
                                waitloop.quit();
                            }
                        });
                ne_con = connect(m_networkscheduler, &networkscheduler::requestFailed,
                        [&](QObject* caller, QString s_reason){
                            if(caller == &waitloop){
                                //qDebug() << "Got requestFailed signal" << s_reason << "in lambda function for compoundform search" << m_word << caller;
                                disconnect(gic_con);
                                disconnect(gia_con);
                                disconnect(gina_con);
                                disconnect(ne_con);
                                waitloop.quit();
                            }
                        });
                getWiktionarySections(&waitloop);
                //qDebug() << "Blocking waitloop" << &waitloop << "for compoundform" << m_word << "...";
                waitloop.exec();
                //qDebug() << "... blocking waitloop" << &waitloop << "for compoundform" << m_word << "finished.";
            }
            m_current_compoundforms += arg;
        }
    }
    emit grammarInfoComplete(caller,m_silent);
}
@}

@i grammarprovider_language_specific.w
