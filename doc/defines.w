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

\newcommand\codecpp{\lstset{language=C++,breaklines=true}}
\newcommand\codeqtproject{\lstset{language=QtProject,breaklines=true}}
\newcommand\codeqml{\lstset{language=QML,breaklines=true}}
\newcommand\codeqrc{\lstset{language=XML,breaklines=true}}
