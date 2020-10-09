coleitra
========

coleitra is an open source vocable and grammar trainer using spaced repetition algorithms. It's intended usage is on a mobile phone with android operating system but it can be compiled for the desktop as well. In principle the used toolkit Qt also compiles for iOS but I can't support this operating system right now.

This document is written in the markup language called "reStructuredText". This language is used in the python programming language for documentation, you can use the `Docutils text processing system <https://docutils.sourceforge.io/>`_ to create a nicely formatted version of this document but it should be readable in plain text as it is.

Install
_______

The program is written following the programming paradigm of literate programming introduced by the computer scientist and mathematician Donald Knuth.

Instructions assume you have a linux shell available and are familiar with using it (If not it is easy to learn though). It should be possible to compile this program on other operating systems as well but I currently only use linux so I can't provide any help there.

The documentation, the program source code and some other necessary files are contained in the doc directory in the format for the "nuweb" program and you need the nuweb program to get both documentation and the binary of the program. The nuweb program is not to be confused with the noweb program which is also used for literate programming.

Requirements
............

nuweb
_____
Download the latest release from the `nuweb webpage <http://nuweb.sourceforge.net/>`_ and follow the instructions in the README file (They probably tell you to run `make nuweb` on your shell to build an executable file called "nuweb").

pdflatex
________
Get some variant of pdflatex from your operating system. You probaby need to install some packages which names start with "texlive".

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


