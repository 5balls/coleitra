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

\chapter{Training}
\section{Interface}
@o ../src/train.h -d
@{
@<Start of @'TRAIN@' header@>
#include <QDebug>
#include "levmar.h"
#include "math.h"
@<Start of class @'train@'@>
public:
    explicit train(QObject *parent = nullptr);
    struct datum{
        long int time;
        bool known;
        long int dt_best;
        long int dt_worst;
    };
    void estimate_forgetting_curve(QList<train::datum>& timestamps, long int& dt_worst, long int prev_timestamp);
private:

@<End of class and header @>
@}

\section{Implementation}

@O ../src/train.cpp -d
@{
#include "train.h"

train::train(QObject *parent) : QObject(parent)
{
}

/* model to be fitted to measurements: x_i = p[0]*exp(-p[1]*i) + p[2], i=0...n-1 */
void polynomial(double *p, double *x, int m, int n, void *data)
{
  int i;

  for(i=0; i<n; ++i){
    x[i]=p[0]*pow((double)i,p[1]) + p[2];
  }
}

/* Jacobian of expfunc() */
void jacobianpolynomial(double *p, double *jac, int m, int n, void *data)
{   
  int i, j;
  
  /* fill Jacobian row by row */
  for(i=j=0; i<n; ++i){
    jac[j++]=pow((double)i,p[1]);
    jac[j++]=p[0]*pow((double)i,p[1])*log((double)i);
    jac[j++]=1.0;
  }
}


/* 
   Assume this is already split up so that known is false for the
   last element and true for all other elements. 
 */
void train::estimate_forgetting_curve(QList<train::datum>& timestamps, long int& dt_worst, long int prev_timestamp){
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
    double* fit_values = (double*)calloc(timestamps.size(),sizeof(double));
    long int previous_timestamp = prev_timestamp;
    int fit_index = 0;
    foreach(const datum& timestamp, timestamps){
        if(previous_timestamp != 0){
            double fit_value = (double)(timestamp.dt_best+timestamp.dt_worst)/2.0;
            fit_value /= (double)(timestamp.time - previous_timestamp);
            *(fit_values + fit_index) = fit_value;
            fit_index++;
        }
        previous_timestamp = timestamp.time;
    }
    double p[3] = {1.0,1.0,*fit_values};
    double opts[LM_OPTS_SZ], info[LM_INFO_SZ];
    int ret = dlevmar_der(polynomial, jacobianpolynomial, p, fit_values, 3, fit_index, 1000, opts, info, NULL, NULL, NULL); // with analytic Jacobian

    qDebug() << "Levenberg-Marquardt returned in" << info[5] << "iter, reason" << info[6] << ", sumsq" << info[1] << " [" << info[0] << "]\n";
    qDebug() << "Best fit parameters:" << p[0] << p[1] << p[2];
    free(fit_values);
    //dlevmar_der();
}

@}
