% Copyright 2020, 2021, 2022 Florian Pesth
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

\section{New template}

\subsection{ColeitraWidgetNewTemplateLanguageEditFormAdd}
@o ../src/ColeitraWidgetNewTemplateLanguageEditFormAdd.qml
@{
import QtQuick 2.14

Rectangle {
    property bool modifiedIndex: stringValue.text != ""
    property alias ntlefasv: stringValue
    id: formEdit
    width: parent.width
    color: formEdit.modifiedIndex? "#FFFFDD" : "#FFFFFF"
    height: feplusbutton.height + formGrammarEdit.height
    Column {
        width: parent.width
        Row {
            width: parent.width
            ColeitraGridImageButton {
                visible: false
                id: feminusbutton
                imageid: "minus"
                height: 40
                clickhandler: function() { 
                    formEdit.destroy();
                }
            }
            ColeitraGridLabel {
                id: stringLabel
                text: "Form"
            }
            Item {
                width: 10
                height: 10
            }
            ColeitraGridTextInput {
                id: stringValue
                width: parent.width - stringLabel.width - 10 - 40
                background: ColeitraWidgetRoundedRectangle { 
                    color: formEdit.modifiedIndex?  "#FFFFDD" : "#DDFFFF"
                }
            }
            ColeitraGridImageButton {
                visible: true
                id: feplusbutton
                imageid: "plus"
                height: 40
                clickhandler: function() { 
                    feplusbutton.visible = false;
                    feminusbutton.visible = true;
                    formEdit.parent.addPart();
                }
            }
        }
        ColeitraWidgetEditGrammarFormComponentList {
            id: formGrammarEdit
            width: parent.width
        }
    }
}
@}

\subsection{ColeitraWidgetNewTemplateLanguageEditLexemeAdd}
@o ../src/ColeitraWidgetNewTemplateLanguageEditLexemeAdd.qml
@{
import QtQuick 2.14

Column {
    id: lexemeAdd
    width: parent? parent.width : 400
    Row {
        width: parent.width
        ColeitraGridImageButton {
            visible: false
            id: laminusbutton
            imageid: "minus"
            height: 40
            clickhandler: function() { 
                lexemeAdd.destroy();
            }
        }
        ColeitraGridLabel {
            text: "Lexeme:"
            width: parent.width - 40
        }
        ColeitraGridImageButton {
            visible: true
            id: laplusbutton
            imageid: "plus"
            height: 40
            clickhandler: function() { 
                laplusbutton.visible = false;
                laminusbutton.visible = true;
                lexemeAdd.parent.addPart();
            }
        }
    }
    ColeitraWidgetEditPartList {
        id: languageedit
        partType: "ColeitraWidgetNewTemplateLanguageEditFormAdd"
        width: parent.width
    }
}
@}

\subsection{ColeitraWidgetNewTemplateLanguageEditTabContent}
@o ../src/ColeitraWidgetNewTemplateLanguageEditTabContent.qml
@{
import QtQuick 2.14

Column {
    property alias nltitle : title
    property alias nldefaultlexemelist: defaultlexemelist
    property alias nldefaultformlist: defaultformlist
    ColeitraGridLabel {
        id: title
    }
    Column {
        width: parent? parent.width : 400
        height: parent.height - buttonrow.height - title.height
        ColeitraGridLabel {
            text: "<b>Default lexemes to add to the database:</b>"
        }
        ColeitraWidgetEditPartList {
            id: defaultlexemelist
            partType: "ColeitraWidgetNewTemplateLanguageEditLexemeAdd"
            width: parent.width
        }
        ColeitraGridLabel {
            text: "<b>Forms to look up to add to the database:</b>"
        }
        ColeitraWidgetEditPartList {
            id: defaultformlist
            partType: "ColeitraWidgetNewTemplateLanguageEditFormAdd"
            width: parent.width
        }
    }
    Row {
        width: parent.width
        id: buttonrow
        ColeitraGridRedButton {
            id: resetButton
            text: "Reset"
            width: parent.width / 2
            height: 80
            onClicked: {
            }
        }
        ColeitraGridGreenButton {
            id: saveConfigButton
            text: "Save config"
            width: parent.width / 2
            height: 80
            onClicked: {
            }
        }
    }
}
@}

