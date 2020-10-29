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
@<Start of class @'train@'@>
public:
    explicit train(QObject *parent = nullptr);
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
@}
