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

\section{Database edit}
This window allows the changing and deleting of single database items.

\subsection{Implementation}

@o ../src/ColeitraWidgetSearchPopupGrammar.qml
@{
import QtQuick 2.14
import QtQuick.Controls 2.14
import DatabaseLib 1.0
import SettingsLib 1.0

Popup {
    property string popupSearchString: "Search grammarforms:"
    property int selectedId: selectedId.value
    property var okFunction: function() {};
    property var searchFunction: function() {
        var numberOfGrammarExpressions = grammarExpressions.children.length;
        var grammarexpressions = [];
        for(var i=0; i<numberOfGrammarExpressions-1; i++){
            var key = grammarExpressions.children[i].gklabel.text;
            var value = grammarExpressions.children[i].gvlabel.text;
            grammarexpressions.push([key,value]);
        }
        var grammarIds = Database.searchGrammarFormsFromStrings(Database.idfromlanguagename(languageSelection.currentText), grammarexpressions);
        for(var i = popupIdList.children.length; i > 0; i--) {
            popupIdList.children[i-1].destroy()
        }
        var numberOfDestroyedChildren = popupIdList.children.length;
        for(var grammarId of grammarIds){
            popupIdList.addPart();
            popupIdList.lastCreatedObject.text = Database.prettyPrintGrammarForm(grammarId);
            popupIdList.lastCreatedObject.value = grammarId;
        }
        if(popupIdList.children.length > numberOfDestroyedChildren){
            popupIdList.children[numberOfDestroyedChildren].checked = true;
        }
        else {
            console.log("No children in popupIdList!");
        }
    }

    property var popupIdList: idList
    Column {
        width: parent.width
        ColeitraGridLabel {
            text: popupSearchString
        }
        ColeitraGridComboBox {
            model: moveNativeAndTrainingLanguageToTop(Database.languagenames());
            id: languageSelection
            width: parent.width
            function moveNativeAndTrainingLanguageToTop(languagelist) {
                var nativelanguage = Database.languagenamefromid(Settings.nativelanguage);
                languagelist.splice(languagelist.indexOf(nativelanguage),1);
                languagelist.unshift(nativelanguage);
                var learninglanguage = Database.languagenamefromid(Settings.learninglanguage);
                languagelist.splice(languagelist.indexOf(learninglanguage),1);
                languagelist.unshift(learninglanguage);
                return languagelist;
            }
        }
        ColeitraWidgetEditGrammarFormComponentList {
            width: parent.width
            id: grammarExpressions
        }
        ButtonGroup {
            buttons: idList.children
        }
        ScrollView {
            height: idList.children.length<=3? 40*idList.children.length : 140
            width: parent.width
            clip: true
            ColeitraWidgetEditPartList {
                property int selectedIdFromIdList: 0
                id: idList
                startWithOneElement: false
                partType: "ColeitraWidgetEditIdRadioButton"
                width: parent.width
                onSelectedIdFromIdListChanged: function(){
                    selectedId.value = selectedIdFromIdList;
                }
            }
        }
        SpinBox {
            id: selectedId
            width: parent.width
            editable: true
            from: -9999
            to: 9999
        }
        Row {
            ColeitraGridButton {
                id: searchButton
                text: "Search"
                onClicked: searchFunction()
            }
            Rectangle {
                height: 1
                width: parent.parent.width - searchButton.width - okButton.width
            }
            ColeitraGridButton {
                id: okButton
                text: "Ok"
                onClicked: okFunction()
            }
        }
    }
    @<Background grey rounded control@>
}
@}


@O ../src/ColeitraWidgetSearchPopupLexeme.qml
@{
import DatabaseLib 1.0

ColeitraWidgetEditSearchPopup {
    width: parent.width
    id: lexemePopup
    popupSearchString: "Search lexemes:"
    searchFunction: function() {
        var lexemeIds = Database.searchLexemes(searchValue);
        for(var i = popupIdList.children.length; i > 0; i--) {
            popupIdList.children[i-1].destroy()
        }
        var numberOfDestroyedChildren = popupIdList.children.length;
        for(var lexemeid of lexemeIds){
            popupIdList.addPart();
            popupIdList.lastCreatedObject.text = Database.prettyPrintLexeme(lexemeid);
            popupIdList.lastCreatedObject.value = lexemeid;
        }
        if(popupIdList.children.length > numberOfDestroyedChildren){
            popupIdList.children[numberOfDestroyedChildren].checked = true;
        }
        else {
            console.log("No children in popupIdList!");
        }
    }
}
@}

