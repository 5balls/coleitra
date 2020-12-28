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
    height: 40
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

@o ../src/ColeitraWidgetEditSearchPopup.qml
@{
import QtQuick 2.14
import QtQuick.Controls 2.14

Popup {
    property string popupSearchString: ""
    property int selectedId: selectedId.value
    property var okFunction: function() {};
    property var searchFunction: function() {};
    property string searchValue: popupSearchValue.text
    property var popupIdList: idList
    Column {
        width: parent.width
        ColeitraGridLabel {
            text: popupSearchString
        }
        ColeitraGridTextInput {
            id: popupSearchValue
            width: parent.width
        }
        ButtonGroup {
            buttons: idList.children
        }
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

@o ../src/ColeitraWidgetEditIdSelection.qml
@{
import QtQuick 2.14
import QtQuick.Controls 2.14

Row {
    property bool existing: existingTranslation.checked
    property var existingtranslation: existingTranslation
    property string existingText: ""
    property string searchText: ""
    property string searchValue: searchPopup.searchValue
    property var popupSearchFunction: function() {}
    property int idValue: idSelection.value
    property var idselection: idSelection
    property int existingId: 0
    property bool showImageButton: false
    property string imageButtonId: "www"
    property var imageButtonClicked: function() {}
    property var idList: searchPopup.popupIdList
    property bool popupEnabled: true
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
        from: -9999
        to: 9999
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
        width: parent.width
        id: searchPopup
        popupSearchString: searchText
        okFunction: function() {
            idSelection.value = searchPopup.selectedId;
            idSelection.enabled = false;
            searchPopup.close();
        }
        searchFunction: popupSearchFunction
    }
    onExistingChanged: {
        if(existing && popupEnabled){
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
            var children_sum_height = 0;
            for(var i=0; i<children.length; i++){
                children_sum_height += children[i].height;
            }
            height = children_sum_height;
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
import DatabaseLib 1.0

Column {
    property var grammarformid: grammarFormId
    property var grammarexpressionlist: grammarExpressionList
    height: grammarFormId.height + (grammarExpressionList.visible ? grammarExpressionList.height : prettyText.height);
    ColeitraWidgetEditIdSelection {
        id: grammarFormId
        existingText: "Grammarform exists"
        searchText: "Search for grammarform"
        existingId: Edit.grammarFormId
    }
    ColeitraWidgetEditGrammarFormComponentList {
        id: grammarExpressionList
        visible: !grammarFormId.existing
        width: parent.width
    }
    ColeitraGridLabel {
        id: prettyText
        visible: grammarFormId.existing
        text: Database.prettyPrintGrammarForm(grammarFormId.idValue);
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
        from: -9999
        to: 9999
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
import DatabaseLib 1.0
import EditLib 1.0

Column {
    property var form: formString
    property var formid: formId.existingId
    property var addgrammar: addGrammar
    property var grammarform: grammarForm
    property var popupenabled: true
    ColeitraWidgetEditIdSelection {
        id: formId
        existingText: "Form exists"
        searchText: "Search for form:"
        popupEnabled: popupenabled
        popupSearchFunction: function() {
            var formIds = Database.searchForms(formId.searchValue);
            for(var i = idList.children.length; i > 0; i--) {
                idList.children[i-1].destroy()
            }
            var numberOfDestroyedChildren = idList.children.length;
            for(var formid of formIds){
                idList.addPart();
                if(formid<0){
                    var formstring = Edit.stringFromFormId(formid);
                    var grammarid = Edit.grammarIdFromFormId(formid);
                    idList.lastCreatedObject.text = Database.prettyPrintForm(formid, formstring, grammarid);
                }
                else {
                    idList.lastCreatedObject.text = Database.prettyPrintForm(formid);
                }
                idList.lastCreatedObject.value = formid;
            }
            if(idList.children.length > numberOfDestroyedChildren){
                idList.children[numberOfDestroyedChildren].checked = true;
            }
            else {
                console.log("No children in idList!");
            }
        }
        existingId: Edit.formId
    }
    ColeitraGridTextInput {
        id: formString
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
        id: grammarForm
        visible:  !formId.existing && addGrammar.checked
        width: parent.width
    }
}
@}

@o ../src/ColeitraWidgetEditSentencePart.qml
@{
import QtQuick 2.14
import QtQuick.Controls 2.14
import DatabaseLib 1.0
import EditLib 1.0

Row {
    id: sentencePart
    property var selectedparttype: selectedPartType
    property var capitalizedcheckbox: capitalizedCheckbox
    property var idselection: idSelection
    property var searchpopup: searchPopup
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
        width: idSelection.visible ? parent.width - capitalizedCheckbox.width - 40 - idSelection.width - prettyText.width : parent.width - capitalizedCheckbox.width - 40
    }
    ColeitraGridLabel {
        visible: idSelection.visible
        id: prettyText
        text: ""
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
        from: -9999
        to: 9999
        onValueChanged: {
            switch(selectedPartType.currentIndex){
                case 0:
                    if(value<0){
                        var formstring = Edit.stringFromFormId(value);
                        var grammarid = Edit.grammarIdFromFormId(value);
                        prettyText.text = Database.prettyPrintForm(value, formstring, grammarid);
                    }
                    else {
                        prettyText.text = Database.prettyPrintForm(value);
                    }
                    break;
                default:
                    prettyText.text = "";
                    break;
            }
        }
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
    property var sentenceid: sentenceId
    property var sentencepartlist: sentencePartList
    property var addgrammar: addGrammar
    property var grammarform: grammarForm
    property var sentenceidid: sentenceId.existingId
    ColeitraWidgetEditIdSelection {
        id: sentenceId
        existingText: "Sentence exists"
        searchText: "Search for sentence:"
        existingId: Edit.sentenceId
    }
    ColeitraWidgetEditPartList {
        id: sentencePartList
        partType: "ColeitraWidgetEditSentencePart"
        width: parent.width
    }
    ColeitraGridCheckBox {
        id: addGrammar
        width: parent.width
        checked: true
        text: "Add grammar form"
    }
    ColeitraWidgetEditGrammarForm {
        id: grammarForm
        visible:  !sentenceId.existing && addGrammar.checked
        width: parent.width
    }
}
@}

@o ../src/ColeitraWidgetEditLexemePart.qml
@{
import QtQuick 2.14
import QtQuick.Controls 2.14
import EditLib 1.0

Column {
    id: lexeme
    height: row.height + (editForm? (editForm.visible ? editForm.height : 0) : 0) + (editCompoundForm? (editCompoundForm.visible ? editCompoundForm.height : 0) : 0) + (editSentence? (editSentence.visible ? editSentence.height : 0) : 0)
    property var selection: lexemeTypeSelection
    property var form: editForm
    property var compoundform: editCompoundForm
    property var sentence: editSentence
    property var pbutton: plusbutton
    property var language: 1
    property var lexemeid: 0
    Row {
        id: row
        visible: !lexemeId.existing
        width: parent.width
        ColeitraGridImageButton {
            id: minusbutton
            visible: false
            imageid: "minus"
            clickhandler: function() {
                lexeme.parent.childRemoved(lexeme);
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
        onEnabledChanged: {
            if(enabled==false){
                var numberOfGrammarExpressions = grammarform.grammarexpressionlist.children.length;
                var grammarexpressions = [];
                for(var i=0; i<numberOfGrammarExpressions-1; i++){
                    var key = grammarform.grammarexpressionlist.children[i].gklabel.text;
                    var value = grammarform.grammarexpressionlist.children[i].gvlabel.text;
                    grammarexpressions.push([key,value]);
                }
                var grammarformid = Edit.createGrammarFormId(language,grammarexpressions);
                grammarform.grammarformid.idselection.value = grammarformid;
                grammarform.grammarformid.popupEnabled = false;
                grammarform.grammarformid.existingtranslation.checked = true;
                Edit.addForm(lexemeid,editForm.formid,grammarformid,editForm.form.text);
            }
        }
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
        onEnabledChanged: {
            if(enabled==false){
                var numberOfGrammarExpressions = grammarform.grammarexpressionlist.children.length;
                var grammarexpressions = [];
                for(var i=0; i<numberOfGrammarExpressions-1; i++){
                    var key = grammarform.grammarexpressionlist.children[i].gklabel.text;
                    var value = grammarform.grammarexpressionlist.children[i].gvlabel.text;
                    grammarexpressions.push([key,value]);
                }
                var grammarformid = Edit.createGrammarFormId(language,grammarexpressions);
                grammarform.grammarformid.idselection.value = grammarformid;
                grammarform.grammarformid.popupEnabled = false;
                grammarform.grammarformid.existingtranslation.checked = true;

                var numberOfSentenceParts = sentencepartlist.children.length;
                var sentenceparts = [];
                for(var i=0; i<numberOfSentenceParts-1; i++){
                    var currentSentencePart = sentencepartlist.children[i];
                    var id = currentSentencePart.idselection.value;
                    var type = currentSentencePart.selectedparttype.currentIndex;
                    var capitalized = currentSentencePart.capitalizedcheckbox.checked;
                    sentenceparts.push([id,type,capitalized]);
                }
                Edit.addSentence(lexemeid,editSentence.sentenceidid,grammarformid,sentenceparts);
            }
        }
    }
    onHeightChanged: {
        parent.height = height;
    }
}
@}

@o ../src/ColeitraWidgetEditPartList.qml
@{
import QtQuick 2.14

Column {
    property string partType: ""
    property bool startWithOneElement: true
    property var lastCreatedObject: null
    function addPart(){
        var component = Qt.createComponent(partType + ".qml");
        if (component.status == Component.Ready) {
            var newObject = component.createObject(this);
	    newObject.width = Qt.binding(function() {return width});
            lastCreatedObject = newObject;
        }
        else {
            console.log("Problem with creation of " + partType);
        }
    }
    Component.onCompleted: {
        if(startWithOneElement) addPart();
    }
}
@}

@o ../src/ColeitraWidgetEditPartStack.qml
@{
import QtQuick 2.14
import QtQuick.Controls 2.14
Column {

    property string partType: ""
    property bool startWithOneElement: true
    property var lastCreatedObject: null
    property var stackElements: new Array();
    property var numberOfElements: 0
    property var stack: columnLayout
    property var onCreation: function(createdObject) {};
    Row {
        width: parent.width
        ColeitraGridLabel {
            id: lexemePartLabel
            text: "Lexeme part " + selectedLexemePart.value.toString() + " / " + numberOfElements
        }
        Rectangle {
            height: 1
            width: parent.width - lexemePartLabel.width - selectedLexemePart.width
        }
        SpinBox {
            id: selectedLexemePart
            from: 1
            to: numberOfElements
            onValueChanged: {
                if(stackElements.length>=value){
                    if(columnLayout.currentItem){
                        columnLayout.currentItem.visible = false;
                    }
                    stackElements[value-1].visible = true;
                    columnLayout.replace(stackElements[value-1]);
                }
            }
        }
    }
    StackView {
        id: columnLayout
        width: parent.width
        function addPart(){
            var component = Qt.createComponent(partType + ".qml");
            if (component.status == Component.Ready) {
                var newObject = component.createObject(columnLayout);
                newObject.width = Qt.binding(function() {return width});
                lastCreatedObject = newObject;
                stackElements.push(newObject);
                numberOfElements++;
                //columnLayout.replace(newObject);
                selectedLexemePart.value = stackElements.indexOf(newObject) + 1;
                onCreation(newObject);
            }
            else {
                console.log("Problem with creation of " + partType);
            }
        }
        function childRemoved(child){
            selectedLexemePart.value++;
            stackElements.splice(stackElements.indexOf(child),1);
            numberOfElements--;
            selectedLexemePart.value--;
        }

        Component.onCompleted: {
            if(startWithOneElement) columnLayout.addPart();
        }
    }
}
@}

@o ../src/ColeitraWidgetEditIdRadioButton.qml
@{
import QtQuick.Controls 2.14

RadioButton {
    property int value: 0
    text: "Id"
    onCheckedChanged: function() {
        parent.selectedIdFromIdList = value;
    }
}
@}

@o ../src/ColeitraWidgetEditSearchTextPopup.qml
@{
import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

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
	popupSearchFunction: function() {
            var lexemeIds = Database.searchLexemes(lexemeId.searchValue);
            for(var i = idList.children.length; i > 0; i--) {
                idList.children[i-1].destroy()
            }
            var numberOfDestroyedChildren = idList.children.length;
            for(var lexemeid of lexemeIds){
                idList.addPart();
                idList.lastCreatedObject.text = Database.prettyPrintLexeme(lexemeid);
                idList.lastCreatedObject.value = lexemeid;
            }
            if(idList.children.length > numberOfDestroyedChildren){
                idList.children[numberOfDestroyedChildren].checked = true;
            }
            else {
                console.log("No children in idList!");
            }

	}
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
    ColeitraWidgetEditPartStack {
        id: lexemePartList
        partType: "ColeitraWidgetEditLexemePart"
        width: parent.width
        onCreation: function(createdLexemePart){
            createdLexemePart.language = languageId;
            createdLexemePart.lexemeid = lexemeId.existingId;
        }
    }
    onLanguageIdChanged: {
        var lexemeParts = lexemePartList.stack.children;
        for(var i=0; i<lexemeParts.length; i++){
            lexemeParts[i].language = languageId;
        }
    }
    ColeitraWidgetEditSearchTextPopup {
        id: searchPopup
        popupSearchString: "Search en.wiktionary.org:"
        searchFunction: function() {
            GrammarProvider.getGrammarInfoForWord(searchPopup, languageId, searchPopup.popupSearchText);
        }
        cancelFunction: function() {
            searchPopup.close();
        }
        okFunction: function() {
            searchPopup.close();
            GrammarProvider.getNextGrammarObject(searchPopup);
        }
        Connections {
            target: GrammarProvider
            property var silentLexemeId: 0
            property var silentSentenceId: 0
            property var silentSentenceParts: []
            function onGrammarInfoAvailable(caller, grammarforms_size, silent){
                if(searchPopup != caller) return;
                if(silent){
                    silentLexemeId = Edit.lexemeId;
                    GrammarProvider.getNextGrammarObject(searchPopup);
                }
		else{
                    searchPopup.okEnabled = true;
		}
            }
            function onFormObtained(caller, formstring, grammarexpressions, silent){
                if(searchPopup != caller) return;
                if(silent){
                    var formid = Edit.formId;
                    var grammarformid = Edit.createGrammarFormId(languageId,grammarexpressions);
                    Edit.addForm(silentLexemeId,formid,grammarformid,formstring);
                }
                else{
                    var currentLexemePart = lexemePartList.stack.currentItem;
                    currentLexemePart.selection.currentIndex = 0;
                    currentLexemePart.form.form.text = formstring;
                    currentLexemePart.form.addgrammar.checked = true;
                    currentLexemePart.form.grammarform.grammarformid.existingtranslation.checked = false;
                    for(var i=0; i<grammarexpressions.length; i++){
                        var currentGrammarExpression = currentLexemePart.form.grammarform.grammarexpressionlist.children[currentLexemePart.form.grammarform.grammarexpressionlist.children.length-1];
                        currentGrammarExpression.gklabel.text = grammarexpressions[i][0];
                        currentGrammarExpression.gvlabel.text = grammarexpressions[i][1];
                        currentGrammarExpression.pbutton.clickhandler();
                    }
                    currentLexemePart.pbutton.clickhandler();
                }
                GrammarProvider.getNextGrammarObject(searchPopup);
            }
            function onSentenceAvailable(caller, parts, silent){
                if(searchPopup != caller) return;
                if(silent){
                    silentSentenceId = Edit.sentenceId;
                }
                else{
                    var currentLexemePart = lexemePartList.stack.currentItem;
                    currentLexemePart.selection.currentIndex = 2;
                }
                GrammarProvider.getNextSentencePart(searchPopup);
            }
            function onSentenceLookupForm(caller,sentencepart,grammarexpressions,silent){
                if(searchPopup != caller) return;
                var formId = Edit.lookupForm(languageId, lexemeId.existingId, sentencepart, grammarexpressions);
                if(silent){
                    silentSentenceParts.push([formId,0,false]);
                }
                else{
                    var currentLexemePart = lexemePartList.stack.currentItem;
                    var currentSentencePart = currentLexemePart.sentence.sentencepartlist.children[currentLexemePart.sentence.sentencepartlist.children.length-1];
                    currentSentencePart.selectedparttype.currentIndex = 0;
                    currentSentencePart.capitalizedcheckbox.checked = false;
                    currentSentencePart.searchpopup.okFunction();
                    currentSentencePart.idselection.value = formId;
                }
                GrammarProvider.getNextSentencePart(searchPopup);
            }
            function onSentenceLookupFormLexeme(caller,sentencepart,grammarexpressions,silent){
                if(searchPopup != caller) return;
                var formId = Edit.lookupFormLexeme(languageId, lexemeId.existingId, sentencepart, grammarexpressions);
                if(silent){
                    silentSentenceParts.push([formId,0,false]);
                }
                else{
                    var currentLexemePart = lexemePartList.stack.currentItem;
                    var currentSentencePart = currentLexemePart.sentence.sentencepartlist.children[currentLexemePart.sentence.sentencepartlist.children.length-1];
                    currentSentencePart.selectedparttype.currentIndex = 0;
                    currentSentencePart.capitalizedcheckbox.checked = false;
                    currentSentencePart.searchpopup.okFunction();
                    currentSentencePart.idselection.value = formId;
                }
                GrammarProvider.getNextSentencePart(searchPopup);

            }
            function onSentenceComplete(caller,grammarexpressions,silent){
                if(searchPopup != caller) return;
                if(silent){
                    var grammarid = Edit.createGrammarFormId(languageId, grammarexpressions);
                    Edit.addSentence(silentLexemeId,silentSentenceId,grammarid,silentSentenceParts);
                }
                else{
                    var currentLexemePart = lexemePartList.stack.currentItem;
                    currentLexemePart.sentence.addgrammar.checked = true;
                    currentLexemePart.sentence.grammarform.grammarformid.existingtranslation.checked = false;
                    for(var i=0; i<grammarexpressions.length; i++){
                        var currentGrammarExpression = currentLexemePart.sentence.grammarform.grammarexpressionlist.children[currentLexemePart.sentence.grammarform.grammarexpressionlist.children.length-1];
                        currentGrammarExpression.gklabel.text = grammarexpressions[i][0];
                        currentGrammarExpression.gvlabel.text = grammarexpressions[i][1];
                        currentGrammarExpression.pbutton.clickhandler();
                    }
                    currentLexemePart.pbutton.clickhandler();
                }
                GrammarProvider.getNextGrammarObject(searchPopup);
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


