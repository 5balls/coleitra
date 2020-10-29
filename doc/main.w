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
#include "settings.h"
#include "database.h"
@<End of header@>
@}

\codecpp
@o ../src/main.cpp -d
@{
#include "main.h"

int main(int argc, char *argv[])
{
    qmlRegisterSingletonType<settings>("SettingsStorageLib", 1, 0, "SettingsStorage", [](
                QQmlEngine *engine,
                QJSEngine *scriptEngine) -> QObject * {
            Q_UNUSED(engine);
            Q_UNUSED(scriptEngine);
            settings *settings_singleton_instance = new settings();
            return settings_singleton_instance;
            });
    qmlRegisterSingletonType<database>("DatabaseLib", 1, 0, "Database", [](
                QQmlEngine *engine,
                QJSEngine *scriptEngine) -> QObject * {
            Q_UNUSED(engine);
            Q_UNUSED(scriptEngine);
            database *db_singleton_instance = new database();
            return db_singleton_instance;
            });

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
