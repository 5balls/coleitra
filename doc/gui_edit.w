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

\section{Edit}

@o ../src/ColeitraWidgetEditGrammarExpression.qml
@{
import QtQuick 2.14
import QtQuick.Layouts 1.14
import GrammarProviderLib 1.0
import DatabaseLib 1.0

Row {
    id: widget
    property var gklabel: grammarkeylabel
    property var gvlabel: grammarvaluelabel
    property var pbutton: plusbutton
    ColeitraGridImageButton {
        visible: false
        id: minusbutton
        imageid: "minus"
        clickhandler: function() { 
            widget.destroy();
        }
    }
    ColeitraGridComboBox {
        id: grammarkey
        model: Database.grammarkeys()
        width: (widget.width - 40)/2
    }
    ColeitraGridComboBox {
        id: grammarvalue
        model: Database.grammarvalues(grammarkey.currentText)
        width: (widget.width - 40)/2
    }
    ColeitraGridLabel {
        visible: false
        id: grammarkeylabel
        text: grammarkey.currentText
        width: (widget.width - 40)/2
        height: 40
        @<Background yellow rounded control@>
    }
    ColeitraGridLabel {
        visible: false
        id: grammarvaluelabel
        text: grammarvalue.currentText
        width: (widget.width - 40)/2
        height: 40
        @<Background yellow rounded control@>
    }
    ColeitraGridImageButton {
        imageid: "plus"
        id: plusbutton
        clickhandler: function() { 
            minusbutton.visible = true;
            grammarkey.visible = false;
            grammarkeylabel.visible = true;
            grammarvalue.visible = false;
            grammarvaluelabel.visible = true;
            plusbutton.visible = false;
            widget.parent.addAddRemoveGrammarExpression();
        }
    }
}
@}

@o ../src/ColeitraWidgetEditGrammarForm.qml
@{
/*
import QtQuick 2.14
import QtQuick.Layouts 1.14
import GrammarProviderLib 1.0
import DatabaseLib 1.0

ColeitraGridInGridLayout {
    id: widget
    property var language: 1
    property var pbutton: plusbutton
    property var lx: lexeme
    ColeitraGridImageButton {
        id: minusbutton
        visible: false
        imageid: "minus"
        clickhandler: function() { 
            widget.destroy();
        }
    }
    ColeitraGridTextInput {
        id: lexeme
        Layout.columnSpan: 6
        Layout.preferredWidth: 120
        Connections {
            target: GrammarProvider
            function onGrammarobtained(caller, expressions, grammarexpressions) {
                if(widget != caller) return;
                var current_lexeme = lexeme;
                var j_max = expressions.length;
                for(var j=0; j<j_max; j++){
                    var item = expressions[j];
                    current_lexeme.text = item;
                    var grammartags = grammarexpressions[j];
                    var i_max = grammartags.length;
                    for(var i=0; i<i_max; i++){
                        var current_grammarexpression = current_lexeme.parent.children[current_lexeme.parent.children.length-1];
                        current_grammarexpression.gklabel.text = grammartags[i][0];
                        current_grammarexpression.gvlabel.text = grammartags[i][1];
                        current_grammarexpression.pbutton.clickhandler();
                    }
                    current_lexeme.parent.pbutton.clickhandler();
                    current_lexeme = current_lexeme.parent.parent.children[current_lexeme.parent.parent.children.length-1].lx;
                }
            }
        }
    }
    ColeitraGridImageButton {
        imageid: "www"
        clickhandler: function() { 
            GrammarProvider.language = language;
            GrammarProvider.word = lexeme.text;
            GrammarProvider.getWiktionarySections(widget)
        }
    }
    ColeitraGridImageButton {
        id: plusbutton
        imageid: "plus"
        clickhandler: function() { 
            plusbutton.visible = false;
            minusbutton.visible = true;
            parent.parent.addAddRemoveGrammarForm();
        }
    }
    function addAddRemoveGrammarExpression(){
        var component = Qt.createComponent("ColeitraWidgetEditGrammarExpression.qml");
        if (component.status == Component.Ready) {
            var newObject = component.createObject(this);
        }
        else {
            console.log("Problem with creation of grammar expression edit widget");
        }
    }
    Component.onCompleted: {
        width = parent.width;
        Layout.preferredWidth = parent.width;
        lexeme.Layout.preferredWidth = parent.width - 80;
        addAddRemoveGrammarExpression();
    }
}
*/
@}