\subsection{ColeitraWidgetNewTemplateProcessInstructions}
@o ../src/ColeitraWidgetNewTemplateProcessInstructions.qml
@{
import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14

Column {
    property var pbutton: piplusbutton
    property var mbutton: piminusbutton
    property var piinstruction: instruction
    property var pigrammaredit: instructiongrammaredit
    id: piwidget
    height: instructiongrammaredit.visible? instructionselection.height + instructiongrammaredit.height : instructionselection.height
    Row {
        id: instructionselection
        width: parent.width
        height: 40
        ColeitraGridImageButton {
            visible: false
            id: piminusbutton
            imageid: "minus"
            height: 40
            clickhandler: function() { 
                piwidget.destroy();
            }
        }
        ColeitraGridLabel {
            visible: false
            id: instructionlabel
            text: instruction.currentText
            width: (piwidget.width - 40)
            height: 40
            @<Background yellow rounded control@>
        }
        ColeitraGridComboBox {
            id: instruction
            model: ["Ignore form", "Look up form", "Look up form (lexeme)", "Add and use form", "Add and ignore form"]
            width: (piwidget.width - 40)
            height: 40
        }
        ColeitraGridImageButton {
            imageid: "plus"
            id: piplusbutton
            height: 40
            clickhandler: function() { 
                piminusbutton.visible = true;
                instruction.visible = false;
                instructionlabel.visible = true;
                piplusbutton.visible = false;
                piwidget.parent.addPart();
            }
        }
    }
    ColeitraWidgetEditGrammarFormComponentList {
        id: instructiongrammaredit
        visible: instruction.currentIndex != 0
        width: parent.width
        height: 40
    }
}
@}

