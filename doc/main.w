\section{Main}

\codecpp
@o ../src/main.h
@{
#ifndef MAIN_H
#define MAIN_H

#include <QApplication>
#include <QQmlApplicationEngine>

#endif // MAIN_H
@}

\codecpp
@o ../src/main.cpp
@{
#include "main.h"

int main(int argc, char *argv[])
{
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
