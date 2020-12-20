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
    property int selectedId: selectedId.value
    property var okFunction: function() {};
    property var searchFunction: function() {};
    Column {
        ColeitraGridLabel {
            text: popupSearchString
        }
        ColeitraGridTextInput {
            width: parent.width
        }
        SpinBox {
            id: selectedId
            width: parent.width
            editable: true
            from: -99
            to: 99
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
    property bool showImageButton: false
    property string imageButtonId: "www"
    property var imageButtonClicked: function() {}
    width: parent.width
    ColeitraGridCheckBox {
        id: existingTranslation
        width: checked ? parent.width - idSelection.width : parent.width - idLabel.width - (showImageButton ? 40 : 0)
        checked: false
        text: existingText
    }
    SpinBox {
        id: idSelection
        visible: existingTranslation.checked
        from: -99
        to: 99
    }
    ColeitraGridImageButton {
        id: plusButton
        imageid: imageButtonId
        visible: showImageButton && !existingTranslation.checked
        clickhandler: imageButtonClicked
    }
    ColeitraGridLabel {
        id: idLabel
        visible: !existingTranslation.checked
        text: existingId.toString()
    }
    ColeitraWidgetEditSearchPopup {
        id: searchPopup
        popupSearchString: searchText
        okFunction: function() {
            idSelection.value = searchPopup.selectedId;
            idSelection.enabled = false;
            searchPopup.close();
        }
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

@o ../src/ColeitraWidgetEditCompoundFormPart.qml
@{
import QtQuick 2.14
import QtQuick.Controls 2.14

Row {
    id: compoundFormPart
    width: parent.width
    ColeitraWidgetEditSearchPopup {
        id: searchPopup
        popupSearchString: "Search for form to add"
        okFunction: function() {
            searchPopup.close();
            searchButton.destroy();
            plusButton.destroy();
            minusButton.visible = true;
            idSelection.value = searchPopup.selectedId;
            idSelection.visible = true;
            idSelection.enabled = false;
            spacerRectangle.visible = true;
            searchPopup.destroy();
            compoundFormPart.parent.addPart();
        }
    }
    ColeitraGridButton {
        id: searchButton
        width: parent.width - 40
        text: "Search / add form"
        onClicked: searchPopup.open()
    }
    ColeitraGridImageButton {
        id: plusButton
        imageid: "plus"
        clickhandler: function() {
            searchPopup.open()
        }
    }
    ColeitraGridImageButton {
        id: minusButton
        imageid: "minus"
        visible: false
        clickhandler: function() {
            compoundFormPart.destroy();
        }
    }
    Rectangle {
        id: spacerRectangle
        height: 1
        visible: false
        width: parent.width - idSelection.width - 40
    }
    SpinBox {
        id: idSelection
        visible: false
        editable: true
        from: -99
        to: 99
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
    ColeitraWidgetEditPartList {
        partType: "ColeitraWidgetEditCompoundFormPart"
        visible: !compoundFormId.existing
        width: parent.width
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

@o ../src/ColeitraWidgetEditSentencePart.qml
@{
import QtQuick 2.14
import QtQuick.Controls 2.14

Row {
    id: sentencePart
    ColeitraGridImageButton {
        id: minusButton
        visible: false
        imageid: "minus"
        clickhandler: function () {
            sentencePart.destroy();
        }
    }
    ColeitraGridComboBox {
        id: selectedPartType
        model: ["Form", "Compoundform", "Grammarform", "Punctuation mark"]
        width: idSelection.visible ? parent.width - capitalizedCheckbox.width - 40 - idSelection.width : parent.width - capitalizedCheckbox.width - 40
    }
    ColeitraGridCheckBox {
        id: capitalizedCheckbox
        text: "Capitalized"
    }
    ColeitraGridImageButton {
        id: plusButton
        imageid: "plus"
        clickhandler: function() {
            searchPopup.open();
        }
    }
    SpinBox {
        id: idSelection
        visible: false
        from: -99
        to: 99
    }
    ColeitraWidgetEditSearchPopup {
        id: searchPopup
        popupSearchString: "Search for " + selectedPartType.currentText
        okFunction: function() {
            searchPopup.close();
            selectedPartType.enabled = false;
            capitalizedCheckbox.enabled = false;
            minusButton.visible = true;
            plusButton.destroy();
            idSelection.value = searchPopup.selectedId;
            idSelection.visible = true;
            idSelection.enabled = false;
            searchPopup.destroy();
            sentencePart.parent.addPart();
        }
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
    ColeitraWidgetEditPartList {
        partType: "ColeitraWidgetEditSentencePart"
        width: parent.width
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
                        editForm.enabled = false;
                        editCompoundForm.destroy();
                        labelCompoundForm.destroy();
                        editSentence.destroy();
                        labelSentence.destroy();
                        lexemeTypeSelection.destroy();
                        labelForm.visible = true;
                        break;
                    case 1:
                        editCompoundForm.enabled = false;
                        editForm.destroy();
                        labelForm.destroy();
                        editSentence.destroy();
                        labelSentence.destroy();
                        lexemeTypeSelection.destroy();
                        labelCompoundForm.visible = true;
                        break;
                    case 2:
                        editSentence.enabled = false;
                        editForm.destroy();
                        labelForm.destroy();
                        editCompoundForm.destroy();
                        labelCompoundForm.destroy();
                        lexemeTypeSelection.destroy();
                        labelSentence.visible = true;
                        break;
                }
                lexeme.parent.addPart();
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

@o ../src/ColeitraWidgetEditPartList.qml
@{
import QtQuick 2.14

Column {
    property string partType: ""
    function addPart(){
        var component = Qt.createComponent(partType + ".qml");
        if (component.status == Component.Ready) {
            var newObject = component.createObject(this);
	    newObject.width = Qt.binding(function() {return width});
        }
        else {
            console.log("Problem with creation of " + partType);
        }
    }
    Component.onCompleted: {
        addPart();
    }
}
@}


@o ../src/ColeitraWidgetEditSearchTextPopup.qml
@{
import QtQuick 2.14
import QtQuick.Controls 2.14

Popup {
    property string popupSearchString: ""
    property string popupSearchText: searchText.text
    property var cancelFunction: function() {}
    property var okFunction: function() {}
    property bool okEnabled: false
    property var searchFunction: function() {}
    Column {
        ColeitraGridLabel {
            text: popupSearchString
        }
        ColeitraGridTextInput {
            id: searchText
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
                width: parent.parent.width - searchButton.width - cancelButton.width - okButton.width
            }
            ColeitraGridButton {
                id: cancelButton
                text: "Cancel"
                onClicked: cancelFunction()
            }
            ColeitraGridButton {
                id: okButton
                text: "Ok"
                enabled: okEnabled
                onClicked: okFunction()
            }
        }
    }
    @<Background grey rounded control@>
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
import GrammarProviderLib 1.0

Column {
    property int languageId: 1
    property var receivedExpressions: null
    property var receivedGrammarExpressions: null
    ColeitraWidgetEditIdSelection {
        id: lexemeId
        existingText: "Lexeme exists"
        searchText: "Search for lexeme:"
        existingId: Edit.lexemeId
        showImageButton: true
        imageButtonClicked: function() {
            searchPopup.open();
        }
    }
    ColeitraGridComboBox {
        visible: !lexemeId.existing
        width: parent.width
        model: Database.languagenames();
        currentIndex: Database.alphabeticidfromlanguageid(languageId);
    }
    ColeitraWidgetEditPartList {
        partType: "ColeitraWidgetEditLexemePart"
        width: parent.width
    }
    ColeitraWidgetEditSearchTextPopup {
        id: searchPopup
        popupSearchString: "Search en.wiktionary.org:"
        searchFunction: function() {
            GrammarProvider.language = languageId;
            GrammarProvider.word = searchPopup.popupSearchText;
            GrammarProvider.getWiktionarySections(searchPopup)
        }
        cancelFunction: function() {
            searchPopup.close();
        }
        okFunction: function() {
            searchPopup.close();
        }
        Connections {
            target: GrammarProvider
            function onGrammarobtained(caller, expressions, grammarexpressions) {
                if(searchPopup != caller) return;
                receivedExpressions = expressions;
                receivedGrammarExpressions = grammarexpressions;
                searchPopup.okEnabled = true;
                /*var current_lexeme = lexeme;
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
                }*/
            }
        }

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


