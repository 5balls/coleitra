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

\section{About}
@o ../src/about.qml
@{
import QtQuick 2.11
import AboutLib 1.0
import DatabaseLib 1.0

ColeitraPage {
    title: "About coleitra"
    ColeitraGridLayout {
        @<Coleitra label @'"GIT commit:"@' with value @'About.gitVersion@'@>
        @<Coleitra label @'"Clean repository?"@' with value @'About.gitClean@'@>
        @<Coleitra label @'"Last commit message:"@' with value @'About.gitLastCommitMessage@'@>
        @<Coleitra label @'"Qt version"@' with value @'About.qtVersion@'@>
        @<Coleitra label @'"DB version"@' with value @'Database.version@'@>
    }
    footer: ColeitraGridLayout {
    }
}
@}

