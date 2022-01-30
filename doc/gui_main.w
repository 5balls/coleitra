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
    visibility: Window.Hidden
    title: qsTr("coleitra")
    //useSafeArea: false

    @<Main header@>

    Component {
        id: stackView
        StackView {
            initialItem: "splash.qml"
            anchors.fill: parent
            onCurrentItemChanged: {
                currentItem.forceActiveFocus()
            }
        }
    }
    Loader {
        id: loader
        anchors.fill: parent
        asynchronous: true
        opacity: 0
        focus: true
        sourceComponent: stackView
        onLoaded: {
            window.visibility = Window.FullScreen;
            loader.opacity = 1;
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuad;
            }
        }
    }

    @<Main drawer@>
}

@}

\subsection{Header}
\index{GUI!Header}
@d Main header
@{
header: ToolBar {
    id: toolBar
    visible: false
    contentHeight: toolButton.implicitHeight
    ToolButton {
        id: toolButton
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        background: Image {
            source: loader.item.depth > 2 ? "back.svg" : "settings.svg"
            sourceSize.height: 50
            fillMode: Image.PreserveAspectFit
        }
        onClicked: {
            if (loader.item.depth > 2) {
                loader.item.pop()
            } else {
                drawer.open()
            }
        }
    }

    Label {
        text: loader.item.currentItem.title
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
        loader.item.push("@2");
        drawer.close();
    }
}
@}


@d Main drawer
@{
Drawer {
    id: drawer
    width: window.width * 0.66
    height: window.height
    visible: false

    Column {
        anchors.fill: parent
        @<Side menu screen option @'Simple enter@' defined in @'simpleedit.qml@' @>
        @<Side menu screen option @'Expert enter@' defined in @'edit.qml@' @>
        @<Side menu screen option @'Database edit@' defined in @'databaseedit.qml@' @>
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

