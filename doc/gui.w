\section{GUI-Elements}

\subsection{Main}
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

\subsubsection{Header}

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

\subsubsection{Drawer}

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
coleitraPage {
    title: "Vocable training"
    coleitraGridLayout {
    }
    footer: coleitraGridLayout {
    }
}
@}

\section{About}
@o ../src/about.qml
@{
coleitraPage {
    title: "About coleitra"
    coleitraGridLayout {
    }
    footer: coleitraGridLayout {
    }
}
@}

\section{Reusable GUI elements}
\subsection{Page}

@o ../src/coleitraPage.qml
@{
import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.3
import VocTrainLib 1.0
import SettingsStorageLib 1.0

Page {
}
@}

\subsection{Grid Layout}

@o ../src/coleitraGridLayout.qml
@{
GridLayout {
    id: body
    visible: true
    anchors.fill: parent
    columns: 12
    columnSpacing: 0
    rowSpacing: 0
    flow: GridLayout.LeftToRight
}
@}

