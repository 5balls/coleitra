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

\section{Calls to grammarprovider}
\begin{figure}[h]
\begin{tikzpicture}
\tikzflowchart
\node [proc] (n-addLexemeHeuristically) {addLexemeHeuristically};
\node [test, join, below=1.5cm] (n-containsSpace) {Lexeme contains '\textvisiblespace'?};
\node [test, join, right=of n-containsSpace] (n-containsDot) {Lexeme contains '.'?};
\node [test, above=of n-containsDot, right=of n-addLexemeHeuristically] (n-containsComma) {Lexeme contains ',\textvisiblespace'?};
\node [term, right=of n-containsDot, text width=4cm] (n-sentenceNotSupported) {Sentence not implemented};
\node [term, below=2cm of n-containsSpace] (n-lookupForm) {lookupForm};
\node [test, join] (n-formInDatabase) {Form in database?};
\node [term, join, below=1cm, text width=4cm] (n-classGrammarprovider) {\ldots continue in grammarprovider class};
\node [term, join=by class, fill=yellow!40, right=of n-classGrammarprovider] (n-getGrammarInfoForWord) {getGrammarInfoForWord};
\node [term, right=of n-formInDatabase] (n-lookupLexeme) {lookupLexeme};
\node [term, join] (n-addLexeme) {addLexeme};
\begin{pgfonlayer}{bg} 
    \draw [->, norm] (n-containsDot) to node[above] {yes} (n-sentenceNotSupported);
    \draw [draw=none] (n-containsSpace) to node[above] {yes} (n-containsDot);
    \draw [->, norm] (n-containsDot) to node[right] {no} (n-containsComma);
    \draw [->, norm] (n-containsComma) to node[above] {yes} (n-addLexemeHeuristically);
    \draw [->, norm] (n-containsSpace) to node[right] {no} (n-lookupForm);
    \draw [->, norm] (n-formInDatabase) to node[above] {yes} (n-lookupLexeme);
    \draw [draw=none] (n-formInDatabase) to node[right] {no} (n-classGrammarprovider);
\end{pgfonlayer}
\end{tikzpicture}
\caption{Flow chart of addLexemeHeuristically}
\end{figure}


\begin{figure}
\centering
\begin{tikzpicture}
\tikzflowchart
\node [emit, text width=4cm, fill=yellow!40] (n-grammarInfoAvailable) {emit grammarInfoAvailable};
\node [term, join=by sig, left=of n-grammarInfoAvailable, text width=4cm] (n-grammarInfoAvailableFromGrammarProvider) {grammar\-Info\-Available\-From\-Grammar\-Provider};
\node [term, join=by class, fill=yellow!40] (n-getNextGrammarObject) {getNextGrammarObject};
\node [test, join, fill=yellow!40, text width=3cm] (n-grammarFormAvailable) {Grammar form available?};
\node [term, join, fill=yellow!40] (n-getNextGrammarForm) {get next grammar form};
\node [test, join, fill=yellow!40] (n-nextForm) {Form?};
\node [test, join, fill=yellow!40, text width=3cm] (n-nextFormIgnoredParts) {Form with ignored parts?};
\node [test, join, fill=yellow!40] (n-nextCompoundForm) {Compoundform?};
\node [test, join, fill=yellow!40] (n-nextSentence) {Sentence?};
\node [test, join, fill=yellow!40] (n-addAndUseForm) {Add and use form?};
\node [emit, join, fill=yellow!40] (n-formObtained3) {emit formObtained};
\node [emit, join, fill=yellow!40] (n-sentenceAvailable) {emit sentenceAvailable};

\node [emit, right=of n-grammarFormAvailable, fill=yellow!40, text width=3cm] (n-grammarInfoComplete) {emit grammarInfoComplete};

\node [emit, right=of n-nextForm, fill=yellow!40, text width=3cm] (n-formObtained) {emit formObtained};

\node [test, right=of n-nextFormIgnoredParts, fill=yellow!40, text width=3cm] (n-formInstructionIgnore) {Ignore form?};
\node [test, join, fill=yellow!40, text width=3cm] (n-formInstructionLookupForm) {Lookup form?};
\node [test, join, fill=yellow!40, text width=3cm] (n-formInstructionLookupFormLexeme) {Lookup lexeme form?};
\node [test, join, fill=yellow!40, text width=3cm] (n-formInstructionAddAndUseForm) {Add and use form?};
\node [test, join, fill=yellow!40, text width=3cm] (n-formInstructionAddAndIgnoreForm) {Add and ignore form?};

\node [term, right=of n-formInstructionIgnore, fill=yellow!40] (n-formInstructionDoNothing) {Do nothing};
\node [term, right=of n-formInstructionLookupForm, fill=yellow!40] (n-formInstructionNotImplemented) {Not implemented};
\node [emit, right=of n-formInstructionAddAndUseForm, fill=yellow!40] (n-formObtained2) {emit formObtained};

