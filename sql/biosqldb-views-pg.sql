--- THIS FILE IS EXPERIMENTAL; SOME OR ALL OF THESE COULD CHANGE

CREATE VIEW seqfeature_key_v
 AS SELECT f.*, key_name 
    FROM seqfeature f, seqfeature_key k 
    WHERE f.seqfeature_key_id = k.seqfeature_key_id;

DROP VIEW gff;
CREATE VIEW gff
 AS SELECT e.accession       AS fref, 
           fl.seq_start      AS fstart, 
           fl.seq_end        AS fend,
           key_name          AS type, 
           NULL              AS fscore,
           fl.seq_strand     AS fstrand, 
           NULL              AS fphase,
           f.seqfeature_id   AS gid
    FROM seqfeature f, 
         seqfeature_key k, 
         seqfeature_location fl,
         bioentry e
    WHERE f.seqfeature_key_id = k.seqfeature_key_id AND
          fl.seqfeature_id = f.seqfeature_id        AND
          f.bioentry_id    = e.bioentry_id
    SORT BY location_rank;

DROP FUNCTION compl(text);
CREATE FUNCTION compl(text) RETURNS text AS
 'SELECT (translate($1, ''ACGT'', ''TGCA'')) as RESULT;'
LANGUAGE 'sql';

DROP FUNCTION reverse(text);
CREATE FUNCTION reverse(text) RETURNS text
  AS '/home/cjm/cvs/biosql-schema/ext/biosqldb-funcs.so' 
  LANGUAGE 'c'
  WITH (isStrict);
SELECT reverse('abcde');

--- doesn't do reverse comp yet
DROP FUNCTION get_subseq(text,int,int,int);
CREATE FUNCTION get_subseq (text, int, int, int)
  RETURNS text
  AS 'BEGIN
        IF $4 > 0 THEN
          return (select 
                   substring($1,
                      $2,
                     ($3 - $2)+1));
        ELSE
           return NULL;
        END IF;
     END;
     '
  LANGUAGE 'plpgsql';
select get_subseq('abcdefg',2,3,1);

DROP VIEW gffseq;
CREATE VIEW gffseq
 AS SELECT e.accession       AS fref, 
           fl.seq_start      AS fstart, 
           fl.seq_end        AS fend,
           key_name          AS type, 
           NULL              AS fscore,
           fl.seq_strand     AS fstrand, 
           NULL              AS fphase,
           f.seqfeature_id   AS gid,
           get_subseq(s.biosequence_str,
                      fl.seq_start,
                      fl.seq_end,
                      fl.seq_strand)
                             AS subseq
    FROM seqfeature f, 
         seqfeature_key k, 
         seqfeature_location fl,
         bioentry e,
         biosequence s
    WHERE f.seqfeature_key_id = k.seqfeature_key_id AND
          fl.seqfeature_id    = f.seqfeature_id        AND
          f.bioentry_id       = e.bioentry_id          AND
          f.bioentry_id       = s.bioentry_id
    ORDER BY location_rank;



--- these are autogenerated:

CREATE VIEW f_source AS
  SELECT * from seqfeature_key_v WHERE key_name = 'source';
CREATE VIEW f_misc_feature AS
  SELECT * from seqfeature_key_v WHERE key_name = 'misc_feature';
CREATE VIEW f_sig_peptide AS
  SELECT * from seqfeature_key_v WHERE key_name = 'sig_peptide';
CREATE VIEW f_CDS AS
  SELECT * from seqfeature_key_v WHERE key_name = 'CDS';
CREATE VIEW f_gene AS
  SELECT * from seqfeature_key_v WHERE key_name = 'gene';
CREATE VIEW f_mat_peptide AS
  SELECT * from seqfeature_key_v WHERE key_name = 'mat_peptide';
CREATE VIEW f_variation AS
  SELECT * from seqfeature_key_v WHERE key_name = 'variation';
CREATE VIEW f_exon AS
  SELECT * from seqfeature_key_v WHERE key_name = 'exon';
CREATE VIEW f_intron AS
  SELECT * from seqfeature_key_v WHERE key_name = 'intron';

