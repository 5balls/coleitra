% Copyright 2020, 2021, 2022 Florian Pesth
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

\newcommand\codecpp{\lstset{language=C++,
breaklines=true,
extendedchars=true,
literate={ä}{{\"a}}1 {ö}{{\"o}}1 {ü}{{\"u}}1 {é}{{\'e}}1 {—}{{-}}1,
}}
\newcommand\codeqtproject{\lstset{language=QtProject,breaklines=true}}
\newcommand\codeqml{\lstset{language=QML,breaklines=true}}
\newcommand\codeqrc{\lstset{language=XML,breaklines=true}}
\newcommand\codecmake{\lstset{language=CMake,breaklines=true}}

\newcounter{todoremovecounter}
\newcommand{\todoremove}[1]{\stepcounter{todoremovecounter}\todo[color=red!40]{Remove \thetodoremovecounter: #1}}
\newcounter{todorefactorcounter}
\newcommand{\todorefactor}[1]{\stepcounter{todorefactorcounter}\todo[color=yellow!40]{Refactor \thetodorefactorcounter: #1}}
\newcounter{tododocumentcounter}
\newcommand{\tododocument}[1]{\stepcounter{tododocumentcounter}\todo[color=green!40]{Document \thetododocumentcounter: #1}}

% This is to fix positioning of todo comments on the left margin:
\setlength{\marginparwidth}{2.7cm}

\usetikzlibrary{shapes,arrows,chains,decorations.pathmorphing,calc}
\pgfdeclarelayer{bg}
\pgfsetlayers{bg,main}
\newcommand{\tikzflowchart}{\tikzset{
  base/.style={draw, on chain, on grid, align=center, minimum height=4ex},
  proc/.style={base, rectangle},
  test/.style={base, diamond, aspect=2},
  term/.style={proc, rounded corners},
  emit/.style={proc, rounded corners, double, double distance=1mm},
  wait/.style={base, trapezium, trapezium left angle=120, trapezium right angle=60},
  var/.style={base, rectangle split, rectangle split parts=2, rounded corners},
  coord/.style={coordinate, on chain, on grid, node distance=6mm and 25mm},
  nmark/.style={draw, cyan, circle, font={\sffamily\bfseries}},
  norm/.style={->, draw},
  sig/.style={->, decorate, decoration={snake}, draw},
  class/.style={dashed, draw},
  indirect/.style={dotted, draw,-},
  it/.style={font={\small\itshape}},
  >=triangle 60,
  start chain=going below,
  node distance=6mm and 50mm,
  every join/.style={norm}
}}


\setcounter{secnumdepth}{5}
\setcounter{tocdepth}{5}
