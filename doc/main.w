% Copyright 2020 Florian Pesth
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

\codecpp
@o ../src/main.h -d
@{
@<Start of @'MAIN@' header@>
#include <QtGlobal>

#if (QT_VERSION >= QT_VERSION_CHECK(5, 12, 0))
    #pragma message "Compiling for Qt version " QT_VERSION_STR 
#else
    #pragma message "Tried to compiling for to old Qt version " QT_VERSION_STR 
    #error "Version of Qt5 >= 5.12.0 is required"
#endif


#include <QApplication>
#include <QQmlApplicationEngine>
#include <QSslSocket>
#include "about.h"
#include "settings.h"
#include "database.h"
#include "edit.h"
#include "train.h"
#include "grammarprovider.h"


#ifdef Q_OS_ANDROID
#include <android/log.h>
#endif
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

#ifdef Q_OS_ANDROID
    void androidAdbLogcatMessageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg){
        const char* const applicationName = "coleitra";
        const char* const local=msg.toLocal8Bit().constData();
        switch (type) {
            case QtDebugMsg:
                __android_log_write(ANDROID_LOG_DEBUG,applicationName,local);
                break;
            case QtInfoMsg:
                __android_log_write(ANDROID_LOG_INFO,applicationName,local);
                break;
            case QtWarningMsg:
                __android_log_write(ANDROID_LOG_WARN,applicationName,local);
                break;
            case QtCriticalMsg:
                __android_log_write(ANDROID_LOG_ERROR,applicationName,local);
                break;
            case QtFatalMsg:
            default:
                __android_log_write(ANDROID_LOG_FATAL,applicationName,local);
                abort();    
        }
    }
#endif

int main(int argc, char *argv[])
{
#ifdef Q_OS_ANDROID
    qInstallMessageHandler(androidAdbLogcatMessageHandler);
    qputenv("ANDROID_OPENSSL_SUFFIX", "_1_1");
#endif
    @<Register singleton @'Settings@' class @'settings@' version @'1@' @'0@' @>
    @<Register singleton @'About@' class @'about@' version @'1@' @'0@' @>
    @<Register singleton @'Database@' class @'database@' version @'1@' @'0@' @>
    @<Register singleton @'Edit@' class @'edit@' version @'1@' @'0@' @>
    @<Register singleton @'GrammarProvider@' class @'grammarprovider@' version @'1@' @'0@' @>

    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setApplicationName("coleitra");
    QCoreApplication::setOrganizationName("coleitra");
    QCoreApplication::setOrganizationDomain("https://icoleitra.org");
    //qputenv("QT_ANDROID_VOLUME_KEYS", "1");

    QApplication app(argc, argv);
    qDebug() << "Device supports OpenSSL: " << QSslSocket::supportsSsl();

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
