\section{Database}
\subsection{Table}
databaseTable abstracts away any database table access.
\codecpp
@o ../src/databasetable.h -d
@{
#ifndef DATABASETABLE_H
#define DATABASETABLE_H
#include <QObject>
class databaseTable : public QObject
{
    Q_OBJECT

private:
    enum databaseFieldType {
        integer,
        double,
        string
    };
    Q_ENUM(databaseFieldType)

    struct databaseField {
        QString name;
        databaseFieldType type;
    };
public:
};
#endif // DATABASETABLE_H
@}