\subsection{ColeitraWidgetNewTemplateTabContent}
@o ../src/ColeitraWidgetNewTemplateTabContent.qml
@{
import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14 as QQC2
import QtQuick.Controls 1.4
import QtQml.Models 2.14

Column {
    property var nttv: tv
    property alias nttitle: title
    property alias ntism: ism
    width: parent? parent.width : 400
    ColeitraGridLabel {
        id: title
    }
    QQC2.ScrollView {
        id: scrollview_processinstructions
        width: parent.width
        height: grammarscrollview.height < (parent.height - buttonrow.height)/ 2.0 ? grammarscrollview.height : (parent.height - buttonrow.height) / 2.0
        clip: true
        Column {
            id: grammarscrollview
            width: parent.width
            ColeitraGridLabel {
                id: selectedview
            }
            ColeitraGridComboBox {
                id: content_type
                model: ["Form", "Form with ignored parts", "Compoundform", "Sentence"]
                width: parent.width
            }
            ColeitraWidgetEditGrammarFormComponentList {
                id: grammaredit
                width: parent.width
            }
            ColeitraWidgetEditPartList {
                partType: "ColeitraWidgetNewTemplateProcessInstructions"
                id: processinstructions
                width: parent.width
                visible: content_type.currentIndex != 0
            }
        }
    }
    ItemSelectionModel {
        id: ism
    }
    TableView {
        id: tv
        width: parent.width
        height: parent.height - title.height - buttonrow.height - scrollview_processinstructions.height 
        rowDelegate: Rectangle{
            width: childrenRect.width
            height: 30
        }
        itemDelegate: Rectangle {
            property var cellIsSelected: false
            color:  cellIsSelected ? (styleData.row % 2? "#DDFFFF" : "#CCEEEE") : (styleData.row % 2? "#FFFFFF": "#EEEEEE")
            Label {
                width: parent.width
                text: {
                    if(styleData.value.length > 0){
                        var cellContent = "";
                        if(cellIsSelected) cellContent += "<b>";
                        for(const cellValue of styleData.value){
                            cellContent += cellValue + ", ";
                        }
                        cellContent = cellContent.slice(0,-2);
                        if(cellIsSelected) cellContent += "</b>";
                        return cellContent;
                    }
                    else
                        return "";
                    //cellIsSelected ? "<b>" + styleData.value[0] + "</b>" : styleData.value[0]
                }
                font.pointSize: 14
            }
            MouseArea {
                anchors.fill: parent
                onClicked: { 
                    ism.select(tv.model.index(styleData.row,styleData.column), ItemSelectionModel.Toggle);
                    if(ism.hasSelection){
                        var selectedIndexesString = "<b>Selected:</b> ";
                        for(const selectedIndex of ism.selectedIndexes){
                            selectedIndexesString += tv.model.data(selectedIndex, selectedIndex.column) + " ";
                        }
                        selectedview.text = selectedIndexesString;
                    }
                    else{
                        selectedview.text = "";
                    }
                }
            }
            Connections {
                target: ism
                function onSelectionChanged(selected, unselected) {
                    var curIndex = tv.model.index(styleData.row,styleData.column);
                    cellIsSelected = false;
                    for(const selectedIndex of ism.selectedIndexes){
                        if(selectedIndex == curIndex){
                            cellIsSelected = true;
                        }
                    }
                }
            }
        }
    }
    Row {
        width: parent.width
        id: buttonrow
        ColeitraGridRedButton {
            id: resetButton
            text: "Reset selection"
            width: parent.width / 4
            height: 80
            onClicked: {
                ism.clearSelection();
                selectedview.text = "";
            }
        }
        ColeitraGridRedButton {
            id: resetGrammarButton
            text: "Reset grammar"
            width: parent.width / 4
            height: 80
            onClicked: {
                for(var i = grammaredit.children.length; i > 0; i--){
                    if(grammaredit.children[i-1].mbutton.visible){
                        grammaredit.children[i-1].destroy();
                    }
                    else{
                        grammaredit.children[i-1].gk.currentIndex = 0;
                        grammaredit.children[i-1].gv.currentIndex = 0;
                    }
                }
                grammaredit.height = 40;
                for(var i = processinstructions.children.length; i > 0; i--){
                    if(processinstructions.children[i-1].mbutton.visible){
                        processinstructions.children[i-1].destroy();
                    }
                    else{
                        for(var j = processinstructions.children[i-1].pigrammaredit.children.length; j > 0; j--){
                            if(processinstructions.children[i-1].pigrammaredit.children[j-1].mbutton.visible){
                                processinstructions.children[i-1].pigrammaredit.children[j-1].destroy();
                            }
                            else{
                                processinstructions.children[i-1].pigrammaredit.children[j-1].gk.currentIndex = 0;
                                processinstructions.children[i-1].pigrammaredit.children[j-1].gv.currentIndex = 0;
                            }
                        }
                        processinstructions.children[i-1].pigrammaredit.height = 40;
                        processinstructions.children[i-1].piinstruction.currentIndex = 0;
                    }
                }
                content_type.currentIndex = 0;
            }
        }
        ColeitraGridGreenButton {
            id: saveGrammarButton
            text: "Save grammar"
            width: parent.width / 4
            height: 80
            onClicked: {
            }
        }
        ColeitraGridGreenButton {
            id: saveTemplateButton
            text: "Save template"
            width: parent.width / 4
            height: 80
            onClicked: {
            }
        }
    }
}

@}

