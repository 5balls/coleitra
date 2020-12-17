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

\chapter{GUI-Elements}
\index{GUI}

@i gui_main.w

@i gui_train.w

@i gui_edit.w

@i gui_about.w

@i gui_settings.w

\section{Reusable GUI elements}
\subsection{Page}

@o ../src/ColeitraPage.qml
@{
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3

Page {
}
@}

\subsection{Grid Layout}

@o ../src/ColeitraGridLayout.qml
@{
import QtQuick 2.11
import QtQuick.Controls 2.4
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

@o ../src/ColeitraGridInGridLayout.qml
@{
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3

GridLayout {
    visible: true
    Layout.columnSpan: 12
    Layout.fillWidth: true
    Layout.preferredWidth: parent.width
    columns: 12
    columnSpacing: 0
    rowSpacing: 0
    flow: GridLayout.LeftToRight
}
@}


\subsection{Grid Label}
@o ../src/ColeitraGridLabel.qml
@{

import QtQuick 2.11
import QtQuick.Controls 2.4
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
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3

Label {
    Layout.columnSpan: 6
    Layout.preferredWidth: parent.width / 2.0
    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
    wrapMode: Text.WordWrap
}
@}

\subsection{Grid Textedit}
@o ../src/ColeitraGridTextInput.qml
@{
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3

TextField {
    Layout.columnSpan: 8
    Layout.preferredWidth: parent.width 
    Layout.alignment: Qt.AlignCenter
    @< Background rounded control@>
}
@}

\subsection{Grid Combobox}
@o ../src/ColeitraGridComboBox.qml
@{
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3

ComboBox {
    Layout.columnSpan: 6
    Layout.preferredWidth: parent.width / 2.0
    Layout.alignment: Qt.AlignCenter
    @< Background rounded control@>
}
@}

\subsection{Grid Checkbox}
@o ../src/ColeitraGridCheckBox.qml
@{
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.3

CheckBox {
    Layout.columnSpan: 12
}
@}

\subsection{Grid button}
@o ../src/ColeitraGridButton.qml
@{
import QtQuick 2.11
import QtQuick.Controls 2.14
import QtQuick.Layouts 1.3

Button {
    Layout.columnSpan: 6
    Layout.preferredWidth: parent.width / 2.0
    @< Background rounded control@>
}
@}

\subsection{Grid image button}
@o ../src/ColeitraGridImageButton.qml
@{
import QtQuick 2.14
import QtQuick.Layouts 1.14

Image {
    property var imageid: "plus"
    property var clickhandler: function() {};
    source: imageid + ".svg"
    Layout.columnSpan: 2
    Layout.preferredHeight: 40
    Layout.preferredWidth: 40
    height: 40
    width: 40
    MouseArea {
        id: ma
        anchors.fill: parent
        onClicked: clickhandler()
        onPressed: {
            parent.source = parent.imageid + "_pressed.svg";
        }
        onReleased: {
            parent.source = parent.imageid + ".svg";
        }
    }
}
@}

\subsection{GUI fragments}
\subsubsection{Label and text}
@d Coleitra label @'name@' with value @'value@'
@{
ColeitraGridLabel {
    text: @1
}
ColeitraGridValueText {
    text: @2
}
@}

@d Background rounded control
@{
background: Rectangle {
    border.color: "black"
    border.width: 1
    color: "#DDFFFF"
    radius: 4
    implicitHeight: 40
}
@}

@d Background yellow rounded control
@{
background: Rectangle {
    border.color: "black"
    border.width: 1
    color: "#FFFFDD"
    radius: 4
    implicitHeight: 40
}
@}

