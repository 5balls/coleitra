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

\chapter{GUI-Elements}
\index{GUI}
\section{Main}
\codeqml
@o ../src/main.qml
@{
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import QtQuick.Window 2.12

ApplicationWindow {
    id: window
    visible: true
    visibility: Window.FullScreen
    title: qsTr("Stack")

    @<Main header@>

    @<Main drawer@>

    StackView {
        id: stackView
        initialItem: "train.qml"
        anchors.fill: parent
        onCurrentItemChanged: {
            currentItem.forceActiveFocus()
        }
    }

}

@}

\subsection{Header}
\index{GUI!Header}
@d Main header
@{
header: ToolBar {
    contentHeight: toolButton.implicitHeight
    ToolButton {
        id: toolButton
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        background: Image {
            source: stackView.depth > 1 ? "back.svg" : "settings.svg"
            sourceSize.height: 50
            fillMode: Image.PreserveAspectFit
        }
        onClicked: {
            if (stackView.depth > 1) {
                stackView.pop()
            } else {
                drawer.open()
            }
        }
    }

    Label {
        text: stackView.currentItem.title
        anchors.centerIn: parent
    }
}
@}

\subsection{Drawer}
\index{GUI!Menu}
@d Main drawer
@{
Drawer {
    id: drawer
    width: window.width * 0.66
    height: window.height

    Column {
        anchors.fill: parent

        ItemDelegate {
            text: qsTr("About")
            width: parent.width
            onClicked: {
                stackView.push("about.qml")
                drawer.close()
            }
        }
    }
}
@}

\section{Train}
@o ../src/train.qml
@{
import QtQuick 2.12
ColeitraPage {
    title: "Vocable training"
    ColeitraGridLayout {
    }
    footer: ColeitraGridLayout {
    }
}
@}

\section{About}
@o ../src/about.qml
@{
import QtQuick 2.12
import SettingsStorageLib 1.0

ColeitraPage {
    title: "About coleitra"
    SettingsStorage {
        id: settingsstorage
    }
    ColeitraGridLayout {
        ColeitraGridLabel {
            text: "GIT commit:"
        }
        ColeitraGridValueText {
            text: settingsstorage.gitVersion
        }
        ColeitraGridLabel {
            text: "Clean repository?"
        }
        ColeitraGridValueText {
            text: settingsstorage.gitClean
        }
        ColeitraGridLabel {
            text: "Last commit message:"
        }
        ColeitraGridValueText {
            text: settingsstorage.gitLastCommitMessage
        }
        ColeitraGridLabel {
            text: "Qt version"
        }
        ColeitraGridValueText {
            text: settingsstorage.qtVersion
        }

    }
    footer: ColeitraGridLayout {
    }
}
@}

\section{Reusable GUI elements}
\subsection{Page}

@o ../src/ColeitraPage.qml
@{
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3

Page {
}
@}

\subsection{Grid Layout}

@o ../src/ColeitraGridLayout.qml
@{
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3

GridLayout {
    visible: true
    anchors.left: parent.left
    anchors.right: parent.right
    columns: 12
    columnSpacing: 0
    rowSpacing: 0
    flow: GridLayout.LeftToRight
}
@}

\subsection{Grid Label}
@o ../src/ColeitraGridLabel.qml
@{

import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3

Label {
    Layout.columnSpan: 6
    Layout.preferredWidth: parent.width / 2.0
    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
    wrapMode: Text.WordWrap
}
@}

\subsection{Grid Values}
\subsubsection{Text}
@o ../src/ColeitraGridValueText.qml
@{
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3

Label {
    Layout.columnSpan: 6
    Layout.preferredWidth: parent.width / 2.0
    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
    wrapMode: Text.WordWrap
}
@}
