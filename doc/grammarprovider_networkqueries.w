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

\section{Network queries}
The API of wiktionary is used to avoid unneccessary network traffic. We never ask for the whole page but only for the parts which we need for the information we desire.

First \verb#getWiktionarySections()# gets a json Object containing all the sections of the wiktionary page. This sections are searched for the current language, e.g. ``Finnish'' for example. Then this language section is searched for an etymology section. If this etymology section exists, we request this section with \verb#getWiktionarySection()# and check to see if it contains a compound template. If we find a compound template, depending on the status of the database we recursively request the words making up the compound (if the word is in the database already we link to it instead).

After the etymology section is parsed we look for flection sections, i.e. ``Conjugation'' or ``Declination''. Again we get the contents of this sections by calling \verb#getWiktionarySection()# and if we can identify a template we call additionaly \verb#getWiktionaryTemplate# to expand the template with the arguments we find (this will practically render the html form of this particular part of the webpage). We call the appropriate parsing function for this template and process the grammar information we obtain this way.

In the following sequence diagram error handling is not shown to keep it managable. Whenever there is a fatal error the appropriate signals are sent to the caller. Signals are also sent, whenever we can obtain a valid grammar object.

\begin{figure}
\centering
\begin{sequencediagram}
\newthread{sections}{getWiktionarySections()}
\newthread{section}{getWiktionarySection()}
\newthread{template}{getWiktionaryTemplate()}
\newthread{network}{Network Thread}
\newthread{parsetemplate}{Parse Template}
\mess{sections}{requestNetworkReply}{network}
\begin{call}{section}{possible retry}{section}{}
\end{call}
\mess{network}{success}{section}
\begin{sdblock}{Etymology}{Found section}
\begin{call}{section}{requestNetworkReply}{network}{blocking wait}
\begin{call}{template}{possible retry}{template}{}
\end{call}
\mess{network}{success}{template}
\begin{sdblock}{Compound}{Found compound}
\begin{call}{template}{}{sections}{\shortstack{This is a recursive call, so it starts again from the\\
beginning until unlocking the blocking wait}}
\postlevel
\end{call}
\end{sdblock}
\end{call}
\end{sdblock}
\begin{sdblock}{Flection}{Found section}
\mess{section}{requestNetworkReply}{network}
\begin{call}{template}{possible retry}{template}{}
\end{call}
\mess{network}{success}{template}
\mess{template}{requestNetworkReply}{network}
\mess{network}{success}{parsetemplate}
\end{sdblock}
\end{sequencediagram}
\caption{Network queries in grammar provider}
\end{figure}

\begin{figure}
\centering
\begin{tikzpicture}
\tikzflowchart
\node [proc, start chain=1, fill=white] (p1) {getGrammarInfoForWord};
\node [term, join] (p2) {getWiktionarySections};
\node [term, join=by sig, right=of p2] (p3) {getWiktionarySection};
\node [test, join] (p4) {Etymology?};
\node [term, join=by sig, right=of p4] (p5) {getWiktionaryTemplate};
\node [test, join, fill=white] (p5a) {Found template?};
\node [test, join, below=18ex of p5a, fill=white] (p6) {Compoundform?};
\node [term, join, below=18ex of p6, fill=white] (p7) {parse\_compoundform};
\node [wait, join, text width=5cm, fill=white] (p8) {Wait for grammarInfoComplete or grammarInfoNotAvailable};
\node [emit, join, fill=yellow!40] (p9) {emit grammarInfoComplete};
\node [term, below=2cm of p9] (p19) {Template not supported};
\node [emit, join, fill=red!40] (p21) {emit grammarInfoNotAvailable};
\node [left=0.75cm of p6] {no};
\node [right=0.75cm of p5a] {no};
\node [term, left=of p7, text width=4cm] (p14) {\ldots continue getWiktionaryTemplate};
\node [term, join=by sig, left=of p14, text width=4cm] (p15) {Language specific parse function};
\node [term, join] (p16) {process\_grammar};
\node [emit, join, fill=orange!40] (p17a) {emit processedGrammar};
\node [emit, join, fill=green!40] (p18) {emit grammarInfoAvailable};
\node [wait, below=of p4, left=of p5a, text width=5cm, fill=white] (p10) {Wait for grammarInfoComplete or grammarInfoNotAvailable};
\draw [->, norm] (p4) to (p10);
\node [test, below=14ex of p10, join] (p11) {Found language?};
\node [emit, join, fill=red!40] (p13) {emit grammarInfoNotAvailable};
\begin{pgfonlayer}{bg} 
    \draw [->, sig] (p11.east) to [out=0, in=-90] node[above, rotate=45] {yes}  (p5.200);
    \draw [->, norm] (p6.west) to [out=180, in=90] (p14.north);
    \draw [->, norm] (p5a.east) to [out=0, in=90] (p19.north);
    \draw [->, norm] (p7.east) to [out=0, in=0] ($(p2)+(10cm,1cm)$) to [out=180, in=45] (p2.45);
    \draw [draw=none] (p4) to node[above] {yes} node[var,below=0.2cm] {m\_caller \nodepart{second} waitloop} (p5);
    \draw [draw=none] (p4) to node[right] {yes} (p10);
    \draw [->, norm] (p4.west) to [out=180, in=180] node[left] {no} (p11.west);
    \draw [draw=none] (p11) to node[right] {no} (p13);
    \draw [draw=none] (p6) to node[right] {yes} (p7);
    \draw [draw=none] (p5a) to node[right] {yes} (p6);
\end{pgfonlayer}
\end{tikzpicture}
\caption{Flow chart of inner workings of grammarprovider class}
\end{figure}

