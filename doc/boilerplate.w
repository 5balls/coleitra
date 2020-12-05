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

@d Start of db constraint class @'classname@'
@{
class @1
{
public:
    @1() = default;
    ~@1() = default;
    @1(const @1 &) = default;
    @1 &operator=(const @1 &) = default;
@}

@d End of db constraint class @'classname@'
@{
};
Q_DECLARE_METATYPE(@1)
@}

@d Valueless db constraint class @'classname@'
@{
@<Start of db constraint class @1 @>
@<End of db constraint class @1 @>
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

\subsection{GUI}

