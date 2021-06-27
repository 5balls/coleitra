% Copyright 2020, 2021 Florian Pesth
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

\chapter{Errorhandling}
@o ../src/error.h -d
@{
@<Start of @'ERROR@' header@>
enum class sql_error {
    create_table,
    insert_record,
    update_record,
    delete_record,
    select_empty,
    select,
};
@<End of header@>
@}

\chapter{Database}
\index{Database}
\section{Interface}
The database class defines an interface for creating the different database connections used at other places in the code.

@o ../src/database.h -d
@{
@<Start of @'DATABASE@' header@>
#include <QSqlDatabase>
#include <QStandardPaths>
#include <QDir>
#include <QFileInfo>
#include <QSqlField>
#include "databasetable.h"

@<Start of class @'database@'@>
public:
    explicit database(QObject *parent = nullptr);
    databasetable* getTableByName(QString name);
    Q_PROPERTY(QString version MEMBER m_version NOTIFY versionChanged);
    Q_INVOKABLE QStringList languagenames();
    Q_INVOKABLE QStringList grammarkeys();
    Q_INVOKABLE int idfromgrammarkey(QString key);
    Q_INVOKABLE QStringList grammarvalues(QString key);
    Q_INVOKABLE int idfromlanguagename(QString languagename);
    Q_INVOKABLE QString languagenamefromid(int id);
    Q_INVOKABLE int alphabeticidfromlanguagename(QString languagename);
    Q_INVOKABLE int alphabeticidfromlanguageid(int languageid);
    Q_INVOKABLE int newTranslation(void);
    Q_INVOKABLE int newTranslationPart(int translation, int lexeme, int sentence, int form, int grammarform);
    Q_INVOKABLE QList<int> translationLexemePartsFromTranslationId(int translation);
    Q_INVOKABLE int newLexeme(int language_id, int license_id = 1);
    Q_INVOKABLE int newForm(int lexeme_id, int grammarFormId, QString string, int license_id = 1);
    Q_INVOKABLE int newSentence(int lexeme_id, int grammarFormId, int license_id = 1);
    Q_INVOKABLE int newSentencePart(int sentenceid, int part, int capitalized, int form, int grammarform, int punctuationmark);
    Q_INVOKABLE int newCompoundFormPart(int compoundform, int part, int form, bool capitalized, QString string);
    Q_INVOKABLE QString prettyPrintTranslation(int translation_id);
    Q_INVOKABLE QString prettyPrintGrammarForm(int grammarForm_id);
    Q_INVOKABLE QString stringFromFormId(int form_id);
    Q_INVOKABLE QString prettyPrintForm(int form_id, QString form = "", int grammarformid = 0);
    Q_INVOKABLE QString prettyPrintLicense(int license_id);
    Q_INVOKABLE QString prettyPrintLicenseReference(int license_ref_id);
    Q_INVOKABLE int grammarFormFromFormId(int form_id);
    Q_INVOKABLE int licenseReferenceIdFromFormId(int form_id);
    Q_INVOKABLE int licenseReferenceIdFromLexemeId(int lexeme_id);
    Q_INVOKABLE int licenseReferenceIdFromTranslationId(int translation_id);
    Q_INVOKABLE QString authorFromLicenseReferenceId(int license_ref_id);
    Q_INVOKABLE QString publisherFromLicenseReferenceId(int license_ref_id);
    Q_INVOKABLE int lexemeFromFormId(int form_id);
    Q_INVOKABLE int languageIdFromLexemeId(int lexeme_id);
    Q_INVOKABLE int languageIdFromGrammarFormId(int grammarform_id);
    Q_INVOKABLE int updateForm(int formid, int newlexeme, int newgrammarform, QString newstring, int licenseid);
    Q_INVOKABLE int updateLexeme(int lexemeid, int newlanguage, int newlicense);
    Q_INVOKABLE QList<int> searchForms(QString string, bool exact=false);
    Q_INVOKABLE QString prettyPrintSentence(int sentence_id);
    Q_INVOKABLE QString prettyPrintLexeme(int lexeme_id);
    Q_INVOKABLE QList<int> searchLexemes(QString string, bool exact=false);
    Q_INVOKABLE QList<QPair<QString,int> > listFormsOfLexeme(int lexeme_id);
    Q_INVOKABLE int languageOfLexeme(int lexeme_id);
    Q_INVOKABLE int grammarFormIdFromStrings(int language_id, QList<QList<QString> > grammarform);
    Q_INVOKABLE QList<int> searchGrammarFormsFromStrings(int language_id, QList<QList<QString> > grammarform);
private:
    QSqlDatabase vocableDatabase;
    QList < databasetable* > tables;
    QString m_version;
signals:
    void versionChanged(const QString &newVersion);
@<End of class and header @>
@}

@o ../src/database.cpp -d
@{
#include "database.h"
@}

\section{Constructor}

We set the \lstinline{QObject} parent by the constructor.

