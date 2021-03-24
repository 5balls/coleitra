% Copyright 2020, 2021 Florian Pesth
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

\chapter{Editing}
\section{Interface}

@d Id property @'idname@'
@{
public:
    Q_PROPERTY(int @1Id READ @1Id CONSTANT)
    int @1Id()
    {
        return m_@1Id--;
    }
private:
    int m_@1Id = -1;
@}

@o ../src/edit.h -d
@{
@<Start of @'EDIT@' header@>
#include <QQmlEngine>
#include "database.h"
#include "grammarprovider.h"


@<Start of class @'edit@'@>
public:
    explicit edit(QObject *parent = nullptr);
    Q_PROPERTY(QString dbversion MEMBER m_dbversion NOTIFY dbversionChanged);
    @<Id property @'translation@' @>
    @<Id property @'lexeme@' @>
    @<Id property @'sentence@' @>
    @<Id property @'form@' @>
    @<Id property @'compoundForm@' @>
    @<Id property @'grammarForm@' @>
    @<Id property @'grammarFormComponent@' @>
private:
    struct form {
        int id;
        int newid;
        QString string;
        int grammarform;
    };
    enum sentencePartType {
        FORM,
        COMPOUNDFORM,
        GRAMMARFORM,
        PUNCTUATION_MARK
    };
    struct sentencepart {
        int id;
        int newid;
        sentencePartType type;
        bool capitalized;
    };
    struct sentence {
        int id;
        int newid;
        int grammarform;
        QList<sentencepart> parts;
    };
    struct lexeme {
        int id;
        int newid;
        int languageid;
        QList<form> forms;
        QList<sentence> sentences;
    };
    struct translation {
        int id;
        int newid;
        QList<lexeme> lexemes;
    };
    QObject* m_caller;
    translation m_translation;
    QList<translation> m_translations;
    translation* m_current_translation;
    QList<lexeme> m_lexemes;
    database* m_database;
    QString m_dbversion;
    grammarprovider* m_grammarprovider;
    int m_current_lexeme_id;
    int m_current_language_id;
    int m_current_translation_id;
    int m_current_sentence_id;
    QList<QList<int> > m_current_sentence_parts;
    QString m_current_pretty_lexeme;
    struct lexeme& getCreateLexeme(int lexemeid, int languageid, int translationid=0);
    struct scheduled_add {
        QObject* m_caller;
        int m_languageid;
        QString m_lexeme;
        int m_translationid;
    };
    QList<scheduled_add> m_scheduled_adds;
    bool m_add_busy;
    void addScheduledLexemeHeuristically(void);
    void networkErrorFromGrammarProvider(QObject* caller, bool silent);
private slots:
    void grammarInfoNotAvailableFromGrammarProvider(QObject* caller, bool silent);
    void grammarInfoAvailableFromGrammarProvider(QObject* caller, int numberOfObjects, bool silent);
    void formObtainedFromGrammarProvider(QObject* caller, QString form, QList<QList<QString> > grammarexpressions, bool silent);
    void compoundFormObtainedFromGrammarProvider(QObject* caller, QString form, bool silent);
    void sentenceAvailableFromGrammarProvider(QObject* caller, int parts, bool silent);
    void sentenceLookupFormFromGramarProvider(QObject* caller, QString form, QList<QList<QString> > grammarexpressions, bool silent);
    void sentenceLookupFormLexemeFromGrammarProvider(QObject* caller, QString form, QList<QList<QString> > grammarexpressions, bool silent);
    void sentenceAddAndUseFormFromGrammarProvider(QObject* caller, QString form, QList<QList<QString> > grammarexpressions, bool silent);
    void sentenceAddAndIgnoreFormFromGrammerProvider(QObject* caller, QString form, QList<QList<QString> > grammarexpressions, bool silent);
    void sentenceCompleteFromGrammarProvider(QObject* caller, QList<QList<QString> > grammarexpressions, bool silent);
    void grammarInfoCompleteFromGrammarProvider(QObject* caller, bool silent);
public:
    Q_INVOKABLE int createGrammarFormId(int language, QList<QList<QString> > grammarexpressions);
    Q_INVOKABLE void addForm(int lexemeid, int formid, int grammarform, QString string, int languageid, int translationid=0);
    Q_INVOKABLE void addSentence(int lexemeid, int sentenceid, int grammarform, QList<QList<int> > parts, int languageid, int translationid=0);
    Q_INVOKABLE int lookupForm(int language, int lexemeid, QString string, QList<QList<QString> > grammarexpressions);
    Q_INVOKABLE int lookupLexeme(int formid);
    Q_INVOKABLE QString prettyPrintLexeme(int lexeme_id);
    Q_INVOKABLE int formIdToNewId(int id);
    Q_INVOKABLE QString stringFromFormId(int formid);
    Q_INVOKABLE int grammarIdFromFormId(int formid);
    Q_INVOKABLE int lookupFormLexeme(int language, int lexemeid, QString string, QList<QList<QString> > grammarexpressions);
    Q_INVOKABLE void resetEverything(void);
    Q_INVOKABLE void saveToDatabase(void);
    Q_INVOKABLE void moveLexemeOutOfTranslation(int language, QString text);
    Q_INVOKABLE void addLexemeHeuristically(QObject* caller, int languageid, QString lexeme, int translationid);
    Q_INVOKABLE void debugStatusCuedLexemes();
    void addLexeme(int lexemeid, int languageid, int translationid=0);
signals:
    void dbversionChanged(const QString &newVersion);
    void processingStart(const QString &waitingString);
    void processingStop(void);
    void addLexemeHeuristicallyResult(QObject* caller, const QString &result);
@<End of class and header @>
@}

