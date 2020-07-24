\section{Qt environment}
Here are the files described, which are needed for compiling code for the Qt framework.

\subsection{Project file}
\codeqtproject
@o ../src/coleitra.pro
@{
QT += quick
QT += sql
QT += texttospeech
QT += qml
QT += widgets
QT += core

VERSION = 0.0.1

CONFIG += c++11

DEFINES += GIT_VERSION=$$system(git --git-dir $$PWD/.git --work-tree $$PWD describe --always --tags)
CLEANGIT = $$quote(if cleanstring=$(git status --untracked-files=no --porcelain) && [ -z "$cleanstring" ]; then echo "yes"; else echo "no"; fi;)
DEFINES += GIT_CLEAN=$$system($$CLEANGIT)
DEFINES += GIT_LAST_COMMIT_MESSAGE='"\\\"$(shell git --git-dir $$_PRO_FILE_PWD_/.git --work-tree $$_PRO_FILE_PWD_ log -1 --pretty=format:%s)\\\""'


DEFINES += QT_DEPRECATED_WARNINGS

SOURCES += \
        main.cpp \

RESOURCES += qml.qrc

HEADERS += \
    main.h

DISTFILES += \
    android/AndroidManifest.xml \
    android/LICENSE-GRADLEW.txt \
    android/Makefile

SUBDIRS += \
    android/gradle.pro \
    android/templates.pro

CONFIG += qtquickcompiler

ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
@}

\subsection{Ressources}
\codeqrc
@o ../src/qml.qrc
@{
<RCC>
    <qresource prefix="/">
        <file>main.qml</file>
        <file>settings.svg</file>
        <file>back.svg</file>
        <file>about.qml</file>
        <file>train.qml</file>
        <file>coleitraGridLayout.qml</file>
        <file>coleitraPage.qml</file>
    </qresource>
</RCC>
@}
