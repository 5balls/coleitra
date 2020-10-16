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

\section{About}
@o ../src/about.qml
@{
import QtQuick 2.11
import SettingsStorageLib 1.0

ColeitraPage {
    title: "About coleitra"
    SettingsStorage {
        id: settingsstorage
    }
    ColeitraGridLayout {
        @<Coleitra label @'"GIT commit:"@' with value @'settingsstorage.gitVersion@'@>
        @<Coleitra label @'"Clean repository?"@' with value @'settingsstorage.gitClean@'@>
        @<Coleitra label @'"Last commit message:"@' with value @'settingsstorage.gitLastCommitMessage@'@>
        @<Coleitra label @'"Qt version"@' with value @'settingsstorage.qtVersion@'@>
    }
    footer: ColeitraGridLayout {
    }
}
@}

