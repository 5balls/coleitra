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

\section{Infrastructure}
\cprotect\subsection{\verb#CMakeLists.txt#}
@o ../src/unittests/CMakeLists.txt
@{
@<Requirements in path @'/..@' for CMakeLists.txt@>
    add_executable(unittests
    main.cpp
    @<C++ files without main in path @'../@'@>
    )

include(Mocxx)
include_directories("../catch2")

target_link_libraries(unittests PUBLIC ${QT_LIBS} ${LIBS} Mocxx)
@}

\cprotect\subsection{\verb#main.cpp#}
@o ../src/unittests/main.cpp -d
@{
#define CATCH_CONFIG_RUNNER
#include "catch.hpp"

#include <mocxx/Mocxx.hpp>
#include <QCoreApplication>
#include "qdebug.h"

using namespace mocxx;

int main(int argc, char* argv[])
{
  QCoreApplication app(argc,argv);
  const int result = Catch::Session().run(argc, argv);
  return result;
}
@}

\section{Test cases}

\subsection{Unittest example}
@o ../src/unittests/main.cpp -d
@{
#include "settings.h"

TEST_CASE("Unittest example","[settings]")
{

  Mocxx moc;
  settings settings_test;

  REQUIRE(settings_test.nativelanguage() == 12);

  moc.ReplaceMember([](const settings* foo) -> int { return 42; }, &settings::nativelanguage);

  REQUIRE(settings_test.nativelanguage() == 42);
}
@}

\subsection{Grammarprovider network functions}
@o ../src/unittests/main.cpp -d
@{
#include <QUrl>
#include <QNetworkAccessManager>
#include <QCoreApplication>
#include "grammarprovider.h"

TEST_CASE("Grammarprovider network functions","[grammarprovider]")
{
  Mocxx moc;
  
  INFO("Register singletons");
  @<Register singleton @'Settings@' class @'settings@' version @'1@' @'0@' @>
  @<Register singleton @'Database@' class @'database@' version @'1@' @'0@' @>
  @<Register singleton @'LevenshteinDistance@' class @'levenshteindistance@' version @'1@' @'0@' @>

  INFO("grammarprovider constructor");
  QQmlEngine qe_test;
  grammarprovider gp_test(&qe_test);

  INFO("sections");
  SECTION("Repeat last network request")
  {
    REQUIRE(gp_test.m_last_request_url == QUrl());
    moc.ReplaceMember([](QNetworkAccessManager* foo, const QNetworkRequest& bar) -> QNetworkReply* { qDebug() << "Hello replacement function"; return nullptr; }, &QNetworkAccessManager::get);
    gp_test.requestNetworkReply("coleitra.org");
    REQUIRE(gp_test.m_last_request_url == QUrl("coleitra.org"));
    moc.Restore(&QNetworkAccessManager::get);
    gp_test.requestNetworkReply("coleitra.org");
  }
}
@}
