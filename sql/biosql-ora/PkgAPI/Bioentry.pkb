--
-- API Package Body for Bioentry.
--
-- Scaffold auto-generated by gen-api.pl (H.Lapp, 2002).
--
-- $Id: Bioentry.pkb,v 1.1.1.2 2003-01-29 08:54:37 lapp Exp $
--

--
-- (c) Hilmar Lapp, hlapp at gnf.org, 2002.
-- (c) GNF, Genomics Institute of the Novartis Research Foundation, 2002.
--
-- You may distribute this module under the same terms as Perl.
-- Refer to the Perl Artistic License (see the license accompanying this
-- software package, or see http://www.perl.com/language/misc/Artistic.html)
-- for the terms under which you may use, modify, and redistribute this module.
-- 
-- THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
-- WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
-- MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
--

CREATE OR REPLACE
PACKAGE BODY Ent IS

Ent_cached	SG_BIOENTRY.OID%TYPE DEFAULT NULL;
cache_key		VARCHAR2(128) DEFAULT NULL;

CURSOR Ent_Acc_c (
		Ent_ACCESSION	IN SG_BIOENTRY.ACCESSION%TYPE,
		Ent_VERSION	IN SG_BIOENTRY.VERSION%TYPE,
		Ent_DB_OID	IN SG_BIOENTRY.DB_OID%TYPE)
RETURN SG_BIOENTRY%ROWTYPE IS
	SELECT t.* FROM SG_BIOENTRY t
	WHERE
	   	t.DB_OID = Ent_DB_OID
	AND	t.ACCESSION = Ent_ACCESSION
	AND	(
		t.VERSION = Ent_VERSION
	OR	Ent_VERSION IS NULL
	)
	;

CURSOR Ent_ID_c (
		Ent_DB_OID	IN SG_BIOENTRY.DB_OID%TYPE,
		Ent_IDENTIFIER	IN SG_BIOENTRY.IDENTIFIER%TYPE)
RETURN SG_BIOENTRY%ROWTYPE IS
	SELECT t.* FROM SG_BIOENTRY t
	WHERE
		t.DB_OID = Ent_DB_OID
	AND	t.IDENTIFIER = Ent_IDENTIFIER
	;

FUNCTION get_oid(
		Ent_OID	IN SG_BIOENTRY.OID%TYPE DEFAULT NULL,
		Ent_ACCESSION	IN SG_BIOENTRY.ACCESSION%TYPE DEFAULT NULL,
		Ent_IDENTIFIER	IN SG_BIOENTRY.IDENTIFIER%TYPE DEFAULT NULL,
		Ent_DISPLAY_ID	IN SG_BIOENTRY.DISPLAY_ID%TYPE DEFAULT NULL,
		Ent_DESCRIPTION	IN SG_BIOENTRY.DESCRIPTION%TYPE DEFAULT NULL,
		Ent_VERSION	IN SG_BIOENTRY.VERSION%TYPE DEFAULT NULL,
		DB_OID	IN SG_BIOENTRY.DB_OID%TYPE DEFAULT NULL,
		TAX_OID	IN SG_BIOENTRY.TAX_OID%TYPE DEFAULT NULL,
		Tax_NAME	IN SG_TAXON.NAME%TYPE DEFAULT NULL,
		Tax_VARIANT	IN SG_TAXON.VARIANT%TYPE DEFAULT NULL,
		Tax_NCBI_TAXON_ID	IN SG_TAXON.NCBI_TAXON_ID%TYPE DEFAULT NULL,
		DB_NAME	IN SG_BIODATABASE.NAME%TYPE DEFAULT NULL,
		DB_ACRONYM	IN SG_BIODATABASE.ACRONYM%TYPE DEFAULT NULL,
		do_DML		IN NUMBER DEFAULT BSStd.DML_NO)
RETURN SG_BIOENTRY.OID%TYPE
IS
	pk	SG_BIOENTRY.OID%TYPE DEFAULT NULL;
	Ent_row Ent_Acc_c%ROWTYPE;
	TAX_OID_	SG_TAXON.OID%TYPE DEFAULT TAX_OID;
	DB_OID_	SG_BIODATABASE.OID%TYPE DEFAULT DB_OID;
	key_str	VARCHAR2(128) DEFAULT DB_OID || '|' || Ent_ACCESSION || '|' || Ent_VERSION || '|' || Ent_IDENTIFIER;
BEGIN
	-- initialize
	IF (do_DML > BSStd.DML_NO) THEN
		pk := Ent_OID;
	END IF;
	-- look up
	IF pk IS NULL THEN
		IF (DB_OID_ IS NULL) THEN
			DB_OID_ := DB.get_oid(
				DB_NAME => DB_NAME,
				DB_ACRONYM => DB_ACRONYM,
				do_DML => do_DML);
		END IF;
		-- reset cache
		cache_key := NULL;
		Ent_cached := NULL;
		-- do the look up
		IF (Ent_IDENTIFIER IS NULL) THEN
		        FOR Ent_row IN Ent_Acc_c(Ent_ACCESSION, 
						 Ent_VERSION, DB_OID_) LOOP
			    pk := Ent_row.OID;
			    -- cache result
			    cache_key := key_str;
			    Ent_cached := pk;
			END LOOP;
		ELSE
		        FOR Ent_row IN Ent_ID_c(DB_OID_, Ent_IDENTIFIER) LOOP
			    pk := Ent_row.OID;
			    -- cache result
			    cache_key := key_str;
			    Ent_cached := pk;
			END LOOP;
		END IF;
	END IF;
	-- insert/update if requested
	IF (pk IS NULL) AND 
	   ((do_DML = BSStd.DML_I) OR (do_DML = BSStd.DML_UI)) THEN
	    	-- look up foreign keys if not provided:
		-- look up SG_BIODATABASE successful?
		IF (DB_OID_ IS NULL) THEN
			raise_application_error(-20101,
				'failed to look up DB <' || DB_NAME || '|' || DB_ACRONYM || '>');
		END IF;
		-- look up SG_TAXON
		IF (TAX_OID_ IS NULL) THEN
			TAX_OID_ := Tax.get_oid(
				Tax_NAME => Tax_NAME,
				Tax_VARIANT => Tax_VARIANT,
				Tax_NCBI_TAXON_ID => Tax_NCBI_TAXON_ID);
		END IF;
		IF (TAX_OID_ IS NULL) AND
		   ((Tax_Name IS NOT NULL) OR
		    (Tax_NCBI_Taxon_ID IS NOT NULL)) THEN
			raise_application_error(-20101,
				'failed to look up Tax <' || Tax_NAME || '|' || Tax_NCBI_TAXON_ID || '>');
		END IF;
	    	-- insert the record and obtain the primary key
	    	pk := do_insert(
		        ACCESSION => Ent_ACCESSION,
			IDENTIFIER => Ent_IDENTIFIER,
			DISPLAY_ID => Ent_DISPLAY_ID,
			DESCRIPTION => Ent_DESCRIPTION,
			VERSION => Ent_VERSION,
			DB_OID => DB_OID_,
			TAX_OID => TAX_OID_);
	ELSIF (do_DML = BSStd.DML_U) OR (do_DML = BSStd.DML_UI) THEN
	        -- update the record (note that not provided FKs will not
		-- be changed nor looked up)
		do_update(
			Ent_OID	=> pk,
		        Ent_ACCESSION => Ent_ACCESSION,
			Ent_IDENTIFIER => Ent_IDENTIFIER,
			Ent_DISPLAY_ID => Ent_DISPLAY_ID,
			Ent_DESCRIPTION => Ent_DESCRIPTION,
			Ent_VERSION => Ent_VERSION,
			Ent_DB_OID => DB_OID_,
			Ent_TAX_OID => TAX_OID_);
	END IF;
	-- return the primary key
	RETURN pk;
END;

FUNCTION do_insert(
		ACCESSION	IN SG_BIOENTRY.ACCESSION%TYPE,
		IDENTIFIER	IN SG_BIOENTRY.IDENTIFIER%TYPE,
		DISPLAY_ID	IN SG_BIOENTRY.DISPLAY_ID%TYPE,
		DESCRIPTION	IN SG_BIOENTRY.DESCRIPTION%TYPE,
		VERSION	IN SG_BIOENTRY.VERSION%TYPE,
		DB_OID	IN SG_BIOENTRY.DB_OID%TYPE,
		TAX_OID	IN SG_BIOENTRY.TAX_OID%TYPE)
RETURN SG_BIOENTRY.OID%TYPE 
IS
	pk	SG_BIOENTRY.OID%TYPE;
BEGIN
	-- pre-generate the primary key value
	SELECT SG_Sequence.nextval INTO pk FROM DUAL;
	-- insert the record
	INSERT INTO SG_BIOENTRY (
		OID,
		ACCESSION,
		IDENTIFIER,
		DISPLAY_ID,
		DESCRIPTION,
		VERSION,
		DB_OID,
		TAX_OID)
	VALUES (pk,
		ACCESSION,
		IDENTIFIER,
		DISPLAY_ID,
		DESCRIPTION,
		VERSION,
		DB_OID,
		TAX_OID)
	;
	-- return the new pk value
	RETURN pk;
END;

PROCEDURE do_update(
		Ent_OID	IN SG_BIOENTRY.OID%TYPE,
		Ent_ACCESSION	IN SG_BIOENTRY.ACCESSION%TYPE,
		Ent_IDENTIFIER	IN SG_BIOENTRY.IDENTIFIER%TYPE,
		Ent_DISPLAY_ID	IN SG_BIOENTRY.DISPLAY_ID%TYPE,
		Ent_DESCRIPTION	IN SG_BIOENTRY.DESCRIPTION%TYPE,
		Ent_VERSION	IN SG_BIOENTRY.VERSION%TYPE,
		Ent_DB_OID	IN SG_BIOENTRY.DB_OID%TYPE,
		Ent_TAX_OID	IN SG_BIOENTRY.TAX_OID%TYPE)
IS
BEGIN
	-- update the record (and leave attributes passed as NULL untouched)
	UPDATE SG_BIOENTRY
	SET
		ACCESSION = NVL(Ent_ACCESSION, ACCESSION),
		IDENTIFIER = NVL(Ent_IDENTIFIER, IDENTIFIER),
		DISPLAY_ID = NVL(Ent_DISPLAY_ID, DISPLAY_ID),
		DESCRIPTION = NVL(Ent_DESCRIPTION, DESCRIPTION),
		VERSION = NVL(Ent_VERSION, VERSION),
		DB_OID = NVL(Ent_DB_OID, DB_OID),
		TAX_OID = NVL(Ent_TAX_OID, TAX_OID)
	WHERE OID = Ent_OID
	;
END;

END Ent;
/

