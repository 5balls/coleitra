coleitra
========

coleitra is an open source vocable and grammar trainer using spaced repetition algorithms. It's intended usage is on a mobile phone with android operating system but it can be compiled for the desktop as well. This is the source code repository of the program, for mor information about the program itself check the `coleitra webpage <https://coleitra.org>`_.

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

You should follow the instructions of Qt - either on their webpage or in the source tarball, but for personal reference, this are the commands I used last for compiling the libraries for cross compiling for android:

.. code-block:: bash

   ./configure -xplatform android-clang --disable-rpath -nomake tests -nomake examples -android-ndk ~/src/foreign/android-ndk-r21 -android-sdk ~/src/foreign/android-sdk-tools -no-warnings-are-errors --prefix=~/src/foreign/qt5-android-install-20201009
   make
   su
   make install
   exit

cmake
_____

Install the cmake package from your operation system.


Compile documentation and create coleitra source code
.....................................................

Run the following code in your shell (pdflatex needs to be run twice as well as nuweb):

.. code-block:: bash
   
   cd doc
   nuweb coleitra.w
   pdflatex coleitra.tex
   pdflatex coleitra.tex
   nuweb coleitra.w
   cd ..

Compile desktop version of coleitra
...................................

Run the following code in your shell (the command line tools git and tr are expected to be available):

.. code-block:: bash

   cd build/x64
   cmake ../../src
   make

If you have compiled Qt5 at a nonstandard location or in addition to your system libraries (which is not a problem) you have to pass the correct path to the file `Qt5Config.cmake`, for example (don't forget `..` at the end):

.. code-block:: bash

   cd build/x64
   rm -r *
   cmake -DQt5_DIR=~/src/foreign/qt5-shadow-build/qtbase/lib/cmake/Qt5/ ../../src
   make

Compile android version of coleitra
...................................

This requires a local installation of the android ndk and sdk. You can download those seperate from the android studio which you don't need for compiling coleitra.

.. code-block:: bash

   cd build/android
   rm -r *
   export ANDROID_SDK=/home/flo/src/foreign/android-sdk-tools/
   export ANDROID_NDK=/home/flo/src/foreign/android-ndk-r21/
   export JAVA_HOME=/usr/lib/jvm/default-java
   cmake -DANDROID_PLATFORM=21 -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH -DCMAKE_TOOLCHAIN_FILE=~/src/foreign/android-ndk-r21/build/cmake/android.toolchain.cmake -DCMAKE_PREFIX_PATH=~/src/foreign/qt5-android-install-20201010/ ../../src

You might not need to set `CMAKE_PREFIX_PATH` and `CMAKE_FIND_ROOT_PATH_MODE_PACKAGE` if you have installed thq Qt5 libraries for cross compiling for android system wide.

