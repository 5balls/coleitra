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

@i gui_main.w

@i gui_train.w

@i gui_about.w

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

\subsection{GUI fragments}
@d Coleitra label @'name@' with value @'value@'
@{
ColeitraGridLabel {
    text: @1
}
ColeitraGridValueText {
    text: @2
}
@}