@o ../src/database.cpp -d
@{
database::database(QObject *parent) : QObject(parent)
{
@}

We try to use an Sqlite\index{Sqlite} driver and check if it is available.

@o ../src/database.cpp -d
@{
    if(!QSqlDatabase::isDriverAvailable("QSQLITE")){
        qDebug("Driver \"QSQLITE\" is not available!");
    }
@}

\index{Database!Path|(}The path of the database file is architecture dependant, for the desktop version we follow the linux convention of using a hidden directory with the programs name in the users home directory.

@o ../src/database.cpp -d
@{
#ifdef Q_OS_ANDROID
    QString dbFileName = QStandardPaths::standardLocations(QStandardPaths::AppDataLocation).at(1) + "/vocables.sqlite";
#else
    QString dbFileName = QStandardPaths::standardLocations(QStandardPaths::HomeLocation).at(0) + "/.coleitra/vocables.sqlite";
#endif
@}

If the path for the database file does not exist, we create it first.

@o ../src/database.cpp -d
@{
    {
        QFileInfo fileName(dbFileName);
        if(!QDir(fileName.absolutePath()).exists()){
            QDir().mkdir(fileName.absolutePath());
        }
    }
@}\index{Database!Path|)}

Now we can create a connection for the database and open the database file.

@o ../src/database.cpp -d
@{
    vocableDatabase = QSqlDatabase::addDatabase("QSQLITE", "vocableDatabase");
    vocableDatabase.setDatabaseName(dbFileName);
    if(!vocableDatabase.open()){
        qDebug("Could not open database file!");
    }
@}

Finally we create our tables if they don't exist already. We begin with
some helper lambda functions which are used to shorten the later
definitions and make them more easy to read.

@o ../src/database.cpp -d
@{
    {
        auto d = [this](QString name, QList<databasefield*> fields){
            databasetable* table = new databasetable(name,fields);
            tables.push_back(table);
            return table;
        };
        auto f = [](const QString& fieldname,
                QVariant::Type type){
            return new databasefield(fieldname, type);};
        auto fc = [](const QString& fieldname,
                QVariant::Type type,
                QList<QVariant*> constraints = {}){
            return new databasefield(fieldname, type, constraints);};

        auto c_nn = [](){
            QVariant* variant = new QVariant();
            variant->setValue(databasefield_constraint_not_null());
            return variant;
        };
        auto c_u = [](){
            QVariant* variant = new QVariant();
            variant->setValue(databasefield_constraint_unique());
            return variant;
        };
        auto c_pk = [](){
            QVariant* variant = new QVariant();
            variant->setValue(databasefield_constraint_primary_key());
            return variant;
        };
        auto c_fk = [](databasetable* fKT,
                QString fFN){
            QVariant* variant = new QVariant();
            variant->setValue(databasefield_constraint_foreign_key(fKT,fFN));
            return variant;
        };
@}

The database structure is versioned to be able to be downwards
compatible on an import basis. That is, a newer version of
coleitra should always be able to read an old variant of the
database and migrating it to the latest database format.

The new version is always attached, this way one can see which
was the original database version which was started with (in
case of regression errors in the migration this might be useful).

@o ../src/database.cpp -d
@{
        bool database_is_empty = false;

        databasetable* dbversiontable = d("dbversion",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("version",QVariant::String,{c_u()})});
        {
            QList<QString> selection;
            selection.push_back("id");
            selection.push_back("version");
            QSqlQuery result = dbversiontable->select(selection);
            int oldid = 0;
            while(result.next()){
                if(result.value("id").toInt() > oldid){
                    m_version = result.value("version").toString();
                }
            }
        }

        if(m_version.isEmpty()){
            m_version = "0.1";
            QMap<QString,QVariant> insert;
            insert["version"] = QVariant(m_version);
            dbversiontable->insertRecord(insert);
            database_is_empty = true;
        }
@}

License information should be kept with each datum so we allow for
possible data interchange / import / export later.

@o ../src/database.cpp -d
@{

	databasetable* licensetable = d("license",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("spdx_identifier",QVariant::String,{c_u()}),
                fc("spdx_full_name",QVariant::String,{c_u()}),
                fc("license_url",QVariant::String),
                fc("full_license_text",QVariant::String)});

        databasetable* licensereferencetable = d("licensereference",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("license",QVariant::Int,{c_fk(licensetable,"id")}),
                fc("author",QVariant::String),
                fc("publisher",QVariant::String),
                fc("url",QVariant::String)
		});
        if(database_is_empty){
            QMap<QString,QVariant> insert;
            insert["spdx_identifier"] = "CC-BY-SA-3.0";
            insert["spdx_full_name"] = "Creative Commons Attribution Share Alike 3.0 Unported";
            insert["license_url"] = "https://creativecommons.org/licenses/by-sa/3.0/legalcode";
            insert["full_license_text"] = R"license_text(Creative Commons Legal Code

Attribution-ShareAlike 3.0 Unported

    CREATIVE COMMONS CORPORATION IS NOT A LAW FIRM AND DOES NOT PROVIDE
    LEGAL SERVICES. DISTRIBUTION OF THIS LICENSE DOES NOT CREATE AN
    ATTORNEY-CLIENT RELATIONSHIP. CREATIVE COMMONS PROVIDES THIS
    INFORMATION ON AN "AS-IS" BASIS. CREATIVE COMMONS MAKES NO WARRANTIES
    REGARDING THE INFORMATION PROVIDED, AND DISCLAIMS LIABILITY FOR
    DAMAGES RESULTING FROM ITS USE.

License

THE WORK (AS DEFINED BELOW) IS PROVIDED UNDER THE TERMS OF THIS CREATIVE
COMMONS PUBLIC LICENSE ("CCPL" OR "LICENSE"). THE WORK IS PROTECTED BY
COPYRIGHT AND/OR OTHER APPLICABLE LAW. ANY USE OF THE WORK OTHER THAN AS
AUTHORIZED UNDER THIS LICENSE OR COPYRIGHT LAW IS PROHIBITED.

BY EXERCISING ANY RIGHTS TO THE WORK PROVIDED HERE, YOU ACCEPT AND AGREE
TO BE BOUND BY THE TERMS OF THIS LICENSE. TO THE EXTENT THIS LICENSE MAY
BE CONSIDERED TO BE A CONTRACT, THE LICENSOR GRANTS YOU THE RIGHTS
CONTAINED HERE IN CONSIDERATION OF YOUR ACCEPTANCE OF SUCH TERMS AND
CONDITIONS.

1. Definitions

 a. "Adaptation" means a work based upon the Work, or upon the Work and
    other pre-existing works, such as a translation, adaptation,
    derivative work, arrangement of music or other alterations of a
    literary or artistic work, or phonogram or performance and includes
    cinematographic adaptations or any other form in which the Work may be
    recast, transformed, or adapted including in any form recognizably
    derived from the original, except that a work that constitutes a
    Collection will not be considered an Adaptation for the purpose of
    this License. For the avoidance of doubt, where the Work is a musical
    work, performance or phonogram, the synchronization of the Work in
    timed-relation with a moving image ("synching") will be considered an
    Adaptation for the purpose of this License.
 b. "Collection" means a collection of literary or artistic works, such as
    encyclopedias and anthologies, or performances, phonograms or
    broadcasts, or other works or subject matter other than works listed
    in Section 1(f) below, which, by reason of the selection and
    arrangement of their contents, constitute intellectual creations, in
    which the Work is included in its entirety in unmodified form along
    with one or more other contributions, each constituting separate and
    independent works in themselves, which together are assembled into a
    collective whole. A work that constitutes a Collection will not be
    considered an Adaptation (as defined below) for the purposes of this
    License.
 c. "Creative Commons Compatible License" means a license that is listed
    at https://creativecommons.org/compatiblelicenses that has been
    approved by Creative Commons as being essentially equivalent to this
    License, including, at a minimum, because that license: (i) contains
    terms that have the same purpose, meaning and effect as the License
    Elements of this License; and, (ii) explicitly permits the relicensing
    of adaptations of works made available under that license under this
    License or a Creative Commons jurisdiction license with the same
    License Elements as this License.
 d. "Distribute" means to make available to the public the original and
    copies of the Work or Adaptation, as appropriate, through sale or
    other transfer of ownership.
 e. "License Elements" means the following high-level license attributes
    as selected by Licensor and indicated in the title of this License:
    Attribution, ShareAlike.
 f. "Licensor" means the individual, individuals, entity or entities that
    offer(s) the Work under the terms of this License.
 g. "Original Author" means, in the case of a literary or artistic work,
    the individual, individuals, entity or entities who created the Work
    or if no individual or entity can be identified, the publisher; and in
    addition (i) in the case of a performance the actors, singers,
    musicians, dancers, and other persons who act, sing, deliver, declaim,
    play in, interpret or otherwise perform literary or artistic works or
    expressions of folklore; (ii) in the case of a phonogram the producer
    being the person or legal entity who first fixes the sounds of a
    performance or other sounds; and, (iii) in the case of broadcasts, the
    organization that transmits the broadcast.
 h. "Work" means the literary and/or artistic work offered under the terms
    of this License including without limitation any production in the
    literary, scientific and artistic domain, whatever may be the mode or
    form of its expression including digital form, such as a book,
    pamphlet and other writing; a lecture, address, sermon or other work
    of the same nature; a dramatic or dramatico-musical work; a
    choreographic work or entertainment in dumb show; a musical
    composition with or without words; a cinematographic work to which are
    assimilated works expressed by a process analogous to cinematography;
    a work of drawing, painting, architecture, sculpture, engraving or
    lithography; a photographic work to which are assimilated works
    expressed by a process analogous to photography; a work of applied
    art; an illustration, map, plan, sketch or three-dimensional work
    relative to geography, topography, architecture or science; a
    performance; a broadcast; a phonogram; a compilation of data to the
    extent it is protected as a copyrightable work; or a work performed by
    a variety or circus performer to the extent it is not otherwise
    considered a literary or artistic work.
 i. "You" means an individual or entity exercising rights under this
    License who has not previously violated the terms of this License with
    respect to the Work, or who has received express permission from the
    Licensor to exercise rights under this License despite a previous
    violation.
 j. "Publicly Perform" means to perform public recitations of the Work and
    to communicate to the public those public recitations, by any means or
    process, including by wire or wireless means or public digital
    performances; to make available to the public Works in such a way that
    members of the public may access these Works from a place and at a
    place individually chosen by them; to perform the Work to the public
    by any means or process and the communication to the public of the
    performances of the Work, including by public digital performance; to
    broadcast and rebroadcast the Work by any means including signs,
    sounds or images.
 k. "Reproduce" means to make copies of the Work by any means including
    without limitation by sound or visual recordings and the right of
    fixation and reproducing fixations of the Work, including storage of a
    protected performance or phonogram in digital form or other electronic
    medium.

2. Fair Dealing Rights. Nothing in this License is intended to reduce,
limit, or restrict any uses free from copyright or rights arising from
limitations or exceptions that are provided for in connection with the
copyright protection under copyright law or other applicable laws.

3. License Grant. Subject to the terms and conditions of this License,
Licensor hereby grants You a worldwide, royalty-free, non-exclusive,
perpetual (for the duration of the applicable copyright) license to
exercise the rights in the Work as stated below:

 a. to Reproduce the Work, to incorporate the Work into one or more
    Collections, and to Reproduce the Work as incorporated in the
    Collections;
 b. to create and Reproduce Adaptations provided that any such Adaptation,
    including any translation in any medium, takes reasonable steps to
    clearly label, demarcate or otherwise identify that changes were made
    to the original Work. For example, a translation could be marked "The
    original work was translated from English to Spanish," or a
    modification could indicate "The original work has been modified.";
 c. to Distribute and Publicly Perform the Work including as incorporated
    in Collections; and,
 d. to Distribute and Publicly Perform Adaptations.
 e. For the avoidance of doubt:

     i. Non-waivable Compulsory License Schemes. In those jurisdictions in
        which the right to collect royalties through any statutory or
        compulsory licensing scheme cannot be waived, the Licensor
        reserves the exclusive right to collect such royalties for any
        exercise by You of the rights granted under this License;
    ii. Waivable Compulsory License Schemes. In those jurisdictions in
        which the right to collect royalties through any statutory or
        compulsory licensing scheme can be waived, the Licensor waives the
        exclusive right to collect such royalties for any exercise by You
        of the rights granted under this License; and,
   iii. Voluntary License Schemes. The Licensor waives the right to
        collect royalties, whether individually or, in the event that the
        Licensor is a member of a collecting society that administers
        voluntary licensing schemes, via that society, from any exercise
        by You of the rights granted under this License.

The above rights may be exercised in all media and formats whether now
known or hereafter devised. The above rights include the right to make
such modifications as are technically necessary to exercise the rights in
other media and formats. Subject to Section 8(f), all rights not expressly
granted by Licensor are hereby reserved.

4. Restrictions. The license granted in Section 3 above is expressly made
subject to and limited by the following restrictions:

 a. You may Distribute or Publicly Perform the Work only under the terms
    of this License. You must include a copy of, or the Uniform Resource
    Identifier (URI) for, this License with every copy of the Work You
    Distribute or Publicly Perform. You may not offer or impose any terms
    on the Work that restrict the terms of this License or the ability of
    the recipient of the Work to exercise the rights granted to that
    recipient under the terms of the License. You may not sublicense the
    Work. You must keep intact all notices that refer to this License and
    to the disclaimer of warranties with every copy of the Work You
    Distribute or Publicly Perform. When You Distribute or Publicly
    Perform the Work, You may not impose any effective technological
    measures on the Work that restrict the ability of a recipient of the
    Work from You to exercise the rights granted to that recipient under
    the terms of the License. This Section 4(a) applies to the Work as
    incorporated in a Collection, but this does not require the Collection
    apart from the Work itself to be made subject to the terms of this
    License. If You create a Collection, upon notice from any Licensor You
    must, to the extent practicable, remove from the Collection any credit
    as required by Section 4(c), as requested. If You create an
    Adaptation, upon notice from any Licensor You must, to the extent
    practicable, remove from the Adaptation any credit as required by
    Section 4(c), as requested.
 b. You may Distribute or Publicly Perform an Adaptation only under the
    terms of: (i) this License; (ii) a later version of this License with
    the same License Elements as this License; (iii) a Creative Commons
    jurisdiction license (either this or a later license version) that
    contains the same License Elements as this License (e.g.,
    Attribution-ShareAlike 3.0 US)); (iv) a Creative Commons Compatible
    License. If you license the Adaptation under one of the licenses
    mentioned in (iv), you must comply with the terms of that license. If
    you license the Adaptation under the terms of any of the licenses
    mentioned in (i), (ii) or (iii) (the "Applicable License"), you must
    comply with the terms of the Applicable License generally and the
    following provisions: (I) You must include a copy of, or the URI for,
    the Applicable License with every copy of each Adaptation You
    Distribute or Publicly Perform; (II) You may not offer or impose any
    terms on the Adaptation that restrict the terms of the Applicable
    License or the ability of the recipient of the Adaptation to exercise
    the rights granted to that recipient under the terms of the Applicable
    License; (III) You must keep intact all notices that refer to the
    Applicable License and to the disclaimer of warranties with every copy
    of the Work as included in the Adaptation You Distribute or Publicly
    Perform; (IV) when You Distribute or Publicly Perform the Adaptation,
    You may not impose any effective technological measures on the
    Adaptation that restrict the ability of a recipient of the Adaptation
    from You to exercise the rights granted to that recipient under the
    terms of the Applicable License. This Section 4(b) applies to the
    Adaptation as incorporated in a Collection, but this does not require
    the Collection apart from the Adaptation itself to be made subject to
    the terms of the Applicable License.
 c. If You Distribute, or Publicly Perform the Work or any Adaptations or
    Collections, You must, unless a request has been made pursuant to
    Section 4(a), keep intact all copyright notices for the Work and
    provide, reasonable to the medium or means You are utilizing: (i) the
    name of the Original Author (or pseudonym, if applicable) if supplied,
    and/or if the Original Author and/or Licensor designate another party
    or parties (e.g., a sponsor institute, publishing entity, journal) for
    attribution ("Attribution Parties") in Licensor's copyright notice,
    terms of service or by other reasonable means, the name of such party
    or parties; (ii) the title of the Work if supplied; (iii) to the
    extent reasonably practicable, the URI, if any, that Licensor
    specifies to be associated with the Work, unless such URI does not
    refer to the copyright notice or licensing information for the Work;
    and (iv) , consistent with Ssection 3(b), in the case of an
    Adaptation, a credit identifying the use of the Work in the Adaptation
    (e.g., "French translation of the Work by Original Author," or
    "Screenplay based on original Work by Original Author"). The credit
    required by this Section 4(c) may be implemented in any reasonable
    manner; provided, however, that in the case of a Adaptation or
    Collection, at a minimum such credit will appear, if a credit for all
    contributing authors of the Adaptation or Collection appears, then as
    part of these credits and in a manner at least as prominent as the
    credits for the other contributing authors. For the avoidance of
    doubt, You may only use the credit required by this Section for the
    purpose of attribution in the manner set out above and, by exercising
    Your rights under this License, You may not implicitly or explicitly
    assert or imply any connection with, sponsorship or endorsement by the
    Original Author, Licensor and/or Attribution Parties, as appropriate,
    of You or Your use of the Work, without the separate, express prior
    written permission of the Original Author, Licensor and/or Attribution
    Parties.
 d. Except as otherwise agreed in writing by the Licensor or as may be
    otherwise permitted by applicable law, if You Reproduce, Distribute or
    Publicly Perform the Work either by itself or as part of any
    Adaptations or Collections, You must not distort, mutilate, modify or
    take other derogatory action in relation to the Work which would be
    prejudicial to the Original Author's honor or reputation. Licensor
    agrees that in those jurisdictions (e.g. Japan), in which any exercise
    of the right granted in Section 3(b) of this License (the right to
    make Adaptations) would be deemed to be a distortion, mutilation,
    modification or other derogatory action prejudicial to the Original
    Author's honor and reputation, the Licensor will waive or not assert,
    as appropriate, this Section, to the fullest extent permitted by the
    applicable national law, to enable You to reasonably exercise Your
    right under Section 3(b) of this License (right to make Adaptations)
    but not otherwise.

