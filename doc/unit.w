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
#include <QCoreApplication>
#include "settings.h"

int main(int argc, char *argv[])
{


}
@}

@o ../src/unittests/settings/CMakeLists.txt
@{
@<Requirements for CMakeLists.txt@>
    add_executable(settings
    @<C++ files without main@>
    )

include(Mocxx)

target_link_libraries(settings PUBLIC ${QT_LIBS} ${LIBS} Mocxx)
@}
