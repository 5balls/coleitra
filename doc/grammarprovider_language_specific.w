\section{Language specific implementations}
\subsection{Finnish}

\cprotect\subsubsection{\verb#fi_requirements#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::fi_requirements(QObject* caller, int fi_id){
    QList<int> olla_forms = m_database->searchForms("olla",true);
    int expected_grammarform = m_database->grammarFormIdFromStrings(fi_id,{{"Infinitive","First"},{"Voice","Active"},{"Part of speech","Verb"}});
    bool found_form = false;
    foreach(int olla_form, olla_forms){
        int grammarform = m_database->grammarFormFromFormId(olla_form);
        if(grammarform == expected_grammarform){
            found_form = true;
            break;
        }
    }
    if(!found_form){
        m_caller = caller;
        m_language = fi_id;
        m_word = "olla";
        m_silent = true;
        QEventLoop waitloop;
        connect( this, &grammarprovider::grammarInfoComplete, &waitloop, &QEventLoop::quit );
        getWiktionarySections();
        waitloop.exec();
    }
}
@}

\cprotect\subsubsection{\verb#fi_compound_parser#}
@O ../src/grammarprovider.cpp -d
@{
QList<QPair<QString,int> > grammarprovider::fi_compound_parser(QObject* caller, int fi_id, int lexeme_id, QList<int> compound_lexemes){
  return QList<QPair<QString,int> >();
}
@}

\cprotect\subsubsection{\verb#parse_fi_verbs#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::parse_fi_verbs(QNetworkReply* reply){
    QList<grammarprovider::tablecell> parsedTable;
    getPlainTextTableFromReply(reply, parsedTable);
    QList<grammarform> grammarforms {
        {1,5,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}}},
        {63,5,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {93,5,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {123,5,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {2,6,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}}},
        {64,6,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {94,6,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {124,6,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {3,7,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}}},
        {65,7,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {95,7,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {125,7,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {4,8,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}}},
        {66,8,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {96,8,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {126,8,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {5,9,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}}},
        {67,9,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {97,9,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {127,9,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {6,10,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}}},
        {68,10,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {98,10,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {128,10,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {7,11,3,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Positive"},{"Voice","Passive"}}},
        {153,11,4,{{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Indicative"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}}}}},
        {158,11,6,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {163,11,7,{{"Mood","Indicative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {8,14,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}}},
        {69,14,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {99,14,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {129,14,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {9,15,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}}},
        {70,15,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {100,15,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {130,15,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {10,16,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}}},
        {71,16,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {101,16,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {131,16,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {11,17,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}}},
        {72,17,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {102,17,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {132,17,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {12,18,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}}},
        {73,18,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {103,18,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {133,18,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {13,19,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}}},
        {74,19,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {104,19,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {134,19,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {14,20,3,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Positive"},{"Voice","Passive"}}},
        {154,20,4,{{"Mood","Indicative"},{"Tense","Past"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {159,20,6,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Positive"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {164,20,7,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {15,24,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}}},
        {75,24,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {105,24,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {135,24,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {16,25,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}}},
        {76,25,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {106,25,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {136,25,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {17,26,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}}},
        {77,26,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {107,26,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {137,26,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {18,27,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}}},
        {78,27,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {108,27,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {138,27,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {19,28,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}}},
        {79,28,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {109,28,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {139,28,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {20,29,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}}},
        {80,29,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {110,29,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {140,29,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {21,30,3,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Positive"},{"Voice","Passive"}}},
        {155,30,4,{{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Conditional"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}}}}},
        {160,30,6,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Positive"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {165,30,7,{{"Mood","Conditional"},{"Tense","Perfect"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {22,34,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}}},
        {81,34,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}}}}},
        {111,34,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {141,34,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {23,35,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}}},
        {82,35,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}}}}},
        {112,35,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {142,35,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {24,36,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}}},
        {83,36,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}}}}},
        {113,36,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {143,36,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {25,37,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}}},
        {84,37,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}}}}},
        {114,37,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {144,37,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {26,38,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}}},
        {85,38,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}}}}},
        {115,38,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {145,38,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {27,39,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}}},
        {86,39,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}}}}},
        {116,39,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {146,39,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {28,40,3,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Positive"},{"Voice","Passive"}}},
        {156,40,4,{{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Imperative"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}}}}},
        {161,40,6,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Positive"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {166,40,7,{{"Mood","Imperative"},{"Tense","Perfect"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {29,44,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}}},
        {87,44,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {117,44,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {147,44,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {30,45,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}}},
        {88,45,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {118,45,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {148,45,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {31,46,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}}},
        {89,46,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {119,46,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {149,46,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Singular"}}}}},
        {32,47,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}}},
        {90,47,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {120,47,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {150,47,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","First"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {33,48,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}}},
        {91,48,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {121,48,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {151,48,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {34,49,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}}},
        {92,49,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"}}}}},
        {122,49,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {152,49,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Active"},{"Tense","Past"},{"Number","Plural"}}}}},
        {35,50,3,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Positive"},{"Voice","Passive"}}},
        {157,50,4,{{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{ADDANDUSEFORM,{{"Part of speech","Verb"},{"Verbform","Connegative"},{"Mood","Potential"},{"Tense","Present"},{"Polarity","Negative"},{"Voice","Passive"}}}}},
        {162,50,6,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Positive"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
        {167,50,7,{{"Mood","Potential"},{"Tense","Perfect"},{"Polarity","Negative"},{"Voice","Passive"}},SENTENCE,{LOOKUPFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Voice","Passive"},{"Tense","Past"}}}}},
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
        {60,64,4,{{"Infinitive","Fourth"},{"Voice","Active"},{"Case","Nominative"}}},
        {61,65,3,{{"Infinitive","Fourth"},{"Voice","Active"},{"Case","Partitive"}}},
        {62,66,3,{{"Infinitive","Fifth"},{"Voice","Active"}}},
    };
    process_grammar(grammarforms,parsedTable,{{"Part of speech","Verb"}});
}
@}

\cprotect\subsubsection{\verb#parse_fi_nominals#}
@O ../src/grammarprovider.cpp -d
@{
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
@}

\subsection{German}

\cprotect\subsubsection{\verb#de_requirements#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::de_requirements(QObject* caller, int de_id){
    QList<int> sein_forms = m_database->searchForms("sein",true);
    int expected_grammarform = m_database->grammarFormIdFromStrings(de_id,{{"Infinitive","First"},{"Part of speech","Verb"}});
    bool found_form = false;
    foreach(int sein_form, sein_forms){
        int grammarform = m_database->grammarFormFromFormId(sein_form);
        if(grammarform == expected_grammarform){
            found_form = true;
            break;
        }
    }
    if(!found_form){
        m_caller = caller;
        m_language = de_id;
        m_word = "sein";
        m_silent = true;
        QEventLoop waitloop;
        connect( this, &grammarprovider::grammarInfoComplete, &waitloop, &QEventLoop::quit );
        getWiktionarySections();
        waitloop.exec();
    }
}
@}

\cprotect\subsubsection{\verb#parse_de_noun_n#}
@O ../src/grammarprovider.cpp -d
@{
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
@}

\cprotect\subsubsection{\verb#parse_de_noun_m#}
@O ../src/grammarprovider.cpp -d
@{
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
@}

\cprotect\subsubsection{\verb#parse_de_noun_f#}
@O ../src/grammarprovider.cpp -d
@{
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
@}

\cprotect\subsubsection{\verb#parse_de_verb#}
@O ../src/grammarprovider.cpp -d
@{
void grammarprovider::parse_de_verb(QNetworkReply* reply){
    // Work in process....

    QList<grammarprovider::tablecell> parsedTable;
    getPlainTextTableFromReply(reply, parsedTable);
    QList<grammarform> grammarforms {
        {1,1,3,{{"Infinitive","First"}}},
        {2,2,3,{{"Verbform","Participle"},{"Tense","Present"}}},
        {3,3,3,{{"Verbform","Participle"},{"Tense","Past"}}},
        {4,4,3,{{"Verbform","Auxiliary"}}},
        {5,6,2,{{"Mood","Indicative"},{"Tense","Present"},{"Person","First"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {6,6,3,{{"Mood","Indicative"},{"Tense","Present"},{"Person","First"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {7,6,5,{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","First"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {8,6,6,{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","First"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {9,7,2,{{"Mood","Indicative"},{"Tense","Present"},{"Person","Second"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {10,7,3,{{"Mood","Indicative"},{"Tense","Present"},{"Person","Second"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {11,7,4,{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","Second"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {12,7,5,{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","Second"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {13,8,2,{{"Mood","Indicative"},{"Tense","Present"},{"Person","Third"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {14,8,3,{{"Mood","Indicative"},{"Tense","Present"},{"Person","Third"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {15,8,4,{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","Third"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {16,8,5,{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","Third"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {17,10,2,{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","First"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {18,10,3,{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","First"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {19,10,5,{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","First"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {20,10,6,{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","First"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {21,11,2,{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","Second"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {22,11,3,{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","Second"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {23,11,4,{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","Second"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {24,11,5,{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","Second"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {25,12,2,{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","Third"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {26,12,3,{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","Third"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {27,12,4,{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","Third"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {28,12,5,{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","Third"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {IGNOREFORM, ADDANDUSEFORM}},
        {29,14,2,{{"Mood","Imperative"},{"Person","Second"},{"Number","Singular"}}, FORM_WITH_IGNORED_PARTS, {ADDANDUSEFORM, IGNOREFORM}},
        {30,14,3,{{"Mood","Imperative"},{"Person","Second"},{"Number","Plural"}}, FORM_WITH_IGNORED_PARTS, {ADDANDUSEFORM, IGNOREFORM}},
        {31,16,2,{{"Mood","Indicative"},{"Tense","Perfect"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {32,16,3,{{"Mood","Indicative"},{"Tense","Perfect"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {33,16,5,{{"Mood","Subjunctive"},{"Tense","Perfect"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {34,16,6,{{"Mood","Subjunctive"},{"Tense","Perfect"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {35,17,2,{{"Mood","Indicative"},{"Tense","Perfect"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {36,17,3,{{"Mood","Indicative"},{"Tense","Perfect"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {37,17,4,{{"Mood","Subjunctive"},{"Tense","Perfect"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {38,17,5,{{"Mood","Subjunctive"},{"Tense","Perfect"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {39,18,2,{{"Mood","Indicative"},{"Tense","Perfect"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {40,18,3,{{"Mood","Indicative"},{"Tense","Perfect"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {41,18,4,{{"Mood","Subjunctive"},{"Tense","Perfect"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {42,18,5,{{"Mood","Subjunctive"},{"Tense","Perfect"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {43,20,2,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {44,20,3,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {45,20,5,{{"Mood","Subjunctive"},{"Tense","Plusquamperfect"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {46,20,6,{{"Mood","Subjunctive"},{"Tense","Plusquamperfect"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {47,21,2,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {48,21,3,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {49,21,4,{{"Mood","Subjunctive"},{"Tense","Plusquamperfect"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {50,21,5,{{"Mood","Subjunctive"},{"Tense","Plusquamperfect"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {51,22,2,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {52,22,3,{{"Mood","Indicative"},{"Tense","Plusquamperfect"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {53,22,4,{{"Mood","Subjunctive"},{"Tense","Plusquamperfect"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {54,22,5,{{"Mood","Subjunctive"},{"Tense","Plusquamperfect"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}}}},
        {55,24,2,{{"Infinitive","First"},{"Tense","Future 1"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {56,24,5,{{"Mood","Subjunctive 1"},{"Tense","Future 1"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {57,24,6,{{"Mood","Subjunctive 1"},{"Tense","Future 1"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {58,25,2,{{"Mood","Subjunctive 1"},{"Tense","Future 1"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {59,25,3,{{"Mood","Subjunctive 1"},{"Tense","Future 1"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {60,26,2,{{"Mood","Subjunctive 1"},{"Tense","Future 1"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {61,26,3,{{"Mood","Subjunctive 1"},{"Tense","Future 1"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {62,28,2,{{"Mood","Indicative"},{"Tense","Future 1"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {63,28,3,{{"Mood","Indicative"},{"Tense","Future 1"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {64,28,5,{{"Mood","Subjunctive 2"},{"Tense","Future 1"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {65,28,6,{{"Mood","Subjunctive 2"},{"Tense","Future 1"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {66,29,2,{{"Mood","Indicative"},{"Tense","Future 1"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {67,29,3,{{"Mood","Indicative"},{"Tense","Future 1"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {68,29,4,{{"Mood","Subjunctive 2"},{"Tense","Future 1"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {69,29,5,{{"Mood","Subjunctive 2"},{"Tense","Future 1"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {70,30,2,{{"Mood","Indicative"},{"Tense","Future 1"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {71,30,3,{{"Mood","Indicative"},{"Tense","Future 1"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {72,30,4,{{"Mood","Subjunctive 2"},{"Tense","Future 1"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {73,30,5,{{"Mood","Subjunctive 2"},{"Tense","Future 1"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Infinitive","First"}}}}},
        {74,32,2,{{"Infinitive","First"},{"Tense","Future 2"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM,LOOKUPFORM}},
        {75,32,5,{{"Mood","Subjunctive 1"},{"Tense","Future 2"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {76,32,6,{{"Mood","Subjunctive 1"},{"Tense","Future 2"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {77,33,2,{{"Mood","Subjunctive 1"},{"Tense","Future 2"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {78,33,3,{{"Mood","Subjunctive 1"},{"Tense","Future 2"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {79,34,2,{{"Mood","Subjunctive 1"},{"Tense","Future 2"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {80,34,3,{{"Mood","Subjunctive 1"},{"Tense","Future 2"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {81,36,2,{{"Mood","Indicative"},{"Tense","Future 2"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {82,36,3,{{"Mood","Indicative"},{"Tense","Future 2"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {83,36,5,{{"Mood","Subjunctive 2"},{"Tense","Future 2"},{"Person","First"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {84,36,6,{{"Mood","Subjunctive 2"},{"Tense","Future 2"},{"Person","First"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {85,37,2,{{"Mood","Indicative"},{"Tense","Future 2"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {86,37,3,{{"Mood","Indicative"},{"Tense","Future 2"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {87,37,4,{{"Mood","Subjunctive 2"},{"Tense","Future 2"},{"Person","Second"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {88,37,5,{{"Mood","Subjunctive 2"},{"Tense","Future 2"},{"Person","Second"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {89,38,2,{{"Mood","Indicative"},{"Tense","Future 2"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {90,38,3,{{"Mood","Indicative"},{"Tense","Future 2"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {91,38,4,{{"Mood","Subjunctive 2"},{"Tense","Future 2"},{"Person","Third"},{"Number","Singular"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
        {92,38,5,{{"Mood","Subjunctive 2"},{"Tense","Future 2"},{"Person","Third"},{"Number","Plural"}},SENTENCE,{IGNOREFORM,LOOKUPFORM,{LOOKUPFORM_LEXEME,{{"Part of speech","Verb"},{"Verbform","Participle"},{"Tense","Past"}}},LOOKUPFORM}},
    };
    process_grammar(grammarforms,parsedTable,{{"Part of speech","Verb"}});
}
@}
