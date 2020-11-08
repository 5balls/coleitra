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
        id: grammarexpression
        model: Database.grammarexpressions()
        Layout.columnSpan: 8
        Layout.preferredWidth: 100
    }
    ColeitraGridLabel {
        visible: false
        id: grammarexpressionlabel
        text: grammarexpression.currentText
        Layout.columnSpan: 8
        Layout.preferredHeight: 40
        Layout.preferredWidth: 100
        font.pixelSize: 20
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
                grammarexpression.visible = false;
                grammarexpressionlabel.visible = true;
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
        grammarexpression.Layout.preferredWidth = parent.width - 40;
        grammarexpressionlabel.Layout.preferredWidth = parent.width - 40;
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
    property var language: 1
    Image {
        visible: false
        source: "minus.svg"
        Layout.columnSpan: 2
        Layout.preferredHeight: 40
        Layout.preferredWidth: 40
    }
    ColeitraGridTextInput {
        id: lexeme
        Layout.columnSpan: 6
        Layout.preferredWidth: 120
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
        source: "plus.svg"
        Layout.columnSpan: 2
        Layout.preferredHeight: 40
        Layout.preferredWidth: 40
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
    id: grammarExpressionContainer
    ColeitraGridLabel {
        id: label
        text: "Lexeme (" + Database.languagenamefromid(lexeme_language) + ")"
        Layout.columnSpan: 10
        Layout.preferredWidth: 40
    }
    Image {
        source: "plus.svg"
        Layout.columnSpan: 2
        Layout.preferredHeight: 40
        Layout.preferredWidth: 40
    }
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
        label.Layout.preferredWidth = parent.width - 40;
        addAddRemoveGrammarForm();
    }
}
@}

@o ../src/edit.qml
@{
import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14
import EditLib 1.0
import SettingsLib 1.0
import DatabaseLib 1.0

ColeitraPage {
    title: "Lexeme editing"
    ScrollView {
        anchors.fill: parent
        ColeitraGridLayout {
            width: Math.max(implicitWidth, parent.availableWidth)
            function addAddRemoveLexeme(language){
                var component = Qt.createComponent("ColeitraWidgetEditLexeme.qml");
                if (component.status == Component.Ready) {
                    var newObject = component.createObject(this, {lexeme_language: language});
                }
                else {
                    console.log("Problem with creation of lexeme edit widget");
                }
            }
            Component.onCompleted: {
                addAddRemoveLexeme(Settings.learninglanguage);
                addAddRemoveLexeme(Settings.nativelanguage);
            }
        }
    }
    footer: ColeitraGridLayout {
    }
}
@}