@O ../src/newtemplate.qml
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
    id: tabPage
    property var tabContent;
    property var tabContentLanguage;
    property var tabContentWidgetString;
    property var tableViewModel;
    property var language;
    property var addLanguageTab: function(l_language){
        language = l_language;
        var tabItem = Qt.createQmlObject('import QtQuick.Controls 2.14; TabButton { text: "Language ' + Database.languagenamefromid(language) + '" }', templateselection);
        templateselection.addItem(tabItem);
        tabContentLanguage = Qt.createComponent("ColeitraWidgetNewTemplateLanguageEditTabContent.qml");
        if(tabContentLanguage.status == Component.Ready) {
            //console.log("1 NO Problem with the creation of language tab");
            finishLanguageTab();
        }
        else {
            //console.log("1 Problem with the creation of language tab");
            tabContentLanguage.statusChanged.connect(finishLanguageTab);
        }
    }
    property var finishLanguageTab: function(){
        if (tabContentLanguage.status == Component.Ready) {
            //console.log("2 NO Problem with the creation of language tab");
            var newObject = tabContentLanguage.createObject(templatecontent); 
            newObject.nltitle.text = "<b>" + Database.languagenamefromid(language) + "</b>";
            newObject.width = tabPage.width;
            newObject.height = tabPage.height-templateselection.height;
            templatecontent.children.push(newObject);
            var formlist = GrammarProvider.getGrammarLookupForms(tabPage, language);
            console.log("Number of lookup forms", typeof(formlist));
            newObject.nldefaultformlist.children[0].ntlefasv.text = "Hello";
            newObject.nldefaultformlist.addPart();
        }
        else{
            //console.log("2 Problem with the creation of language tab");
        }
    }
    property var addPossibleNewTemplate: function(unnamed_arguments, named_arguments, tableView){
        var tabItem = Qt.createQmlObject('import QtQuick.Controls 2.14; TabButton { text: "Template ' + unnamed_arguments[0] + '" }', templateselection);
        templateselection.addItem(tabItem);
        if(unnamed_arguments.length>0){
            tabContentWidgetString = '<b>' + unnamed_arguments[0] + '</b> ';
            if(unnamed_arguments.length>1){
                for(var i=1; i<unnamed_arguments.length; i++){
                    if(unnamed_arguments[i].indexOf(' ')<0){
                        tabContentWidgetString += unnamed_arguments[i] + ' ';
                    }
                    else {
                        tabContentWidgetString += '\\"' + unnamed_arguments[i] + '\\" ';
                    }
                }
            }
            if(named_arguments.length>0){
                for(var i=0; i<named_arguments.length; i++){
                    if(named_arguments[i][0].indexOf(' ')<0){
                        tabContentWidgetString += named_arguments[i][0];
                    }
                    else {
                        tabContentWidgetString += '\\"' + named_arguments[i][0] + '\\"';
                    }
                    tabContentWidgetString += '=';
                    if(named_arguments[i][1].indexOf(' ')<0){
                        tabContentWidgetString += named_arguments[i][1];
                    }
                    else {
                        tabContentWidgetString += '\\"' + named_arguments[i][1] + '\\"';
                    }
                    tabContentWidgetString += ' ';
                }
            }
            tabContent = Qt.createComponent("ColeitraWidgetNewTemplateTabContent.qml");
            tableViewModel = tableView;
            if(tabContent.status == Component.Ready) {
                //console.log("1 NO Problem with the creation of new template tab");
                finishNewTemplateTab();
            }
            else {
                //console.log("1 Problem with the creation of new template tab");
                tabContent.statusChanged.connect(finishNewTemplateTab);
            }
        };
    }
    property var finishNewTemplateTab: function(){
        if (tabContent.status == Component.Ready) {
            //console.log("2 NO Problem with the creation of new template tab");
            var newObject = tabContent.createObject(templatecontent); 
            newObject.nttitle.text = tabContentWidgetString;
            for(var i=0; i<tableViewModel.columnCount(); i++){
                var tableViewColumn = Qt.createQmlObject('
import QtQuick.Controls 1.4;
 TableViewColumn {
 role: "col' + i.toString() + '"
 } ', newObject.nttv);

                newObject.nttv.addColumn(tableViewColumn);
            }
            newObject.nttv.model = tableViewModel;
            newObject.ntism.model = tableViewModel;
            newObject.width = tabPage.width;
            newObject.height = tabPage.height-templateselection.height;
            templatecontent.children.push(newObject);
        }
        else{
            //console.log("2 Problem with the creation of new template tab");
        }
    }
    title: "New Template"
    focus: true
    Column{
        anchors.fill: parent
            TabBar {
                id: templateselection
                width: parent.width
            }
            StackLayout {
                width: parent.width
                id: templatecontent
                currentIndex: templateselection.currentIndex
           }
    }
}
@}
