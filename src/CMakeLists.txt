cmake_minimum_required(VERSION 3.7.0)


if(ANDROID)
    set(ANDROID_PLATFORM "20")
endif()

include(CMakePrintHelpers)

project(coleitra)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

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


find_package(Qt5 COMPONENTS Quick QuickControls2 QuickWidgets Sql Svg Qml Widgets REQUIRED)
set(QT_LIBS Qt5::Quick Qt5::QuickControls2 Qt5::QuickWidgets Qt5::Sql Qt5::Svg Qt5::Qml Qt5::Widgets)


include_directories(${Qt5Widgets_INCLUDE_DIRS} ${QtQml_INCLUDE_DIRS})
add_definitions(${Qt5Widgets_DEFINITIONS} ${QtQml_DEFINITIONS} ${${Qt5Quick_DEFINITIONS}})

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

target_link_libraries(coleitra PUBLIC ${QT_LIBS})

if(ANDROID)
    include(${CMAKE_CURRENT_LIST_DIR}/qt-android-cmake/AddQtAndroidApk.cmake)
    add_qt_android_apk(coleitra.apk coleitra
        NAME "coleitra"
        VERSION_CODE 1
        PACKAGE_NAME "org.coleitra.coleitra"
        INSTALL
    )
endif()
