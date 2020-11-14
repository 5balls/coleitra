% Copyright 2020 Florian Pesth
%
% This file is part of coleitra.
%
% coleitra is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% coleitra is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with coleitra.  If not, see <https://www.gnu.org/licenses/>.

% Those are latex includes and defines, not for the program:
@i includes.w
@i defines.w

\makeindex

\begin{document}

@i title.w

\tableofcontents

@i abstract.w

@i infrastructure.w

@i settings.w

@i about.w

@i database.w

@i train.w

@i edit.w

@i grammarprovider.w

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
