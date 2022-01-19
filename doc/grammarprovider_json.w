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
        "description": "Language name in english",
        "type": "string",
        "enum": [
            "English",
            "Mandarin Chinese",
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
    "language",
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

\subsection{Language specific files}
\subsubsection{Finnish}
@O ../src/android/assets/grammarprovider/configurations/fi.json
@{{
  "version": "0.1",
  "language": "Finnish",
  "base_url": "https://en.wiktionary.org/w/api.php?",
  "inflectiontables": [
    {
      "tablename": "Conjugation",
      "identifiers": [
        "fi-conj-sanoa",
        "fi-conj-muistaa"
      ],
      "cells": [
        {
          "index": 1,
          "row": 5,
          "column": 3,
          "grammarexpressions": {
            "format": "coleitra",
            "version": "0.1",
            "tags": {
              "Mood": "Indicative",
              "Tense": "Present",
              "Polarity": "Positive",
              "Person": "First",
              "Number": "Singular"
            }
          },
          "content_type": "SENTENCE",
          "process": [
            {
              "instruction": "LOOKUPFORM",
              "grammarexpressions": {
                "format": "coleitra",
                "version": "0.1",
                "tags": {
                  "Part of speech": "Verb"
                }
              }
            }
          ]
        }
      ]
    }
  ]
}
@}

