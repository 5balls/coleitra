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

\chapter{Unit tests}

The unit tests are for development purposes and don't need to be compiled by any user of the software. These tests may also be not as portable as coleitra itself, this tests may only compile on linux.

\section{settings class}

@o ../src/unittests/settings/main.cpp -d
@{
#include <mocxx/Mocxx.hpp>
#include <QCoreApplication>
#include "qdebug.h"
#include "settings.h"

using namespace mocxx;

int main(int argc, char *argv[])
{

Mocxx moc;

settings settings_test;

moc.ReplaceMember([](const settings* foo) -> int { return 42; }, &settings::nativelanguage);

qDebug() << settings_test.nativelanguage();
qDebug() << settings_test.nativelanguage();

}
@}

@o ../src/unittests/settings/CMakeLists.txt
@{
@<Requirements in path @'/../..@' for CMakeLists.txt@>
    add_executable(settings
    main.cpp
    @<C++ files without main in path @'../../@'@>
    )

include(Mocxx)

target_link_libraries(settings PUBLIC ${QT_LIBS} ${LIBS} Mocxx)
@}
