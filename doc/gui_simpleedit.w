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

\section{Simple edit}
\subsection{TODO}
\begin{enumerate}
\item Different interface than \verb#gui_edit.w#. Multiple forms should be processed by the cpp code and just a string needs to be transfered back (there might need to be a selection possibility for ambiguos forms)
\item Is it running in a different thread than cpp code? Should it?
\item How to deal with forms in sentences which don't have a translation yet?
\end{enumerate}

@O ../src/ColeitraWidgetSimpleEditInput.qml
@{
import QtQuick 2.14
import DatabaseLib 1.0
import EditLib 1.0

FocusScope {
    x: simpleeditinput.x
    y: simpleeditinput.y
    height: simpleeditinput.height
    width: simpleeditinput.width
    property var language: 1
    property var translationid: 0
    property var inputField: inputfield
    property var searchResult: searchresult
    Column {
        id: simpleeditinput
        width: parent.parent.width
        ColeitraGridLabel {
            text: Database.languagenamefromid(language)
            width: parent.width
        }
        ColeitraGridTextInput {
            focus: true
            id: inputfield
            width: parent.width
            property var oldtext: ""
            onEditingFinished: function(){
                if(!(text === oldtext)){
                    if(!(oldtext === "")){
                        Edit.moveLexemeOutOfTranslation(language, oldtext);
                    }
                    progressPopup.popupTitle = "Obtaining grammar information for " + text;
                    progressPopup.open();
                    Edit.addLexemeHeuristically(simpleeditinput,language, text, translationid);
                }
                oldtext = text;
            }
        }
        ColeitraGridLabel {
            id: searchresult
            text: ""
            width: parent.width
            Connections {
                target: Edit
                function onAddLexemeHeuristicallyResult(caller, result){
                    if(caller != simpleeditinput) return;
                    searchresult.text = result;
                    simpleeditinput.parent.parent.readytosave = Edit.isReadyToSave();
                    progressPopup.close();
                }
                function onProcessingUpdate(progress_action){
                    progressPopup.popupAction = progress_action;
                }
                function onPossibleTemplateAvailable(caller, number_of_templates, silent){
                    if(caller != simpleeditinput) return;
                    loader.item.push("newtemplate.qml");
                    Edit.getNextPossibleTemplate(simpleeditinput);
                }
                function onPossibleTemplateEdit(caller, unnamed_arguments, named_arguments, tableView){
                    if(caller != simpleeditinput) return;
                    loader.item.currentItem.addPossibleNewTemplate(unnamed_arguments, named_arguments, tableView);
                    Edit.getNextPossibleTemplate(simpleeditinput);
                }
            }
        }
        ColeitraWidgetProgressPopup {
            id: progressPopup
            width: parent.width
        }

    }
}

@}

\subsection{Implementation}
@O ../src/simpleedit.qml
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
    title: "Simple translation edit"
    focus: true
    ScrollView {
        anchors.fill: parent
        focus: true
        Column {
            id: inputFields
            width: parent.width
            property var translation_id: Edit.translationId
            property var readytosave: false
            ColeitraWidgetSimpleEditInput {
                id: inputLearningLanguage
                KeyNavigation.tab: inputNativeLanguage
                focus: true
                language: Settings.learninglanguage
                translationid: parent.translation_id
            }
            ColeitraWidgetSimpleEditInput {
                id: inputNativeLanguage
                KeyNavigation.tab: saveButton
                focus: false
                language: Settings.nativelanguage
                translationid: parent.translation_id
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
                        inputFields.readytosave = false;
                        Edit.resetEverything();
                        inputLearningLanguage.inputField.text = "";
                        inputLearningLanguage.inputField.oldtext = "";
                        inputLearningLanguage.searchResult.text = "";
                        inputNativeLanguage.inputField.text = "";
                        inputNativeLanguage.inputField.oldtext = "";
                        inputNativeLanguage.searchResult.text = "";
                    }
                }
                ColeitraGridGreenButton {
                    id: saveButton
                    KeyNavigation.tab: inputLearningLanguage
                    text: "Save"
                    width: parent.width / 2
                    height: 80
                    enabled: inputFields.readytosave
                    Keys.onReturnPressed: save()
                    Keys.onEnterPressed: save()
                    onClicked: save()
                    function save(){
                        inputFields.readytosave = false;
                        Edit.saveToDatabase();
                        Edit.resetEverything();
                        inputLearningLanguage.inputField.text = "";
                        inputLearningLanguage.inputField.oldtext = "";
                        inputLearningLanguage.searchResult.text = "";
                        inputNativeLanguage.inputField.text = "";
                        inputNativeLanguage.inputField.oldtext = "";
                        inputNativeLanguage.searchResult.text = "";
                        inputLearningLanguage.forceActiveFocus();
                    }
                    onEnabledChanged: {
                        if(enabled) {
                            forceActiveFocus();
                        }
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

@O ../src/ColeitraWidgetProgressPopup.qml
@{
import QtQuick 2.14
import QtQuick.Controls 2.14

Popup {
    property string popupTitle: ""
    property string popupAction: ""
    Column {
        width: parent.width
        ColeitraGridLabel {
            width: parent.width
            text: "<b>" + popupTitle + "</b>"
        }
        ColeitraGridLabel {
            width: parent.width
            text: "<i>" + popupAction + "</i>"
        }
        ProgressBar {
            width: parent.width
            indeterminate: true
        }
    }
    @<Background grey rounded control@>
}
@}
