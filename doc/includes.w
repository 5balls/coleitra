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

\documentclass[a4paper]{book}
\usepackage{listings}
\usepackage{imakeidx}
\usepackage[margin=3cm]{geometry}
\usepackage[nottoc]{tocbibind}
\usepackage{longtable}
\usepackage{cprotect}
\usepackage{verbatim}
\usepackage{pgf-umlsd}
\usepackage{tikz}
\usepackage[textsize=tiny, textwidth=2.7cm, colorinlistoftodos]{todonotes}
\usepackage{etoolbox}% http://ctan.org/pkg/etoolbox
\makeatletter
\patchcmd{\@@makechapterhead}{\vspace*{50\p@@}}{}{}{}% Removes space above \chapter head
\patchcmd{\@@makeschapterhead}{\vspace*{50\p@@}}{}{}{}% Removes space above \chapter* head
\makeatother
\usepackage[colorlinks=true]{hyperref}
\makeindex
