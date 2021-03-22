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

Column {
    id: simpleeditinput
    width: parent.width
    property var language: 1
    property var translationid: 0
    ColeitraGridLabel {
	text: Database.languagenamefromid(language)
	width: parent.width
    }
    ColeitraGridTextInput {
	width: parent.width
        property var oldtext: ""
	onEditingFinished: function(){
            if(!(text === oldtext)){
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
            }
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
    ScrollView {
        anchors.fill: parent
        Column {
            width: parent.width
            property var translation_id: Edit.translationId
            ColeitraWidgetSimpleEditInput {
                language: Settings.learninglanguage
                translationid: parent.translation_id
            }
            ColeitraWidgetSimpleEditInput {
                language: Settings.nativelanguage
                translationid: parent.translation_id
            }
        }
    }
    footer: Column {
       width: parent.width
        Row {
            width: parent.width
            ColeitraGridRedButton {
                text: "Reset"
                width: parent.width / 2
                height: 80
                onClicked: {
                    Edit.resetEverything();
                }
            }
            ColeitraGridGreenButton {
                text: "Save"
                width: parent.width / 2
                height: 80
                onClicked: {
                    //Edit.saveToDatabase();
                }
            }
        }
        Item {
            height: 20
            width: parent.width
        }
    }
}
@}


