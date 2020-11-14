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

\chapter{Training}
\section{Interface}
@o ../src/train.h -d
@{
@<Start of @'TRAIN@' header@>
#include "levmar.h"
@<Start of class @'train@'@>
public:
    explicit train(QObject *parent = nullptr);
    struct datum{
        long int time;
        bool known;
        long int dt_best;
        long int dt_worst;
    };
    void estimate_forgetting_curve(QList<train::datum>& timestamps, long int& dt_worst);
private:

@<End of class and header @>
@}

\section{Implementation}

@o ../src/train.cpp -d
@{
#include "train.h"

train::train(QObject *parent) : QObject(parent)
{
}

/*void levmar_exp(double *p, double *x, int m, int n, void *data)
{
}*/

/* 
   Assume this is already split up so that known is false for the
   last element and true for all other elements. 
 */
void train::estimate_forgetting_curve(QList<train::datum>& timestamps, long int& dt_worst){
    auto dt = [timestamps](int t1_index, int t05_index){
        return timestamps.at(t05_index).time-timestamps.at(t1_index).time;
    };
    int i_max = timestamps.size()-1;
    if(dt(0,i_max-1)>dt_worst)
        dt_worst = dt(0,i_max-1);
    for(int i=0; i<=i_max; i++){
        timestamps[i].dt_worst = dt_worst;
    }
    long int dt_best = dt(i_max-1,i_max);
    for(int i=0; i<=i_max; i++){
        if(dt_best > timestamps.at(i).dt_worst)
            timestamps[i].dt_best = dt_best;
        else 
            timestamps[i].dt_best = timestamps.at(i).dt_worst;
    }
    {
        long int worst_estimate = dt(0,1);
        for(int i=1; i<i_max-1; i++){
            long int current_estimate = dt(i,i+1);
            if(worst_estimate > timestamps.at(i).dt_worst){
                timestamps[i].dt_worst = worst_estimate;
                // Unlikely but possible:
                for(int j=i;j<=i_max;j++){
                    if(worst_estimate > timestamps.at(i).dt_best){
                        timestamps[i].dt_best = worst_estimate;
                    }
                }
            }
            else 
                worst_estimate = timestamps.at(i).dt_worst;
        }
        if(worst_estimate > dt_worst)
            dt_worst = worst_estimate;
    }
    //dlevmar_der();
}

@}
