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
@o ../src/edit.qml
@{
import QtQuick 2.14
import QtQuick.Layouts 1.14
import EditLib 1.0
import SettingsLib 1.0
import GrammarProviderLib 1.0

ColeitraPage {
    title: "Lexeme editing"
    ColeitraGridLayout {
        ColeitraGridTextInput {
            id: lexeme
            Layout.columnSpan: 6
            Layout.preferredWidth: parent.width - 120
            text: Edit.dbversion;
        }
        Image {
            source: "www.svg"
            Layout.columnSpan: 2
            Layout.preferredHeight: 40
            Layout.preferredWidth: 40
            MouseArea {
                anchors.fill: parent
                onClicked: { 
                    GrammarProvider.language = Settings.learninglanguage;
                    GrammarProvider.word = lexeme.text;
                    GrammarProvider.getWiktionarySections()
                }
            }
        }
        Image {
            source: "plus.svg"
            Layout.columnSpan: 2
            Layout.preferredHeight: 40
            Layout.preferredWidth: 40
        }
        Image {
            source: "minus.svg"
            Layout.columnSpan: 2
            Layout.preferredHeight: 40
            Layout.preferredWidth: 40
        }

    }
    footer: ColeitraGridLayout {
    }
}
@}


