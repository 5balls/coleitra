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

\section{Main}
\codeqml
@o ../src/main.qml
@{
import QtQuick 2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import QtQuick.Window 2.11

ApplicationWindow {
    id: window
    visible: true
    visibility: Window.FullScreen
    title: qsTr("Stack")
    //useSafeArea: false

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

@d Side menu screen option @'optionname@' defined in @'qmlfile@'
@{
ItemDelegate {
    text: "@1"
    width: parent.width
    onClicked: {
        stackView.push("@2")
        drawer.close()
    }
}
@}


@d Main drawer
@{
Drawer {
    id: drawer
    width: window.width * 0.66
    height: window.height

    Column {
        anchors.fill: parent
        @<Side menu screen option @'Edit@' defined in @'edit.qml@' @>
        @<Side menu screen option @'Settings@' defined in @'settings.qml@' @>
        @<Side menu screen option @'About@' defined in @'about.qml@' @>
        ItemDelegate {
            text: "Quit"
            width: parent.width
            onClicked: {
                Qt.callLater(Qt.quit)
            }
        }
    }
}
@}

