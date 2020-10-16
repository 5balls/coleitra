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

\section{Boilerplate fragments}
\subsection{Headerfiles}
\codecpp
@d Start of @'classname@' header
@{
#ifndef @1_H
#define @1_H
#include <QObject>
@}

@d Start of class @'classname@'
@{
class @1 : public QObject
{
    Q_OBJECT
@}

@d End of header
@{
#endif 
@}

@d End of class and header
@{
};
#endif
@}

\subsection{Qt property system}
@d Qt readonly property @'propertyname@'
@{
Q_PROPERTY(QString @1 READ @1 CONSTANT)
@}

@d Function @'functionname@' return string @'string@'
@{
QString @1()
{
    return QString(@2);
}
@}