@O ../src/ColeitraWidgetSearchPopupForm.qml
@{
import DatabaseLib 1.0

ColeitraWidgetEditSearchPopup {
        width: parent.width
        id: formPopup
        popupSearchString: "Search forms:"
        searchFunction: function() {
            var formIds = Database.searchForms(searchValue);
            for(var i = popupIdList.children.length; i > 0; i--) {
                popupIdList.children[i-1].destroy()
            }
            var numberOfDestroyedChildren = popupIdList.children.length;
            for(var formid of formIds){
                popupIdList.addPart();
                if(formid<0){
                    var formstring = Edit.stringFromFormId(formid);
                    var grammarid = Edit.grammarIdFromFormId(formid);
                    popupIdList.lastCreatedObject.text = Database.prettyPrintForm(formid, formstring, grammarid);
                }
                else {
                    popupIdList.lastCreatedObject.text = Database.prettyPrintForm(formid);
                }
                popupIdList.lastCreatedObject.value = formid;
            }
            if(popupIdList.children.length > numberOfDestroyedChildren){
                popupIdList.children[numberOfDestroyedChildren].checked = true;
            }
            else {
                console.log("No children in popupIdList!");
            }
        }
    }
@}

@O ../src/ColeitraWidgetDatabaseFormEdit.qml
@{
import QtQuick 2.14
import QtQuick.Controls 2.14
import DatabaseLib 1.0
import EditLib 1.0
import DatabaseLib 1.0
import SettingsLib 1.0

Column {
    width: parent? parent.width : 100
    property var saveFunction: function () {
        var newlexeme = -1;
        var newgrammarform = -1;
        var newstring = "";
        if(lexemeId.value != Database.lexemeFromFormId(formId.value)) 
            newlexeme = lexemeId.value;
        if(grammarId.value != Database.grammarFormFromFormId(formId.value))
            newgrammarform = grammarId.value;
        if(stringValue.text != Database.stringFromFormId(formId.value))
            newstring = stringValue.text;
        var retval = Database.updateForm(formId.value, newlexeme, newgrammarform, newstring);
    }
    property var setId: function(id){
        formId.value = id;
    }
    property var getId: function(){
        return formId.value;
    }
    Row {
        width: parent.width
        ColeitraGridLabel {
            id: prettyForm
            text: Database.prettyPrintForm(formId.value, "", Edit.grammarIdFromFormId(formId.value))
            width: parent.width - formId.width - stringSearch.width
        }
        SpinBox {
            id: formId
            editable: true
            from: -9999
            to: 9999
        }
        ColeitraGridButton {
            id: stringSearch
            text: "Search"
            onClicked: formPopup.open();
        }
        ColeitraWidgetSearchPopupForm {
            id: formPopup
            okFunction: function() {
                formId.value = formPopup.selectedId;
                formPopup.close();
            }
        }
    }
    Rectangle {
        width: parent.width
        height: stringEdit.height
        color: stringValue.text == Database.stringFromFormId(formId.value)? "#FFFFFF" : "#FFFFDD"
        Row {
            id: stringEdit
            width: parent.width
            ColeitraGridLabel {
                id: stringLabel
                text: "<b>String</b>"
            }
            Item {
                width: 10
                height: 10
            }
            ColeitraGridTextInput {
                id: stringValue
                width: parent.width - stringLabel.width - 10
                text: Database.stringFromFormId(formId.value)
            }
        }
    }
    Rectangle {
        width: parent.width
        height: lexemeEdit.height
        color: lexemeId.value == Database.lexemeFromFormId(formId.value)? "#FFFFFF" : "#FFFFDD"
        Row {
            id: lexemeEdit
            width: parent.width
            ColeitraGridLabel {
                id: lexemeLabel
                text: "<b>Lexeme</b>"
            }
            ColeitraGridLabel {
                width: parent.width - lexemeId.width - lexemeLabel.width - lexemeSearch.width
                text: Database.prettyPrintLexeme(lexemeId.value)
            }
            SpinBox {
                id: lexemeId
                value: Database.lexemeFromFormId(formId.value)
                editable: true
                from: -9999
                to: 9999
            }
            ColeitraGridButton {
                id: lexemeSearch
                text: "Search"
                onClicked: lexemePopup.open();
            }
            ColeitraWidgetSearchPopupLexeme {
                id: lexemePopup
                okFunction: function() {
                    lexemeId.value = lexemePopup.selectedId;
                    lexemePopup.close();
                }
            }
        }
    }
    Rectangle {
        width: parent.width
        height: grammarEdit.height
        color: grammarId.value == Database.grammarFormFromFormId(formId.value)? "#FFFFFF" : "#FFFFDD"
        Row {
            id: grammarEdit
            width: parent.width
            ColeitraGridLabel {
                id: grammarLabel
                text: "<b>Grammarform</b>"
            }
            ColeitraGridLabel {
                width: parent.width - grammarLabel.width - grammarId.width - grammarSearch.width
                text: Database.prettyPrintGrammarForm(grammarId.value)
            }
            SpinBox {
                id: grammarId
                value: Database.grammarFormFromFormId(formId.value)
                editable: true
                from: -9999
                to: 9999
            }
            ColeitraGridButton {
                id: grammarSearch
                text: "Search"
                onClicked: grammarPopup.open();
            }
            ColeitraWidgetSearchPopupGrammar {
                id: grammarPopup
                width: parent.width
                okFunction: function() {
                    grammarId.value = grammarPopup.selectedId;
                    grammarPopup.close();
                }
            }
        }
    }

    

}
@}

