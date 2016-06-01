package Olfr::App;
use warnings;
use strict;
use Carp;
use Dancer2;
use String::Random qw(random_regex);
use Data::Dumper;
use DBI;


our $VERSION = '0.1';
our $db_name = 'gencode_sf5_mouse_olfr_models';
our $public_dir = './public/';


get '/' => sub {
  template 'index', {
   next_gene_url         => uri_for('/next_gene'),
   add_a_transcript_url  => uri_for('/add_a_transcript'),
   download_gtf_url      => uri_for('/download_gtf'),
   dump_the_db_url       => uri_for('/dump_the_db'),
   gtf_file              => undef,
   db_dump               => undef,
  };
};

get '/dump_the_db' => sub {

  my $dump_name = "db_dumps/$db_name" . q{_} . random_regex('\w'x15) . '.mysql';
  my $dump_dir = $public_dir . $dump_name;
  my $db_dump = undef;
  system("mysqldump -u$ENV{GC_USER} -p$ENV{GC_PASS} -P$ENV{GC_PORT} -h$ENV{GC_HOST} $db_name | gzip > $dump_dir.gz");
  if(-s "$dump_dir.gz") {
   $db_dump = 1;   
  }
 
  template 'index', {
   next_gene_url         => uri_for('/next_gene'),
   add_a_transcript_url  => uri_for('/add_a_transcript'),
   download_gtf_url      => uri_for('/download_gtf'),
   dump_the_db_url       => uri_for('/dump_the_db'),
   gtf_file              => undef,
   db_dump               => $db_dump,
  };

};


get '/download_gtf' => sub {

  my $dbh = get_schema(); 
  my $gtf_file = 'download_files/olfr_models_' . random_regex('\w'x15) . '.gtf';
  my $file_dir = $public_dir . $gtf_file;
  my %H;
  my $get_gtf_sth = $dbh->prepare("SELECT * FROM show_all"); 
  $get_gtf_sth->execute;

  while(my $row =$get_gtf_sth->fetchrow_arrayref) {
   push@{ $H{ $row->[6] }{ $row->[7] }{ $row->[8] }{ $row->[9] } }, [ @{ $row }[0..5] ],   
  }

  open IN, q{>}, $file_dir or croak("can't open file $file_dir"); 
  foreach my $chrom(sort keys %H) {
   foreach my $start(sort {$a <=> $b} keys %{ $H{$chrom} }) {
    foreach my $end(sort {$a <=> $b} keys %{ $H{$chrom}{$start} }) {
     foreach my $strand( keys %{ $H{$chrom}{$start}{$end} }) {
      foreach my $anno(@{ $H{$chrom}{$start}{$end}{$strand} }) {
       my $nar = 'gene_id "' . $anno->[3] . '"; transcript_id "' . $anno->[4] .'"; exon_number "' . $anno->[5] . '";';
       print IN join("\t", $chrom, 'new_model', 'exon', $start, $end, q{.}, $strand, q{.}, $nar), "\n";
      }
     }
    }
   }
  } 
  close(IN);

  template 'index', {
   next_gene_url         => uri_for('/next_gene'),
   add_a_transcript_url  => uri_for('/add_a_transcript'),
   download_gtf_url      => uri_for('/download_gtf'),
   dump_the_db_url       => uri_for('/dump_the_db'),
   gtf_file              => $gtf_file, 
   db_dump               => undef,
  };
};

