..
   Copyright 2020 Florian Pesth

..
   This file is part of coleitra.

..
   coleitra is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

..
   coleitra is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

..
   You should have received a copy of the GNU General Public License
   along with coleitra.  If not, see <https://www.gnu.org/licenses/>.


coleitra
========

.. attention:: Unfinished software!
   This software is not in a usable state yet. Please wait for the first release!

.. contents::

coleitra is an open source vocable and grammar trainer using spaced repetition algorithms. It's intended usage is on a mobile phone with android operating system but it can be compiled for the desktop as well. This is the source code repository of the program, for more information about the program itself check the `coleitra webpage <https://coleitra.org>`_.

In principle the used toolkit Qt also compiles for iOS but I can't support this operating system right now.

This document is written in the markup language called "reStructuredText". This language is used in the python programming language for documentation, you can use the `Docutils text processing system <https://docutils.sourceforge.io/>`_ to create a nicely formatted version of this document but it should be readable in plain text as it is.

Install
-------

The program is written following the programming paradigm of literate programming introduced by the computer scientist and mathematician Donald Knuth.

Instructions assume you have a linux shell available and are familiar with using it (If not it is easy to learn though - search for `bash tutorial` and there should be plenty available to get you started.). It should be possible to compile this program on other operating systems as well but I currently only use linux so I can't provide any help there.

The documentation, the program source code and some other necessary files are contained in the doc directory in the format for the "nuweb" program and you need the nuweb program to get both documentation and the binary of the program. The nuweb program is not to be confused with the noweb program which is also used for literate programming.

Requirements
............

nuweb
_____

Unfortunately nuweb does not seem to be included in major linux distributions. Download the latest release from the `nuweb webpage <http://nuweb.sourceforge.net/>`_ and follow the instructions in the README file (They probably tell you to run `make nuweb` on your shell to build an executable file called "nuweb").

pdflatex
________

Install some variant of pdflatex from your operating system. You probaby need to install some packages which have names starting with "texlive".

Qt5
___

Install either the development packages for Qt5 (these are usually different from the "regular" library packages) or compile them yourself from source. Unfortunately I can't recommend using the installer from Qt itself as it requires registering with a seperate account and I strongly disagree with this decision of the Qt team to forcefully collect user data.

You should follow the instructions of Qt - either on their webpage or in the source tarball, but for personal reference, this are the commands I used last for compiling the libraries for cross compiling for android (you need the android SDK and NDK for cross compiling the android app, see below):

.. code-block:: bash

   ./configure -xplatform android-clang \
   --disable-rpath \
   -nomake tests -nomake examples \
   -android-ndk ~/src/foreign/android-sdk/ndk-bundle \
   -android-sdk ~/src/foreign/android-sdk \
   -no-warnings-are-errors \
   --prefix=/home/user/src/foreign/qt5-android-install-20201022
   make
   su
   make install
   exit

Choose the open source license and accept the LGPLv3 offer. It may take quite some time to compile Qt as it is a large library (expect several hours of compile time depending on your setup).

Android SDK and NDK
___________________

You don't need Android Studio to compile coleitra. Download just the commandlinetools package (it is usually a bit hidden on googles webpage, you might need to scroll down quite  bit), at the time of this writing the file was called `commandlinetools-linux-6858069_latest.zip` but that may change.

.. code-block:: bash
   
   mkdir ~/src/foreign/android-sdk
   mkdir ~/src/foreign/android-sdk/cmdline-tools
   unzip commandlinetools-linux-6858069_latest.zip
   mv cmdline-tools ~/src/foreign/android-sdk/cmdline-tools/tools
   export PATH=$PATH:~/src/foreign/android-sdk/cmdline-tools/tools/bin
   export ANDROID_SDK_ROOT=~/src/foreign/android-sdk
   sdkmanager ndk-bundle

Directory structure seems to have changed, but this seems to work for the current version.


cmake
_____

Install the cmake package from your operation system.

coleitra
........

Compile documentation and create coleitra source code
_____________________________________________________

Run the following code in your shell (pdflatex needs to be run twice as well as nuweb):

.. code-block:: bash
   
   cd doc
   nuweb -lr coleitra.w
   pdflatex coleitra.tex
   makeindex coleitra.idx
   pdflatex coleitra.tex
   nuweb -lr coleitra.w
   cd ..

Compile desktop version of coleitra
___________________________________

Run the following code in your shell (the command line tools git and tr are expected to be available):

.. code-block:: bash

   cd build/x64
   cmake ../../src
   make

If you have compiled Qt5 at a nonstandard location or in addition to your system libraries (which is not a problem) you have to pass the correct path to the file `Qt5Config.cmake`, for example (don't forget `..` at the end):

.. code-block:: bash

   cd build/x64
   rm -r *
   cmake -DQt5_DIR=~/src/foreign/qt5-shadow-build/qtbase/lib/cmake/Qt5/ \
   ../../src
   make

Compile android version of coleitra
___________________________________

This requires a local installation of the android ndk and sdk. You can download those seperate from the android studio which you don't need for compiling coleitra.

.. code-block:: bash

   cd build/android
   rm -r *
   export ANDROID_SDK=~/src/foreign/android-sdk
   export ANDROID_NDK=~/src/foreign/android-sdk/ndk-bundle
   export JAVA_HOME=/usr/lib/jvm/default-java
   cmake -DANDROID_PLATFORM=21 \
   -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
   -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
   -DCMAKE_PREFIX_PATH=~/src/foreign/qt5-android-install-20201022/ \
   ../../src
   make

You might not need to set `CMAKE_PREFIX_PATH` and `CMAKE_FIND_ROOT_PATH_MODE_PACKAGE` if you have installed thq Qt5 libraries for cross compiling for android system wide. Also this might download quite some android stuff on the first run. Subsequent runs should be faster.