5. Representations, Warranties and Disclaimer

UNLESS OTHERWISE MUTUALLY AGREED TO BY THE PARTIES IN WRITING, LICENSOR
OFFERS THE WORK AS-IS AND MAKES NO REPRESENTATIONS OR WARRANTIES OF ANY
KIND CONCERNING THE WORK, EXPRESS, IMPLIED, STATUTORY OR OTHERWISE,
INCLUDING, WITHOUT LIMITATION, WARRANTIES OF TITLE, MERCHANTIBILITY,
FITNESS FOR A PARTICULAR PURPOSE, NONINFRINGEMENT, OR THE ABSENCE OF
LATENT OR OTHER DEFECTS, ACCURACY, OR THE PRESENCE OF ABSENCE OF ERRORS,
WHETHER OR NOT DISCOVERABLE. SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION
OF IMPLIED WARRANTIES, SO SUCH EXCLUSION MAY NOT APPLY TO YOU.

6. Limitation on Liability. EXCEPT TO THE EXTENT REQUIRED BY APPLICABLE
LAW, IN NO EVENT WILL LICENSOR BE LIABLE TO YOU ON ANY LEGAL THEORY FOR
ANY SPECIAL, INCIDENTAL, CONSEQUENTIAL, PUNITIVE OR EXEMPLARY DAMAGES
ARISING OUT OF THIS LICENSE OR THE USE OF THE WORK, EVEN IF LICENSOR HAS
BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

7. Termination

 a. This License and the rights granted hereunder will terminate
    automatically upon any breach by You of the terms of this License.
    Individuals or entities who have received Adaptations or Collections
    from You under this License, however, will not have their licenses
    terminated provided such individuals or entities remain in full
    compliance with those licenses. Sections 1, 2, 5, 6, 7, and 8 will
    survive any termination of this License.
 b. Subject to the above terms and conditions, the license granted here is
    perpetual (for the duration of the applicable copyright in the Work).
    Notwithstanding the above, Licensor reserves the right to release the
    Work under different license terms or to stop distributing the Work at
    any time; provided, however that any such election will not serve to
    withdraw this License (or any other license that has been, or is
    required to be, granted under the terms of this License), and this
    License will continue in full force and effect unless terminated as
    stated above.

8. Miscellaneous

 a. Each time You Distribute or Publicly Perform the Work or a Collection,
    the Licensor offers to the recipient a license to the Work on the same
    terms and conditions as the license granted to You under this License.
 b. Each time You Distribute or Publicly Perform an Adaptation, Licensor
    offers to the recipient a license to the original Work on the same
    terms and conditions as the license granted to You under this License.
 c. If any provision of this License is invalid or unenforceable under
    applicable law, it shall not affect the validity or enforceability of
    the remainder of the terms of this License, and without further action
    by the parties to this agreement, such provision shall be reformed to
    the minimum extent necessary to make such provision valid and
    enforceable.
 d. No term or provision of this License shall be deemed waived and no
    breach consented to unless such waiver or consent shall be in writing
    and signed by the party to be charged with such waiver or consent.
 e. This License constitutes the entire agreement between the parties with
    respect to the Work licensed here. There are no understandings,
    agreements or representations with respect to the Work not specified
    here. Licensor shall not be bound by any additional provisions that
    may appear in any communication from You. This License may not be
    modified without the mutual written agreement of the Licensor and You.
 f. The rights granted under, and the subject matter referenced, in this
    License were drafted utilizing the terminology of the Berne Convention
    for the Protection of Literary and Artistic Works (as amended on
    September 28, 1979), the Rome Convention of 1961, the WIPO Copyright
    Treaty of 1996, the WIPO Performances and Phonograms Treaty of 1996
    and the Universal Copyright Convention (as revised on July 24, 1971).
    These rights and subject matter take effect in the relevant
    jurisdiction in which the License terms are sought to be enforced
    according to the corresponding provisions of the implementation of
    those treaty provisions in the applicable national law. If the
    standard suite of rights granted under applicable copyright law
    includes additional rights not granted under this License, such
    additional rights are deemed to be included in the License; this
    License is not intended to restrict the license of any rights under
    applicable law.


Creative Commons Notice

    Creative Commons is not a party to this License, and makes no warranty
    whatsoever in connection with the Work. Creative Commons will not be
    liable to You or any party on any legal theory for any damages
    whatsoever, including without limitation any general, special,
    incidental or consequential damages arising in connection to this
    license. Notwithstanding the foregoing two (2) sentences, if Creative
    Commons has expressly identified itself as the Licensor hereunder, it
    shall have all rights and obligations of Licensor.

    Except for the limited purpose of indicating to the public that the
    Work is licensed under the CCPL, Creative Commons does not authorize
    the use by either party of the trademark "Creative Commons" or any
    related trademark or logo of Creative Commons without the prior
    written consent of Creative Commons. Any permitted use will be in
    compliance with Creative Commons' then-current trademark usage
    guidelines, as may be published on its website or otherwise made
    available upon request from time to time. For the avoidance of doubt,
    this trademark restriction does not form part of the License.

    Creative Commons may be contacted at https://creativecommons.org/.
)license_text";
                licensetable->insertRecord(insert);

                QMap<QString,QVariant> insert_ref;
                insert_ref["license"] = 1;
                insert_ref["author"] = "Wiktionary contributors";
                insert_ref["publisher"] = "Wiktionary, The Free Dictionary.";
                insert_ref["url"] = "https://en.wiktionary.org";
                licensereferencetable->insertRecord(insert_ref);

                QMap<QString,QVariant> insert_ref2;
                insert_ref2["license"] = 1;
                insert_ref2["author"] = "Coleitra developers";
                insert_ref2["publisher"] = "Coleitra";
                insert_ref2["url"] = "https://coleitra.org";
                licensereferencetable->insertRecord(insert_ref2);
        }
@}

Categories are not used currently but we add them in case we need them
later.

@o ../src/database.cpp -d
@{

	databasetable* categorytable = d("category",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("name",QVariant::String,{c_u()})});
        databasetable* categoryselectiontable = d("categoryselection",
                {fc("id",QVariant::Int,{c_pk(),c_nn()})});
        databasetable* categoryselectionparttable = d("categoryselectionpart",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("category",QVariant::Int,{c_fk(categorytable,"id")})});
@}

This language selection covers the mostly spoken languages plus the
languages spoken in the european union. In the beginning the program
will have a bias towards western europe languages as the programmer
is living there and learning these languages but this will hopefully
be more balanced over time.

The aim of the program is to be as useful as possible to
languagelearners of any language.

Locale should be an ISO code that QtLocale understands to be able to
use the speech synthesizer with this code.