get '/next_gene' => sub {
 
  my $dbh = get_schema();

  if(my $gene_not_ok = param('gene_not_ok[]')) {
   my $del_gene_sth = $dbh->prepare("CALL DeleteGene(?)");
   if(ref($gene_not_ok) eq 'ARRAY') {
    my %H;
    foreach my $gene_id(@{ $gene_not_ok }) {
     $H{ $gene_id }++;
    }
    foreach my $g_id(keys %H) {
     $del_gene_sth->execute($g_id);
    }
   }
   else {
    $del_gene_sth->execute($gene_not_ok);
   }
  }
  elsif(my $trans_not_ok = param('trans_not_ok[]')) {
   my $del_trans_sth = $dbh->prepare("CALL DeleteTrans(?)");
   my $gene_id = param('tgene_id');
   my $tgene_id;
   if(ref($gene_id) eq 'ARRAY') {
    $tgene_id = $gene_id->[0];
   }
   else {
    $tgene_id = $gene_id;
   }
   if(ref($trans_not_ok) eq 'ARRAY') {
    my %H;
    foreach my $trans_id(@{ $trans_not_ok }) {
     $H{ $trans_id }++;
    }
    foreach my $t_id(keys %H) {
     $del_trans_sth->execute($t_id);
    }
   }
   else {
    $del_trans_sth->execute($trans_not_ok);
   }
   my $ck_gene_sth = $dbh->prepare("CALL CheckGene(?)");
   $ck_gene_sth->execute($tgene_id);
   my $ck_gene = $ck_gene_sth->fetchall_arrayref;
   if(! $ck_gene->[0]->[0]) {
    $dbh->do("CALL DeleteGene(?)", undef, $tgene_id); 
   }
  }
  elsif(my $exon_not_ok = param('exon_not_ok[]')) {
   my $gene_id = param('egene_id');
   my $trans_ids = param('etrans_ids');
   my $egene_id;
   if(ref($gene_id) eq 'ARRAY') {
    $egene_id = $gene_id->[0];
   }
   else {
    $egene_id =  $gene_id;
   }
   my $del_exon_sth = $dbh->prepare("CALL DeleteExon(?)");
   if(ref($exon_not_ok) eq 'ARRAY') { 
    my %H;
    foreach my $exon_id( @{ $exon_not_ok }) {
     $H{ $exon_id }++;
    }
    foreach my $e_id(keys %H) {
     $del_exon_sth->execute($e_id);
    }
   }
   else {
    $del_exon_sth->execute($exon_not_ok);
   }
   my $ck_gene_sth = $dbh->prepare("CALL CheckTrans(?)");
   my %T;
   if(ref($trans_ids) eq 'ARRAY') {
    foreach my $trans_id(@{ $trans_ids }) {
     $T{ $trans_id }++;
    }    
   }
   else {
    $T{ $trans_ids }++;
   } 
   foreach my $trans_id(keys %T) {
    my $ck_trans_sth = $dbh->prepare("CALL CheckTrans(?)");
    $ck_trans_sth->execute($trans_id);
    my $ck_trans = $ck_trans_sth->fetchall_arrayref;
    if(! $ck_trans->[0]->[0]) {
     $dbh->do("CALL DeleteTrans(?)", undef, $trans_id);
    }
    my $ck_gene_sth = $dbh->prepare("CALL CheckGene(?)");
    $ck_gene_sth->execute($egene_id);
    my $ck_gene = $ck_gene_sth->fetchall_arrayref;
    if(! $ck_gene->[0]->[0]) {
     $dbh->do("CALL DeleteGene(?)", undef, $egene_id);
    }
   }
  }
  else {
   my $exfrom = param("exon_from");
   my $exto = param("exon_to");
   my $ex_ids = param("efexon_id");
   if(ref($exfrom) eq "ARRAY"){
    for(my$i=0;$i<@$exfrom;$i++) {
     $dbh->do("CALL UpdateExon(?,?,?)", undef, $exfrom->[$i], $exto->[$i], $ex_ids->[$i]);
    }
   }
   else {
    $dbh->do("CALL UpdateExon(?,?,?)", undef, $exfrom, $exto, $ex_ids);
   }
  }

  my $comments = param("comments");
  my $com_gen_id = param("com_gen_id");
  if($comments) {
   $dbh->do("CALL UpdateComments(?,?)", undef, $comments, $com_gen_id);
  }


  my $ng_sth = $dbh->prepare("SELECT * FROM next_gene");
  $ng_sth->execute;
  my $ng = $ng_sth->fetchall_arrayref;
  my $n_row_sth = $dbh->prepare("CALL GetNextRec(?)");
  $n_row_sth->execute($ng->[0]->[0]);
  my $col_names = $n_row_sth->{'NAME'};
  my $next_gene = $n_row_sth->fetchall_arrayref;
  unshift@{ $next_gene }, $col_names;
 
  my $ct_gn_sth = $dbh->prepare("SELECT * FROM count_genes");
  $ct_gn_sth->execute;
  my $cgn = $ct_gn_sth->fetchall_arrayref;
  
  my $ct_ts_sth = $dbh->prepare("SELECT * FROM count_trans");
  $ct_ts_sth->execute;
  my $cts = $ct_ts_sth->fetchall_arrayref;
 
  my $dt_gn_sth = $dbh->prepare("SELECT * FROM done_genes");
  $dt_gn_sth->execute;
  my $dgn = $dt_gn_sth->fetchall_arrayref;
  
  my $dt_ts_sth = $dbh->prepare("SELECT * FROM done_trans");
  $dt_ts_sth->execute;
  my $dts = $dt_ts_sth->fetchall_arrayref;
  
  my $del_gn_sth = $dbh->prepare("SELECT * FROM del_genes");
  $del_gn_sth->execute;
  my $del_gn = $del_gn_sth->fetchall_arrayref;
  
  my $del_ts_sth = $dbh->prepare("SELECT * FROM del_trans");
  $del_ts_sth->execute;
  my $del_ts = $del_ts_sth->fetchall_arrayref;
  
  my $add_gn_sth = $dbh->prepare("SELECT * FROM add_genes");
  $add_gn_sth->execute;
  my $add_gn = $add_gn_sth->fetchall_arrayref;
  
  my $add_ts_sth = $dbh->prepare("SELECT * FROM add_trans");
  $add_ts_sth->execute;
  my $add_ts = $add_ts_sth->fetchall_arrayref;
  
  
  template 'next_gene', {
   next_gene     => $next_gene, 
   gene_count    => $cgn->[0]->[0],
   trans_count   => $cts->[0]->[0],
   done_genes    => $dgn->[0]->[0], 
   done_trans    => $dts->[0]->[0],
   del_genes     => $del_gn->[0]->[0],
   del_trans     => $del_ts->[0]->[0],
   add_genes     => $add_gn->[0]->[0],
   add_trans    => $add_ts->[0]->[0],
   next_gene_url => uri_for('/next_gene'),
  };

};


