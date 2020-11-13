% Copyright 2020 Florian Pesth
%
% This file is part of coleitra.
%
% coleitra is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% coleitra is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with coleitra.  If not, see <https://www.gnu.org/licenses/>.

\section{Edit}

@o ../src/ColeitraWidgetEditGrammarExpression.qml
@{
import QtQuick 2.14
import QtQuick.Layouts 1.14
import GrammarProviderLib 1.0
import DatabaseLib 1.0

ColeitraGridInGridLayout {
    id: widget
    Image {
        visible: false
        id: minusbutton
        source: "minus.svg"
        Layout.columnSpan: 2
        Layout.preferredHeight: 40
        Layout.preferredWidth: 40
        MouseArea {
            anchors.fill: parent
            onClicked: { 
                widget.destroy();
            }
            onPressed: {
                parent.source = "minus_pressed.svg";
            }
            onReleased: {
                parent.source = "minus.svg";
            }
        }
    }
    ColeitraGridComboBox {
        id: grammarkey
        model: Database.grammarkeys()
        Layout.columnSpan: 4
        Layout.preferredWidth: 100
    }
    ColeitraGridComboBox {
        id: grammarvalue
        model: Database.grammarvalues(grammarkey.currentText)
        Layout.columnSpan: 4
        Layout.preferredWidth: 100
    }

    ColeitraGridLabel {
        visible: false
        id: grammarkeylabel
        text: grammarkey.currentText
        Layout.columnSpan: 4
        Layout.preferredHeight: 40
        Layout.preferredWidth: 100
        @<Background yellow rounded control@>
    }
    ColeitraGridLabel {
        visible: false
        id: grammarvaluelabel
        text: grammarvalue.currentText
        Layout.columnSpan: 4
        Layout.preferredHeight: 40
        Layout.preferredWidth: 100
        @<Background yellow rounded control@>
    }

    Image {
        source: "plus.svg"
        id: plusbutton
        Layout.columnSpan: 2
        Layout.preferredHeight: 40
        Layout.preferredWidth: 40
        MouseArea {
            anchors.fill: parent
            onClicked: { 
                minusbutton.visible = true;
                grammarkey.visible = false;
                grammarkeylabel.visible = true;
                grammarvalue.visible = false;
                grammarvaluelabel.visible = true;
                plusbutton.visible = false;
                widget.parent.addAddRemoveGrammarExpression();
            }
            onPressed: {
                parent.source = "plus_pressed.svg";
            }
            onReleased: {
                parent.source = "plus.svg";
            }
        }
    }
    Component.onCompleted: {
        grammarkey.Layout.preferredWidth = parent.width/2.0 - 20;
        grammarkeylabel.Layout.preferredWidth = parent.width/2.0 - 20;
        grammarvalue.Layout.preferredWidth = parent.width/2.0 - 20;
        grammarvaluelabel.Layout.preferredWidth = parent.width/2.0 - 20;
    }
}
@}

@o ../src/ColeitraWidgetEditGrammarForm.qml
@{
import QtQuick 2.14
import QtQuick.Layouts 1.14
import GrammarProviderLib 1.0
import DatabaseLib 1.0

ColeitraGridInGridLayout {
    id: widget
    property var language: 1
    Image {
        id: minusbutton
        visible: false
        source: "minus.svg"
        Layout.columnSpan: 2
        Layout.preferredHeight: 40
        Layout.preferredWidth: 40
        MouseArea {
            anchors.fill: parent
            onClicked: { 
                widget.destroy();
            }
            onPressed: {
                parent.source = "minus_pressed.svg";
            }
            onReleased: {
                parent.source = "minus.svg";
            }
        }
    }
    ColeitraGridTextInput {
        id: lexeme
        Layout.columnSpan: 6
        Layout.preferredWidth: 120
        Connections {
            target: GrammarProvider
            onGrammarobtained: {
                console.log("Received the signal " + expressions.length + "==" + grammarexpressions.length);
                var j,j_max;
                j_max = expressions.length;
                for(j=0; j<j_max; j++){
                    var item = expressions[j];
                    console.log("Item " + item);
                    var grammartags;
                    grammartags = grammarexpressions[j];
                    console.log("  item length " + grammarexpressions[j]);
                    var i,i_max;
                    i_max = grammartags.length;
                    for(i=0; i<i_max; i++){
                        console.log("["+grammartags[i][0] + "]=" + grammartags[i][1]);
                    }
                }
            }
        }
    }
    Image {
        source: "www.svg"
        Layout.columnSpan: 2
        Layout.preferredHeight: 40
        Layout.preferredWidth: 40
        MouseArea {
            anchors.fill: parent
            onClicked: { 
                GrammarProvider.language = language;
                GrammarProvider.word = lexeme.text;
                GrammarProvider.getWiktionarySections()
            }
            onPressed: {
                parent.source = "www_pressed.svg";
            }
            onReleased: {
                parent.source = "www.svg";
            }
        }


    }
    Image {
        id: plusbutton
        source: "plus.svg"
        Layout.columnSpan: 2
        Layout.preferredHeight: 40
        Layout.preferredWidth: 40
        MouseArea {
            anchors.fill: parent
            onClicked: { 
                plusbutton.visible = false;
                minusbutton.visible = true;
                parent.parent.parent.addAddRemoveGrammarForm();
            }
            onPressed: {
                parent.source = "plus_pressed.svg";
            }
            onReleased: {
                parent.source = "plus.svg";
            }
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
@}

@o ../src/ColeitraWidgetEditLexeme.qml
@{
import DatabaseLib 1.0
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

}
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
    Image {
        id: minusbutton
        visible: false
        source: "minus.svg"
        Layout.columnSpan: 2
        Layout.preferredHeight: 40
        Layout.preferredWidth: 40
        MouseArea {
            anchors.fill: parent
            onClicked: { 
                widget.destroy();
            }
            onPressed: {
                parent.source = "minus_pressed.svg";
            }
            onReleased: {
                parent.source = "minus.svg";
            }
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
    Image {
        id: plusbutton
        source: "plus.svg"
        Layout.columnSpan: 2
        Layout.preferredHeight: 40
        Layout.preferredWidth: 40
        MouseArea {
            anchors.fill: parent
            onClicked: { 
                plusbutton.visible = false;
                minusbutton.visible = true;
                parent.parent.parent.addAddRemoveEdit(edit_language);
            }
            onPressed: {
                parent.source = "plus_pressed.svg";
            }
            onReleased: {
                parent.source = "plus.svg";
            }
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
            Column {
                /*ColeitraWidgetEdit {
                    edit_language: Settings.learninglanguage
                    width: parent.width
                }*/
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

            }
        }
    }
        
    footer: ColeitraGridLayout {
    }
}
@}


