% Copyright 2020 Florian Pesth
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

\lstdefinelanguage{QtProject}
{
    basicstyle=\footnotesize,
    morecomment=[l]{\#},
    commentstyle=\ttfamily,
    morekeywords={QT,SOURCES,VERSION,HEADERS,CONFIG,DEFINES,DISTFILES,SUBDIRS,ANDROID\_PACKAGE\_SOURCE\_DIR,RESOURCES,\$\$PWD,\$\$system,\$\$quote},
    keywordstyle={\bfseries}
}

\lstdefinelanguage{QML}{
  keywords={break, case, catch, continue, debugger, default, delete, do, else, false, finally, for, function, if, in, instanceof, new, null, return, switch, this, throw, true, try, typeof, var, void, while, with},
  morecomment=[l]{//},
  morecomment=[s]{/*}{*/},
  morestring=[b]',
  morestring=[b]",
  ndkeywords={class, export, boolean, throw, implements, import, this},
  keywordstyle=\bfseries,
  ndkeywordstyle=\bfseries,
  identifierstyle=\color{black},
  commentstyle=\ttfamily,
  stringstyle=\ttfamily,
  sensitive=true
}

\lstdefinelanguage{CMake}{
  keywords={cmake_minimum_required, if, endif, include, project, set, execute\_process, cmake\_print\_variables, add\_definitions, find\_package, include\_directories, add\_library, else, add\_executable, target\_link\_libraries},
  morecomment=[l]{//},
  morecomment=[s]{/*}{*/},
  morestring=[b]',
  morestring=[b]",
  ndkeywords={},
  keywordstyle=\bfseries,
  ndkeywordstyle=\bfseries,
  identifierstyle=\color{black},
  commentstyle=\ttfamily,
  stringstyle=\ttfamily,
  sensitive=true
}

\newcommand\codecpp{\lstset{language=C++,breaklines=true}}
\newcommand\codeqtproject{\lstset{language=QtProject,breaklines=true}}
\newcommand\codeqml{\lstset{language=QML,breaklines=true}}
\newcommand\codeqrc{\lstset{language=XML,breaklines=true}}
\newcommand\codecmake{\lstset{language=CMake,breaklines=true}}
