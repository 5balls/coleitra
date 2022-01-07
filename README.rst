..
   Copyright 2020, 2021, 2022 Florian Pesth

..
   This file is part of coleitra.

..
   coleitra is free software: you can redistribute it and/or modify
   it under the terms of the GNU Affero General Public License as
   published by the Free Software Foundation version 3 of the
   License.

..
   coleitra is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Affero General Public License for more details.

   You should have received a copy of the GNU Affero General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.



coleitra
========

.. attention:: Unfinished software!
   This software is not in a usable state yet. Please wait for the first release!

.. contents::

coleitra is an open source (AGPL-3.0-only) vocable and grammar trainer using spaced repetition algorithms. It's intended usage is on a mobile phone with an android operating system but it can be compiled for the desktop as well. This is the source code repository of the program, for more information about the program itself check the `coleitra webpage <https://coleitra.org>`_.

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
   -openssl-runtime \
   -optimize-size \
   -I ~/src/foreign/openssl-1.1.1i/include \
   -prefix ~/src/foreign/qt5-android-install-20201222
   make
   su
   make install
   exit

Choose the open source license and accept the LGPLv3 offer. It may take quite some time to compile Qt as it is a large library (expect several hours of compile time depending on your setup) to speed up the process you can make use of multiple cores by adding -j4 to the make commnd (in the case of four cores for example). If compiling the desktop version on linux the -xcb switch seems to be needed or at least the required dependencies to be able to add this option, maybe it is automatically compiled when the dependencies are fullfilled.

It might help to pass also the `-ltcg` flag to configure to enable link time optimization and make the resulting binary smaller but I could not make it work yet.

Qt5 Debian package installation
_______________________________


Tested on debian version 11.2 (bullseye); might not be complete:

For compiling:

.. code-block:: bash
   
   apt-get install qtbase5-dev qtdeclarative5-dev libqt5svg5-dev


.. code-block:: bash
   
   apt-get install qml-module-qtquick2 qml-module-qtquick-controls qml-module-qtquick-controls2


Android SDK and NDK
___________________

You don't need Android Studio to compile coleitra. Download just the commandlinetools package (it is usually a bit hidden on googles webpage, you might need to scroll down quite  bit), at the time of this writing the file was called `commandlinetools-linux-6858069_latest.zip` located at `this place <https://developer.android.com/studio#command-tools>`_ but that may change.

.. code-block:: bash
   
   mkdir ~/src/foreign/android-sdk
   mkdir ~/src/foreign/android-sdk/cmdline-tools
   unzip commandlinetools-linux-6858069_latest.zip
   mv cmdline-tools ~/src/foreign/android-sdk/cmdline-tools/tools
   export PATH=$PATH:~/src/foreign/android-sdk/cmdline-tools/tools/bin
   export ANDROID_SDK_ROOT=~/src/foreign/android-sdk
   sdkmanager ndk-bundle
   sdkmanager "platform-tools" "platforms;android-28"

You have to agree to googles license agreement to continue. Directory structure seems to have changed, but this seems to work for the current version.

OpenSSL
_______

Qt5 needs to be configured with OpenSSL which is needed for https requests. Download the last stable version from `the OpenSSL webpage <https://www.openssl.org/source/>`_, at the time of this writing this is version 1.1.1.. Follow the instructions to compile it for android, in my case this is written in

.. code-block:: bash


   export ANDROID_NDK_HOME=~/src/foreign/android-sdk/ndk-bundle
   export PATH=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK_HOME/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin:$PATH
   cd openssl-1.1.1h
   ./Configure android-arm -D__ANDROID_API__=21
   make SHLIB_VERSION_NUMBER= SHLIB_EXT=_1_1.so build_libs

The extension of the libraries needs to be changed from standard naming because android does not seem to like libraries which don't end on .so, so libssl.so.1.1 is not working while libssl_1_1.so is. `make install` will not work with this extension but this is fine we don't need it.

cmake
_____

Install the cmake package from your operating system.

LAPACK
______

Install a lapack library package from your operating system, on debian one possible package is named liblapack-dev.

f2c
___

Install the f2c package from your operating system, on debian the package name is "f2c". (This might not be necessary. It may be needed by the original LAPACK version which was written in fortran.)

nlohmann JSON
_____________

Install json parsing library from Niels Lohmann per source from https://github.com/nlohmann/json or as package your the distribution (Debian package is available).

JSON schema validator
_____________________

Install the JSON schema validator library from Patrick Boettcher per source from https://github.com/pboettch/json-schema-validator or via package manager (I think there is no debian package yet) and install it somewhere where cmake can find it.

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

If you have compiled Qt5 at a nonstandard location or in addition to your system libraries (which is not a problem) you have to pass the correct path cmake, using `CMAKE_PREFIX_PATH`, for example:

.. code-block:: bash

   cd build/x64
   rm -r *
   export CMAKE_PREFIX_PATH=/home/flo/src/foreign/qt5-install-20201127
   cmake ../../src
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
   -DCMAKE_PREFIX_PATH=~/src/foreign/qt5-android-install-20201222/ \
   ../../src
   cp ~/src/foreign/qt5-android-install-20201222/jar/QtAndroidNetwork.jar coleitra-armeabi-v7a/libs
   make

That the jar file is not copied seems to be a bug in recent Qt versions, there is probably a more elegant way to do this. You might not need to set `CMAKE_PREFIX_PATH` and `CMAKE_FIND_ROOT_PATH_MODE_PACKAGE` if you have installed the Qt5 libraries for cross compiling for android system wide. Also this might download quite some android stuff on the first run. Subsequent runs should be faster.