@o ../src/database.cpp -d
@{
        databasetable* languagetable = d("language",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("licensereference",QVariant::Int,{c_fk(licensereferencetable,"id")}),
                fc("locale",QVariant::String,{c_u()})});
        databasetable* languagenametable = d("languagename",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("language",QVariant::Int,{c_fk(languagetable,"id")}),
                f("name",QVariant::String),
                fc("nameisinlanguage",QVariant::Int,{c_fk(languagetable,"id")})});
        if(database_is_empty){
            QMap<QString,QVariant> add_language;
            QMap<QString,QVariant> add_language_name;
            QList< QList< QString> > languages = {
                {"cmn","Mandarin Chinese"},
                {"hi","Hindi"},
                {"es","Spanish"},
                {"fr","French"},
                {"arb","Standard Arabic"},
                {"bn","Bengali"},
                {"ru","Russian"},
                {"pt","Portuguese"},
                {"id","Indonesian"},
                {"ur","Urdu"},
                {"de","German"},
                {"ja","Japanese"},
                {"sw","Swahili"},
                {"mr","Marathi"},
                {"te","Telugu"},
                {"tr","Turkish"},
                {"yue","Yue Chinese"},
                {"ta","Tamil"},
                {"pa","Punjabi"},
                {"wuu","Wu Chinese"},
                {"ko","Korean"},
                {"vi","Vietnamese"},
                {"ha","Hausa"},
                {"jv","Javanese"},
                {"arz","Egyptian Arabic"},
                {"it","Italian"},
                {"th","Thai"},
                {"gu","Gujarati"},
                {"kn","Kannada"},
                {"fa","Persian"},
                {"bho","Bhojpuri"},
                {"nan","Southern Min"},
                {"fil","Filipino"},
                {"nl","Dutch"},
                {"da","Danish"},
                {"el","Greek"},
                {"fi","Finnish"},
                {"sv","Swedish"},
                {"cs","Czech"},
                {"et","Estonian"},
                {"hu","Hungarian"},
                {"lv","Latvian"},
                {"lt","Lithuanian"},
                {"mt","Maltese"},
                {"pl","Polish"},
                {"sk","Slovak"},
                {"sl","Slovene"},
                {"bg","Bulgarian"},
                {"ga","Irish"},
                {"ro","Romanian"},
                {"hr","Croatian"}
            };
            add_language["locale"] = QVariant("en");
            int en_id = languagetable->insertRecord(add_language);
            add_language_name["language"] = QVariant(en_id);
            add_language_name["name"] = QVariant("English");
            add_language_name["nameisinlanguage"] = QVariant(en_id);
            languagenametable->insertRecord(add_language_name);
            QList<QString> language;
            foreach(language, languages){
                add_language["locale"] = QVariant(language.first());
                int language_id = languagetable->insertRecord(add_language);
                add_language_name["language"] = QVariant(language_id);
                add_language_name["name"] = QVariant(language.last());
                add_language_name["nameisinlanguage"] = QVariant(en_id);
                languagenametable->insertRecord(add_language_name);
            }
        }
@}

Here is where it gets tricky. I define a lexeme as a unit which
possesses a meaning. This can consist of one or more words and it can
have multiple grammatical forms. Different lexemes can have the same
grammar form. A one word lexeme in one language can correspond to a
multiple word lexeme in a different language.


@o ../src/database.cpp -d
@{
        databasetable* lexemetable = d("lexeme",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("licensereference",QVariant::Int,{c_fk(licensereferencetable,"id")}),
                fc("language",QVariant::Int,{c_fk(languagetable,"id")})});

        databasetable* grammarkeytable = d("grammarkey",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("licensereference",QVariant::Int,{c_fk(licensereferencetable,"id")}),
                f("string",QVariant::String)});

        databasetable* grammarexpressiontable = d("grammarexpression",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("licensereference",QVariant::Int,{c_fk(licensereferencetable,"id")}),
                fc("key",QVariant::Int,{c_fk(grammarkeytable,"id")}),
                f("value",QVariant::String)});

        if(database_is_empty){
            QList<QList<QString> > grammarexpressions = {
                // Case
                {"Case", "Ablative", "Accusative", "Abessive", "Adessive", "Allative", "Causal-final", "Comitative", "Dative", "Delative", "Elative", "Essive", "Genitive", "Illative", "Inessive", "Infinitive", "Instructive", "Instrumental", "Locative", "Nominative", "Partitive", "Possessive", "Prolative", "Sociative", "Sublative", "Superessive", "Terminative", "Translative", "Vocative"},
                // Voice
                {"Voice","Active", "Passive"},
                // Gender
                {"Gender","Feminine", "Masculine", "Neuter"},
                // Number
                {"Number","Singular", "Plural"},
                // Tense
                {"Tense", "Future", "Future 1", "Future 2", "Past", "Perfect", "Plusquamperfect", "Present", "Preterite", "Agent"},
                // Mood
                {"Mood", "Imperative", "Indicative", "Potential", "Subjunctive", "Subjunctive 1", "Subjunctive 2", "Optative"},
                // Part of speech
                {"Part of speech", "Noun", "Verb", "Adjective", "Adverb", "Pronoun", "Preposition", "Conjunction", "Interjection", "Numeral", "Article", "Determiner", "Postposition"},
                // Person
                {"Person","First","Second","Third"},
                // Polarity
                {"Polarity", "Negative", "Positive"},
                // Infinitive
                {"Infinitive", "First", "Long first", "Second", "Third", "Fourth", "Fifth"},
                // Verbform
                {"Verbform", "Participle", "Auxiliary", "Connegative"},
            };
            QMap<QString,QVariant> add_ge;
            QMap<QString,QVariant> add_gk;
            QList<QString> grammarexpression;
            int current_key_id = 0;
            foreach(grammarexpression, grammarexpressions){
                current_key_id = 0;
                foreach(const QString& grammarvalue, grammarexpression){
                    if(current_key_id == 0){
                        add_gk["string"] = grammarvalue;
                        current_key_id = grammarkeytable->insertRecord(add_gk);
                    }
                    else{
                        add_ge["key"] = current_key_id;
                        add_ge["value"] = grammarvalue;
                        grammarexpressiontable->insertRecord(add_ge);
                    }
                }
            }
        }

        databasetable* grammarformtable = d("grammarform",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("language",QVariant::Int,{c_fk(languagetable,"id")}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("licensereference",QVariant::Int,{c_fk(licensereferencetable,"id")})});
        databasetable* grammarformcomponenttable = d("grammarformcomponent",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("licensereference",QVariant::Int,{c_fk(licensereferencetable,"id")}),
                fc("grammarform",QVariant::Int,{c_fk(grammarformtable,"id")}),
                fc("grammarexpression",QVariant::Int,{c_fk(grammarexpressiontable,"id")})});

        databasetable* formtable = d("form",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("licensereference",QVariant::Int,{c_fk(licensereferencetable,"id")}),
                fc("lexeme",QVariant::Int,{c_fk(lexemetable,"id")}),
                fc("grammarform",QVariant::Int,{c_fk(grammarformtable,"id")}),
                f("string",QVariant::String)});
@}

We need to add certain entries to the database to support the finnish
help verbs.

@o ../src/database.cpp -d
@{
        if(database_is_empty){
            struct newform{
                QString form;
                QList<QList<QString> > grammarform;
            };
            QList<newform> fi_negation_verb_forms = {
                {"en",{{"Mood","Indicative"},{"Number","Singular"},{"Person","First"}}},
                {"et",{{"Mood","Indicative"},{"Number","Singular"},{"Person","Second"}}},
                {"ei",{{"Mood","Indicative"},{"Number","Singular"},{"Person","Third"}}},
                {"emme",{{"Mood","Indicative"},{"Number","Plural"},{"Person","First"}}},
                {"ette",{{"Mood","Indicative"},{"Number","Plural"},{"Person","Second"}}},
                {"eivät",{{"Mood","Indicative"},{"Number","Plural"},{"Person","Third"}}},

                {"älkääni",{{"Mood","Imperative"},{"Number","Singular"},{"Person","First"}}},
                {"älkäämi",{{"Mood","Imperative"},{"Number","Singular"},{"Person","First"}}},
                {"älä",{{"Mood","Imperative"},{"Number","Singular"},{"Person","Second"}}},
                {"älköön",{{"Mood","Imperative"},{"Number","Singular"},{"Person","Third"}}},
                {"älkäämme",{{"Mood","Imperative"},{"Number","Plural"},{"Person","First"}}},
                {"älkää",{{"Mood","Imperative"},{"Number","Plural"},{"Person","Second"}}},
                {"älkööt",{{"Mood","Imperative"},{"Number","Plural"},{"Person","Third"}}},

                {"ällön",{{"Mood","Optative"},{"Number","Singular"},{"Person","First"}}},
                {"ällös",{{"Mood","Optative"},{"Number","Singular"},{"Person","Second"}}},
                {"älköön",{{"Mood","Optative"},{"Number","Singular"},{"Person","Third"}}},
                {"älköömme",{{"Mood","Optative"},{"Number","Plural"},{"Person","First"}}},
                {"älköötte",{{"Mood","Optative"},{"Number","Plural"},{"Person","Second"}}},
                {"älkööt",{{"Mood","Optative"},{"Number","Plural"},{"Person","Third"}}},
            };
            // Check if finnish exists in database:
            int fi_id = idfromlanguagename("Finnish");
            // Create lexeme for negation verb:
            int lexeme_id = newLexeme(fi_id,2);
            foreach(const struct newform& fi_negation_verb_form, fi_negation_verb_forms){
                QList<QList<QString> > grammarform = fi_negation_verb_form.grammarform;
                grammarform.push_back({"Part of speech","Verb"});
                int grammarform_id = grammarFormIdFromStrings(fi_id, grammarform);
                newForm(lexeme_id, grammarform_id, fi_negation_verb_form.form,2);
            }
        }
@}

We need to add also some german forms to bootstrap it.

