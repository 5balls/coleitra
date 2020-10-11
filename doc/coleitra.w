@i includes.w
@i defines.w

\makeindex

\begin{document}

@i title.w

\tableofcontents

@i abstract.w

@i main.w

@i settings.w

@i database.w

\chapter{Algorithm}

@i gui.w

@i qt.w

\begin{appendix}
\chapter{Code indices}
\section{Files}
@f

\section{Fragments}
@m

\section{User identifiers}
@u

\cleardoublepage\printindex
\end{appendix}
\end{document}
