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

\subsection{ColeitraWidgetNewTemplateTabContent}
@o ../src/ColeitraWidgetNewTemplateTabContent.qml
@{
import QtQuick 2.14
import QtQuick.Layouts 1.14
import QtQuick.Controls 2.14
import QtQuick.Controls 1.4

Column {
    property var nttv: tv
    property var nttitle: title
    width: parent? parent.width : 400
    ColeitraGridLabel {
        id: title
    }
    TableView {
        width: parent.width
        height: parent.height - title.height
        id: tv
        itemDelegate: Label {
            text: styleData.value
        }
        TableViewColumn {
            role: "col0"
        }
        TableViewColumn {
            role: "col1"
        }
        TableViewColumn {
            role: "col2"
        }
        TableViewColumn {
            role: "col3"
        }
        TableViewColumn {
            role: "col4"
        }
        TableViewColumn {
            role: "col5"
        }
        TableViewColumn {
            role: "col6"
        }
        TableViewColumn {
            role: "col7"
        }
        TableViewColumn {
            role: "col8"
        }
        TableViewColumn {
            role: "col9"
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
    property var tabContentWidgetString;
    property var tableViewModel;
    property var addPossibleNewTemplate: function(unnamed_arguments, named_arguments, tableView){
        var tabItem = Qt.createQmlObject('import QtQuick.Controls 2.14; TabButton { text: "' + unnamed_arguments[0] + '" }', templateselection);
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
                console.log("1 NO Problem with the creation of new template tab");
                finishNewTemplateTab();
            }
            else {
                console.log("1 Problem with the creation of new template tab");
                tabContent.statusChanged.connect(finishNewTemplateTab);
            }
        };
    }
    property var finishNewTemplateTab: function(){
        if (tabContent.status == Component.Ready) {
            console.log("2 NO Problem with the creation of new template tab");
            var newObject = tabContent.createObject(templatecontent); 
            newObject.nttitle.text = tabContentWidgetString;
            newObject.nttv.model = tableViewModel;
            console.log("Test",tabPage.height);
            newObject.width = tabPage.width;
            newObject.height = tabPage.height-templateselection.height;
            templatecontent.children.push(newObject);
        }
        else{
            console.log("2 Problem with the creation of new template tab");
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
