--
-- SQL script to create the trigger(s) enabling the load API for
-- SGLD_Biosequences.
--
-- Scaffold auto-generated by gen-api.pl.
--
--
-- $Id: Biosequences.trg,v 1.1.1.1 2002-08-13 19:51:10 lapp Exp $
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

CREATE OR REPLACE TRIGGER BIUR_Biosequences
       INSTEAD OF INSERT OR UPDATE
       ON SGLD_Biosequences
       REFERENCING NEW AS new OLD AS old
       FOR EACH ROW
DECLARE
	pk		SG_BIOSEQUENCE.OID%TYPE DEFAULT :new.Seq_Oid;
	do_DML		INTEGER DEFAULT BSStd.DML_NO;
BEGIN
	IF INSERTING THEN
		do_DML := BSStd.DML_I;
	ELSE
		-- this is an update
		do_DML := BSStd.DML_UI;
	END IF;
	-- do insert or update (depending on whether it exists or not)
	pk := Seq.get_oid(
			Seq_OID => pk,
		        Seq_VERSION => Seq_VERSION,
			Seq_LENGTH => Seq_LENGTH,
			Seq_SEQ => Seq_SEQ,
			do_DML             => do_DML);
END;
/
