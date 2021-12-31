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

\section{Language support status}
See the helper script below to see how this tables were generated.
\subsection{Finnish}
\subsubsection{Inflection templates}
Command to create Template row of the table:
\begin{lstlisting}[language=bash]
./get_templates.py Finnish_inflection-table_templates | sort -d | xclip -selection c
\end{lstlisting}

\begin{longtable}{l|l|l}
Template & Example & Function \\ \hline\hline
\verb#FiAdvCases# & & \\
\verb#fi-adv-dir# & & \\
\verb#fi-adv-poss# & & \\
\verb#fi-conj# & & \\
\verb#fi-conj-ei# & & \\
\verb#fi-conj-huutaa# & piirtää & \verb#parse_fi_verbs# \\
\verb#fi-conj-juoda# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-juosta# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-kaikaa# & & \\
\verb#fi-conj-kaivaa# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-katketa# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-kumajaa# & & \\
\verb#fi-conj-käydä# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-laskea# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-lähteä# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-muistaa# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-nähdä# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-olla# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-rohkaista# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-saada# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-saartaa# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-salata# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-sallia# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-sanoa# & & \verb#parse_fi_verbs#\\
\verb#fi-conj-see# & & \\
\verb#fi-conj-seistä# & & \\
\verb#fi-conj-selvitä# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-soutaa# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-subj# & & \\
\verb#fi-conj-table# & & \\
\verb#fi-conj-taitaa# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-tulla# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-tuntea# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-tupakoida# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-valita# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-vanheta# & & \verb#parse_fi_verbs# \\
\verb#fi-conj-virkkaa# & & \\
\verb#fi-conj-voida# & & \verb#parse_fi_verbs# \\
\verb#fi-decl# & & \\
\verb#fi-decl-compound# & & \\
\verb#fi-decl-filee# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-filee-dot# & & \\
\verb#fi-decl-hame# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-internal# & & \\
\verb#fi-decl-kahdeksas# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-kahdeksas-kahdeksas# & & \\
\verb#fi-decl-kahdeksas-koira# & & \\
\verb#fi-decl-kahdeksas-palvelu# & & \\
\verb#fi-decl-kahdeksas-valo# & & \\
\verb#fi-decl-kahdeksas-vieras# & & \\
\verb#fi-decl-kaksi# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-kala# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-kala-kala# & & \\
\verb#fi-decl-kala-koira# & & \\
\verb#fi-decl-kala-maa# & & \\
\verb#fi-decl-kala-nainen# & & \\
\verb#fi-decl-kala-ovi# & & \\
\verb#fi-decl-kala-paperi# & & \\
\verb#fi-decl-kala-risti# & & \\
\verb#fi-decl-kala-sisar# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-kala-suo# & & \\
\verb#fi-decl-kala-uni# & & \\
\verb#fi-decl-kala-valo# & & \\
\verb#fi-decl-kala-vastaus# & & \\
\verb#fi-decl-kalleus# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-katiska# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-kevät# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-koira# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-koira-dot# & & \\
\verb#fi-decl-koira-hame# & & \\
\verb#fi-decl-koira-kala# & & \\
\verb#fi-decl-koira-kalleus# & & \\
\verb#fi-decl-koira-koira# & & \\
\verb#fi-decl-koira-käsi# & & \\
\verb#fi-decl-koira-kulkija# & & \\
\verb#fi-decl-koira-laatikko# & & \\
\verb#fi-decl-koira-maa# & & \\
\verb#fi-decl-koira-mies# & & \\
\verb#fi-decl-koira-nainen# & & \\
\verb#fi-decl-koira-nalle# & & \\
\verb#fi-decl-koira-ovi# & & \\
\verb#fi-decl-koira-paperi# & & \\
\verb#fi-decl-koira-pieni# & & \\
\verb#fi-decl-koira-risti# & & \\
\verb#fi-decl-koira-sisar# & & \\
\verb#fi-decl-koira-suo# & & \\
\verb#fi-decl-koira-uni# & & \\
\verb#fi-decl-koira-valo# & & \\
\verb#fi-decl-koira-valtio# & & \\
\verb#fi-decl-koira-vapaa# & & \\
\verb#fi-decl-koira-vastaus# & & \\
\verb#fi-decl-koira-vieras# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-korkea# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-korkea-hame# & & \\
\verb#fi-decl-korkea-kala# & & \\
\verb#fi-decl-korkea-koira# & & \\
\verb#fi-decl-korkea-käsi# & & \\
\verb#fi-decl-korkea-kulkija# & & \\
\verb#fi-decl-korkea-paperi# & & \\
\verb#fi-decl-korkea-risti# & & \\
\verb#fi-decl-korkea-solakka# & & \\
\verb#fi-decl-korkea-valo# & & \\
\verb#fi-decl-korkea-valtio# & & \\
\verb#fi-decl-korkea-vastaus# & & \\
\verb#fi-decl-käsi# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-käsi-kala# & & \\
\verb#fi-decl-käsi-koira# & & \\
\verb#fi-decl-käsi-käsi# & & \\
\verb#fi-decl-käsi-kulkija# & & \\
\verb#fi-decl-käsi-maa# & & \\
\verb#fi-decl-käsi-risti# & & \\
\verb#fi-decl-kulkija# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-kulkija-kulkija# & & \\
\verb#fi-decl-kuollut# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-kuollut-kalleus# & & \\
\verb#fi-decl-kuollut-koira# & & \\
\verb#fi-decl-kuollut-kulkija# & & \\
\verb#fi-decl-kuollut-kuollut# & & \\
\verb#fi-decl-kuollut-kytkin# & & \\
\verb#fi-decl-kuollut-risti# & & \\
\verb#fi-decl-kuollut-valo# & & \\
\verb#fi-decl-kuollut-vastaus# & & \\
\verb#fi-decl-kynsi# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-kytkin# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-kytkin-kala# & & \\
\verb#fi-decl-kytkin-kulkija# & & \\
\verb#fi-decl-kytkin-ovi# & & \\
\verb#fi-decl-kytkin-valo# & & \\
\verb#fi-decl-kytkin-valtio# & & \\
\verb#fi-decl-laatikko# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-lapsi# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-lämmin# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-lämmin-koira# & & \\
\verb#fi-decl-lämmin-käsi# & & \\
\verb#fi-decl-lämmin-palvelu# & & \\
\verb#fi-decl-lämmin-valo# & & \\
\verb#fi-decl-maa# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-maa-dot# & & \\
\verb#fi-decl-mies# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-nainen# & & \\
\verb#fi-decl-nainen-hame# & & \\
\verb#fi-decl-nainen-kala# & & \\
\verb#fi-decl-nainen-kalleus# & & \\
\verb#fi-decl-nainen-katiska# & & \\
\verb#fi-decl-nainen-koira# & & \\
\verb#fi-decl-nainen-käsi# & & \\
\verb#fi-decl-nainen-kulkija# & & \\
\verb#fi-decl-nainen-kytkin# & & \\
\verb#fi-decl-nainen-laatikko# & & \\
\verb#fi-decl-nainen-maa# & & \\
\verb#fi-decl-nainen-nainen# & & \\
\verb#fi-decl-nainen-omena# & & \\
\verb#fi-decl-nainen-ovi# & & \\
\verb#fi-decl-nainen-palvelu# & & \\
\verb#fi-decl-nainen-paperi# & & \\
\verb#fi-decl-nainen-pieni# & & \\
\verb#fi-decl-nainen-risti# & & \\
\verb#fi-decl-nainen-solakka# & & \\
\verb#fi-decl-nainen-suo# & & \\
\verb#fi-decl-nainen-uni# & & \\
\verb#fi-decl-nainen-valo# & & \\
\verb#fi-decl-nainen-valtio# & & \\
\verb#fi-decl-nainen-vastaus# & & \\
\verb#fi-decl-nainen-vieras# & & \\
\verb#fi-decl-nalle# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-ohut# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-omena# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-onneton# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-onneton-kala# & & \\
\verb#fi-decl-onneton-käsi# & & \\
\verb#fi-decl-onneton-nainen# & & \\
\verb#fi-decl-onneton-pieni# & & \\
\verb#fi-decl-onneton-risti# & & \\
\verb#fi-decl-onneton-suo# & & \\
\verb#fi-decl-onneton-valo# & & \\
\verb#fi-decl-onneton-vastaus# & & \\
\verb#fi-decl-onneton-vieras# & & \\
\verb#fi-decl-ovi# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-ovi-ovi# & & \\
\verb#fi-decl-palvelu# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-paperi# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-paperi-pieni# & & \\
\verb#fi-decl-paperi-risti# & & \\
\verb#fi-decl-parfait# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-pieni# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-pieni-kalleus# & & \\
\verb#fi-decl-pieni-koira# & & \\
\verb#fi-decl-pieni-maa# & & \\
\verb#fi-decl-pieni-mies# & & \\
\verb#fi-decl-pieni-ovi# & & \\
\verb#fi-decl-pieni-risti# & & \\
\verb#fi-decl-pieni-suo# & & \\
\verb#fi-decl-pieni-uni# & & \\
\verb#fi-decl-pieni-valo# & & \\
\verb#fi-decl-pieni-vastaus# & & \\
\verb#fi-decl-pred-adv# & & \\
\verb#fi-decl-pron# & & \\
\verb#fi-decl-risti# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-risti-dot# & & \\
\verb#fi-decl-risti-kala# & & \\
\verb#fi-decl-risti-katiska# & & \\
\verb#fi-decl-risti-kulkija# & & \\
\verb#fi-decl-risti-kynsi# & & \\
\verb#fi-decl-risti-nainen# & & \\
\verb#fi-decl-risti-valo# & & \\
\verb#fi-decl-rosé# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-see# & & \\
\verb#fi-decl-sisar# & & \\
\verb#fi-decl-sisin# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-sisin-kalleus# & & \\
\verb#fi-decl-sisin-risti# & & \\
\verb#fi-decl-solakka# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-solakka-valo# & & \\
\verb#fi-decl-suo# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-table# & & \\
\verb#fi-decl-tiili# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-toimi# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-tuhat# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-uni# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-valo# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-valo-hame# & & \\
\verb#fi-decl-valo-kala# & & \\
\verb#fi-decl-valo-kalleus# & & \\
\verb#fi-decl-valo-koira# & & \\
\verb#fi-decl-valo-käsi# & & \\
\verb#fi-decl-valo-kulkija# & & \\
\verb#fi-decl-valo-kytkin# & & \\
\verb#fi-decl-valo-maa# & & \\
\verb#fi-decl-valo-mies# & & \\
\verb#fi-decl-valo-nainen# & & \\
\verb#fi-decl-valo-omena# & & \\
\verb#fi-decl-valo-ovi# & & \\
\verb#fi-decl-valo-paperi# & & \\
\verb#fi-decl-valo-pieni# & & \\
\verb#fi-decl-valo-risti# & & \\
\verb#fi-decl-valo-suo# & & \\
\verb#fi-decl-valo-uni# & & \\
\verb#fi-decl-valo-valo# & & \\
\verb#fi-decl-valo-valtio# & & \\
\verb#fi-decl-valo-vastaus# & & \\
\verb#fi-decl-valo-vieras# & & \\
\verb#fi-decl-valtio# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-vanhempi# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-vanhempi-kala# & & \\
\verb#fi-decl-vanhempi-koira# & & \\
\verb#fi-decl-vanhempi-mies# & & \\
\verb#fi-decl-vanhempi-palvelu# & & \\
\verb#fi-decl-vanhempi-paperi# & & \\
\verb#fi-decl-vapaa# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-vapaa-hame# & & \\
\verb#fi-decl-vapaa-kala# & & \\
\verb#fi-decl-vapaa-koira# & & \\
\verb#fi-decl-vapaa-käsi# & & \\
\verb#fi-decl-vapaa-risti# & & \\
\verb#fi-decl-vapaa-valo# & & \\
\verb#fi-decl-vasen# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-vastaus# & & \\
\verb#fi-decl-vastaus-risti# & & \\
\verb#fi-decl-vastaus-vastaus# & & \\
\verb#fi-decl-veitsi# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-vieras# & & \\
\verb#fi-decl-vieras-kala# & & \\
\verb#fi-decl-vieras-koira# & & \\
\verb#fi-decl-vieras-käsi# & & \\
\verb#fi-decl-vieras-nainen# & & \verb#parse_fi_nominals# \\
\verb#fi-decl-vieras-palvelu# & & \\
\verb#fi-decl-vieras-risti# & & \\
\verb#fi-decl-vieras-valo# & & \\
\verb#fi-decl-vieras-vastaus# & & \verb#parse_fi_nominals# \\
\verb#FiNounCases# & & \\
\verb#fi-word-poss# & & \\
\end{longtable}

