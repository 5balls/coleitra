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

\section{cmake}
\codecmake
@o ../src/CMakeLists.txt
@{
cmake_minimum_required(VERSION 3.7.0)

if(ANDROID)
    set(ANDROID_PLATFORM "20")
endif()

include(CMakePrintHelpers)

project(coleitra)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)
@}

This bash scripts gather some information about the git repository and then we make them available to the program via preprocessor definitions:

@o ../src/CMakeLists.txt
@{
execute_process(
    COMMAND bash "-c" "git --git-dir ${CMAKE_CURRENT_LIST_DIR}/../.git --work-tree ${CMAKE_CURRENT_LIST_DIR}/.. describe --always --tags | tr -d '\n'"
    OUTPUT_VARIABLE GIT_VERSION
)


execute_process(
    COMMAND bash "-c" "if cleanstring=$(git --git-dir ${CMAKE_CURRENT_LIST_DIR}/../.git --work-tree ${CMAKE_CURRENT_LIST_DIR}/.. status --untracked-files=no --porcelain) && [ -z \"$cleanstring\" ]; then echo 'yes'; else echo 'no'; fi | tr -d '\n'"
    OUTPUT_VARIABLE GIT_CLEAN
)

execute_process(
    COMMAND bash "-c" "git log -1 --pretty=%B | tr -d '\n'"
    OUTPUT_VARIABLE GIT_LAST_COMMIT_MESSAGE
)

cmake_print_variables(GIT_VERSION)
cmake_print_variables(GIT_CLEAN)
cmake_print_variables(GIT_LAST_COMMIT_MESSAGE)

add_definitions(
    -DGIT_VERSION=${GIT_VERSION}
    -DGIT_CLEAN=${GIT_CLEAN}
    -DGIT_LAST_COMMIT_MESSAGE=${GIT_LAST_COMMIT_MESSAGE}
)
@}


We need to define all needed Qt5 components here:

@o ../src/CMakeLists.txt
@{
find_package(Qt5 COMPONENTS Quick QuickControls2 QuickWidgets Sql Svg Qml Widgets REQUIRED)
set(QT_LIBS Qt5::Quick Qt5::QuickControls2 Qt5::QuickWidgets Qt5::Sql Qt5::Svg Qt5::Qml Qt5::Widgets)

include_directories(${Qt5Widgets_INCLUDE_DIRS} ${QtQml_INCLUDE_DIRS})
add_definitions(${Qt5Widgets_DEFINITIONS} ${QtQml_DEFINITIONS} ${${Qt5Quick_DEFINITIONS}})
@}

A slightly different command is needed if we compile for android as the program entry point is a java function and not our C++ main function:

@o ../src/CMakeLists.txt
@{
if(ANDROID)
    add_library(coleitra SHARED
    @<C++ files@>
    @<Ressource files@>
    )
else()
    add_executable(coleitra
    @<C++ files@>
    @<Ressource files@>
    )
endif()

target_link_libraries(coleitra PUBLIC ${QT_LIBS})
@}

In this step we finally can produce the APK file. For a new release we should probably increase the VERSION\_CODE.

@o ../src/CMakeLists.txt
@{
if(ANDROID)
    include(${CMAKE_CURRENT_LIST_DIR}/qt-android-cmake/AddQtAndroidApk.cmake)
    add_qt_android_apk(coleitra.apk coleitra
        NAME "coleitra"
        VERSION_CODE 1
        PACKAGE_NAME "org.coleitra.coleitra"
        INSTALL
    )
endif()
@}
