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

\section{Settings}
@o ../src/settings.qml
@{
import QtQml 2.14
import QtQuick 2.14
import QtQuick.Controls 2.14
import SettingsLib 1.0
import DatabaseLib 1.0

ColeitraPage {
    title: "Settings"
    property int currentKeypressTarget: 0
    ColeitraGridLayout {
        ColeitraGridLabel {
            text: "Native language"
        }
        ColeitraGridComboBox {
            model: Database.languagenames();
            currentIndex: Database.alphabeticidfromlanguageid(Settings.nativelanguage);
            onCurrentTextChanged: Settings.nativelanguage = Database.idfromlanguagename(currentText);
        }
        ColeitraGridLabel {
            text: "Learning language"
        }
        ColeitraGridComboBox {
            model: Database.languagenames();
            currentIndex: Database.alphabeticidfromlanguageid(Settings.learninglanguage);
            onCurrentTextChanged: Settings.learninglanguage = Database.idfromlanguagename(currentText);
        }
        ColeitraGridCheckBox {
            checked: Settings.externalcontrol
            onCheckedChanged: Settings.externalcontrol = checked
            text: "Enable external control"
        }
        ColeitraGridLabel {
            text: "Known"
        }
        ColeitraGridButton {
            text: "Set Keycode"
            onClicked: {
                currentKeypressTarget = 1;
            }
        }
        ColeitraGridLabel {
            text: "Current Keycode"
        }
        ColeitraGridValueText {
            id: knownkeycodevalue
            text: Settings.knownkeycodevalue
        }

        ColeitraGridLabel {
            text: "Unknown"
        }
        ColeitraGridButton {
            text: "Set Keycode"
            onClicked: {
                currentKeypressTarget = 2;
            }
        }
        ColeitraGridLabel {
            text: "Current Keycode"
        }
        ColeitraGridValueText {
            id: unknownkeycodevalue
            text: Settings.unknownkeycodevalue
        }

        ColeitraGridLabel {
            text: "Repeat"
        }
        ColeitraGridButton {
            text: "Set Keycode"
            onClicked: {
                currentKeypressTarget = 3;
            }
        }
        ColeitraGridLabel {
            text: "Current Keycode"
        }
        ColeitraGridValueText {
            id: repeatkeycodevalue
            text: Settings.repeatkeycodevalue
        }


        ColeitraGridCheckBox {
            checked: Settings.ttsoutput
            onCheckedChanged: Settings.ttsoutput = checked
            text: "Enable external control"
        }


    }
    footer: ColeitraGridLayout {
    }
    Keys.onPressed: {
        switch(currentKeypressTarget){
            case 1:
                currentKeypressTarget = 0;
                Settings.knownkeycodevalue = event.key;
                break;
            case 2:
                currentKeypressTarget = 0;
                Settings.unknownkeycodevalue = event.key;
                break;
            case 3:
                currentKeypressTarget = 0;
                Settings.repeatkeycodevalue = event.key;
                break;
            default:
        break;
        }
    }
}
@}

