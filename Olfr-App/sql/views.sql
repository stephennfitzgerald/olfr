CREATE OR REPLACE VIEW next_gene AS
 SELECT gn.id 
 FROM gene gn INNER JOIN transcript tr 
 ON tr.gene_id = gn.id INNER JOIN exon ex 
 ON ex.transcript_id = tr.id 
 WHERE ex.ok = '1' 
 AND tr.ok = '1' 
 AND gn.ok = '1'
 GROUP BY gn.id 
 ORDER BY gn.seq_region, ex.pos_from 
 LIMIT 1;

CREATE OR REPLACE VIEW count_genes AS
 SELECT count(*) 
 FROM gene
 WHERE ok = '1';

CREATE OR REPLACE VIEW count_trans AS
 SELECT count(*)
 FROM transcript
 WHERE ok = '1';

CREATE OR REPLACE VIEW done_genes AS
 SELECT count(*) 
 FROM gene
 WHERE ok = '2';

CREATE OR REPLACE VIEW done_trans AS
 SELECT count(*)
 FROM transcript
 WHERE ok = '2';

CREATE OR REPLACE VIEW del_genes AS
 SELECT count(*) 
 FROM gene
 WHERE ok = '0';

CREATE OR REPLACE VIEW del_trans AS
 SELECT count(*)
 FROM transcript
 WHERE ok = '0';

CREATE OR REPLACE VIEW add_genes AS
 SELECT count(*) 
 FROM gene
 WHERE ok = '3';

CREATE OR REPLACE VIEW add_trans AS
 SELECT count(*)
 FROM transcript
 WHERE ok = '3';

CREATE OR REPLACE VIEW show_all AS 
 SELECT gn.id gene_id, 
        tr.id trans_id,
        ex.id exon_id,
        gn.name gene_name,
        tr.name trans_name,
        ex.exon_num exon_num,
        gn.seq_region,
        ex.pos_from exon_from,
        ex.pos_to exon_to,
        gn.strand,
        gn.ok gene_ok,
        tr.ok trans_ok,
        ex.ok exon_ok
FROM gene gn INNER JOIN transcript tr
 ON gn.id = tr.gene_id INNER JOIN exon ex
 ON tr.id = ex.transcript_id
WHERE ( ex.ok != "0" AND tr.ok != "0" AND gn.ok != "0" ) 
ORDER BY gn.id, tr.id, ex.exon_num;

CREATE OR REPLACE VIEW show_todo AS
 SELECT gn.id gene_id, 
        gn.name gene_name,
        gn.seq_region,
        gn.ok gene_ok,
        gn.strand,
        tr.id trans_id,
        tr.name trans_name,
        tr.ok trans_ok,
        ex.id exon_id,
        ex.pos_from exon_from,
        ex.pos_to exon_to,
        ex.exon_num exon_num,
        ex.ok exon_ok
FROM gene gn INNER JOIN transcript tr
 ON gn.id = tr.gene_id INNER JOIN exon ex
 ON tr.id = ex.transcript_id
WHERE ex.ok = "1" AND tr.ok = "1" AND gn.ok = "1"
ORDER BY gn.id, tr.id, ex.exon_num;
 

CREATE OR REPLACE VIEW show_done AS
 SELECT gn.id gene_id, 
        gn.name gene_name,
        gn.seq_region,
        gn.ok gene_ok,
        gn.strand,
        tr.id trans_id,
        tr.name trans_name,
        tr.ok trans_ok,
        ex.id exon_id,
        ex.pos_from exon_from,
        ex.pos_to exon_to,
        ex.exon_num exon_num,
        ex.ok exon_ok
FROM gene gn INNER JOIN transcript tr
 ON gn.id = tr.gene_id INNER JOIN exon ex
 ON tr.id = ex.transcript_id
WHERE ex.ok = "2" OR ex.ok = "3"
ORDER BY gn.id, tr.id, ex.exon_num;


CREATE OR REPLACE VIEW show_new AS
 SELECT gn.id gene_id, 
        gn.name gene_name,
        gn.seq_region,
        gn.ok gene_ok,
        gn.strand,
        tr.id trans_id,
        tr.name trans_name,
        tr.ok trans_ok,
        ex.id exon_id,
        ex.pos_from exon_from,
        ex.pos_to exon_to,
        ex.exon_num exon_num,
        ex.ok exon_ok
FROM gene gn INNER JOIN transcript tr
 ON gn.id = tr.gene_id INNER JOIN exon ex
 ON tr.id = ex.transcript_id
WHERE ex.ok = "3"
ORDER BY gn.id, tr.id, ex.exon_num;


CREATE OR REPLACE VIEW show_removed AS
 SELECT gn.id gene_id, 
        gn.name gene_name,
        gn.seq_region,
        gn.ok gene_ok,
        gn.strand,
        tr.id trans_id,
        tr.name trans_name,
        tr.ok trans_ok,
        ex.id exon_id,
        ex.pos_from exon_from,
        ex.pos_to exon_to,
        ex.exon_num exon_num,
        ex.ok exon_ok
FROM gene gn INNER JOIN transcript tr
 ON gn.id = tr.gene_id INNER JOIN exon ex
 ON tr.id = ex.transcript_id
WHERE ex.ok = "0"
ORDER BY gn.id, tr.id, ex.exon_num;

