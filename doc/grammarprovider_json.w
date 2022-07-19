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

\section{JSON files}
\subsection{Schema}
The definitions in the grammarprovider class are currently hardcoded. To make them better configurable and to give the user a possibility to extend the definitions (which is crucial) we define a JSON Schema file for configuration files.

@O ../src/android/assets/grammarprovider/schemas/main.json
@{{
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
    "language": {
        "$ref": "#/$defs/language"
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
            "description": "Identifier for table required for obtaining it. In case of en.wiktionary.org this is the mediawiki template name of the inflection table.",
            "type": "array",
            "items": {
              "type": "string"
            },
            "minItems": 1
          },
          "forms": {
            "description": "Array of instructions how to parse forms (can be cells in a table)",
            "type": "array",
            "items": {
              "description": "How to parse this particular cell",
              "type": "object",
              "additionalProperties": false,
              "properties": {
                "index": {
                  "description": "Index of cell, i.e. to describe in which order the forms are going to be processed. This is important if some forms depent on other forms. If no index is given, the next free index - starting from 1 is used which may not be what you want. Unless you don't do any reordering (in which case you can omit all indices) you should probably give all forms indices.",
                  "type": "number"
                },
                "source": {
                    "description": "How to obtain the text string for later processing",
                    "type": "object",
                    "properties": {
                        "row": {
                            "description": "Row of cell in table",
                            "type": "number"
                        },
                        "column": {
                            "description": "Column of cell in table",
                            "type": "number"
                        },
                        "xquery": {
                            "description": "XQuery 1.0 expression to obtain information from xml",
                            "type": "string"
                        }
                    }
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
                  "description": "List of instructions how to process contents of this form. If given, content_type also is required.",
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
                "source",
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
          "forms"
        ]
      }
    },
    "default_lexemes": {
      "description": "This entries are put into the database before any us of inflectiontables. They should only contain entries which can not be looked up just by themselfes",
      "type": "array",
      "items": {
          "type": "object",
          "properties": {
              "forms": {
                  "type": "array",
                  "items": {
                      "$ref": "#/$defs/form"
                  }
              }
          },
          "required": [
              "forms"
          ]
      }
    },
    "lookup_forms": {
        "description": "Look up this forms. This is done after default lexemes are put in the database but before any other form from the user is looked up. Should ony contain forms needed for the lookup of other forms",
        "type": "array",
        "items": {
            "$ref": "#/$defs/form"
        }
    }
  },
  "required": [
    "version",
    "language",
    "base_url"
  ],
  "$defs": {
      "language": {
          "description": "Language name in english",
          "type": "string",
          "enum": [
              "English",
              "Mandarin",
              "Hindi",
              "Spanish",
              "French",
              "Standard Arabic",
              "Bengali",
              "Russian",
              "Portuguese",
              "Indonesian",
              "Urdu",
              "German",
              "Japanese",
              "Swahili",
              "Marathi",
              "Telugu",
              "Turkish",
              "Yue Chinese",
              "Tamil",
              "Punjabi",
              "Wu Chinese",
              "Korean",
              "Vietnamese",
              "Hausa",
              "Javanese",
              "Egyptian Arabic",
              "Italian",
              "Thai",
              "Gujarati",
              "Kannada",
              "Persian",
              "Bhojpuri",
              "Southern Min",
              "Filipino",
              "Dutch",
              "Danish",
              "Greek",
              "Finnish",
              "Swedish",
              "Czech",
              "Estonian",
              "Hungarian",
              "Latvian",
              "Lithuanian",
              "Maltese",
              "Polish",
              "Slovak",
              "Slovene",
              "Bulgarian",
              "Irish",
              "Romanian",
              "Croatian"
          ]
    },
      "form": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
              "content": {
                  "description": "UTF-8 string for this word form. This should be a single word.",
                  "type": "string"
              },
              "grammarexpressions": {
                  "$ref": "#/$defs/grammarexpressions"
              }
          },
          "required": [
              "content"
          ]
      },
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

\subsection{Language specific files}
These files will mostly be boilerplate at the beginning and don't have any content.

\subsubsection{English}
@o ../src/android/assets/grammarprovider/configurations/en.json
@{{
  "version": "0.1",
  "language": "English",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Mandarin}
@o ../src/android/assets/grammarprovider/configurations/cmn.json
@{{
  "version": "0.1",
  "language": "Mandarin",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Hindi}
@o ../src/android/assets/grammarprovider/configurations/hi.json
@{{
  "version": "0.1",
  "language": "Hindi",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Spanish}
@o ../src/android/assets/grammarprovider/configurations/es.json
@{{
  "version": "0.1",
  "language": "Spanish",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{French}
@o ../src/android/assets/grammarprovider/configurations/fr.json
@{{
  "version": "0.1",
  "language": "French",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Standard Arabic}
@o ../src/android/assets/grammarprovider/configurations/arb.json
@{{
  "version": "0.1",
  "language": "Standard Arabic",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Bengali}
@o ../src/android/assets/grammarprovider/configurations/bn.json
@{{
  "version": "0.1",
  "language": "Bengali",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Russian}
@o ../src/android/assets/grammarprovider/configurations/ru.json
@{{
  "version": "0.1",
  "language": "Russian",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Portuguese}
@o ../src/android/assets/grammarprovider/configurations/pt.json
@{{
  "version": "0.1",
  "language": "Portuguese",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Indonesian}
@o ../src/android/assets/grammarprovider/configurations/id.json
@{{
  "version": "0.1",
  "language": "Indonesian",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Urdu}
@o ../src/android/assets/grammarprovider/configurations/ur.json
@{{
  "version": "0.1",
  "language": "Urdu",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{German}
@o ../src/android/assets/grammarprovider/configurations/de.json
@{{
  "version": "0.1",
  "language": "German",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Japanese}
@o ../src/android/assets/grammarprovider/configurations/ja.json
@{{
  "version": "0.1",
  "language": "Japanese",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Swahili}
@o ../src/android/assets/grammarprovider/configurations/sw.json
@{{
  "version": "0.1",
  "language": "Swahili",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Marathi}
@o ../src/android/assets/grammarprovider/configurations/mr.json
@{{
  "version": "0.1",
  "language": "Marathi",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Telugu}
@o ../src/android/assets/grammarprovider/configurations/te.json
@{{
  "version": "0.1",
  "language": "Telugu",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Turkish}
@o ../src/android/assets/grammarprovider/configurations/tr.json
@{{
  "version": "0.1",
  "language": "Turkish",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Yue Chinese}
@o ../src/android/assets/grammarprovider/configurations/yue.json
@{{
  "version": "0.1",
  "language": "Yue Chinese",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Tamil}
@o ../src/android/assets/grammarprovider/configurations/ta.json
@{{
  "version": "0.1",
  "language": "Tamil",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Punjabi}
@o ../src/android/assets/grammarprovider/configurations/pa.json
@{{
  "version": "0.1",
  "language": "Punjabi",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Wu Chinese}
@o ../src/android/assets/grammarprovider/configurations/wuu.json
@{{
  "version": "0.1",
  "language": "Wu Chinese",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Korean}
@o ../src/android/assets/grammarprovider/configurations/ko.json
@{{
  "version": "0.1",
  "language": "Korean",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Vietnamese}
@o ../src/android/assets/grammarprovider/configurations/vi.json
@{{
  "version": "0.1",
  "language": "Vietnamese",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Hausa}
@o ../src/android/assets/grammarprovider/configurations/ha.json
@{{
  "version": "0.1",
  "language": "Hausa",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Javanese}
@o ../src/android/assets/grammarprovider/configurations/jv.json
@{{
  "version": "0.1",
  "language": "Javanese",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Egyptian Arabic}
@o ../src/android/assets/grammarprovider/configurations/arz.json
@{{
  "version": "0.1",
  "language": "Egyptian Arabic",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Italian}
@o ../src/android/assets/grammarprovider/configurations/it.json
@{{
  "version": "0.1",
  "language": "Italian",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Thai}
@o ../src/android/assets/grammarprovider/configurations/th.json
@{{
  "version": "0.1",
  "language": "Thai",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Gujarati}
@o ../src/android/assets/grammarprovider/configurations/gu.json
@{{
  "version": "0.1",
  "language": "Gujarati",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Kannada}
@o ../src/android/assets/grammarprovider/configurations/kn.json
@{{
  "version": "0.1",
  "language": "Kannada",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Persian}
@o ../src/android/assets/grammarprovider/configurations/fa.json
@{{
  "version": "0.1",
  "language": "Persian",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Bhojpuri}
@o ../src/android/assets/grammarprovider/configurations/bho.json
@{{
  "version": "0.1",
  "language": "Bhojpuri",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Southern Min}
@o ../src/android/assets/grammarprovider/configurations/nan.json
@{{
  "version": "0.1",
  "language": "Southern Min",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Filipino}
@o ../src/android/assets/grammarprovider/configurations/fil.json
@{{
  "version": "0.1",
  "language": "Filipino",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Dutch}
@o ../src/android/assets/grammarprovider/configurations/nl.json
@{{
  "version": "0.1",
  "language": "Dutch",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Danish}
@o ../src/android/assets/grammarprovider/configurations/da.json
@{{
  "version": "0.1",
  "language": "Danish",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Greek}
@o ../src/android/assets/grammarprovider/configurations/el.json
@{{
  "version": "0.1",
  "language": "Greek",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}

\subsubsection{Finnish}
@o ../src/android/assets/grammarprovider/configurations/fi.json
@{{
  "version": "0.1",
  "language": "Finnish",
  "base_url": "https://en.wiktionary.org/w/api.php?",
  "default_lexemes": [
  {
      "forms": [
      {
          "content": "en",
          "grammarexpressions": {
              "format": "coleitra",
              "version": "0.1",
              "tags": {
                  "Mood": "Indicative",
                  "Number": "Singular",
                  "Person": "First",
                  "Part of speech": "Verb"
              }
          }
      }
      ]
  }
  ]
}
@}

\subsubsection{Swedish}
@o ../src/android/assets/grammarprovider/configurations/sv.json
@{{
  "version": "0.1",
  "language": "Swedish",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Czech}
@o ../src/android/assets/grammarprovider/configurations/cs.json
@{{
  "version": "0.1",
  "language": "Czech",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Estonian}
@o ../src/android/assets/grammarprovider/configurations/et.json
@{{
  "version": "0.1",
  "language": "Estonian",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Hungarian}
@o ../src/android/assets/grammarprovider/configurations/hu.json
@{{
  "version": "0.1",
  "language": "Hungarian",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Latvian}
@o ../src/android/assets/grammarprovider/configurations/lv.json
@{{
  "version": "0.1",
  "language": "Latvian",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Lithuanian}
@o ../src/android/assets/grammarprovider/configurations/lt.json
@{{
  "version": "0.1",
  "language": "Lithuanian",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Maltese}
@o ../src/android/assets/grammarprovider/configurations/mt.json
@{{
  "version": "0.1",
  "language": "Maltese",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Polish}
@o ../src/android/assets/grammarprovider/configurations/pl.json
@{{
  "version": "0.1",
  "language": "Polish",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Slovak}
@o ../src/android/assets/grammarprovider/configurations/sk.json
@{{
  "version": "0.1",
  "language": "Slovak",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Slovene}
@o ../src/android/assets/grammarprovider/configurations/sl.json
@{{
  "version": "0.1",
  "language": "Slovene",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Bulgarian}
@o ../src/android/assets/grammarprovider/configurations/bg.json
@{{
  "version": "0.1",
  "language": "Bulgarian",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Irish}
@o ../src/android/assets/grammarprovider/configurations/ga.json
@{{
  "version": "0.1",
  "language": "Irish",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Romanian}
@o ../src/android/assets/grammarprovider/configurations/ro.json
@{{
  "version": "0.1",
  "language": "Romanian",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}
\subsubsection{Croatian}
@o ../src/android/assets/grammarprovider/configurations/hr.json
@{{
  "version": "0.1",
  "language": "Croatian",
  "base_url": "https://en.wiktionary.org/w/api.php?"
}
@}

