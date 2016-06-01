
DELIMITER $$
DROP PROCEDURE IF EXISTS GetNextRec$$

CREATE PROCEDURE GetNextRec (
 IN gene_id_param INT(10)
)
BEGIN
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
 WHERE gn.ok = '1' 
 AND tr.ok = '1'
 AND ex.ok = '1'
 AND gn.id = gene_id_param;
END$$
DELIMITER ;


DELIMITER $$
DROP PROCEDURE IF EXISTS DeleteGene$$

CREATE PROCEDURE DeleteGene (
 IN gene_id_param INT(10)
)
BEGIN
 UPDATE gene gn 
 INNER JOIN transcript tr 
 ON gn.id = tr.gene_id 
 INNER JOIN exon ex 
 ON tr.id = ex.transcript_id 
 SET gn.ok = '0', tr.ok = '0', ex.ok = '0'
 WHERE gn.id = gene_id_param;
END$$
DELIMITER ;


DELIMITER $$
DROP PROCEDURE IF EXISTS ResetGene$$

CREATE PROCEDURE ResetGene (
 IN gene_name_param VARCHAR(255)
)
BEGIN
 UPDATE exon ex 
 INNER JOIN transcript tr 
 ON ex.transcript_id = tr.id 
 INNER JOIN gene gn 
 ON tr.gene_id = gn.id 
 SET ex.ok = "1", tr.ok = "1", gn.ok = "1" 
 WHERE gn.name = gene_name_param;
END$$
DELIMITER ;


DELIMITER $$
DROP PROCEDURE IF EXISTS DeleteTrans$$

CREATE PROCEDURE DeleteTrans (
 IN trans_id_param INT(10)
)
BEGIN
 UPDATE transcript tr 
 INNER JOIN exon ex 
 ON tr.id = ex.transcript_id 
 SET tr.ok = '0', ex.ok = '0'
 WHERE tr.id = trans_id_param;
END$$
DELIMITER ;


DELIMITER $$
DROP PROCEDURE IF EXISTS DeleteExon$$

CREATE PROCEDURE DeleteExon (
 IN exon_id_param INT(10)
)
BEGIN
 UPDATE exon ex 
 SET ex.ok = '0'
 WHERE ex.id = exon_id_param;
END$$
DELIMITER ;


DELIMITER $$
DROP PROCEDURE IF EXISTS CheckGene$$

CREATE PROCEDURE CheckGene (
 IN gene_id_param INT(10)
)
BEGIN
 SELECT COUNT(*)
 FROM gene gn INNER JOIN transcript tr 
 ON tr.gene_id = gn.id 
 WHERE tr.ok = '1' 
 AND tr.gene_id = gene_id_param;
END$$
DELIMITER ;


DELIMITER $$
DROP PROCEDURE IF EXISTS CheckTrans$$

CREATE PROCEDURE CheckTrans (
 IN trans_id_param INT(10)
)
BEGIN
 SELECT COUNT(*)
 FROM transcript tr INNER JOIN exon ex 
 ON ex.transcript_id = tr.id 
 WHERE ex.ok = '1' 
 AND ex.transcript_id = trans_id_param;
END$$
DELIMITER ;


DELIMITER $$
DROP PROCEDURE IF EXISTS UpdateExon$$

CREATE PROCEDURE UpdateExon (
 IN exon_from_param INT(10),
 IN exon_to_param INT(10),
 IN exon_id_param INT(10)
)
BEGIN
 UPDATE exon ex INNER JOIN transcript tr
 ON tr.id = ex.transcript_id INNER JOIN gene gn
 ON gn.id = tr.gene_id
 SET ex.pos_from = exon_from_param,
 ex.pos_to = exon_to_param,
 tr.ok = '2',
 gn.ok = '2'
 WHERE ex.id = exon_id_param;
END$$
DELIMITER ;


DELIMITER $$
DROP PROCEDURE IF EXISTS AddComment$$

CREATE PROCEDURE AddComment (
 IN comments_param TEXT,
 IN gene_name_param VARCHAR(255)
)
BEGIN
 UPDATE gene 
 SET comments = comments_param
 WHERE name = gene_name_param;
END$$
DELIMITER ; 


DELIMITER $$
DROP PROCEDURE IF EXISTS UpdateComments$$

CREATE PROCEDURE UpdateComments (
 IN comments_param TEXT,
 IN gene_id_param INT(10)
)
BEGIN
 UPDATE gene 
 SET comments = comments_param
 WHERE id = gene_id_param;
END$$
DELIMITER ; 


DELIMITER $$
DROP PROCEDURE IF EXISTS AddGene$$

CREATE PROCEDURE AddGene (
 IN name_param VARCHAR(255),
 IN chr_param VARCHAR(255),
 IN strand_param ENUM('-', '+'),
 IN ok_param ENUM('0','1', '2', '3'),
 OUT insert_id int(10) 
)

BEGIN 
 INSERT INTO gene (
  name, 
  seq_region, 
  strand, 
  ok
 )
 VALUES (
  name_param,
  chr_param,
  strand_param,
  ok_param
 );
 SET insert_id = LAST_INSERT_ID();
END$$
DELIMITER ;
  

DELIMITER $$
DROP PROCEDURE IF EXISTS AddTrans$$

CREATE PROCEDURE AddTrans (
 IN name_param VARCHAR(255),
 IN gene_id_param INT(10),
 IN ok_param ENUM('0','1', '2', '3'),
 OUT insert_id int(10) 
)

BEGIN 
 INSERT INTO transcript (
  name, 
  gene_id,
  ok
 )
 VALUES (
  name_param,
  gene_id_param,
  ok_param
 );
 SET insert_id = LAST_INSERT_ID();
END$$
DELIMITER ;


DELIMITER $$
DROP PROCEDURE IF EXISTS AddExon$$

CREATE PROCEDURE AddExon (
 IN exon_num_param INT(10),
 IN trans_id_param INT(10),
 IN exon_fr_param INT(10),
 IN exon_to_param INT(10),
 IN ok_param ENUM('0','1', '2', '3')
)

BEGIN
 INSERT INTO exon (
  exon_num,
  transcript_id,
  pos_from,
  pos_to,
  ok
 )
 VALUES (
  exon_num_param,
  trans_id_param,
  exon_fr_param,
  exon_to_param,
  ok_param
 );
END$$
DELIMITER ;
