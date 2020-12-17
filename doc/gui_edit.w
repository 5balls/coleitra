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

@o ../src/ColeitraWidgetEditLexeme.qml
@{
/*import DatabaseLib 1.0
import QtQuick 2.14
import QtQuick.Layouts 1.14

ColeitraGridInGridLayout {
    property var lexeme_language: 1
    id: widget
    function addAddRemoveGrammarForm(){
        var component = Qt.createComponent("ColeitraWidgetEditGrammarForm.qml");
        if (component.status == Component.Ready) {
            var newObject = component.createObject(this, {language: lexeme_language});
        }
        else {
            console.log("Problem with creation of grammar form edit widget");
        }
    }
    Component.onCompleted: {
        width = parent.width;
        Layout.preferredWidth = parent.width;
        addAddRemoveGrammarForm();
    }

}*/
@}

@o ../src/ColeitraWidgetEdit.qml
@{
import DatabaseLib 1.0
import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14

ColeitraGridInGridLayout {
    property var edit_language: 1
    id: widget
    Layout.columnSpan: 12
    ColeitraGridLabel {
        Layout.columnSpan: 12
        text: Database.languagenamefromid(edit_language) + ":"
    }
    ColeitraGridImageButton {
        id: minusbutton
        visible: false
        imageid: "minus"
        clickhandler: function() {
            widget.destroy();
        }
    }
    TabBar {
        id: editselection
        Layout.columnSpan: 8
        TabButton {
            text: qsTr("Lexeme")
        }
        TabButton {
            text: qsTr("Sentence")
        }
        TabButton {
            text: qsTr("Form")
        }
        TabButton {
            text: qsTr("Grammarform")
        }
    }
    ColeitraGridImageButton {
        id: plusbutton
        imageid: "plus"
        clickhandler: function() {
            plusbutton.visible = false;
            minusbutton.visible = true;
            parent.parent.addAddRemoveEdit(edit_language);
        }
    }
    StackLayout {
        id: editfield
        Layout.columnSpan: 12
        currentIndex: editselection.currentIndex
        ColeitraWidgetEditLexeme {
            lexeme_language: edit_language
            Layout.preferredWidth: parent.width
        }
        ColeitraGridLabel {
            text: "Sentence"
        }
        ColeitraGridLabel {
            text: "Form"
        }
        ColeitraGridLabel {
            text: "Grammarform"
        }
    }

    Component.onCompleted: {
        width = parent.width;
        Layout.preferredWidth = parent.width;
        editselection.width = width - 40;
        editselection.Layout.preferredWidth = width - 40;
        editfield.Layout.preferredWidth = width;
        editfield.width = width;
    }
}
@}

@o ../src/ColeitraWidgetEditIdSelection.qml
@{
import QtQuick 2.14
import QtQuick.Controls 2.14

Row {
    property bool existing: existingTranslation.checked
    property string existingText: ""
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
}
@}

@o ../src/ColeitraWidgetEditGrammarFormComponent.qml
@{
import QtQuick 2.14
import EditLib 1.0

Column {
    ColeitraWidgetEditIdSelection {
        id: grammarFormComponentId
        existingText: "Grammarformcomponent exists"
        existingId: Edit.grammarFormComponentId
    }
    ColeitraWidgetEditGrammarExpression {
        visible: !grammarFormComponentId.existing
        width: parent.width
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
        existingId: Edit.grammarFormId
    }
    ColeitraWidgetEditGrammarFormComponent {
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
        existingId: Edit.compoundFormId
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
        existingId: Edit.sentenceId
    }
}
@}

@o ../src/ColeitraWidgetEditLexeme.qml
@{
import QtQuick 2.14
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.14
import EditLib 1.0
import DatabaseLib 1.0

Column {
    property int languageId: 1
    ColeitraWidgetEditIdSelection {
        id: lexemeId
        existingText: "Lexeme exists"
        existingId: Edit.lexemeId
    }
    ColeitraGridComboBox {
        visible: !lexemeId.existing
        width: parent.width
        model: Database.languagenames();
        currentIndex: Database.alphabeticidfromlanguageid(languageId);
    }
    Row {
        visible: !lexemeId.existing
        width: parent.width
        ColeitraGridImageButton {
            id: minusbutton
            visible: false
            imageid: "minus"
            clickhandler: function() {
            //    widget.destroy();
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
        ColeitraGridImageButton {
            id: plusbutton
            imageid: "plus"
            clickhandler: function() {
                plusbutton.visible = false;
                minusbutton.visible = true;
            }
        }
    }
    StackLayout {
        visible: !lexemeId.existing
        width: parent.width
        currentIndex: lexemeTypeSelection.currentIndex
        ColeitraWidgetEditForm {
        }
        ColeitraWidgetEditCompoundForm {
        }
        ColeitraWidgetEditSentence {
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
        existingText: "Translation exists"
        existingId: Edit.translationId
    }
    Column {
        width: parent.width
        visible: !translationPartId.existing
        ColeitraGridComboBox {
            id: translationPartType
            width: parent.width
            model: ["Lexeme", "Sentence", "Form", "Compundform", "Grammarform"]
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
        ColeitraGridLayout {
            width: Math.max(implicitWidth, parent.availableWidth)
            ColeitraWidgetEditTranslationPart {
                translationLanguageId: Settings.learninglanguage
                width: parent.width
            }
            ColeitraWidgetEditTranslationPart {
                translationLanguageId: Settings.nativelanguage
                width: parent.width
            }
            /*Column {
                width: parent.width
                Layout.columnSpan: 12
                function addAddRemoveEdit(language){
                    var component = Qt.createComponent("ColeitraWidgetEdit.qml");
                    if (component.status == Component.Ready) {
                        var newObject = component.createObject(this, {edit_language: language});
                    }
                    else {
                        console.log("Problem with creation of lexeme edit widget");
                    }
                }
                Component.onCompleted: {
                    addAddRemoveEdit(Settings.learninglanguage);
                }
            }
            Rectangle {
                width: 0
                height: 40
                Layout.columnSpan: 12
            }
            Column {
                width: parent.width
                Layout.columnSpan: 12
                function addAddRemoveEdit(language){
                    var component = Qt.createComponent("ColeitraWidgetEdit.qml");
                    if (component.status == Component.Ready) {
                        var newObject = component.createObject(this, {edit_language: language});
                    }
                    else {
                        console.log("Problem with creation of lexeme edit widget");
                    }
                }
                Component.onCompleted: {
                    addAddRemoveEdit(Settings.nativelanguage);
                }
            }*/
        }
    }
    footer: ColeitraGridLayout {
    }
}
@}


