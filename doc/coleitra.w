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

% Those are latex includes and defines, not for the program:
@i includes.w
@i defines.w

\makeindex

\begin{document}

@i title.w

\tableofcontents
\listoffigures

@i abstract.w

@i version.w

@i infrastructure.w

@i settings.w

@i about.w

@i database.w

@i train.w

@i edit.w

@i databaseedit.w

@i grammarprovider.w

@i networkscheduler.w

@i startupsequence.w

@i gui.w

@i levenshteindistance.w

@i qt.w

@i unit.w

\begin{appendix}
\chapter{Code indices}
\section{Files}
@f

\section{Fragments}
@m

\section{User identifiers}
@u

\todototoc\listoftodos

\cleardoublepage\printindex
\end{appendix}
\end{document}
