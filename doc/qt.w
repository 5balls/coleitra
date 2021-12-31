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

\section{Qt environment}
Here are the files described, which are needed for compiling code for the Qt framework.

\subsection{Ressources}
\codeqrc
@O ../src/qml.qrc
@{
<RCC>
    <qresource prefix="/">
        <file>ColeitraGridLayout.qml</file>
        <file>ColeitraGridInGridLayout.qml</file>
        <file>ColeitraPage.qml</file>
        <file>ColeitraGridLabel.qml</file>
        <file>ColeitraGridValueText.qml</file>
        <file>ColeitraGridTextInput.qml</file>
        <file>ColeitraGridComboBox.qml</file>
        <file>ColeitraGridCheckBox.qml</file>
        <file>ColeitraGridButton.qml</file>
        <file>ColeitraGridGreenButton.qml</file>
        <file>ColeitraGridRedButton.qml</file>
        <file>ColeitraGridImageButton.qml</file>
        <file>ColeitraWidgetEditLexeme.qml</file>
        <file>ColeitraWidgetEditLexemePart.qml</file>
        <file>ColeitraWidgetEditGrammarExpression.qml</file>
        <file>ColeitraWidgetEditTranslationPart.qml</file>
        <file>ColeitraWidgetEditSentence.qml</file>
        <file>ColeitraWidgetEditSentencePart.qml</file>
        <file>ColeitraWidgetEditForm.qml</file>
        <file>ColeitraWidgetEditCompoundForm.qml</file>
        <file>ColeitraWidgetEditCompoundFormPart.qml</file>
        <file>ColeitraWidgetEditGrammarForm.qml</file>
        <file>ColeitraWidgetEditIdSelection.qml</file>
        <file>ColeitraWidgetEditGrammarFormComponentList.qml</file>
        <file>ColeitraWidgetEditSearchPopup.qml</file>
        <file>ColeitraWidgetEditSearchTextPopup.qml</file>
        <file>ColeitraWidgetEditPartList.qml</file>
        <file>ColeitraWidgetEditPartStack.qml</file>
        <file>ColeitraWidgetEditIdRadioButton.qml</file>
        <file>ColeitraWidgetSimpleEditInput.qml</file>
        <file>ColeitraWidgetDatabaseFormEdit.qml</file>
        <file>ColeitraWidgetDatabaseLexemeEdit.qml</file>
        <file>ColeitraWidgetDatabaseTranslationEdit.qml</file>
        <file>ColeitraWidgetDatabaseTranslationPartLexemeEdit.qml</file>
        <file>ColeitraWidgetDatabaseTranslationPartSentenceEdit.qml</file>
        <file>ColeitraWidgetDatabaseTranslationPartFormEdit.qml</file>
        <file>ColeitraWidgetDatabaseTranslationPartCompoundFormEdit.qml</file>
        <file>ColeitraWidgetDatabaseTranslationPartGrammarFormEdit.qml</file>
        <file>ColeitraWidgetDatabaseSentenceEdit.qml</file>
        <file>ColeitraWidgetSearchPopupForm.qml</file>
        <file>ColeitraWidgetSearchPopupLexeme.qml</file>
        <file>ColeitraWidgetSearchPopupGrammar.qml</file>
        <file>ColeitraWidgetLanguageComboBox.qml</file>
        <file>ColeitraWidgetRoundedRectangle.qml</file>
        <file>ColeitraWidgetRoundedGreenRectangle.qml</file>
        <file>ColeitraWidgetRoundedRedRectangle.qml</file>
        <file>ColeitraWidgetRoundedYellowRectangle.qml</file>
        <file>ColeitraWidgetRoundedBlueRectangle.qml</file>
        <file>ColeitraWidgetRoundedGreenRectangleButton.qml</file>
        <file>ColeitraWidgetRoundedRedRectangleButton.qml</file>
        <file>ColeitraWidgetRoundedYellowRectangleButton.qml</file>
        <file>ColeitraWidgetRoundedBlueRectangleButton.qml</file>
        <file>ColeitraWidgetLicenseSelectId.qml</file>
        <file>main.qml</file>
        <file>settings.svg</file>
        <file>settings_pressed.svg</file>
        <file>back.svg</file>
        <file>back_pressed.svg</file>
        <file>plus.svg</file>
        <file>plus_pressed.svg</file>
        <file>www.svg</file>
        <file>www_pressed.svg</file>
        <file>minus.svg</file>
        <file>minus_pressed.svg</file>
        <file>scrollprogress.svg</file>
        <file>about.qml</file>
        <file>train.qml</file>
        <file>edit.qml</file>
        <file>simpleedit.qml</file>
        <file>databaseedit.qml</file>
        <file>settings.qml</file>
    </qresource>
</RCC>
@}