@O ../src/ColeitraWidgetDatabaseLexemeEdit.qml
@{
import QtQuick 2.14
import DatabaseLib 1.0
import EditLib 1.0

Row {
    width: parent? parent.width : 100
    ColeitraGridLabel {
        width: parent.width
        text: "Lexeme edit not implemented yet..."
    }
}
@}

@O ../src/ColeitraWidgetDatabaseTranslationEdit.qml
@{
import QtQuick 2.14
import DatabaseLib 1.0
import EditLib 1.0

Row {
    width: parent? parent.width : 100
    ColeitraGridLabel {
        width: parent.width
        text: "Translation edit not implemented yet..."
    }
}
@}

@O ../src/ColeitraWidgetDatabaseSentenceEdit.qml
@{
import QtQuick 2.14
import DatabaseLib 1.0
import EditLib 1.0

Row {
    width: parent? parent.width : 100
    ColeitraGridLabel {
        width: parent.width
        text: "Sentence edit not implemented yet..."
    }
}
@}


@O ../src/databaseedit.qml
@{
import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14
import QtQuick.Controls.impl 2.14
import QtQml 2.14
import EditLib 1.0
import SettingsLib 1.0
import DatabaseLib 1.0
import GrammarProviderLib 1.0

ColeitraPage {
    title: "Database edit"
    focus: true
    ScrollView {
        anchors.fill: parent
        focus: true
        Column {
            width: parent.width
            ColeitraGridComboBox {
                id: editAreaSelection
                width: parent.width
                model: ["Form", "Lexeme", "Translation", "Sentence"]
                function resetEditArea() {
                    editarea.pop();
                    switch(currentText){
                        case "Form":
                            editarea.push("ColeitraWidgetDatabaseFormEdit.qml");
                            break;
                        case "Lexeme":
                            editarea.push("ColeitraWidgetDatabaseLexemeEdit.qml");
                            break;
                        case "Translation":
                            editarea.push("ColeitraWidgetDatabaseTranslationEdit.qml");
                            break;
                        case "Sentence":
                            editarea.push("ColeitraWidgetDatabaseSentenceEdit.qml");
                            break;
                    }
                }
                onCurrentTextChanged: resetEditArea()
            }
            StackView {
                y: editAreaSelection.height
                id: editarea
                initialItem: "ColeitraWidgetDatabaseFormEdit.qml"
                width: parent.width
            }
        }
    }
    footer: FocusScope {
        x: footercolumn.x
        y: footercolumn.y
        height: footercolumn.height
        width: parent.width
        Column {
            id: footercolumn
            width: parent.width
            Row {
                width: parent.width
                ColeitraGridRedButton {
                    id: resetButton
                    text: "Reset"
                    width: parent.width / 2
                    height: 80
                    onClicked: {
                        editAreaSelection.resetEditArea();
                    }
                }
                ColeitraGridGreenButton {
                    id: saveButton
                    text: "Save changes"
                    width: parent.width / 2
                    height: 80
                    onClicked: save()
                    function save(){
                        editarea.currentItem.saveFunction();
                        var id = editarea.currentItem.getId();
                        editAreaSelection.resetEditArea();
                        editarea.currentItem.setId(id);
                    }
                }
            }
            Item {
                height: 20
                width: parent.width
            }
        }
    }
}
@}