\section{Implementation}

@o ../src/edit.cpp -d
@{
#include "edit.h"

edit::edit(QObject *parent) : QObject(parent), m_add_busy(false), m_current_sentence_parts({}), m_translationId(-1)
{
    QQmlEngine* engine = qobject_cast<QQmlEngine*>(parent);
    m_database = engine->singletonInstance<database*>(qmlTypeId("DatabaseLib", 1, 0, "Database"));
    m_dbversion = m_database->property("version").toString();
    m_grammarprovider = engine->singletonInstance<grammarprovider*>(qmlTypeId("GrammarProviderLib", 1, 0, "GrammarProvider"));
    translation newTranslation = {translationId(),0,{}};
    m_translations.append(newTranslation);
    m_current_translation = &(m_translations.last());
}

int edit::createGrammarFormId(int language, QList<QList<QString> > grammarexpressions){
    return m_database->grammarFormIdFromStrings(language,grammarexpressions);
}

void edit::addForm(int lexemeid, int formid, int grammarform, QString string, int languageid, int translationid){
    //qDebug() << "addForm" << lexemeid << formid << grammarform << string << languageid << translationid;
    form newForm = {formid,0,string,grammarform};
    lexeme& currentLexeme = getCreateLexeme(lexemeid, languageid, translationid);
    currentLexeme.forms.push_back(newForm);
}

edit::lexeme& edit::getCreateLexeme(int lexemeid, int languageid, int translationid){
    QList<lexeme>* lexemes;
    if(translationid==0)
        lexemes = &m_lexemes;
    else{
        lexemes = &(m_current_translation->lexemes);
    }
    bool foundLexeme = false;
    QMutableListIterator<lexeme> lexemei(*lexemes);
    while(lexemei.hasNext()){
        lexeme& currentLexeme = lexemei.next();
        if(currentLexeme.id == lexemeid){
            return currentLexeme;
        }
    }
    addLexeme(lexemeid, languageid, translationid);
    return (*lexemes)[lexemes->size()-1];
}

void edit::addSentence(int lexemeid, int sentenceid, int grammarform, QList<QList<int> > parts, int languageid, int translationid){
    QList<int> part;
    QList<sentencepart> sparts;
    //qDebug() << "addSentence" << lexemeid << sentenceid << grammarform << parts << languageid << translationid;
    foreach(part, parts){
        if(part.size() != 3){
            qDebug() << "Malformed sentence part (size=" + QString::number(part.size()) + ")";
            continue;
        }
        //qDebug() << "sentencePart" << part;
        //if(part[0] < 0){
            sentencepart newSentencePart = {part[0],0,sentencePartType(part[1]),bool(part[2])};
        /*}
        else {
            sentencepart newSentencePart = {0,part[0],sentencePartType(part[1]),bool(part[2])};
        }*/
        sparts.push_back(newSentencePart);
    }
    sentence newSentence = {sentenceid,0,grammarform,sparts};
    lexeme& currentLexeme = getCreateLexeme(lexemeid, languageid, translationid);
    currentLexeme.sentences.push_back(newSentence);
}

int edit::lookupForm(int language, int lexemeid, QString string, QList<QList<QString> > grammarexpressions){
    int grammarid = 0;
    if(grammarexpressions.size() > 0){
        //qDebug() << "Grammarexpression given as" << grammarexpressions;
        grammarid = createGrammarFormId(language,grammarexpressions);
    }
    else {
        //qDebug() << "No grammarexpression given";
    }
    // First search the cued forms:
    QList<lexeme>* lexemes;
    for(int i=0; i<2; i++){
        switch(i){
            case 0:
                lexemes = &m_lexemes;
                break;
            case 1:
                lexemes = &(m_current_translation->lexemes);
                break;
        }
        foreach(const lexeme& m_lexeme, *lexemes)
            foreach(const form& m_form, m_lexeme.forms)
                if(m_form.string == string)
                    if((m_form.grammarform == grammarid) || (grammarid == 0))
                        return m_form.id;
    }
    QList<int> formids = m_database->searchForms(string,true);
    foreach(int formid, formids){
        int gf = m_database->grammarFormFromFormId(formid);
        if((gf == grammarid) || (grammarid == 0)){
            int lexeme_id = m_database->lexemeFromFormId(formid);
            int found_lang_id = m_database->languageIdFromLexemeId(lexeme_id);
            if((found_lang_id == language) || (language == 0))
                return formid;
        }
    }
    return 0;
}

int edit::lookupLexeme(int formid){
    // First search the cued forms:
    QList<lexeme>* lexemes;
    for(int i=0; i<2; i++){
        switch(i){
            case 0:
                lexemes = &m_lexemes;
                break;
            case 1:
                lexemes = &(m_current_translation->lexemes);
                break;
        }
        foreach(const lexeme& m_lexeme, *lexemes)
            foreach(const form& m_form, m_lexeme.forms)
                if(m_form.id == formid)
                    return m_lexeme.id;
    }
    // Let's check the database:
    return m_database->lexemeFromFormId(formid);
}

QString edit::prettyPrintLexeme(int lexeme_id){
    QString pretty_string;
    if(lexeme_id < 0){
        // First search the cued forms:
        QList<lexeme>* lexemes;
        for(int i=0; i<2; i++){
            switch(i){
                case 0:
                    lexemes = &m_lexemes;
                    break;
                case 1:
                    lexemes = &(m_current_translation->lexemes);
                    break;
            }
            foreach(const lexeme& m_lexeme, *lexemes)
                if(lexeme_id == m_lexeme.id){
                    foreach(const form& m_form, m_lexeme.forms)
                        pretty_string += m_form.string + ", ";
                    pretty_string.chop(2);
                    return pretty_string;
                }
        }
        qDebug() << "Unexpected error: lexeme_id < 0 but could not find any forms!";
    }
    return m_database->prettyPrintLexeme(lexeme_id);
}

int edit::formIdToNewId(int id){
    QList<lexeme>* lexemes;
    for(int i=0; i<2; i++){
        switch(i){
            case 0:
                lexemes = &m_lexemes;
                break;
            case 1:
                lexemes = &(m_current_translation->lexemes);
                break;
        }
        foreach(const lexeme& m_lexeme, *lexemes)
            foreach(const form& m_form, m_lexeme.forms)
                if(m_form.id == id)
                    return m_form.newid;
    }
    return 0;
}

QString edit::stringFromFormId(int formid){
    QList<lexeme>* lexemes;
    for(int i=0; i<2; i++){
        switch(i){
            case 0:
                lexemes = &m_lexemes;
                break;
            case 1:
                lexemes = &(m_current_translation->lexemes);
                break;
        }
        foreach(const lexeme& m_lexeme, *lexemes)
            foreach(const form& m_form, m_lexeme.forms)
                if(m_form.id == formid)
                    return m_form.string;
    }
    return "";
}

int edit::grammarIdFromFormId(int formid){
    QList<lexeme>* lexemes;
    for(int i=0; i<2; i++){
        switch(i){
            case 0:
                lexemes = &m_lexemes;
                break;
            case 1:
                lexemes = &(m_current_translation->lexemes);
                break;
        }
        foreach(const lexeme& m_lexeme, *lexemes)
            foreach(const form& m_form, m_lexeme.forms)
                if(m_form.id == formid)
                    return m_form.grammarform;
    }
    return 0;
}

int edit::lookupFormLexeme(int language, int lexemeid, QString string, QList<QList<QString> > grammarexpressions){
    int grammarid = 0;
    if(grammarexpressions.size() > 0){
        //qDebug() << "Grammarexpression given as" << grammarexpressions;
        grammarid = createGrammarFormId(language,grammarexpressions);
    }
    else {
        //qDebug() << "No grammarexpression given";
    }
    // First search the cued forms:
    QList<lexeme>* lexemes;
    for(int i=0; i<2; i++){
        switch(i){
            case 0:
                lexemes = &m_lexemes;
                break;
            case 1:
                lexemes = &(m_current_translation->lexemes);
                break;
        }
        foreach(const lexeme& m_lexeme, *lexemes)
            if(m_lexeme.id == lexemeid)
                foreach(const form& m_form, m_lexeme.forms)
                    if(m_form.string == string)
                        if((m_form.grammarform == grammarid) || (grammarid == 0))
                            return m_form.id;
    }
    QList<int> formids = m_database->searchForms(string,true);
    foreach(int formid, formids){
        int gf = m_database->grammarFormFromFormId(formid);
        if((gf == grammarid) || (grammarid == 0))
            return formid;
    }
    qDebug() << "FAILED lookupFormLexeme" << language << lexemeid << string << grammarexpressions;
    return 0;
}

void edit::addLexeme(int lexemeid, int languageid, int translationid){
    QList<lexeme>* lexemes;
    if(translationid==0)
        lexemes = &m_lexemes;
    else{
        lexemes = &(m_current_translation->lexemes);
    }
    lexeme newLexeme = {lexemeid,0,languageid,{}};
    lexemes->push_back(newLexeme);
}

void edit::addScheduledLexemeHeuristically(void){
    if(!m_scheduled_adds.isEmpty()){
        scheduled_add scha = m_scheduled_adds.first();
        qDebug() << "Processing scheduled lexeme " << scha.m_lexeme;
        m_scheduled_adds.removeFirst();
        addLexemeHeuristically(scha.m_caller, scha.m_languageid, scha.m_lexeme, scha.m_translationid);
    }
    else{
        // m_add_busy == true should not happen here:
        if(m_add_busy) qDebug() << "This seems to be a bug / race condition in edit::addScheduledLexemeHeuristically";
        m_add_busy = false;
    }
}

void edit::debugStatusCuedLexemes(){
    QList<lexeme>* lexemes;
    for(int i=0; i<2; i++){
        switch(i){
            case 0:
                lexemes = &m_lexemes;
                qDebug() << "Lexemes outside of translation:";
                break;
            case 1:
                lexemes = &(m_current_translation->lexemes);
                qDebug() << "Translation lexemes:";
                break;
        }
        foreach(const lexeme& m_lexeme, *lexemes)
            qDebug() << "  " << m_database->languagenamefromid(m_lexeme.languageid) << prettyPrintLexeme(m_lexeme.id);
    }
}

void edit::moveLexemeOutOfTranslation(int language, QString text){
    int form_id = lookupForm(language, 0, text, {});
    if(form_id == 0) return;
    int lexeme_id = lookupLexeme(form_id);
    if(lexeme_id == 0) return;
    QList<lexeme>* lexemes = &(m_current_translation->lexemes);
    int i=0;
    lexeme found_lexeme;
    foreach(const lexeme& m_lexeme, *lexemes){
        if(m_lexeme.id == lexeme_id){
            found_lexeme = m_lexeme;
            m_current_translation->lexemes.removeAt(i);
            m_lexemes.append(found_lexeme);
            return;
        }
        i++;
    }
}

void edit::addLexemeHeuristically(QObject* caller, int languageid, QString lexeme, int translationid){
    if(lexeme.isEmpty()){
        return;
    }
    if(m_add_busy == true){
        qDebug() << "Edit is busy... scheduling for later";
        m_scheduled_adds.push_back({caller,languageid,lexeme,translationid});
        return;
    }
    else{
        m_add_busy = true;
    }
    qDebug() << "Processing" << lexeme;
    m_caller = caller;
    m_current_language_id = languageid;
    m_current_translation_id = translationid;
    if(lexeme.contains(' ')){
        if(lexeme.contains('.')){
            //sentence
            emit addLexemeHeuristicallyResult(m_caller, "<i>Sentence not implemented yet, sorry!</i>");
        }
        else if(lexeme.contains(", ")){
            //multiple meanings
            emit addLexemeHeuristicallyResult(m_caller, "<i>Multiple meanings not implemented yet, sorry!</i>");
        }
    }
    else{
        //single word
        // Let's see first, if we have it in the database...
        qDebug() << "Checking if we have it available...";
        int form_id = lookupForm(languageid, 0, lexeme, {});
        if(form_id != 0){
            qDebug() << "Seems we have it, form_id =" << form_id;
            int lexeme_id = lookupLexeme(form_id);
            // We found it, great!
            qDebug() << "lexeme_id =" << lexeme_id;
            addLexeme(lexeme_id, m_current_language_id, m_current_translation_id);
            emit addLexemeHeuristicallyResult(m_caller, prettyPrintLexeme(lexeme_id));
            m_add_busy = false;
            addScheduledLexemeHeuristically();
        }
        else {
            connect(m_grammarprovider,&grammarprovider::grammarInfoAvailable,this,&edit::grammarInfoAvailableFromGrammarProvider);
            connect(m_grammarprovider,&grammarprovider::grammarInfoNotAvailable,this,&edit::grammarInfoNotAvailableFromGrammarProvider);
            connect(m_grammarprovider,&grammarprovider::networkError, this, &edit::networkErrorFromGrammarProvider);
            qDebug() << "Looking up" << lexeme;
            m_grammarprovider->getGrammarInfoForWord(m_caller, languageid, lexeme);
        }
    }
}

void edit::networkErrorFromGrammarProvider(QObject* caller, bool silent){
    disconnect(m_grammarprovider,&grammarprovider::grammarInfoAvailable,this,&edit::grammarInfoAvailableFromGrammarProvider);
    disconnect(m_grammarprovider,&grammarprovider::grammarInfoNotAvailable,this,&edit::grammarInfoNotAvailableFromGrammarProvider);
    disconnect(m_grammarprovider,&grammarprovider::networkError, this, &edit::networkErrorFromGrammarProvider);
    emit addLexemeHeuristicallyResult(m_caller, "<b>Warning:</b> Network error when trying to look up grammar information on en.wiktionary.org. Do we have internet access?");
    m_add_busy = false;
}

void edit::grammarInfoNotAvailableFromGrammarProvider(QObject* caller, bool silent){
    disconnect(m_grammarprovider,&grammarprovider::grammarInfoAvailable,this,&edit::grammarInfoAvailableFromGrammarProvider);
    disconnect(m_grammarprovider,&grammarprovider::grammarInfoNotAvailable,this,&edit::grammarInfoNotAvailableFromGrammarProvider);
    disconnect(m_grammarprovider,&grammarprovider::networkError, this, &edit::networkErrorFromGrammarProvider);
    emit addLexemeHeuristicallyResult(m_caller, "<b>Warning:</b> Could not obtain grammar information for this word - could there be a spelling mistake or maybe the word is missing on en.wiktionary.org?");
    m_add_busy = false;
}

void edit::grammarInfoAvailableFromGrammarProvider(QObject* caller, int numberOfObjects, bool silent){
    qDebug() << __FUNCTION__ << __LINE__ << "silent" << silent;
    this->disconnect();
    disconnect(m_grammarprovider,&grammarprovider::grammarInfoAvailable,this,&edit::grammarInfoAvailableFromGrammarProvider);
    disconnect(m_grammarprovider,&grammarprovider::grammarInfoNotAvailable,this,&edit::grammarInfoNotAvailableFromGrammarProvider);
    disconnect(m_grammarprovider,&grammarprovider::networkError, this, &edit::networkErrorFromGrammarProvider);
    disconnect(m_grammarprovider,&grammarprovider::formObtained,this,&edit::formObtainedFromGrammarProvider);
    disconnect(m_grammarprovider,&grammarprovider::compoundFormObtained,this,&edit::compoundFormObtainedFromGrammarProvider);
    disconnect(m_grammarprovider,&grammarprovider::sentenceAvailable,this,&edit::sentenceAvailableFromGrammarProvider);
    disconnect(m_grammarprovider,&grammarprovider::sentenceLookupForm,this,&edit::sentenceLookupFormFromGramarProvider);
    disconnect(m_grammarprovider,&grammarprovider::sentenceLookupFormLexeme,this,&edit::sentenceLookupFormLexemeFromGrammarProvider);
    disconnect(m_grammarprovider,&grammarprovider::sentenceAddAndUseForm,this,&edit::sentenceAddAndUseFormFromGrammarProvider);
    disconnect(m_grammarprovider,&grammarprovider::sentenceAddAndIgnoreForm,this,&edit::sentenceAddAndIgnoreFormFromGrammerProvider);
    disconnect(m_grammarprovider,&grammarprovider::sentenceComplete,this,&edit::sentenceCompleteFromGrammarProvider);
    disconnect(m_grammarprovider,&grammarprovider::grammarInfoComplete,this,&edit::grammarInfoCompleteFromGrammarProvider);

    m_current_lexeme_id = lexemeId();
    qDebug() << "Obtained " << numberOfObjects << " forms for lexeme " << m_current_lexeme_id;
    connect(m_grammarprovider,&grammarprovider::formObtained,this,&edit::formObtainedFromGrammarProvider);
    connect(m_grammarprovider,&grammarprovider::compoundFormObtained,this,&edit::compoundFormObtainedFromGrammarProvider);
    connect(m_grammarprovider,&grammarprovider::sentenceAvailable,this,&edit::sentenceAvailableFromGrammarProvider);
    connect(m_grammarprovider,&grammarprovider::sentenceLookupForm,this,&edit::sentenceLookupFormFromGramarProvider);
    connect(m_grammarprovider,&grammarprovider::sentenceLookupFormLexeme,this,&edit::sentenceLookupFormLexemeFromGrammarProvider);
    connect(m_grammarprovider,&grammarprovider::sentenceAddAndUseForm,this,&edit::sentenceAddAndUseFormFromGrammarProvider);
    connect(m_grammarprovider,&grammarprovider::sentenceAddAndIgnoreForm,this,&edit::sentenceAddAndIgnoreFormFromGrammerProvider);
    connect(m_grammarprovider,&grammarprovider::sentenceComplete,this,&edit::sentenceCompleteFromGrammarProvider);
    connect(m_grammarprovider,&grammarprovider::grammarInfoComplete,this,&edit::grammarInfoCompleteFromGrammarProvider);
    m_grammarprovider->getNextGrammarObject(caller);
}

void edit::formObtainedFromGrammarProvider(QObject* caller, QString form, QList<QList<QString> > grammarexpressions, bool silent){
    // qDebug() << __FUNCTION__ << __LINE__ << "silent" << silent;
    int grammar_id = createGrammarFormId(m_current_language_id, grammarexpressions);
    int form_id = formId();
    //qDebug() << "Obtained form " << form << "id" << form_id;
    if(!silent){
        m_current_pretty_lexeme += form + ", ";
        addForm(m_current_lexeme_id,form_id,grammar_id,form,m_current_language_id, m_current_translation_id);
    }
    else{
        // Don't add to translation but as normal lexeme:
        addForm(m_current_lexeme_id,form_id,grammar_id,form,m_current_language_id, 0);
    }
    m_grammarprovider->getNextGrammarObject(caller);
}

void edit::compoundFormObtainedFromGrammarProvider(QObject* caller, QString form, bool silent){
    qDebug() << __FUNCTION__ << __LINE__ << "silent" << silent;
    // Not implemented in grammar provider yet
}

void edit::sentenceAvailableFromGrammarProvider(QObject* caller, int parts, bool silent){
    qDebug() << __FUNCTION__ << __LINE__ << "silent" << silent;
    m_current_sentence_id = sentenceId();
    //qDebug() << "Obtained " << parts << "sentence parts for sentence" << m_current_sentence_id;
    m_grammarprovider->getNextSentencePart(caller);
}

void edit::sentenceLookupFormFromGramarProvider(QObject* caller, QString form, QList<QList<QString> > grammarexpressions, bool silent){
    qDebug() << __FUNCTION__ << __LINE__ << "silent" << silent;
    int form_id = lookupForm(m_current_language_id, m_current_lexeme_id, form, grammarexpressions);
    //qDebug() << "Sentence part " << form << "looked up as id" << form_id << "for sentence id " << m_current_sentence_id;
    if(!silent)
        m_current_pretty_lexeme += form + " ";
    m_current_sentence_parts.push_back({form_id,0,false});
    m_grammarprovider->getNextSentencePart(caller);
}

void edit::sentenceLookupFormLexemeFromGrammarProvider(QObject* caller, QString form, QList<QList<QString> > grammarexpressions, bool silent){
    qDebug() << __FUNCTION__ << __LINE__ << "silent" << silent;
    int form_id = lookupFormLexeme(m_current_language_id, m_current_lexeme_id, form, grammarexpressions);
    //qDebug() << "Sentence part " << form << "looked up with lexeme as id" << form_id << "for sentence id " << m_current_sentence_id;
    if(!silent)
        m_current_pretty_lexeme += form + " ";
    m_current_sentence_parts.push_back({form_id,0,false});
    m_grammarprovider->getNextSentencePart(caller);
}

void edit::sentenceAddAndUseFormFromGrammarProvider(QObject* caller, QString form, QList<QList<QString> > grammarexpressions, bool silent){
    qDebug() << __FUNCTION__ << __LINE__ << "silent" << silent;
    // FIXME Currently not used by any grammar, should be implemented
    //qDebug() << "sentenceAddAndUseFormFromGrammarProvider not implemented yet!";

    m_grammarprovider->getNextSentencePart(caller);
}

void edit::sentenceAddAndIgnoreFormFromGrammerProvider(QObject* caller, QString form, QList<QList<QString> > grammarexpressions, bool silent){
    qDebug() << __FUNCTION__ << __LINE__ << "silent" << silent;
    // FIXME Currently not used by any grammar, should be implemented
    //qDebug() << "sentenceAddAndIgnoreFormFromGrammerProvider not implemented yet!";
    m_grammarprovider->getNextSentencePart(caller);
}

void edit::sentenceCompleteFromGrammarProvider(QObject* caller, QList<QList<QString> > grammarexpressions, bool silent){
    qDebug() << __FUNCTION__ << __LINE__ << "silent" << silent;
    int grammar_id = createGrammarFormId(m_current_language_id, grammarexpressions);
    //qDebug() << "Sentence with id " << m_current_sentence_id << "complete";
    if(!silent){
        m_current_pretty_lexeme.chop(1);
        m_current_pretty_lexeme += ", ";
    }
    addSentence(m_current_lexeme_id, m_current_sentence_id, grammar_id, m_current_sentence_parts, m_current_language_id);
    m_current_sentence_parts.clear();
    m_grammarprovider->getNextGrammarObject(caller);
}

void edit::grammarInfoCompleteFromGrammarProvider(QObject* caller, bool silent){
    static int numberofcalls = 0;
    numberofcalls++;
    this->disconnect();
    disconnect(m_grammarprovider,&grammarprovider::formObtained,this,&edit::formObtainedFromGrammarProvider);
    disconnect(m_grammarprovider,&grammarprovider::compoundFormObtained,this,&edit::compoundFormObtainedFromGrammarProvider);
    disconnect(m_grammarprovider,&grammarprovider::sentenceAvailable,this,&edit::sentenceAvailableFromGrammarProvider);
    disconnect(m_grammarprovider,&grammarprovider::sentenceLookupForm,this,&edit::sentenceLookupFormFromGramarProvider);
    disconnect(m_grammarprovider,&grammarprovider::sentenceLookupFormLexeme,this,&edit::sentenceLookupFormLexemeFromGrammarProvider);
    disconnect(m_grammarprovider,&grammarprovider::sentenceAddAndUseForm,this,&edit::sentenceAddAndUseFormFromGrammarProvider);
    disconnect(m_grammarprovider,&grammarprovider::sentenceAddAndIgnoreForm,this,&edit::sentenceAddAndIgnoreFormFromGrammerProvider);
    disconnect(m_grammarprovider,&grammarprovider::sentenceComplete,this,&edit::sentenceCompleteFromGrammarProvider);
    disconnect(m_grammarprovider,&grammarprovider::grammarInfoComplete,this,&edit::grammarInfoCompleteFromGrammarProvider);

    qDebug() << __FUNCTION__ << __LINE__ << "silent" << silent << numberofcalls << "caller" << caller;
    qDebug() << "Grammar info complete";
    if(!silent){
        m_current_pretty_lexeme.chop(2);
        emit addLexemeHeuristicallyResult(m_caller, m_current_pretty_lexeme);
        m_current_pretty_lexeme.clear();
    }
    else {
        connect(m_grammarprovider,&grammarprovider::grammarInfoAvailable,this,&edit::grammarInfoAvailableFromGrammarProvider);
    }
    m_add_busy = false;
    addScheduledLexemeHeuristically();
}

void edit::resetEverything(void){
    m_current_translation->lexemes.clear();
    m_lexemes.clear();
    m_translationId = -1;
    m_lexemeId = -1;
    m_sentenceId = -1;
    m_formId = -1;
    m_compoundFormId = -1;
    m_grammarFormId = -1;
    m_grammarFormComponentId = -1;
}

void edit::saveToDatabase(void){
    emit processingStart("Saving to database...");
    QList<lexeme>* lexemes;
    m_current_translation->newid = m_database->newTranslation();
    for(int i=0; i<2; i++){
        qDebug() << "Lexeme" << i;
        switch(i){
            case 0:
                lexemes = &m_lexemes;
                break;
            case 1:
                lexemes = &(m_current_translation->lexemes);
                break;
        }
        QMutableListIterator<lexeme> lexemei(*lexemes);
        while(lexemei.hasNext()){
            lexeme& currentLexeme = lexemei.next();
            qDebug() << "newLexeme" << currentLexeme.languageid;
            if(currentLexeme.id < 0)
                currentLexeme.newid = m_database->newLexeme(currentLexeme.languageid);
            else
                currentLexeme.newid = currentLexeme.id;
            if(i==1){
                //qDebug() << "newTranslationPart" << m_translation.newid << currentLexeme.newid;
                m_database->newTranslationPart(m_current_translation->newid, currentLexeme.newid, 0, 0, 0, 0);
                //qDebug() << "<<newTranslationPart";
            }
            QMutableListIterator<form> formi(currentLexeme.forms);
            while(formi.hasNext()){
                form& currentForm = formi.next();
                //qDebug() << "newForm" << currentLexeme.newid << currentForm.grammarform << currentForm.string;
                if(currentForm.id < 0)
                    currentForm.newid = m_database->newForm(currentLexeme.newid, currentForm.grammarform, currentForm.string);
                else
                    currentForm.newid = currentForm.id;
            }
            QMutableListIterator<sentence> sentencei(currentLexeme.sentences);
            while(sentencei.hasNext()){
                sentence& currentSentence = sentencei.next();
                //qDebug() << "saveSentence" << currentLexeme.newid << currentSentence.grammarform;
                if(currentSentence.id < 0)
                    currentSentence.newid = m_database->newSentence(currentLexeme.newid, currentSentence.grammarform);
                else
                    currentSentence.newid = currentSentence.id;
                QMutableListIterator<sentencepart> sentenceparti(currentSentence.parts);
                int spart=1;
                int sn=0;
                while(sentenceparti.hasNext()){
                    sentencepart& currentSentencePart = sentenceparti.next();
                    int formid = 0;
                    int compoundformid = 0;
                    int grammarformid = 0;
                    int punctuationmarkid = 0;
                    switch(currentSentencePart.type){
                        case FORM:
                            formid = currentSentencePart.id;
                            if(formid < 0){
                                formid = formIdToNewId(formid);
                            }
                            //qDebug() << m_database->prettyPrintForm(formid);
                            break;
                        case COMPOUNDFORM:
                            compoundformid = currentSentencePart.id;
                            if(compoundformid < 0)
                                qDebug() << "Unexpected negative compoundform id!";
                            break;
                        case GRAMMARFORM:
                            grammarformid = currentSentencePart.id;
                            if(grammarformid < 0)
                                qDebug() << "Unexpected negative grammarform id!";
                            break;
                        case PUNCTUATION_MARK:
                            punctuationmarkid = currentSentencePart.id;
                            if(punctuationmarkid < 0)
                                qDebug() << "Unexpected negative punctuation mark id!";
                            break;
                    }
                    //qDebug() << "saveSentencePart" << currentSentence.newid << spart << currentSentencePart.capitalized << formid << compoundformid << grammarformid << punctuationmarkid;
                    //qDebug() << "newSentencePart" << currentSentence.newid << spart << currentSentencePart.capitalized << formid << compoundformid << grammarformid << punctuationmarkid;
                    if(currentSentencePart.id < 0)
                        currentSentencePart.newid = m_database->newSentencePart(currentSentence.newid, spart, currentSentencePart.capitalized, formid, compoundformid, grammarformid, punctuationmarkid); 
                    else
                        currentSentencePart.newid = currentSentencePart.id;
                    spart++;
                }
            }
        }
    }
    emit processingStop();
}
@}
