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
    translation m_translation;
    QList<lexeme> m_lexemes;
    database* m_database;
    QString m_dbversion;
    struct lexeme& getCreateLexeme(int lexemeid, int languageid, int translationid=0);
public:
    Q_INVOKABLE int createGrammarFormId(int language, QList<QList<QString> > grammarexpressions);
    Q_INVOKABLE void addForm(int lexemeid, int formid, int grammarform, QString string, int languageid, int translationid=0);
    Q_INVOKABLE void addSentence(int lexemeid, int sentenceid, int grammarform, QList<QList<int> > parts, int languageid, int translationid=0);
    Q_INVOKABLE int lookupForm(int language, int lexemeid, QString string, QList<QList<QString> > grammarexpressions);
    Q_INVOKABLE int formIdToNewId(int id);
    Q_INVOKABLE QString stringFromFormId(int formid);
    Q_INVOKABLE int grammarIdFromFormId(int formid);
    Q_INVOKABLE int lookupFormLexeme(int language, int lexemeid, QString string, QList<QList<QString> > grammarexpressions);
    Q_INVOKABLE void resetEverything(void);
    Q_INVOKABLE void saveToDatabase(void);
    void addLexeme(int lexemeid, int languageid, int translationid=0);
signals:
    void dbversionChanged(const QString &newVersion);
@<End of class and header @>
@}

\section{Implementation}

@o ../src/edit.cpp -d
@{
#include "edit.h"

edit::edit(QObject *parent) : QObject(parent)
{

    QQmlEngine* engine = qobject_cast<QQmlEngine*>(parent);
    m_database = engine->singletonInstance<database*>(qmlTypeId("DatabaseLib", 1, 0, "Database"));
    m_dbversion = m_database->property("version").toString();
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
        lexemes = &(m_translation.lexemes);
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
                lexemes = &(m_translation.lexemes);
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
        if((gf == grammarid) || (grammarid == 0))
            return formid;
    }
    return 0;
}


int edit::formIdToNewId(int id){
    QList<lexeme>* lexemes;
    for(int i=0; i<2; i++){
        switch(i){
            case 0:
                lexemes = &m_lexemes;
                break;
            case 1:
                lexemes = &(m_translation.lexemes);
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
                lexemes = &(m_translation.lexemes);
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
                lexemes = &(m_translation.lexemes);
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
                lexemes = &(m_translation.lexemes);
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
        lexemes = &(m_translation.lexemes);
    }
    lexeme newLexeme = {lexemeid,0,languageid,{}};
    lexemes->push_back(newLexeme);
}


void edit::resetEverything(void){
    m_translation.lexemes.clear();
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
    QList<lexeme>* lexemes;
    m_translation.newid = m_database->newTranslation();
    for(int i=0; i<2; i++){
        qDebug() << "Lexeme" << i;
        switch(i){
            case 0:
                lexemes = &m_lexemes;
                break;
            case 1:
                lexemes = &(m_translation.lexemes);
                break;
        }
        QMutableListIterator<lexeme> lexemei(*lexemes);
        while(lexemei.hasNext()){
            lexeme& currentLexeme = lexemei.next();
            qDebug() << "newLexeme" << currentLexeme.languageid;
            currentLexeme.newid = m_database->newLexeme(currentLexeme.languageid);
            if(i==1){
                qDebug() << "newTranslationPart" << m_translation.newid << currentLexeme.newid;
                m_database->newTranslationPart(m_translation.newid, currentLexeme.newid, 0, 0, 0, 0);
                qDebug() << "<<newTranslationPart";
            }
            QMutableListIterator<form> formi(currentLexeme.forms);
            while(formi.hasNext()){
                form& currentForm = formi.next();
                qDebug() << "newForm" << currentLexeme.newid << currentForm.grammarform << currentForm.string;
                currentForm.newid = m_database->newForm(currentLexeme.newid, currentForm.grammarform, currentForm.string);
            }
            QMutableListIterator<sentence> sentencei(currentLexeme.sentences);
            while(sentencei.hasNext()){
                sentence& currentSentence = sentencei.next();
                //qDebug() << "saveSentence" << currentLexeme.newid << currentSentence.grammarform;
                currentSentence.newid = m_database->newSentence(currentLexeme.newid, currentSentence.grammarform);
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
                            qDebug() << m_database->prettyPrintForm(formid);
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
                    qDebug() << "newSentencePart" << currentSentence.newid << spart << currentSentencePart.capitalized << formid << compoundformid << grammarformid << punctuationmarkid;
                    currentSentencePart.newid = m_database->newSentencePart(currentSentence.newid, spart, currentSentencePart.capitalized, formid, compoundformid, grammarformid, punctuationmarkid); 
                    spart++;
                }
            }
        }
    }
}
@}