\begin{pgfonlayer}{bg} 
    \draw [->, norm] (n-grammarFormAvailable) to node[above] {no} (n-grammarInfoComplete);
    \draw [draw=none] (n-grammarFormAvailable) to node[right] {yes} (n-getNextGrammarForm);
    \draw [draw=none] (n-nextForm) to node[right] {no} (n-nextFormIgnoredParts);
    \draw [->, norm] (n-nextForm) to node[above] {yes} (n-formObtained);
    \draw [draw=none] (n-nextFormIgnoredParts) to node[right] {no} (n-nextCompoundForm);
    \draw [draw=none] (n-nextCompoundForm) to node[right] {no} (n-nextSentence);
    \draw [draw=none] (n-nextSentence) to node[right] {yes} (n-addAndUseForm);
    \draw [draw=none] (n-addAndUseForm) to node[right] {yes} (n-formObtained3);
    \draw [->, norm] (n-addAndUseForm.west) to [out=180, in=180] node[right] {no} (n-sentenceAvailable.west);
    \draw [->, norm] (n-nextFormIgnoredParts) to node[above] {yes} (n-formInstructionIgnore);
    \draw [draw=none] (n-formInstructionIgnore) to node[right] {no} (n-formInstructionLookupForm);
    \draw [draw=none] (n-formInstructionLookupForm) to node[right] {no} (n-formInstructionLookupFormLexeme);
    \draw [draw=none] (n-formInstructionLookupFormLexeme) to node[right] {no} (n-formInstructionAddAndUseForm);
    \draw [draw=none] (n-formInstructionAddAndUseForm) to node[right] {no} (n-formInstructionAddAndIgnoreForm);
    \draw [->, norm] (n-formInstructionIgnore) to node[above] {yes} (n-formInstructionDoNothing);
    \draw [->, norm] (n-formInstructionLookupForm) to node[above] {yes} (n-formInstructionNotImplemented);
    \draw [->, norm] (n-formInstructionLookupFormLexeme.east) to [out=0, in=-90] node[above] {yes} (n-formInstructionNotImplemented.south);
    \draw [->, norm] (n-formInstructionAddAndUseForm) to node[above] {yes} (n-formObtained2);
    \draw [->, norm] (n-formInstructionAddAndIgnoreForm.east) to [out=0, in=0] node[above] {yes} (n-formInstructionNotImplemented.east);

\end{pgfonlayer}
\end{tikzpicture}
\caption{Flow chart of getNextGrammarObject}
\end{figure}

\begin{figure}
\hspace{-2cm}\begin{tikzpicture}
\tikzflowchart
\node [term] (n-addLexemeHeuristically) {addLexemeHeuristically};
\node [term, join=by class, right=of n-addLexemeHeuristically, fill=yellow!40] (n-getGrammarInfoForWord) {getGrammarInfoForWord};
\node [emit, join=by indirect, fill=yellow!40] (n-grammarInfoAvailable) {emit grammarInfoAvailable};
\node [term, join=by sig, left=of n-grammarInfoAvailable, text width=3cm] (n-grammarInfoAvailableFromGrammarProvider) {grammar\-Info\-Available\-From\-Grammar\-Provider};
\node [term, below=1cm of n-grammarInfoAvailable, fill=yellow!40] (n-getNextGrammarObject) {getNextGrammarObject};
\node [emit, join=by indirect, fill=yellow!40] (n-formObtained) {emit formObtained};
\node [emit, join=by indirect, fill=yellow!40] (n-sentenceAvailable) {emit sentenceAvailable};
\node [emit, join=by indirect, below=1cm, text width=3cm, fill=yellow!40] (n-grammarInfoComplete) {emit grammar\-Info\-Complete};
\node [term, fill=yellow!40] (n-getNextSentencePart) {getNextSentencePart};
\node [emit, join=by indirect, fill=yellow!40] (n-sentenceLookupForm) {emit sentenceLookupForm};
\node [emit, join=by indirect, text width=3cm, fill=yellow!40] (n-sentenceLookupFormLexeme) {emit sentence\-Lookup\-Form\-Lexeme};
\node [emit, join=by indirect, text width=3cm, fill=yellow!40] (n-sentenceAddAndUseForm) {emit sentence\-Add\-And\-Use\-Form};
\node [emit, join=by indirect, text width=3cm, fill=yellow!40] (n-sentenceAddAndIgnoreForm) {emit sentence\-Add\-And\-Ignore\-Form};
\node [emit, join=by indirect, fill=yellow!40] (n-sentenceComplete) {emit sentenceComplete};

\node [term, left=of n-formObtained, text width=3cm] (n-formObtainedFromGrammarProvider) {form\-Obtained\-From\-Grammar\-Provider};
\node [term, join] (n-addForm) {addForm};