\subsubsection{Headword templates}

\begin{lstlisting}[language=bash,caption=Used command]
./get_templates.py Finnish_headword-line_templates | sort -d | xclip -selection c
\end{lstlisting}


\begin{longtable}{l|l}
Template & Function \\ \hline\hline
\verb#fi-adj# & \\
\verb#fi-adv# & \\
\verb#fi-adv-pos# & \\
\verb#fi-colverbform# & \\
\verb#fi-con# & \\
\verb#fi-consonant# & \\
\verb#fi-contr# & \\
\verb#fi-int# & \\
\verb#fi-letter# & \\
\verb#fi-monopersonal# & \\
\verb#fi-noun# & \\
\verb#fi-num# & \\
\verb#fi-phrase# & \\
\verb#fi-postp# & \\
\verb#fi-prefix# & \\
\verb#fi-pron# & \\
\verb#fi-proper noun# & \\
\verb#fi-suffix# & \\
\verb#fi-verb# & \\
\end{longtable}

\subsection{German}
\subsubsection{Inflection templates}
Command to create Template row of the table:

\begin{lstlisting}[language=bash]
./get_templates.py German_inflection-table_templates | sort -d | xclip -selection c
\end{lstlisting}

The Function row is filled in manually.

\begin{longtable}{l|l}
Template & Function \\ \hline\hline
\verb#de-conj# & \verb#parse_de_verb#\\
\verb#de-decl-adj# & \\
\verb#de-decl-adj/comp# & \\
\verb#de-decl-adj-inc# & \\
\verb#de-decl-adj-inc-notcomp# & \\
\verb#de-decl-adj-inc-notcomp-nopred# & \\
\verb#de-decl-adj-notcomp# & \\
\verb#de-decl-adj-notcomp-nopred# & \\
\verb#de-decl-adj+noun# & \\
\verb#de-decl-adj+noun# & \\
\verb#de-decl-adj+noun-f# & \\
\verb#de-decl-adj+noun-f# & \\
\verb#de-decl-adj+noun-m# & \\
\verb#de-decl-adj+noun-m# & \\
\verb#de-decl-adj+noun-n# & \\
\verb#de-decl-adj+noun-n# & \\
\verb#de-decl-adj+noun-pl# & \\
\verb#de-decl-adj+noun-pl# & \\
\verb#de-decl-adj+noun-sg# & \\
\verb#de-decl-adj+noun-sg# & \\
\verb#de-decl-adj+noun-sg-f# & \\
\verb#de-decl-adj+noun-sg-f# & \\
\verb#de-decl-adj+noun-sg-m# & \\
\verb#de-decl-adj+noun-sg-m# & \\
\verb#de-decl-adj+noun-sg-n# & \\
\verb#de-decl-adj+noun-sg-n# & \\
\verb#de-decl-adj/pos# & \\
\verb#de-decl-adj-predonly# & \\
\verb#de-decl-adj/sup# & \\
\verb#de-decl-adj-table# & \\
\verb#de-decl-all# & \\
\verb#de-decl-all# & \\
\verb#de-decl-anderer# & \\
\verb#de-decl-anderer# & \\
\verb#de-decl-definite article# & \\
\verb#de-decl-demonstrative pronouns# & \\
\verb#de-decl-dieser# & \\
\verb#de-decl-ein# & \\
\verb#de-decl-ein# & \\
\verb#de-decl-einer# & \\
\verb#de-decl-euer# & \\
\verb#de-decl-euer# & \\
\verb#de-decl-jeder# & \\
\verb#de-decl-jeder# & \\
\verb#de-decl-jedweder# & \\
\verb#de-decl-jedweder# & \\
\verb#de-decl-jeglicher# & \\
\verb#de-decl-jener# & \\
\verb#de-decl-kein# & \\
\verb#de-decl-noun-f# & \verb#parse_de_noun_f#\\
\verb#de-decl-noun-langname# & \\
\verb#de-decl-noun-m# & \verb#parse_de_noun_m#\\
\verb#de-decl-noun-n# & \verb#parse_de_noun_n#\\
\verb#de-decl-noun-pl# & \\
\verb#de-decl-noun-table-full# & \\
\verb#de-decl-noun-table-pl# & \\
\verb#de-decl-noun-table-sg# & \\
\verb#de-decl-noun-table-sg-av# & \\
\verb#de-decl-personal pronouns# & \\
\verb#de-decl-possessive pronouns# & \\
\verb#de-decl-pronoun# & \\
\verb#de-decl-relative pronoun# & \\
\verb#de-decl-sein# & \\
\verb#de-decl-selber# & \\
\verb#de-decl-selber# & \\
\verb#de-decl-unßer# & \\
\verb#de-decl-unser# & \\
\end{longtable}

