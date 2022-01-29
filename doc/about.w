% Copyright 2020, 2021, 2022 Florian Pesth
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

\chapter{About}
\codecpp
@o ../src/about.h -d
@{
@<Start of @'ABOUT@' header@>
#include <QObject>
#include <QSettings>
#include <QDebug>
#include <QtGlobal>

#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)
@<Start of class @'about@'@>
    @<Git properties@>
    @<Compile environment@>
public:
    explicit about(QObject *parent = nullptr);
    @<Git properties read implementation@>
    @<Compile environment read implementation@>
private:
    QSettings s_about;
@<End of class and header@>
@}

\codecpp
@o ../src/about.cpp
@{
#include "about.h"

about::about(QObject *parent) : QObject(parent)
{

}
@}

\subsection{Git properties}
@d Git properties
@{
@<Qt readonly property @'gitVersion@' @>
@<Qt readonly property @'gitClean@' @>
@<Qt readonly property @'gitLastCommitMessage@' @>
@<Qt readonly property @'coleitraVersion@' @>
@}

\codecpp
@d Git properties read implementation
@{
@<Function @'gitVersion@' return string @'TOSTRING(GIT_VERSION)@' @>
@<Function @'gitClean@' return string @'TOSTRING(GIT_CLEAN)@' @>
@<Function @'gitLastCommitMessage@' return string @'TOSTRING(GIT_LAST_COMMIT_MESSAGE)@' @>
@<Function @'coleitraVersion@' return string @'TOSTRING(COLEITRA_VERSION)@' @>
@}

\subsection{Compile environment}
@d Compile environment
@{
@<Qt readonly property @'qtVersion@' @>
@}

@d Compile environment read implementation
@{
@<Function @'qtVersion@' return string @'QT_VERSION_STR@' @>
@}

