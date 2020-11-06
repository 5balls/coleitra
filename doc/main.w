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

\section{Main}

\codecpp
@o ../src/main.h -d
@{
@<Start of @'MAIN@' header@>
#include <QApplication>
#include <QQmlApplicationEngine>
#include "about.h"
#include "settings.h"
#include "database.h"
#include "edit.h"
#include "train.h"
#include "grammarprovider.h"
@<End of header@>
@}

@d Register singleton @'qmlobjectname@' class @'classname@' version @'major@' @'minor@'
@{
qmlRegisterSingletonType<@2>("@1Lib", @3, @4, "@1", [](
            QQmlEngine *engine,
            QJSEngine *scriptEngine) -> QObject * {
        Q_UNUSED(scriptEngine);
        @2 *@2_singleton_instance = new @2(engine);
        return @2_singleton_instance;
        });
@}


\codecpp
@o ../src/main.cpp -d
@{
#include "main.h"

int main(int argc, char *argv[])
{
    @<Register singleton @'Settings@' class @'settings@' version @'1@' @'0@' @>
    @<Register singleton @'About@' class @'about@' version @'1@' @'0@' @>
    @<Register singleton @'Database@' class @'database@' version @'1@' @'0@' @>
    @<Register singleton @'Edit@' class @'edit@' version @'1@' @'0@' @>
    @<Register singleton @'GrammarProvider@' class @'grammarprovider@' version @'1@' @'0@' @>

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setApplicationName("coleitra");
    QCoreApplication::setOrganizationName("coleitra");
    QCoreApplication::setOrganizationDomain("https://pesth.org");
    //qputenv("QT_ANDROID_VOLUME_KEYS", "1");
    QApplication app(argc, argv);

    QQmlApplicationEngine engine;

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
@}
