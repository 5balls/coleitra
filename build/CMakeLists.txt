cmake_minimum_required(VERSION 3.7.0)

include(CMakePrintHelpers)

project(coleitra)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt5 COMPONENTS Quick Sql Qml Widgets Core)

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

if(ANDROID)
    add_library(coleitra SHARED
        ../src/main.cpp
        ../src/settings.cpp
        ../src/qml.qrc
    )
else()
    add_executable(coleitra
        ../src/main.cpp
        ../src/settings.cpp
        ../src/qml.qrc
    )
endif()

target_link_libraries(coleitra 
    PUBLIC
    Qt5::Core
    Qt5::Widgets
    Qt5::Qml
)

if(ANDROID)
    include(${CMAKE_CURRENT_LIST_DIR}/qt-android-cmake/AddQtAndroidApk.cmake)
    add_qt_android_apk(coleitra.apk coleitra)
endif()