@o ../src/database.cpp -d
@{
        if(database_is_empty){
            struct newform{
                QString form;
                QList<QList<QString> > grammarform;
            };
            QList<newform> de_werden_verb_forms = {
                {"werden",{{"Infinitive","First"}}},
                {"werdend",{{"Verbform","Participle"},{"Tense","Present"}}},
                {"geworden",{{"Verbform","Participle"},{"Tense","Past"}}},
                {"worden",{{"Verbform","Participle"},{"Tense","Past"}}},
                {"sein",{{"Verbform","Auxiliary"}}},
                {"werde",{{"Mood","Indicative"},{"Tense","Present"},{"Person","First"},{"Number","Singular"}}},
                {"werden",{{"Mood","Indicative"},{"Tense","Present"},{"Person","First"},{"Number","Plural"}}},
                {"werde",{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","First"},{"Number","Singular"}}},
                {"werden",{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","First"},{"Number","Plural"}}},
                {"wirst",{{"Mood","Indicative"},{"Tense","Present"},{"Person","Second"},{"Number","Singular"}}},
                {"werdet",{{"Mood","Indicative"},{"Tense","Present"},{"Person","Second"},{"Number","Plural"}}},
                {"werdest",{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","Second"},{"Number","Singular"}}},
                {"werdet",{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","Second"},{"Number","Plural"}}},
                {"wird",{{"Mood","Indicative"},{"Tense","Present"},{"Person","Third"},{"Number","Singular"}}},
                {"werden",{{"Mood","Indicative"},{"Tense","Present"},{"Person","Third"},{"Number","Plural"}}},
                {"werde",{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","Third"},{"Number","Singular"}}},
                {"werden",{{"Mood","Subjunctive 1"},{"Tense","Present"},{"Person","Third"},{"Number","Plural"}}},
                {"wurde",{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","First"},{"Number","Singular"}}},
                {"ward",{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","First"},{"Number","Singular"}}},
                {"wurden",{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","First"},{"Number","Plural"}}},
                {"würde",{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","First"},{"Number","Singular"}}},
                {"würden",{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","First"},{"Number","Plural"}}},
                {"wurdest",{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","Second"},{"Number","Singular"}}},
                {"wardst",{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","Second"},{"Number","Singular"}}},
                {"wurdet",{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","Second"},{"Number","Plural"}}},
                {"würdest",{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","Second"},{"Number","Singular"}}},
                {"würdet",{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","Second"},{"Number","Plural"}}},
                {"wurde",{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","Third"},{"Number","Singular"}}},
                {"ward",{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","Third"},{"Number","Singular"}}},
                {"wurden",{{"Mood","Indicative"},{"Tense","Preterite"},{"Person","Third"},{"Number","Plural"}}},
                {"würde",{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","Third"},{"Number","Singular"}}},
                {"würden",{{"Mood","Subjunctive 2"},{"Tense","Preterite"},{"Person","Third"},{"Number","Plural"}}},
                {"werd",{{"Mood","Imperative"},{"Person","Second"},{"Number","Singular"}}},
                {"werde",{{"Mood","Imperative"},{"Person","Second"},{"Number","Singular"}}},
                {"werdet",{{"Mood","Imperative"},{"Person","Second"},{"Number","Plural"}}},
            };
            // Check if finnish exists in database:
            int de_id = idfromlanguagename("German");
            // Create lexeme for negation verb:
            int lexeme_id = newLexeme(de_id,2);
            foreach(const struct newform& de_werden_verb_form, de_werden_verb_forms){
                QList<QList<QString> > grammarform = de_werden_verb_form.grammarform;
                grammarform.push_back({"Part of speech","Verb"});
                int grammarform_id = grammarFormIdFromStrings(de_id, grammarform);
                newForm(lexeme_id, grammarform_id, de_werden_verb_form.form,2);
            }
        }
@}

@o ../src/database.cpp -d
@{
        databasetable* compoundformparttable = d("compoundformpart",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("licensereference",QVariant::Int,{c_fk(licensereferencetable,"id")}),
                f("capitalized",QVariant::Bool),
                f("string",QVariant::String),
                f("part",QVariant::Int),
                fc("compoundform",QVariant::Int,{c_fk(formtable,"id")}),
                fc("form",QVariant::Int,{c_fk(formtable,"id")})});

        databasetable* sentencetable = d("sentence",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("lexeme",QVariant::Int,{c_fk(lexemetable,"id")}),
                fc("grammarform",QVariant::Int,{c_fk(grammarformtable,"id")}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("licensereference",QVariant::Int,{c_fk(licensereferencetable,"id")})});
        databasetable* punctuationmarktable = d("punctuationmark",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("licensereference",QVariant::Int,{c_fk(licensereferencetable,"id")}),
                f("string",QVariant::String)});
        databasetable* sentenceparttable = d("sentencepart",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("licensereference",QVariant::Int,{c_fk(licensereferencetable,"id")}),
                fc("sentence",QVariant::Int,{c_fk(sentencetable,"id")}),
                f("part",QVariant::Int),
                f("capitalized",QVariant::Bool),
                fc("form",QVariant::Int,{c_fk(formtable,"id")}),
                fc("grammarform",QVariant::Int,{c_fk(grammarformtable,"id")}),
                fc("punctuationmark",QVariant::Int,{c_fk(punctuationmarktable,"id")})});

        databasetable* translationtable = d("translation",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("licensereference",QVariant::Int,{c_fk(licensereferencetable,"id")}),
                });

        databasetable* translationparttable = d("translationpart",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("licensereference",QVariant::Int,{c_fk(licensereferencetable,"id")}),
                fc("translation",QVariant::Int,{c_fk(translationtable,"id")}),
                fc("lexeme",QVariant::Int,{c_fk(lexemetable,"id")}),
                fc("sentence",QVariant::Int,{c_fk(sentencetable,"id")}),
                fc("form",QVariant::Int,{c_fk(formtable,"id")}),
                fc("grammarform",QVariant::Int,{c_fk(grammarformtable,"id")}),
                });

        databasetable* programminglanguagetable = d("programminglanguage",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("licensereference",QVariant::Int,{c_fk(licensereferencetable,"id")}),
                f("language",QVariant::String)});

        databasetable* trainingmodetable = d("trainingmode",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("programminglanguage",QVariant::Int,{c_fk(programminglanguagetable,"id")}),
                fc("description",QVariant::String,{c_u()}),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("licensereference",QVariant::Int,{c_fk(licensereferencetable,"id")}),
                f("code",QVariant::String),
                });

        databasetable* trainingidtable = d("trainingid",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                });
        databasetable* trainingdatumtable = d("trainingdatum",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("trainingmode",QVariant::Int,{c_fk(trainingmodetable,"id")}),
                fc("trainingid",QVariant::Int,{c_fk(trainingidtable,"id")}),
                f("timestamp_shown",QVariant::Int),
                f("timestamp_answered",QVariant::Int),
                f("knowledgesteps",QVariant::Int),
                f("knowledge",QVariant::Double),
                fc("categoryselection",QVariant::Int,{c_fk(categoryselectiontable,"id")}),
                fc("licensereference",QVariant::Int,{c_fk(licensereferencetable,"id")}),
                });
        databasetable* trainingaffecteddatatable = d("trainingaffecteddata",
                {fc("id",QVariant::Int,{c_pk(),c_nn()}),
                fc("trainingdatum",QVariant::Int,{c_fk(trainingdatumtable,"id")}),
                fc("lexeme",QVariant::Int,{c_fk(lexemetable,"id")}),
                fc("grammarform",QVariant::Int,{c_fk(grammarformtable,"id")})});

    }
}

databasetable* database::getTableByName(QString name){
    foreach(databasetable* table, tables){
        if(table->name() == name) return table;
    }
    return nullptr;
}

QStringList database::languagenames()
{
    databasetable* languagenametable = getTableByName("languagename");

    QList<QString> selection;
    selection.push_back("name");
    QSqlQuery result = languagenametable->select(selection, qMakePair(QString("nameisinlanguage"),QVariant(1)));

    QStringList languages;
    while(result.next()){
        QString language = result.value("name").toString();
        languages.push_back(language);
    }
    languages.sort();
    return languages;
}

QStringList database::grammarkeys(){
    databasetable* grammarkeytable = getTableByName("grammarkey");
    QList<QString> selection;
    selection.push_back("string");
    QSqlQuery result = grammarkeytable->select(selection);
    QStringList grammarexpressions;
    while(result.next()){
        QString key = result.value("string").toString();
        grammarexpressions.push_back(key);
    }
    return grammarexpressions;
}

int database::idfromgrammarkey(QString key){
    databasetable* grammarkeytable = getTableByName("grammarkey");
    QList<QString> selection;
    selection.push_back("id");
    QList< QPair< QString, QVariant > > wheres;
    wheres.push_back(qMakePair(QString("string"),QVariant(key)));
    QSqlQuery result = grammarkeytable->select(selection, wheres);
    if(!result.next()) throw sql_error::select_empty;
    return result.value("id").toInt();
}

QStringList database::grammarvalues(QString key){
    QStringList grammarvalues;
    if(key.isEmpty()){
        return grammarvalues;
    }
    int key_id = idfromgrammarkey(key);
    databasetable* grammarexpressiontable = getTableByName("grammarexpression");
    QList<QString> selection;
    selection.push_back("value");
    QList< QPair< QString, QVariant > > wheres;
    wheres.push_back(qMakePair(QString("key"),QVariant(key_id)));
    QSqlQuery result = grammarexpressiontable->select(selection, wheres);
    while(result.next()){
        QString value = result.value("value").toString();
        grammarvalues.push_back(value);
    }
    return grammarvalues;
}

int database::alphabeticidfromlanguagename(QString languagename){
    int index=0;
    foreach(const QString& test_languagename, languagenames()){
        if(test_languagename == languagename) return index;
        index++;
    }
    return index;
}

int database::alphabeticidfromlanguageid(int languageid){
    return alphabeticidfromlanguagename(languagenamefromid(languageid));
}

int database::newTranslation(void){
    databasetable* translationtable = getTableByName("translation");
    QMap<QString,QVariant> add_translation;
    return translationtable->insertRecord(add_translation);
}

int database::newTranslationPart(int translation, int lexeme, int sentence, int form, int grammarform){
    databasetable* translationparttable = getTableByName("translationpart");
    QMap<QString,QVariant> add_translationpart;
    add_translationpart["translation"] = translation;
    add_translationpart["lexeme"] = lexeme;
    add_translationpart["sentence"] = sentence;
    add_translationpart["form"] = form;
    add_translationpart["grammarform"] = grammarform;
    return translationparttable->insertRecord(add_translationpart);
}

QList<int> database::translationLexemePartsFromTranslationId(int translation){
    QList<int> lexeme_ids;
    if(translation==0) return lexeme_ids;
    databasetable* translationparttable = getTableByName("translationpart");
    QSqlQuery result = translationparttable->select({"lexeme"},{"translation",translation});
    while(result.next())
        lexeme_ids += result.value("lexeme").toInt();
    return lexeme_ids;
}

int database::newLexeme(int language_id, int license_id){
    databasetable* lexemetable = getTableByName("lexeme");
    QMap<QString,QVariant> add_lexeme;
    add_lexeme["language"] = language_id;
    add_lexeme["licensereference"] = license_id;
    return lexemetable->insertRecord(add_lexeme);
}

int database::newForm(int lexeme_id, int grammarFormId, QString string, int license_id){
    databasetable* formtable = getTableByName("form");
    QMap<QString,QVariant> add_form;
    add_form["lexeme"] = lexeme_id;
    add_form["grammarform"] = grammarFormId;
    add_form["string"] = string;
    add_form["licensereference"] = license_id;
    return formtable->insertRecord(add_form);
}

int database::newSentence(int lexeme_id, int grammarFormId, int license_id){
    databasetable* sentencetable = getTableByName("sentence");
    QMap<QString,QVariant> add_sentence;
    add_sentence["lexeme"] = lexeme_id;
    add_sentence["grammarform"] = grammarFormId;
    add_sentence["licensereference"] = license_id;
    return sentencetable->insertRecord(add_sentence);
}

int database::newSentencePart(int sentence, int part, int capitalized, int form, int grammarform, int punctuationmark){
    databasetable* sentenceparttable = getTableByName("sentencepart");
    QMap<QString,QVariant> add_sentencepart;
    add_sentencepart["sentence"] = sentence;
    add_sentencepart["part"] = part;
    add_sentencepart["capitalized"] = capitalized;
    add_sentencepart["form"] = form;
    add_sentencepart["grammarform"] = grammarform;
    add_sentencepart["punctuationmark"] = punctuationmark;
    return sentenceparttable->insertRecord(add_sentencepart);
}

int database::newCompoundFormPart(int compoundform, int part, int form, bool capitalized, QString string){
    databasetable* compoundformparttable = getTableByName("compoundformpart");
    QMap<QString,QVariant> add_compoundformpart;
    add_compoundformpart["part"] = part;
    add_compoundformpart["compoundform"] = compoundform;
    add_compoundformpart["form"] = form;
    add_compoundformpart["capitalized"] = capitalized;
    add_compoundformpart["string"] = string;
    return compoundformparttable->insertRecord(add_compoundformpart);
}

QString database::prettyPrintTranslation(int translation_id){
    //qDebug() << __FILE__ << __FUNCTION__ << __LINE__ << translation_id;
    if(translation_id == 0) return "";
    databasetable* translationparttable = getTableByName("translationpart");
    QSqlQuery result = translationparttable->select({"lexeme","sentence","form","grammarform"},{"translation",translation_id});
    QString pretty_string;
    while(result.next()){
        int lexeme_id = result.value("lexeme").toInt();
        int sentence_id = result.value("sentence").toInt();
        int form_id = result.value("form").toInt();
        int grammarform_id = result.value("grammarform").toInt();
        if(lexeme_id!=0)
            pretty_string += prettyPrintLexeme(lexeme_id) + "<br />";
        if(sentence_id!=0)
            pretty_string += prettyPrintSentence(sentence_id) + "<br />";
        if(form_id!=0)
            pretty_string += prettyPrintForm(form_id) + "<br />";
        if(grammarform_id!=0)
            pretty_string += prettyPrintGrammarForm(grammarform_id) + "<br />";
    }
    pretty_string.chop(6);
    return pretty_string;
}

QString database::prettyPrintGrammarForm(int grammarForm_id){
    QString prettystring;
    databasetable* grammarformcomponenttable = getTableByName("grammarformcomponent");
    databasetable* grammarexpressiontable = getTableByName("grammarexpression");
    databasetable* grammarkeytable = getTableByName("grammarkey");
    QSqlQuery result = grammarformcomponenttable->select({"grammarexpression"},{"grammarform",grammarForm_id});
    while(result.next()){
        QSqlQuery result2 = grammarexpressiontable->select({"value","key"},{"id",result.value("grammarexpression").toInt()});
        if(result2.next()){
            QSqlQuery result3 = grammarkeytable->select({"string"},{"id",result2.value("key").toInt()});
            if(result3.next()){
                prettystring += result3.value("string").toString() + ": ";
                prettystring += "<i>" + result2.value("value").toString() + "</i>, ";
            }
        }
    }
    prettystring.chop(2);
    return prettystring;
}

QString database::stringFromFormId(int form_id){
    databasetable* formtable = getTableByName("form");
    QSqlQuery result = formtable->select({"string"},{"id",form_id});
    if(result.next()){
        return result.value("string").toString();
    }
    return "";
}

QString database::prettyPrintForm(int form_id, QString form, int grammarformid){
    QString prettystring;
    if(form_id<1){
        prettystring += "<b>" + form + "</b> ";
        prettystring += prettyPrintGrammarForm(grammarformid);
    } 
    databasetable* formtable = getTableByName("form");
    QSqlQuery result = formtable->select({"string","grammarform"},{"id",form_id});
    if(result.next()){
        prettystring += "<b>" + result.value("string").toString() + "</b> ";
        prettystring += prettyPrintGrammarForm(result.value("grammarform").toInt());
    }
    return prettystring;
}

QString database::prettyPrintLicense(int license_id){
    if(license_id == 0) return "";
    databasetable* licensetable = getTableByName("license");
    QSqlQuery result = licensetable->select({"spdx_identifier","license_url"},{"id",license_id});
    if(result.next())
        return result.value("spdx_identifier").toString() + ": <a href=\"" + result.value("license_url").toString() + "\">" + result.value("license_url").toString() + "</a>";
    else
        return "";
}

QString database::prettyPrintLicenseReference(int license_ref_id){
    if(license_ref_id==0) return "";
    databasetable* licensereferencetable = getTableByName("licensereference");
    QSqlQuery result = licensereferencetable->select({"author","publisher","url","license"},{"id",license_ref_id});
    if(result.next())
        return result.value("author").toString() + ": <i>" + result.value("publisher").toString() + "</i> <a href=\"" + result.value("url").toString() + "\">"+ result.value("url").toString() + "</a> (" + prettyPrintLicense(result.value("license").toInt()) + ")";
    else
        return "";
}

int database::grammarFormFromFormId(int form_id){
    if(form_id==0) return 0;
    databasetable* formtable = getTableByName("form");
    QSqlQuery result = formtable->select({"grammarform"},{"id",form_id});
    if(result.next())
        return result.value("grammarform").toInt();
    else
        return 0;
}

int database::licenseReferenceIdFromFormId(int form_id){
    if(form_id==0) return 0;
    databasetable* formtable = getTableByName("form");
    QSqlQuery result = formtable->select({"licensereference"},{"id",form_id});
    if(result.next())
        return result.value("licensereference").toInt();
    else
        return 0;
}

int database::licenseReferenceIdFromLexemeId(int lexeme_id){
    if(lexeme_id==0) return 0;
    databasetable* lexemetable = getTableByName("lexeme");
    QSqlQuery result = lexemetable->select({"licensereference"},{"id",lexeme_id});
    if(result.next())
        return result.value("licensereference").toInt();
    else
        return 0;
}

int database::licenseReferenceIdFromTranslationId(int translation_id){
    if(translation_id==0) return 0;
    databasetable* translationtable = getTableByName("translation");
    QSqlQuery result = translationtable->select({"licensereference"},{"id",translation_id});
    if(result.next())
        return result.value("licensereference").toInt();
    else
        return 0;
}


QString database::authorFromLicenseReferenceId(int license_ref_id){
    if(license_ref_id==0) return "";
    databasetable* licensereferencetable = getTableByName("licensereference");
    QSqlQuery result = licensereferencetable->select({"author"},{"id",license_ref_id});
    if(result.next())
        return result.value("author").toString();
    else
        return 0;
}

QString database::publisherFromLicenseReferenceId(int license_ref_id){
    if(license_ref_id==0) return "";
    databasetable* licensereferencetable = getTableByName("licensereference");
    QSqlQuery result = licensereferencetable->select({"publisher"},{"id",license_ref_id});
    if(result.next())
        return result.value("publisher").toString();
    else
        return 0;
}


int database::lexemeFromFormId(int form_id){
    databasetable* formtable = getTableByName("form");
    QSqlQuery result = formtable->select({"lexeme"},{"id",form_id});
    if(result.next())
        return result.value("lexeme").toInt();
    else
        return 0;
}

int database::languageIdFromLexemeId(int lexeme_id){
    databasetable* lexemetable = getTableByName("lexeme");
    QSqlQuery result = lexemetable->select({"language"},{"id", lexeme_id});
    if(result.next())
        return result.value("language").toInt();
    else
        return 0;
}

int database::languageIdFromGrammarFormId(int grammarform_id){
    if(grammarform_id == 0) return 0;
    databasetable* grammarformtable = getTableByName("grammarform");
    QSqlQuery result = grammarformtable->select({"language"},{"id", grammarform_id});
    if(result.next())
        return result.value("language").toInt();
    else
        return 0;
}

int database::updateForm(int formid, int newlexeme, int newgrammarform, QString newstring, int licenseid){
    databasetable* formtable = getTableByName("form");
    QMap<QString, QVariant> fields;
    if(newlexeme >= 0) fields["lexeme"] = newlexeme;
    if(newgrammarform >= 0) fields["grammarform"] = newgrammarform;
    if(!newstring.isEmpty()) fields["string"] = newstring;
    if(licenseid >= 0) fields["licensereference"] = licenseid;
    if(fields.size()>0)
        return formtable->updateRecord({"id",formid},fields);
    else
        return 0;
}

int database::updateLexeme(int lexemeid, int newlanguage, int newlicensereference){
    databasetable* lexemetable = getTableByName("lexeme");
    return lexemetable->updateRecord({"id",lexemeid},{{"language",newlanguage},{"licensereference",newlicensereference}});
}

QList<int> database::searchForms(QString string, bool exact){
    databasetable* formtable = getTableByName("form");
    QList<int> form_ids;
    QSqlQuery result;
    if(exact)
        result = formtable->select({"id"},{"string",string});
    else
        result = formtable->select({"id"},{"string","%" + string + "%"},true);
    while(result.next())
        form_ids.push_back(result.value("id").toInt());
    return form_ids;
}

QString database::prettyPrintSentence(int sentence_id){
    if(sentence_id==0) return "";
    QString pretty_string;
    databasetable* sentenceparttable = getTableByName("sentencepart");
    QSqlQuery result = sentenceparttable->select({"capitalized","form","grammarform","punctuationmark"},{"sentence",sentence_id});
    while(result.next()){
        bool capitalized = result.value("capitalized").toInt();
        int form = result.value("form").toInt();
        int grammarform = result.value("grammarform").toInt();
        QString punctuationmark = result.value("punctuationmark").toString();
        if(form!=0){
            QString formString = stringFromFormId(form);
            if(capitalized) formString.replace(0,1,formString[0].toUpper());
            pretty_string += formString;
        }
        // FIXME implement compound form pretty print
        if(grammarform!=0)
            pretty_string += "&lt;" + prettyPrintGrammarForm(grammarform) + "&gt;";
        if(punctuationmark != "0"){
            pretty_string.chop(1);
            pretty_string += punctuationmark;
        }
        pretty_string += " ";
    }
    pretty_string.chop(1);
    return pretty_string;
}

QString database::prettyPrintLexeme(int lexeme_id){
    if(lexeme_id==0) return "";
    //qDebug() << __FILE__ << __FUNCTION__ << __LINE__ << lexeme_id;
    QString prettystring;
    databasetable* formtable = getTableByName("form");
    QSqlQuery result = formtable->select({"string"},{"lexeme",lexeme_id});
    while(result.next()){
        prettystring += result.value("string").toString() + ", ";
    }
    databasetable* sentencetable = getTableByName("sentence");
    databasetable* sentenceparttable = getTableByName("sentencepart");
    QSqlQuery result2 = sentencetable->select({"id"},{"lexeme",lexeme_id});
    while(result2.next()){
        prettystring += prettyPrintSentence(result2.value("id").toInt());
        prettystring += ", ";
    }
    prettystring.chop(2);
    return prettystring;
}


QList<int> database::searchLexemes(QString string, bool exact){
    QList<int> lexeme_ids;
    QList<int> form_ids = searchForms(string,exact);
    databasetable* formtable = getTableByName("form");
    foreach(int form_id, form_ids){
        QSqlQuery result = formtable->select({"lexeme"},{"id",form_id});
        if(result.next()){
            int lexeme_id = result.value("lexeme").toInt();
            if(!lexeme_ids.contains(lexeme_id))
                lexeme_ids.push_back(lexeme_id);
        }
    }
    return lexeme_ids;
}

QList<QPair<QString,int> > database::listFormsOfLexeme(int lexeme_id){
    databasetable* formtable = getTableByName("form");
    QSqlQuery result = formtable->select({"string","id"},{"lexeme",lexeme_id});
    QList<QPair<QString,int> > forms;
    while(result.next())
        forms.push_back({result.value("string").toString(),result.value("id").toInt()});
    return forms;
}

int database::languageOfLexeme(int lexeme_id){
    int language_id = 0;
    databasetable* lexemetable = getTableByName("lexeme");
    QSqlQuery result = lexemetable->select({"language"},{"id",lexeme_id});
    if(result.next())
        language_id = result.value("language").toInt();
    return language_id;
}

int database::grammarFormIdFromStrings(int language_id, QList<QList<QString> > grammarform){
    databasetable* grammarexpressiontable = getTableByName("grammarexpression");
    databasetable* grammarkeytable = getTableByName("grammarkey");
    databasetable* grammarformcomponenttable = getTableByName("grammarformcomponent");
    databasetable* grammarformtable = getTableByName("grammarform");
    QList<int> i_grammarform;
    // Get ids for grammar expressions:
    QList<QString> grammarexpression;
    foreach(grammarexpression, grammarform){
        QSqlQuery result = grammarexpressiontable->select({"id","key"},
                {"value",grammarexpression.last()});
        while(result.next()){
            QSqlQuery result2 = grammarkeytable->select({"id"},
                    {{"id",result.value("key").toInt()},
                    {"string",grammarexpression.first()}});
            if(result2.next()){
                i_grammarform.push_back(result.value("id").toInt());
            }
        }
    }
    // Check if grammarform exists already:
    QSqlQuery result = grammarformcomponenttable->select({"id","grammarform"},{"grammarexpression",i_grammarform.first()});
    int grammarform_id = 0;
    while(result.next()){
        bool grammarform_valid = true;
        foreach(int grammarexpression, i_grammarform){
            QSqlQuery result2 = grammarformcomponenttable->select({"id","grammarform"},
                    {{"grammarform", result.value("grammarform").toInt()},
                    {"grammarexpression",grammarexpression}});
            if(!result2.next()) grammarform_valid = false;
        }
        if(grammarform_valid){
            grammarform_id = result.value("grammarform").toInt();
            // Check that this grammarform is for finnish:
            QSqlQuery result2 = grammarformtable->select({"id"},{{"id",grammarform_id},{"language",language_id}});
            if(result2.next()){
                /* Check, if the number of grammar expressions matches
                   the number of grammar expressions passed to this
                   function: */
                QSqlQuery result3 = grammarformcomponenttable->select({"id","grammarform"},{"grammarform",result.value("grammarform").toInt()});
                int queryresultsnumber = 0;
                while(result3.next()) queryresultsnumber++;
                if(queryresultsnumber == grammarform.size()){
                    break;
                }
            }
            grammarform_id = 0;
        }
    }
    // If grammarform does not exist, create it:
    if(grammarform_id == 0){
        QMap<QString,QVariant> add_grammarform;
        add_grammarform["language"] = language_id;
        grammarform_id = grammarformtable->insertRecord(add_grammarform);
        QMap<QString,QVariant> add_grammarformcomponent;
        foreach(int grammarexpression, i_grammarform){
            add_grammarformcomponent["grammarform"] = grammarform_id;
            add_grammarformcomponent["grammarexpression"] = grammarexpression;
            grammarformcomponenttable->insertRecord(add_grammarformcomponent);
        }
    }
    return grammarform_id;
}

QList<int> database::searchGrammarFormsFromStrings(int language_id, QList<QList<QString> > grammarform){
    QList<int> grammarform_candidates;
    databasetable* grammarexpressiontable = getTableByName("grammarexpression");
    databasetable* grammarkeytable = getTableByName("grammarkey");
    databasetable* grammarformcomponenttable = getTableByName("grammarformcomponent");
    databasetable* grammarformtable = getTableByName("grammarform");
    QList<int> i_grammarform;
    // Get ids for grammar expressions:
    QList<QString> grammarexpression;
    foreach(grammarexpression, grammarform){
        QSqlQuery result = grammarexpressiontable->select({"id","key"},
                {"value",grammarexpression.last()});
        while(result.next()){
            QSqlQuery result2 = grammarkeytable->select({"id"},
                    {{"id",result.value("key").toInt()},
                    {"string",grammarexpression.first()}});
            if(result2.next()){
                i_grammarform.push_back(result.value("id").toInt());
            }
        }
    }
    // Check if grammarform exists already:
    QSqlQuery result = grammarformcomponenttable->select({"id","grammarform"},{"grammarexpression",i_grammarform.first()});
    int grammarform_id = 0;
    while(result.next()){
        bool grammarform_valid = true;
        foreach(int grammarexpression, i_grammarform){
            QSqlQuery result2 = grammarformcomponenttable->select({"id","grammarform"},
                    {{"grammarform", result.value("grammarform").toInt()},
                    {"grammarexpression",grammarexpression}});
            if(!result2.next()) grammarform_valid = false;
        }
        if(grammarform_valid){
            grammarform_id = result.value("grammarform").toInt();
            // Check that this grammarform is for finnish:
            QSqlQuery result2 = grammarformtable->select({"id"},{{"id",grammarform_id},{"language",language_id}});
            if(result2.next())
                grammarform_candidates.push_back(grammarform_id);
            grammarform_id = 0;
        }
    }
    return grammarform_candidates;
}
 
QString database::languagenamefromid(int id){
    if(id==0) return "";
    databasetable* languagenametable = getTableByName("languagename");
    QList<QString> selection;
    selection.push_back("name");
    QList< QPair< QString, QVariant > > wheres;
    wheres.push_back(qMakePair(QString("nameisinlanguage"),QVariant(1)));
    wheres.push_back(qMakePair(QString("language"),QVariant(id)));
    QSqlQuery result = languagenametable->select(selection, wheres);
    if(!result.next()) throw sql_error::select_empty;
    return result.value("name").toString();

}

int database::idfromlanguagename(QString languagename){
    if(languagename.isEmpty()) return 0;
    databasetable* languagenametable = getTableByName("languagename");
    QList<QString> selection;
    selection.push_back("language");
    QList< QPair< QString, QVariant > > wheres;
    wheres.push_back(qMakePair(QString("nameisinlanguage"),QVariant(1)));
    wheres.push_back(qMakePair(QString("name"),QVariant(languagename)));
    QSqlQuery result = languagenametable->select(selection, wheres);
    if(!result.next()) throw sql_error::select_empty;
    return result.value("language").toInt();
}
@}

\section{Field}
\subsection{Interface}
@o ../src/databasefield.h -d
@{
@<Start of @'DATABASEFIELD@' header@>
#include <QSqlField>
@}

We need to predeclare databasetable, because we have a circular dependency between databasefield and databasetable here:

@o ../src/databasefield.h -d
@{
class databasetable;
@}

Constrains on the column of a database table are handled as QVariant. The basis to make such a QVariant is defined by the fragments for the constraint classes.

@o ../src/databasefield.h -d
@{
@<Valueless db constraint class @'databasefield_constraint_not_null@' @>
@<Valueless db constraint class @'databasefield_constraint_unique@' @>
@<Valueless db constraint class @'databasefield_constraint_primary_key@' @>

@<Start of db constraint class @'databasefield_constraint_foreign_key@' @>
public:
    databasefield_constraint_foreign_key(databasetable* fKT, QString fFN) : m_foreignKeyTable(fKT), m_foreignFieldName(fFN){};
    databasetable* foreignKeyTable(){return m_foreignKeyTable;};
    QString foreignFieldName(){return m_foreignFieldName;};
private:
    databasetable* m_foreignKeyTable;
    QString m_foreignFieldName;
@<End of db constraint class @'databasefield_constraint_foreign_key@' @>

class databasefield 
{
public:
    explicit databasefield(const QString& fieldname,
            QVariant::Type type,
            QList<QVariant*> constraints = {});
    QSqlField field(){return m_field;};
    QList<QVariant*> constraints(){return m_constraints;};
    QString sqLiteType();
private:
    QSqlField m_field;
    QList<QVariant*> m_constraints;
@<End of class and header@>
@}

\subsection{Implementation}
@o ../src/databasefield.cpp -d
@{
#include "databasefield.h"

databasefield::databasefield(const QString& fieldname,
        QVariant::Type type,
        QList<QVariant*> constraints) : m_field(fieldname, type), m_constraints(constraints){
}

QString databasefield::sqLiteType(void){
    switch(m_field.type()){
        case QVariant::Int:
        case QVariant::Bool:
            return "INTEGER";
        case QVariant::String:
            return "TEXT";
    }
    return "";
}
@}

\section{Table}
\subsection{Interface}
@o ../src/databasetable.h -d
@{
@<Start of @'DATABASETABLE@' header@>
#include <QSqlRecord>
#include <QSqlField>
#include <QString>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QDebug>
#include <QMap>
#include <QSqlError>
#include "databasefield.h"
#include "error.h"

class databasetable : public QObject, QSqlRecord
{
    Q_OBJECT
public:
    explicit databasetable(QString name = "", QList<databasefield*> fields = {});
    int insertRecord(const QMap<QString, QVariant>& fields);
    int updateRecord(const QPair<QString, QVariant>& id, const QMap<QString, QVariant>& fields);
    int deleteRecord(const QPair<QString, QVariant>& id);
    QSqlQuery select(const QList<QString>& selection, const QPair<QString, QVariant>& where = qMakePair(QString(),QVariant(0)), bool like = false);
    QSqlQuery select(const QList<QString>& selection, const QList< QPair<QString, QVariant> >& where);
    QString name(){return m_name;};
private:
    QString m_name;
    QSqlDatabase m_vocableDatabase;
    QList<databasefield*> m_fields;
    QString s_databasefield_constraint_not_null;
    QString s_databasefield_constraint_unique;
    QString s_databasefield_constraint_primary_key;
    QString s_databasefield_constraint_foreign_key;
@<End of class and header@>
@}

\subsection{Implementation}
@o ../src/databasetable.cpp -d
@{
#include "databasetable.h"
databasetable::databasetable(QString name, QList<databasefield*> fields) : m_name(name),
    m_fields(fields),
    s_databasefield_constraint_not_null("databasefield_constraint_not_null"),
    s_databasefield_constraint_unique("databasefield_constraint_unique"),
    s_databasefield_constraint_primary_key("databasefield_constraint_primary_key"),
    s_databasefield_constraint_foreign_key("databasefield_constraint_foreign_key")
    {
    m_vocableDatabase = QSqlDatabase::database("vocableDatabase");
    if(!m_vocableDatabase.isValid()){
        qDebug() << "No valid database connection!";
        return;
    }
    QString sqlString = "CREATE TABLE IF NOT EXISTS `" + m_name + "` (";
    QString sqlStringForeignKeys;
    foreach(databasefield* field, m_fields){
      sqlString += "`" + field->field().name() + "` " + field->sqLiteType();
      foreach(QVariant* constraint, field->constraints()){
          QString constraintType = constraint->typeName();
          if(constraintType == s_databasefield_constraint_not_null)
              sqlString += " NOT NULL";
          if(constraintType == s_databasefield_constraint_unique)
              sqlString += " UNIQUE";
          if(constraintType == s_databasefield_constraint_primary_key)
              sqlString += " PRIMARY KEY";
          if(constraintType == s_databasefield_constraint_foreign_key){
              databasefield_constraint_foreign_key fk_constraint =
                  qvariant_cast<databasefield_constraint_foreign_key>(*constraint);
              sqlStringForeignKeys += "FOREIGN KEY ("
                  + field->field().name()
                  + ") REFERENCES "
                  + fk_constraint.foreignKeyTable()->name()
                  + "("
                  + fk_constraint.foreignFieldName()
                  + "), ";
          }
      }
      sqlString += ", ";
    }
    sqlString += sqlStringForeignKeys;
    sqlString.truncate(sqlString.size()-2);
    sqlString += ")";
    QSqlQuery sqlQuery(m_vocableDatabase);
    bool querySuccessful = sqlQuery.exec(sqlString);
}

int databasetable::insertRecord(const QMap<QString, QVariant>& fields){
    QList < QPair < QString, QVariant > > accepted_fields;
    QString sqlString = "INSERT INTO " + m_name + " (";
    QString sqlStringValues = "VALUES (";
    foreach(databasefield* field, m_fields){
        bool skip_column = false;
        QString fieldname = field->field().name();
        if(fields.contains(fieldname)){
            foreach(QVariant* constraint, field->constraints()){
                QString constraintType = constraint->typeName();
                if(constraintType == s_databasefield_constraint_primary_key){
                    skip_column = true;
                    break;
                }
            }
            if(skip_column) continue;
            sqlString += fieldname + ", ";
            sqlStringValues += ":" + fieldname + ", ";
            accepted_fields.push_back(qMakePair(fieldname,fields[fieldname]));
        }
    }
    sqlString.truncate(sqlString.size()-2);
    sqlString += ") ";
    sqlStringValues.truncate(sqlStringValues.size()-2);
    sqlStringValues += ")";
    sqlString += sqlStringValues;
    if(fields.size() == 0){
        sqlString = "INSERT INTO " + m_name + " DEFAULT VALUES";
    }

    QSqlQuery sqlQuery(m_vocableDatabase);
    //qDebug() << "SQL query:" << sqlString;
    sqlQuery.prepare(sqlString);
    QPair<QString, QVariant> accepted_field;
    foreach(accepted_field, accepted_fields){
        sqlQuery.bindValue(":" + accepted_field.first, accepted_field.second);
    }
    if(!sqlQuery.exec()) throw sql_error::insert_record;
    if(!sqlQuery.exec("select last_insert_rowid();")) throw sql_error::select;
    if(!sqlQuery.first()) throw sql_error::select_empty;
    return sqlQuery.value(0).toInt();
}

int databasetable::updateRecord(const QPair<QString, QVariant>& id, const QMap<QString, QVariant>& fields){
    QList < QPair < QString, QVariant > > accepted_fields;
    QString sqlString = "UPDATE " + m_name + " SET ";
    foreach(databasefield* field, m_fields){
        bool skip_column = false;
        QString fieldname = field->field().name();
        if(fields.contains(fieldname)){
            foreach(QVariant* constraint, field->constraints()){
                QString constraintType = constraint->typeName();
                if(constraintType == s_databasefield_constraint_primary_key){
                    skip_column = true;
                    break;
                }
            }
            if(skip_column) continue;
            sqlString += fieldname + "=:" + fieldname + ", ";
            accepted_fields.push_back(qMakePair(fieldname,fields[fieldname]));
        }
    }
    sqlString.truncate(sqlString.size()-2);
    sqlString += " WHERE " + id.first + "=:" + id.first;

    QSqlQuery sqlQuery(m_vocableDatabase);
    sqlQuery.prepare(sqlString);
    QPair<QString, QVariant> accepted_field;
    foreach(accepted_field, accepted_fields){
        sqlQuery.bindValue(":" + accepted_field.first, accepted_field.second);
    }
    sqlQuery.bindValue(":" + id.first, id.second);
    if(!sqlQuery.exec()){
        QSqlError error = sqlQuery.lastError();
        qDebug() << error.databaseText();
        qDebug() << error.driverText();
        qDebug() << "Query was generated from string" << sqlString;
        foreach(accepted_field, accepted_fields){
            qDebug() << "Binding" << accepted_field.first << accepted_field.second;
        }
        throw sql_error::update_record;
    }
    return id.second.toInt();
}

int databasetable::deleteRecord(const QPair<QString, QVariant>& id){
    QString sqlString = "DELETE FROM " + m_name + " WHERE " + id.first + "=:" + id.first;
    
    QSqlQuery sqlQuery(m_vocableDatabase);
    sqlQuery.prepare(sqlString);
    sqlQuery.bindValue(":" + id.first, id.second);
    if(!sqlQuery.exec()){
        QSqlError error = sqlQuery.lastError();
        qDebug() << error.databaseText();
        qDebug() << error.driverText();
        throw sql_error::delete_record;
    }
    return id.second.toInt();
}

QSqlQuery databasetable::select(const QList<QString>& selection, const QPair<QString, QVariant>& where, bool like){
    QString sqlString = "SELECT ";
    foreach(databasefield* field, m_fields){
        QString fieldname = field->field().name();
        if(selection.contains(fieldname)){
            sqlString += fieldname + ", ";
        }
    }
    sqlString.truncate(sqlString.size()-2);
    sqlString += " FROM " + m_name; 
    QSqlQuery sqlQuery(m_vocableDatabase);
    if(!where.first.isEmpty()){
        if(like)
            sqlString += " WHERE " + where.first + " LIKE :" + where.first;
        else
            sqlString += " WHERE " + where.first + "=:" + where.first;
    }
    //qDebug() << "SQL query:" << sqlString;
    sqlQuery.prepare(sqlString);
    if(!where.first.isEmpty()){
        sqlQuery.bindValue(":" + where.first, where.second);
        //qDebug() << "SQL bind:" << where.first + ":" << where.second;
    }
    if(!sqlQuery.exec()){
        QSqlError error = sqlQuery.lastError();
        qDebug() << sqlString;
        qDebug() << error.databaseText();
        qDebug() << error.driverText();
        throw sql_error::select;
    }
    return sqlQuery;
}

QSqlQuery databasetable::select(const QList<QString>& selection, const QList< QPair<QString, QVariant> >& wheres){
    QString sqlString = "SELECT ";
    foreach(databasefield* field, m_fields){
        QString fieldname = field->field().name();
        if(selection.contains(fieldname)){
            sqlString += fieldname + ", ";
        }
    }
    sqlString.truncate(sqlString.size()-2);
    sqlString += " FROM " + m_name; 
    QSqlQuery sqlQuery(m_vocableDatabase);
    QPair<QString, QVariant> where;
    foreach(where, wheres){
        if(where == wheres.first()) sqlString += " WHERE";
        sqlString += " " + where.first + "=:" + where.first + " AND";
    }
    sqlString.truncate(sqlString.size()-4);
    //qDebug() << "SQL query:" << sqlString;
    sqlQuery.prepare(sqlString);
    foreach(where, wheres){
        //qDebug() << "SQL bind:" << ":" + where.first << where.second;
        sqlQuery.bindValue(":" + where.first, where.second);
    }
    if(!sqlQuery.exec()){
        QSqlError error = sqlQuery.lastError();
        qDebug() << sqlString;
        qDebug() << error.databaseText();
        qDebug() << error.driverText();
        throw sql_error::select;
    }
    return sqlQuery;
}

@}