\subsubsection{Headword templates}

\begin{lstlisting}[language=bash]
./get_templates.py German_headword-line_templates | sort -d | xclip -selection c
\end{lstlisting}

\begin{longtable}{l|l}
Template & Function \\ \hline\hline
\verb#de-adj# & \\
\verb#de-adv# & \\
\verb#de-interj# & \\
\verb#de-letter# & \\
\verb#de-noun# & \\
\verb#de-phrase# & \\
\verb#de-prefix# & \\
\verb#de-prep# & \\
\verb#de-pron# & \\
\verb#de-proper noun# & \\
\verb#de-suffix# & \\
\verb#de-verb# & \\
\end{longtable}

\subsection{French}
\subsubsection{Inflection templates}
Command to create Template row of the table:

\begin{lstlisting}[language=bash]
./get_templates.py French_inflection-table_templates | sort -d | xclip -selection c
\end{lstlisting}

The Function row is filled in manually.

\begin{longtable}{l|l}
Template & Function \\ \hline\hline
\verb#fr-conj# & \\
\verb#fr-conj-auto# & \\
\verb#fr-conj-copier-coller# & \\
\verb#fr-conj-havoir# & \\
\verb#fr-conj-occire# & \\
\verb#fr-conj-ramentevoir# & \\
\verb#fr-conj-vader# & \\
\end{longtable}

\subsubsection{Headword templates}

\begin{longtable}{l|l}
Template & Function \\ \hline\hline
\verb#fr-adj# & \\
\verb#fr-adv# & \\
\verb#fr-diacritical mark# & \\
\verb#fr-intj# & \\
\verb#fr-letter# & \\
\verb#fr-noun# & \\
\verb#fr-past participle# & \\
\verb#fr-phrase# & \\
\verb#fr-prefix# & \\
\verb#fr-prep# & \\
\verb#fr-prep phrase# & \\
\verb#fr-pron# & \\
\verb#fr-proper noun# & \\
\verb#fr-punctuation mark# & \\
\verb#fr-suffix# & \\
\verb#fr-verb# & \\
\end{longtable}