get '/add_a_transcript' => sub {
 
 my $dbh = get_schema();


 my($gene_name, $trans_name, $chromosome, $sel_strand) = 
 (param('gene_name'), param('trans_name'), param('chromosome'), param('strand'));

 my($exon_numb, $exon_fr, $exon_to) = (param('exon_number'), param('exon_from'), param('exon_to'));

 my $gene_comment = param('gene_comment');
 
 my ($wrong_chrom, $wrong_strand, $wrong_trans);

 if($gene_name && $trans_name && $chromosome && $sel_strand) {
  my($new_gene_id, $new_trans_id, $orig_chr, $orig_strand);
  my $gene_id_sth = $dbh->prepare("SELECT id, seq_region, strand FROM gene WHERE name = ?");
  $gene_id_sth->execute("$gene_name");
  my $gene_id = $gene_id_sth->fetchall_arrayref;
  if(@{ $gene_id }) {
   ($new_gene_id, $orig_chr, $orig_strand) = @{ $gene_id->[0] };
   if($orig_chr ne $chromosome) {
    $wrong_chrom = 1;
   }
   if($sel_strand ne $orig_strand) {
    $wrong_strand = 1;
   }
  }
  my $trans_id_sth = $dbh->prepare("SELECT tr.id FROM transcript tr INNER JOIN gene gn on gn.id = tr.gene_id 
                                   WHERE gn.name = ? AND tr.name = ?");
  $trans_id_sth->execute("$gene_name", "$trans_name");
  my $trans_id = $trans_id_sth->fetchall_arrayref;
  $wrong_trans = $trans_id->[0]->[0];
  if(! $wrong_chrom && ! $wrong_strand && ! $wrong_trans) {
   if(! $new_gene_id) {
    my $add_new_gene_sth = $dbh->prepare("CALL AddGene(?,?,?,?,\@gene_insert_id)");
    $add_new_gene_sth->execute($gene_name, $chromosome, $sel_strand, '3');
    ($new_gene_id) = $dbh->selectrow_array("SELECT \@gene_insert_id");
   }
   my $add_new_trans_sth = $dbh->prepare("CALL AddTrans(?,?,?,\@trans_insert_id)");  
   $add_new_trans_sth->execute($trans_name, $new_gene_id, '3');
   ($new_trans_id) = $dbh->selectrow_array("SELECT \@trans_insert_id");
   for(my$i=0;$i<@$exon_fr;$i++) {
    if($exon_fr->[$i] && $exon_to->[$i]) {
     $dbh->do("CALL AddExon(?,?,?,?,?)", undef, $exon_numb->[$i], $new_trans_id, $exon_fr->[$i], $exon_to->[$i], '3');
    }
   }
  }
 }
 if($gene_comment) {
  $dbh->do("CALL AddComment(?,?)", undef, $gene_comment, $gene_name);
 }

 my $chr = ["select","1","10","11","12","13","14","15","16","17","18","19","2","3","4","5","6","7","8","9","MT","X","Y"];

 my $strand = ['select','-','+'];
 
 my $exons = [1,2,3,4,5,6];
 
 $wrong_trans = $wrong_trans ? $trans_name : undef;
 
 my $ct_gn_sth = $dbh->prepare("SELECT * FROM count_genes");
 $ct_gn_sth->execute;
 my $cgn = $ct_gn_sth->fetchall_arrayref;
 
 my $ct_ts_sth = $dbh->prepare("SELECT * FROM count_trans");
 $ct_ts_sth->execute;
 my $cts = $ct_ts_sth->fetchall_arrayref;

 my $dt_gn_sth = $dbh->prepare("SELECT * FROM done_genes");
 $dt_gn_sth->execute;
 my $dgn = $dt_gn_sth->fetchall_arrayref;
 
 my $dt_ts_sth = $dbh->prepare("SELECT * FROM done_trans");
 $dt_ts_sth->execute;
 my $dts = $dt_ts_sth->fetchall_arrayref;
 
 my $del_gn_sth = $dbh->prepare("SELECT * FROM del_genes");
 $del_gn_sth->execute;
 my $del_gn = $del_gn_sth->fetchall_arrayref;
 
 my $del_ts_sth = $dbh->prepare("SELECT * FROM del_trans");
 $del_ts_sth->execute;
 my $del_ts = $del_ts_sth->fetchall_arrayref;

 my $add_gn_sth = $dbh->prepare("SELECT * FROM add_genes");
 $add_gn_sth->execute;
 my $add_gn = $add_gn_sth->fetchall_arrayref;

 my $add_ts_sth = $dbh->prepare("SELECT * FROM add_trans");
 $add_ts_sth->execute;
 my $add_ts = $add_ts_sth->fetchall_arrayref;



 template 'add_a_transcript', { 
  add_a_transcript_url  => uri_for('/add_a_transcript'),   
  gene_count    => $cgn->[0]->[0],
  trans_count   => $cts->[0]->[0],
  done_genes    => $dgn->[0]->[0], 
  done_trans    => $dts->[0]->[0],
  del_genes     => $del_gn->[0]->[0],
  del_trans     => $del_ts->[0]->[0],
  add_genes     => $add_gn->[0]->[0],
  add_trans     => $add_ts->[0]->[0],
  chromosomes   => $chr,
  strand        => $strand,
  exons         => $exons,
  wrong_chrom   => $wrong_chrom,
  wrong_strand  => $wrong_strand,
  wrong_trans   => $wrong_trans, 
 };

};


sub get_schema { 
 my ( $host, $port ) = ( $ENV{'GC_HOST'}, $ENV{'GC_PORT'} );
 return DBI->connect( "DBI:mysql:$db_name;host=$host;port=$port",
    $ENV{'GC_USER'}, $ENV{'GC_PASS'} )
    or die "Cannot connect to database $db_name\n$?";
}

true;
