% Copyright 2020, 2021 Florian Pesth
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

\chapter{Levenshtein distance}
\section{Interface}

@o ../src/levenshteindistance.h -d
@{
@<Start of @'LEVENSHTEINDISTANCE@' header@>
#include <limits>
#include <QString>
#include <QDebug>
#include <QElapsedTimer>

@<Start of class @'levenshteindistance@'@>
public:
    explicit levenshteindistance(QObject *parent = nullptr);
    struct compoundpart {
        int division;
        int id;
        bool capitalized;
        QString string;
    };
public slots:
    Q_INVOKABLE double distance(const QString& string1, const QString& string2);
    Q_INVOKABLE QList<compoundpart> stringdivision(QList<QList<QPair<QString,int> > > compoundformpart_candidates, QString compoundform, QList<int> divisions = {});
private:
signals:
@<End of class and header @>
@}

\section{Implementation}

@o ../src/levenshteindistance.cpp -d
@{
#include "levenshteindistance.h"

levenshteindistance::levenshteindistance(QObject *parent) : QObject(parent)
{
    // Testing compoundpart finder:
    /*QList<QPair<QString,int> > dampfforms = {{"Dampf",2},{"Dämpfe",3},{"Dampfes",4},{"Dampfs",5},{"Dämpfe",6},{"Dampf",7},{"Dampfe",8},{"Dämpfen",9},{"Dampf",10},{"Dämpfe",11}};
   
    QList<QPair<QString,int> > schifffahrtforms = {{"Schifffahrt",12},{"Schifffahrten",13},{"Schifffahrt",14},{"Schifffahrten",15},{"Schifffahrt",16},{"Schifffahrten",17},{"Schifffahrt",18},{"Schifffahrten",19}};

    QList<QList<QPair<QString,int> > > compoundformpart_candidates = {{{"Donau",1}},dampfforms,schifffahrtforms,{{"Gesellschaft",20},{"Gesellschaften",21},{"Gesellschaft",22},{"Gesellschaften",23},{"Gesellschaft",24},{"Gesellschaften",25},{"Gesellschaft",26},{"Gesellschaften",27}},{{"Kapitän",28},{"Kapitäne",29},{"Kapitänes",30},{"Kapitäns",31},{"Kapitäne",32},{"Kapitän",33},{"Kapitäne",34},{"Kapitänen",35},{"Kapitän",36},{"Kapitäne",37}}};

    QString testcompound = "Donaudampfschifffahrtsgesellschaftskapitän";

    QElapsedTimer timer;
    timer.start();
    QList<compoundpart> results = stringdivision(compoundformpart_candidates, testcompound);
    qDebug() << "The slow operation took" << timer.elapsed() << "milliseconds";


    qDebug() << "Results for" << testcompound;
    foreach(const compoundpart& result, results){
        qDebug() << result.division << result.id << result.capitalized << result.string;
    }
     */
}


double levenshteindistance::distance(const QString& string1, const QString& string2){
    int m = string1.size();
    int n = string2.size();
    double dist[m+1][n+1];
    for(int i=1; i<=m; i++)
        dist[i][0] = i;
    for(int j=1; j<=n; j++)
        dist[0][j] = j;
    for(int j=1; j<=n; j++){
        for(int i=1; i<=m; i++){
            int substitution_cost;
            if(string1.at(i-1) == string2.at(j-1))
                substitution_cost = 0;
            else
                substitution_cost = 1;
            if(dist[i-1][j] + 1 < dist[i][j-1] + 1)
                dist[i][j] = dist[i-1][j] + 1;
            else
                dist[i][j] = dist[i][j-1] + 1;
            if(dist[i-1][j-1] + substitution_cost < dist[i][j])
                dist[i][j] = dist[i-1][j-1] + substitution_cost;
        }
    }
    return dist[m][n];
}

QList<levenshteindistance::compoundpart> levenshteindistance::stringdivision(QList<QList<QPair<QString,int> > > compoundformpart_candidates, QString compoundform, QList<int> divisions){
    int ndiv = compoundformpart_candidates.size();
    int stringsize = compoundform.size();
    int current_ndiv = divisions.size()+1;
    int remaining_ndiv = ndiv - current_ndiv;
    //qDebug() << "ndiv" << ndiv << "stringsize" << stringsize << "current_ndiv" << current_ndiv << "remaining_ndiv" << remaining_ndiv;
    static int levenshteindistance_min = std::numeric_limits<int>::max();
    static QList<levenshteindistance::compoundpart> currently_best_result;
    if(current_ndiv==1){
        levenshteindistance_min = std::numeric_limits<int>::max();
        currently_best_result.clear();
    }
    if(remaining_ndiv <= 0){
        /* We have decided how to divide the string for this test, so
           let's calculate the minimal sum of the levenshtein distances
           for this division: */ 
        QList<levenshteindistance::compoundpart> current_testdivision;
        int part=0;
        double levstd_sum=0;
        QList<QPair<QString,int> > compoundform_candidate;
        foreach(compoundform_candidate, compoundformpart_candidates){
            QString divisionstring;
            if(part==0)
                divisionstring = compoundform.left(divisions.at(0)+1);
            else if(part<current_ndiv-1)
                divisionstring = compoundform.mid(divisions.at(part-1)+1,divisions.at(part)-divisions.at(part-1));
            else
                divisionstring = compoundform.right(compoundform.size()-divisions.at(part-1)-1);
            //qDebug() << "divisionstring" << divisionstring;
            int min_levstd_form = std::numeric_limits<int>::max();
            int min_id = 0;
            QPair<QString,int> compoundform_form;
            foreach(compoundform_form, compoundform_candidate){
                /* TODO toLower might not be the right function choice
                   here as it might not lead to the desired result
                   for most locales. However this will only lead to
                   a bit more storage so it is probably fine for now. */
                double levstd_form = distance(divisionstring.toLower(), compoundform_form.first.toLower());
                //qDebug() << divisionstring.toLower() << compoundform_form.second << compoundform_form.first.toLower() << levstd_form;
                if(levstd_form < min_levstd_form){
                    min_levstd_form = levstd_form;
                    min_id = compoundform_form.second;
                }
            }
            //qDebug() << "Best match" << min_id;
            int divisionsatpart = 0;
            if(part<current_ndiv-1)
                divisionsatpart = divisions.at(part);
            else
                divisionsatpart = stringsize - 1;
            if(part<current_ndiv)
                if(min_levstd_form==0)
                    current_testdivision.push_back({divisionsatpart, min_id, divisionstring.at(0).isUpper(), ""});
                else
                    current_testdivision.push_back({divisionsatpart, min_id, divisionstring.at(0).isUpper(), divisionstring});
            levstd_sum += min_levstd_form;
            part++;
        }
        //qDebug() << "Levenshtein distance sum" << levstd_sum;
        if(levstd_sum < levenshteindistance_min){
            //qDebug() << "New minimum!";
            currently_best_result = current_testdivision;
            levenshteindistance_min = levstd_sum;
        }
        return currently_best_result;
    }
    int lastdivision;
    if(!divisions.isEmpty())
        lastdivision = divisions.last();
    else
        lastdivision = -1;
    for(int div = stringsize - remaining_ndiv - 1; div > lastdivision; div--){
        QList<int> newdivisions = divisions;
        newdivisions.push_back(div);
        stringdivision(compoundformpart_candidates, compoundform, newdivisions);
    }
    return currently_best_result;
}
@}
