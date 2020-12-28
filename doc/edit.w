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
        COMPUNDFORM,
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
        QList<form> forms;
        QList<sentence> sentences;
    };
    QList<lexeme> m_lexemes;
    database* m_database;
    QString m_dbversion;
    struct lexeme& getCreateLexeme(int lexemeid);
public:
    Q_INVOKABLE int createGrammarFormId(int language, QList<QList<QString> > grammarexpressions);
    Q_INVOKABLE void addForm(int lexemeid, int formid, int grammarform, QString string);
    Q_INVOKABLE void addSentence(int lexemeid, int sentenceid, int grammarform, QList<QList<int> > parts);
    Q_INVOKABLE int lookupForm(int language, int lexemeid, QString string, QList<QList<QString> > grammarexpressions);
    Q_INVOKABLE QString stringFromFormId(int formid);
    Q_INVOKABLE int grammarIdFromFormId(int formid);
    Q_INVOKABLE int lookupFormLexeme(int language, int lexemeid, QString string, QList<QList<QString> > grammarexpressions);

    Q_INVOKABLE void addLexeme(int lexemeid);
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

void edit::addForm(int lexemeid, int formid, int grammarform, QString string){
    static int numberOfCalls=0;
    form newForm = {formid,0,string,grammarform};
    lexeme& currentLexeme = getCreateLexeme(lexemeid);
    currentLexeme.forms.push_back(newForm);
}

edit::lexeme& edit::getCreateLexeme(int lexemeid){
    bool foundLexeme = false;
    QMutableListIterator<lexeme> lexemei(m_lexemes);
    while(lexemei.hasNext()){
        lexeme& currentLexeme = lexemei.next();
        if(currentLexeme.id == lexemeid){
            return currentLexeme;
        }
    }
    addLexeme(lexemeid);
    return m_lexemes[m_lexemes.size()-1];
}

void edit::addSentence(int lexemeid, int sentenceid, int grammarform, QList<QList<int> > parts){
    QList<int> part;
    QList<sentencepart> sparts;
    foreach(part, parts){
        if(part.size() != 3){
            qDebug() << "Malformed sentence part (size=" + QString::number(part.size()) + ")";
            continue;
        }
        sentencepart newSentencePart = {part[0],0,sentencePartType(part[1]),bool(part[2])};
        sparts.push_back(newSentencePart);
    }
    sentence newSentence = {sentenceid,0,grammarform,sparts};
    lexeme& currentLexeme = getCreateLexeme(lexemeid);
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
    foreach(const lexeme& m_lexeme, m_lexemes)
        foreach(const form& m_form, m_lexeme.forms)
            if(m_form.string == string)
                if((m_form.grammarform == grammarid) || (grammarid == 0))
                    return m_form.id;
    QList<int> formids = m_database->searchForms(string,true);
    foreach(int formid, formids){
        int gf = m_database->grammarFormFromFormId(formid);
        if((gf == grammarid) || (grammarid == 0))
            return formid;
    }
    return 0;
}

QString edit::stringFromFormId(int formid){
    foreach(const lexeme& m_lexeme, m_lexemes)
        foreach(const form& m_form, m_lexeme.forms)
            if(m_form.id == formid)
                return m_form.string;
}

int edit::grammarIdFromFormId(int formid){
    foreach(const lexeme& m_lexeme, m_lexemes)
        foreach(const form& m_form, m_lexeme.forms)
            if(m_form.id == formid)
                return m_form.grammarform;
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
    foreach(const lexeme& m_lexeme, m_lexemes)
        if(m_lexeme.id == lexemeid)
            foreach(const form& m_form, m_lexeme.forms)
                if(m_form.string == string)
                    if((m_form.grammarform == grammarid) || (grammarid == 0))
                        return m_form.id;
    QList<int> formids = m_database->searchForms(string,true);
    foreach(int formid, formids){
        int gf = m_database->grammarFormFromFormId(formid);
        if((gf == grammarid) || (grammarid == 0))
            return formid;
    }
    return 0;
}

void edit::addLexeme(int lexemeid){
    lexeme newLexeme = {lexemeid,0,{}};
    m_lexemes.push_back(newLexeme);
}
@}
