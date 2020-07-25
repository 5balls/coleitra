\section{Settings}

\codecpp
@o ../src/settings.h
@{
#ifndef SETTINGS_H
#define SETTINGS_H

#include <QObject>
#include <QSettings>
#include <QDebug>

#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)

class settings : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString gitVersion READ gitVersion CONSTANT)
    Q_PROPERTY(QString gitClean READ gitClean CONSTANT)
    Q_PROPERTY(QString gitLastCommitMessage READ gitLastCommitMessage CONSTANT)

public:
    explicit settings(QObject *parent = nullptr);
    QString gitVersion()
    {
        return QString(TOSTRING(GIT_VERSION));
    }
    QString gitClean()
    {
        return QString(TOSTRING(GIT_CLEAN));
    }
    QString gitLastCommitMessage()
    {
        return QString(TOSTRING(GIT_LAST_COMMIT_MESSAGE));
    }

private:
    QSettings s_settings;

};


#endif
@}

\codecpp
@o ../src/settings.cpp
@{
#include "settings.h"

settings::settings(QObject *parent) : QObject(parent)
{

}
@}
