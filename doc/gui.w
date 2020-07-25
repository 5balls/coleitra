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
}
@}