@o ../src/ColeitraWidgetEditSearchPopup.qml
@{
import QtQuick 2.14
import QtQuick.Controls 2.14

Popup {
    property string popupSearchString: ""
    function okFunction(){}
    function searchFunction(){}
    Column {
        ColeitraGridLabel {
            text: popupSearchString
        }
        ColeitraGridTextInput {
            width: parent.width
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
/*            DropShadow
    {
        width: searchLexeme.width;
        height: searchLexeme.height;
//                source: searchLexeme.background;
        horizontalOffset: 0;
        verticalOffset: 5;
        radius: 10;
        samples: 7;
        color: "black";
    }*/
}
@}

@o ../src/ColeitraWidgetEditIdSelection.qml
@{
import QtQuick 2.14
import QtQuick.Controls 2.14

Row {
    property bool existing: existingTranslation.checked
    property string existingText: ""
    property string searchText: ""
    property int idValue: idSelection.value
    property int existingId: 0
    width: parent.width
    ColeitraGridCheckBox {
        id: existingTranslation
        width: checked ? parent.width - idSelection.width : parent.width - idLabel.width
        checked: false
        text: existingText
    }
    SpinBox {
        id: idSelection
        visible: existingTranslation.checked
    }
    ColeitraGridLabel {
        id: idLabel
        visible: !existingTranslation.checked
        text: existingId.toString()
    }
    ColeitraWidgetEditSearchPopup {
        id: searchPopup
        popupSearchString: searchText
        function okFunction() {searchPopup.close()}
    }
    onExistingChanged: {
        if(existing){
            searchPopup.open()
        }
    }
}
@}

@o ../src/ColeitraWidgetEditGrammarFormComponentList.qml
@{
import QtQuick 2.14

Column {
    function addAddRemoveGrammarExpression(){
        var component = Qt.createComponent("ColeitraWidgetEditGrammarExpression.qml");
        if (component.status == Component.Ready) {
            var newObject = component.createObject(this);
	    newObject.width = Qt.binding(function() {return width});
        }
        else {
            console.log("Problem with creation of grammar expression edit widget");
        }
    }
    Component.onCompleted: {
        addAddRemoveGrammarExpression();
    }
}
@}

@o ../src/ColeitraWidgetEditGrammarForm.qml
@{
import QtQuick 2.14
import EditLib 1.0

Column {
    ColeitraWidgetEditIdSelection {
        id: grammarFormId
        existingText: "Grammarform exists"
        searchText: "Search for grammarform"
        existingId: Edit.grammarFormId
    }
    ColeitraWidgetEditGrammarFormComponentList {
        visible: !grammarFormId.existing
        width: parent.width
    }
}
@}

@o ../src/ColeitraWidgetEditCompoundForm.qml
@{
import QtQuick 2.14
import EditLib 1.0

Column {
    ColeitraWidgetEditIdSelection {
        id: compoundFormId
        existingText: "Compoundform exists"
        searchText: "Search for compoundform:"
        existingId: Edit.compoundFormId
    }
    Row {
        visible: !compoundFormId.existing
        width: parent.width
        ColeitraGridButton {
            width: parent.width / 2
            text: "Search / add form"
            ColeitraWidgetEditSearchPopup {
                id: searchPopup
                popupSearchString: "Search for form to add"
                function okFunction() {searchPopup.close()}
            }
            onClicked: searchPopup.open()
        }
        ColeitraGridButton {
            width: parent.width / 2
            text: "Remove form"
        }
    }
}
@}

@o ../src/ColeitraWidgetEditForm.qml
@{
import QtQuick 2.14
import EditLib 1.0

Column {
    ColeitraWidgetEditIdSelection {
        id: formId
        existingText: "Form exists"
        searchText: "Search for form:"
        existingId: Edit.formId
    }
    ColeitraGridTextInput {
        visible: !formId.existing
        width: parent.width
    }
    ColeitraGridCheckBox {
        visible: !formId.existing
        id: addGrammar
        width: parent.width
        checked: true
        text: "Add grammar form"
    }
    ColeitraWidgetEditGrammarForm {
        visible:  !formId.existing && addGrammar.checked
        width: parent.width
    }
}
@}

@o ../src/ColeitraWidgetEditSentence.qml
@{
import QtQuick 2.14
import EditLib 1.0

Column {
    ColeitraWidgetEditIdSelection {
        id: sentenceId
        existingText: "Sentence exists"
        searchText: "Search for sentence:"
        existingId: Edit.sentenceId
    }
}
@}

@o ../src/ColeitraWidgetEditLexemePart.qml
@{
import QtQuick 2.14
import QtQuick.Controls 2.14

Column {
    id: lexeme
    Row {
        visible: !lexemeId.existing
        width: parent.width
        ColeitraGridImageButton {
            id: minusbutton
            visible: false
            imageid: "minus"
            clickhandler: function() {
                lexeme.destroy();
            }
        }
        TabBar {
            id: lexemeTypeSelection
            width: parent.width - 40
            TabButton {
                text: "Form"
            }
            TabButton {
                text: "Compoundform"
            }
            TabButton {
                text: "Sentence"
            }
        }
        ColeitraGridLabel {
            id: labelForm
            visible: false
            width: parent.width - 40
            height: 40
            text: "Form"
            @<Background yellow rounded control@>
        }
        ColeitraGridLabel {
            id: labelCompoundForm
            visible: false
            width: parent.width - 40
            height: 40
            text: "Compoundform"
            @<Background yellow rounded control@>
        }
        ColeitraGridLabel {
            id: labelSentence
            visible: false
            width: parent.width - 40
            height: 40
            text: "Sentence"
            @<Background yellow rounded control@>
        }
        ColeitraGridImageButton {
            id: plusbutton
            imageid: "plus"
            clickhandler: function() {
                plusbutton.visible = false;
                minusbutton.visible = true;
                switch (lexemeTypeSelection.currentIndex) {
                    case 0:
                        editCompoundForm.destroy();
                        labelCompoundForm.destroy();
                        editSentence.destroy();
                        labelSentence.destroy();
                        lexemeTypeSelection.destroy();
                        labelForm.visible = true;
                        break;
                    case 1:
                        editForm.destroy();
                        labelForm.destroy();
                        editSentence.destroy();
                        labelSentence.destroy();
                        lexemeTypeSelection.destroy();
                        labelCompoundForm.visible = true;
                        break;
                    case 2:
                        editForm.destroy();
                        labelForm.destroy();
                        editCompoundForm.destroy();
                        labelCompoundForm.destroy();
                        lexemeTypeSelection.destroy();
                        labelSentence.visible = true;
                        break;
                }
                lexeme.parent.addAddRemoveLexemePart();
            }
        }
    }
    ColeitraWidgetEditForm {
        id: editForm
        width: parent.width
        visible: !lexemeId.existing && ((lexemeTypeSelection == null) || (lexemeTypeSelection.currentIndex == 0))
    }
    ColeitraWidgetEditCompoundForm {
        id: editCompoundForm
        width: parent.width
        visible: !lexemeId.existing && ((lexemeTypeSelection == null) || (lexemeTypeSelection.currentIndex == 1))
    }
    ColeitraWidgetEditSentence {
        id: editSentence
        width: parent.width
        visible: !lexemeId.existing && ((lexemeTypeSelection == null) || (lexemeTypeSelection.currentIndex == 2))
    }
}
@}


@o ../src/ColeitraWidgetEditLexemePartList.qml
@{
import QtQuick 2.14

Column {
    function addAddRemoveLexemePart(){
        var component = Qt.createComponent("ColeitraWidgetEditLexemePart.qml");
        if (component.status == Component.Ready) {
            var newObject = component.createObject(this);
	    newObject.width = Qt.binding(function() {return width});
        }
        else {
            console.log("Problem with creation of lexeme part edit widget");
        }
    }
    Component.onCompleted: {
        addAddRemoveLexemePart();
    }
}
@}

@o ../src/ColeitraWidgetEditLexeme.qml
@{
import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import QtGraphicalEffects 1.14
import EditLib 1.0
import DatabaseLib 1.0

Column {
    property int languageId: 1
    ColeitraWidgetEditIdSelection {
        id: lexemeId
        existingText: "Lexeme exists"
        searchText: "Search for lexeme:"
        existingId: Edit.lexemeId
    }
    ColeitraGridComboBox {
        visible: !lexemeId.existing
        width: parent.width
        model: Database.languagenames();
        currentIndex: Database.alphabeticidfromlanguageid(languageId);
    }
    ColeitraWidgetEditLexemePartList {
        width: parent.width
    }
}
@}

@o ../src/ColeitraWidgetEditTranslationPart.qml
@{
import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14
import EditLib 1.0

Column {
    property int translationLanguageId: 1
    Layout.columnSpan: 12
    ColeitraWidgetEditIdSelection {
        id: translationPartId
        existingText: "Translationpart exists"
        searchText: "Search for translationpart:"
        existingId: Edit.translationId
    }
    Column {
        width: parent.width
        visible: !translationPartId.existing
        ColeitraGridComboBox {
            id: translationPartType
            width: parent.width
            model: ["Lexeme", "Sentence", "Form", "Compoundform", "Grammarform"]
        }
        ColeitraWidgetEditLexeme {
            languageId: translationLanguageId
            width: parent.width
            visible: translationPartType.currentIndex == 0
        }
        ColeitraWidgetEditSentence {
            width: parent.width
            visible: translationPartType.currentIndex == 1
        }
        ColeitraWidgetEditForm {
            width: parent.width
            visible: translationPartType.currentIndex == 2
        }
        ColeitraWidgetEditCompoundForm {
            width: parent.width
            visible: translationPartType.currentIndex == 3
        }
        ColeitraWidgetEditGrammarForm {
            width: parent.width
            visible: translationPartType.currentIndex == 4
        }
    }
}
@}

@o ../src/edit.qml
@{
import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14
import QtQml 2.14
import EditLib 1.0
import SettingsLib 1.0
import DatabaseLib 1.0
import GrammarProviderLib 1.0

ColeitraPage {
    title: "Edit translation"
    ScrollView {
        anchors.fill: parent
        Column {
            width: parent.width
            Row {
                width: parent.width
                Image {
                    source: "scrollprogress.svg"
                    height: learningTranslationPart.height
                    width: 40
                }
                ColeitraWidgetEditTranslationPart {
                    id: learningTranslationPart
                    translationLanguageId: Settings.learninglanguage
                    width: parent.width - 40
                }
            }
            Row {
                width: parent.width
                Image {
                    source: "scrollprogress.svg"
                    height: nativeTranslationPart.height
                    width: 40
                }
                ColeitraWidgetEditTranslationPart {
                    id: nativeTranslationPart
                    translationLanguageId: Settings.nativelanguage
                    width: parent.width - 40
                }
            }
        }
    }
    footer: ColeitraGridLayout {
    }
}
@}


