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

\section{cmake}
\codecmake
@d Standard definitions for CMakeLists.txt
@{
cmake_minimum_required(VERSION 3.7.0)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
message(STATUS "${CMAKE_CURRENT_SOURCE_DIR}")

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

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

@d Scripts for git in CMakeLists.txt
@{
@<Scripts for git in path @'@' in CMakeLists.txt@>
@}

@d Scripts for git in path @'path@' in CMakeLists.txt
@{
execute_process(
    COMMAND bash "-c" "git --git-dir ${CMAKE_CURRENT_LIST_DIR}@1/../.git --work-tree ${CMAKE_CURRENT_LIST_DIR}/.. describe --always --tags | tr -d '\n'"
    OUTPUT_VARIABLE GIT_VERSION
)


execute_process(
    COMMAND bash "-c" "if cleanstring=$(git --git-dir ${CMAKE_CURRENT_LIST_DIR}@1/../.git --work-tree ${CMAKE_CURRENT_LIST_DIR}/.. status --untracked-files=no --porcelain) && [ -z \"$cleanstring\" ]; then echo 'yes'; else echo 'no'; fi | tr -d '\n'"
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

@d Packages and libraries for Qt5 and levmar in CMakeLists.txt
@{
@<Packages and libraries for Qt5 and levmar in path @'@' in CMakeLists.txt@>
@}

@d Packages and libraries for Qt5 and levmar in path @'path@' in CMakeLists.txt
@{
find_package(Qt5 COMPONENTS Quick QuickControls2 QuickWidgets Sql Svg Qml Widgets Network REQUIRED)
set(QT_LIBS Qt5::Quick Qt5::QuickControls2 Qt5::QuickWidgets Qt5::Sql Qt5::Svg Qt5::Qml Qt5::Widgets Qt5::Network)

if(ANDROID)
set(ANDROID_EXTRA_LIBS
    /usr/local/lib/libcrypto_1_1.so
    /usr/local/lib/libssl_1_1.so
CACHE INTERNAL "")
set(LIBS ${LIBS} android log)
endif()

set(HAVE_LAPACK 0 CACHE BOOL "Do we have LAPACK/BLAS?")
set(NEED_F2C 0 CACHE BOOL "Do we need either f2c or F77/I77?")
set(HAVE_PLASMA 0 CACHE BOOL "Do we have PLASMA parallel linear algebra library?")
set(LINSOLVERS_RETAIN_MEMORY 1 CACHE BOOL "Should linear solvers retain working memory between calls? (non-reentrant!)")
set(LM_DBL_PREC 1 CACHE BOOL "Build double precision routines?")
set(LM_SNGL_PREC 1 CACHE BOOL "Build single precision routines?")
configure_file(${CMAKE_CURRENT_LIST_DIR}@1/levmar-2.6/levmar.h.in ${CMAKE_CURRENT_LIST_DIR}@1/levmar-2.6/levmar.h)

include_directories(${Qt5Widgets_INCLUDE_DIRS} ${QtQml_INCLUDE_DIRS} ${OPENSSL_INCLUDE_DIR} ${CMAKE_CURRENT_LIST_DIR}@1 ${CMAKE_CURRENT_LIST_DIR}@1/levmar-2.6)
add_definitions(${Qt5Widgets_DEFINITIONS} ${QtQml_DEFINITIONS} ${QtNetwork} ${${Qt5Quick_DEFINITIONS}})
@}

@d Requirements for CMakeLists.txt
@{
@<Standard definitions for CMakeLists.txt@>
@<Scripts for git in CMakeLists.txt@>
@<Packages and libraries for Qt5 and levmar in CMakeLists.txt@>
@}

@d Requirements in path @'path@' for CMakeLists.txt
@{
@<Standard definitions for CMakeLists.txt@>
@<Scripts for git in path @1 in CMakeLists.txt@>
@<Packages and libraries for Qt5 and levmar in path @1 in CMakeLists.txt@>
@}

A slightly different command is needed if we compile for android as the program entry point is a java function and not our C++ main function:

@o ../src/CMakeLists.txt
@{
@<Requirements for CMakeLists.txt@>
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

target_link_libraries(coleitra PUBLIC ${QT_LIBS} ${LIBS})
@}

In this step we finally can produce the APK file. For a new release we should probably increase the VERSION\_CODE.

@o ../src/CMakeLists.txt
@{
if(ANDROID)
    include(${CMAKE_CURRENT_LIST_DIR}/qt-android-cmake/AddQtAndroidApk.cmake)
    add_qt_android_apk(coleitra.apk coleitra
        NAME "coleitra"
        VERSION_CODE 0010
        PACKAGE_NAME "org.coleitra.coleitra"
        DEPENDS
        ${ANDROID_EXTRA_LIBS}
        INSTALL
    )
endif()
@}
