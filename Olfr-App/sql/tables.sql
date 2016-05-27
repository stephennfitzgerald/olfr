CREATE TABLE IF NOT EXISTS gene (
 id                 INT(10) NOT NULL AUTO_INCREMENT,
 name               VARCHAR(255) NOT NULL,
 seq_region         VARCHAR(255) NOT NULL,
 strand             ENUM('-', '+') NOT NULL,
 ok                 ENUM('0','1', '2', '3') DEFAULT '1' NOT NULL,
 comments           TEXT NULL,

 PRIMARY            KEY(id),
 UNIQUE             KEY(name, seq_region, strand)

) COLLATE=latin1_swedish_ci ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS transcript (
 id                 INT(10) NOT NULL AUTO_INCREMENT,
 name               VARCHAR(255) NOT NULL,
 gene_id            INT(10) NOT NULL,
 ok                 ENUM('0','1', '2', '3') DEFAULT '1' NOT NULL,

 PRIMARY            KEY(id),
 UNIQUE             KEY(name),
 FOREIGN            KEY(gene_id) REFERENCES gene(id)

) COLLATE=latin1_swedish_ci ENGINE=InnoDB;


CREATE TABLE IF NOT EXISTS exon (
 id                 INT(10) NOT NULL AUTO_INCREMENT,
 exon_num           INT(10) NOT NULL,
 transcript_id      INT(10) NOT NULL,
 pos_from           INT(10) NOT NULL,
 pos_to             INT(10) NOT NULL, 
 ok                 ENUM('0','1', '2', '3') DEFAULT '1' NOT NULL,
 

 PRIMARY            KEY(id),
 FOREIGN            KEY(transcript_id) REFERENCES transcript(id)

) COLLATE=latin1_swedish_ci ENGINE=InnoDB;