\node [term, left=of n-grammarInfoComplete, text width=3cm] (n-grammarInfoCompleteFromGrammarProvider) {grammar\-Info\-Complete\-From\-Grammar\-Provider};
\node [emit, join] (n-addLexemeHeuristicallyResult) {addLexemeHeuristicallyResult};
\node [term, join, text width=3cm] (n-addScheduledLexemeHeuristically) {add\-Scheduled\-Lexeme\-Heuristically};

\node [term, right=of n-sentenceAvailable, text width=3cm] (n-sentenceAvailableFromGrammarProvider) {sentence\-Available\-From\-Grammar\-Provider};

\node [term, right=of n-sentenceLookupForm, text width=3cm] (n-sentenceLookupFormFromGramarProvider) {sentence\-Lookup\-Form\-From\-Gramar\-Provider};

\node [term, right=of n-sentenceLookupFormLexeme, text width=3cm] (n-sentenceLookupFormLexemeFromGrammarProvider) {sentence\-Lookup\-Form\-Lexeme\-From\-Grammar\-Provider};

\node [term, right=of n-sentenceAddAndUseForm, text width=3cm] (n-sentenceAddAndUseFormFromGrammarProvider) {sentence\-Add\-And\-Use\-Form\-From\-Grammar\-Provider};

\node [term, right=of n-sentenceAddAndIgnoreForm, text width=3cm] (n-sentenceAddAndIgnoreFormFromGrammerProvider) {sentence\-Add\-And\-Ignore\-Form\-From\-Grammer\-Provider};

\node [term, right=of n-sentenceComplete, text width=3cm] (n-sentenceCompleteFromGrammarProvider) {sentence\-Complete\-From\-Grammar\-Provider};
\node [term, join] (n-addSentence) {addSentence};

\begin{pgfonlayer}{bg}
    \draw [->, class] (n-grammarInfoAvailableFromGrammarProvider.south) to [out=-90, in=180] (n-getNextGrammarObject.west);
    \draw [->, class] (n-addForm.east) to [out=0, in=180] (n-getNextGrammarObject.west);
    \draw [->, sig] (n-formObtained) to (n-formObtainedFromGrammarProvider);
    \draw [->, sig] (n-sentenceAvailable) to (n-sentenceAvailableFromGrammarProvider);
    \draw [->, class] (n-sentenceAvailableFromGrammarProvider.south) to [out=-90, in=0] (n-getNextSentencePart);
    \draw [->, sig] (n-sentenceLookupForm) to (n-sentenceLookupFormFromGramarProvider);
    \draw [->, class] (n-sentenceLookupFormFromGramarProvider.north) to [out=90, in=0] (n-getNextSentencePart.east);
    \draw [->, sig] (n-sentenceLookupFormLexeme) to (n-sentenceLookupFormLexemeFromGrammarProvider);
    \draw [->, class] (n-sentenceLookupFormLexemeFromGrammarProvider.east) to [out=0, in=-45] ($(n-getNextSentencePart)+(7cm,0cm)$) to [out=135, in=0] (n-getNextSentencePart);
    \draw [->, sig] (n-sentenceAddAndUseForm) to (n-sentenceAddAndUseFormFromGrammarProvider);
    \draw [->, class] (n-sentenceAddAndUseFormFromGrammarProvider.east) to [out=0, in=-45] ($(n-getNextSentencePart)+(7cm,0cm)$) to [out=135, in=0] (n-getNextSentencePart);
    \draw [->, sig] (n-sentenceAddAndIgnoreForm) to (n-sentenceAddAndIgnoreFormFromGrammerProvider);
    \draw [->, class] (n-sentenceAddAndIgnoreFormFromGrammerProvider.east) to [out=0, in=-45] ($(n-getNextSentencePart)+(7cm,0cm)$) to [out=135, in=0] (n-getNextSentencePart);
    \draw [->, sig] (n-sentenceComplete) to (n-sentenceCompleteFromGrammarProvider);
    \draw [->, class] (n-addSentence) to [out=0, in=-90] ($(n-addSentence)!0.5!(n-getNextGrammarObject)+(7cm,0cm)$) to [out=90, in=0] (n-getNextGrammarObject);
    \draw [->, sig] (n-grammarInfoComplete) to (n-grammarInfoCompleteFromGrammarProvider);
    \draw [->, norm] (n-addScheduledLexemeHeuristically.west) to [out=180, in=-90] ($(n-addScheduledLexemeHeuristically)!0.5!(n-addLexemeHeuristically)+(-3cm,0cm)$) to [out=90, in=180] (n-addLexemeHeuristically.west);
\end{pgfonlayer}
\end{tikzpicture}
\caption{Flow chart of communication between edit.w and grammarprovider.w when grammar object is available}
\end{figure}
\clearpage

