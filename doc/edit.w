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

\chapter{Editing}
\section{Interface}
@o ../src/edit.h -d
@{
@<Start of @'EDIT@' header@>
@<Start of class @'edit@'@>
public:
    explicit edit(QObject *parent = nullptr);
private:
@<End of class and header @>
@}

\section{Implementation}

@o ../src/edit.cpp -d
@{
#include "edit.h"

edit::edit(QObject *parent) : QObject(parent)
{
}
@}
