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

\chapter{Main}

\codecpp
@o ../src/main.h
@{
#ifndef MAIN_H
#define MAIN_H

#include <QApplication>
#include <QQmlApplicationEngine>

#include "settings.h"

#endif // MAIN_H
@}

\codecpp
@o ../src/main.cpp
@{
#include "main.h"

int main(int argc, char *argv[])
{
    qmlRegisterType<settings>("SettingsStorageLib", 1, 0, "SettingsStorage");

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
