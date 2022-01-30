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

\section{Splash screen}
We prepare certain things for the app before we show the regular screen. To inform the user, we show a splash screen with variations of the logo, which tell the user what is going on.

@O ../src/splash.qml
@{
import QtQuick.Controls 2.14
import QtQuick 2.15
import StartupSequenceLib 1.0

ColeitraPage {
    title: "coleitra startup"
    Image {
        id: splashImage
        anchors.centerIn: parent
        source: "splash_start.png"
        fillMode: Image.Pad
                Connections {
            target: StartupSequence
            function onDatabaseReady(){
                splashImage.source = "splash_grammar.png";
                StartupSequence.prepareGrammarprovider();
            }
            function onGrammarproviderReady(){
                splashImage.source = "splash_done.png";
                parent.push("train.qml");
                toolBar.visible = true;
            }
        }
    }
    Component.onCompleted: {
        splashImage.source = "splash_database.png";
        StartupSequence.prepareDatabase();
    }
}
@}
