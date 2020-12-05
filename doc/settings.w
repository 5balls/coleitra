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

\chapter{Settings}

@d Setting @'name@' in @'category@' type @'typename@' typeconversion @'typeconversion@' default @'defaultvalue@'
@{
public:
    Q_PROPERTY(int @1 READ @1 WRITE set@1 NOTIFY @1changed);
    @3 @1() const{
        return s_settings.value("@2/@1", 12).@4();
    }
    void set@1(@3 @1){
        if(s_settings.value("@2/@1").@4() != @1){
            s_settings.setValue("@2/@1", @1);
            emit @1changed(@1);
        }
    }
signals:
    void @1changed(@3);
@}



\codecpp
@o ../src/settings.h -d
@{
@<Start of @'SETTINGS@' header@>
#include <QSettings>

@<Start of class @'settings@'@>
@<Setting @'nativelanguage@' in @'training@' type @'int@' typeconversion @'toInt@' default @'12@' @>
@<Setting @'learninglanguage@' in @'training@' type @'int@' typeconversion @'toInt@' default @'12@' @>
@<Setting @'externalcontrol@' in @'controls@' type @'bool@' typeconversion @'toBool@' default @'true@' @>
@<Setting @'knownkeycodevalue@' in @'controls@' type @'int@' typeconversion @'toInt@' default @'0@' @>
@<Setting @'unknownkeycodevalue@' in @'controls@' type @'int@' typeconversion @'toInt@' default @'0@' @>
@<Setting @'repeatkeycodevalue@' in @'controls@' type @'int@' typeconversion @'toInt@' default @'0@' @>
@<Setting @'ttsoutput@' in @'controls@' type @'bool@' typeconversion @'toBool@' default @'true@' @>
public:
    explicit settings(QObject *parent = nullptr);
private:
    QSettings s_settings;
@<End of class and header@>
@}

\codecpp
@o ../src/settings.cpp -d
@{
#include "settings.h"

settings::settings(QObject *parent) : QObject(parent)
{

}
@}

