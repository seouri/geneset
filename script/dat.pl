#!/usr/bin/perl -w
# articles.dat        : id | title | source | pubdate
# genes.dat           : id | taxnomy_id | symbol | name | chromosome | 
#                       map_location | articles_count | start_position | 
#                       end_position
# subjects.dat        : id | term
# article_genes.dat   : id | article_id | gene_id
# article_subjects.dat: id | article_id | subject_id
# gene_subjects.dat   : id | gene_id | subject_id | articles_count
# mesh_entry_terms.dat: id | subject_id | term

use strict;

my $year = 2011;
my @source = (
  "ftp://ftp.ncbi.nih.gov/gene/DATA/gene2pubmed.gz",
  "ftp://ftp.ncbi.nih.gov/gene/DATA/gene_info.gz",
  "ftp://nlmpubs.nlm.nih.gov/online/mesh/.asciimesh/d$year.bin"
);

download(@source);

my ($article_ids, $gene_ids) = do_gene2pubmed();
do_gene_info($gene_ids);
do_dbin($year);

sub download {
  my @source = @_;
  foreach my $s (@source) {
    my @path = split /\//, $s;
    my $file = $path[-1];
    my $file_unzipped = $file; $file_unzipped =~ s/\.gz$//g;
    print STDERR "DOWNLOAD $s ... ";
    `curl -s -o "tmp/$file" "$s"`
      unless -e "tmp/$file" || -e "tmp/$file_unzipped";
    `gunzip -f tmp/$file`
      if $file =~ /gz$/ && -e "tmp/$file";
    print STDERR "done.\n";
  }
}

sub do_gene2pubmed {
  open(FH, "< tmp/gene2pubmed") or die("Can't read tmp/gene2pubmed: $!\n");
  open(AG, "> tmp/article_genes.dat") or die("Can't write tmp/article_genes.dat: $!\n");
  print STDERR "WRITE article_genes.dat ... ";
  my $head = <FH>;
  my $article_gene_id = 0;
  my (%article_id, %gene_id);
  while (<FH>) {
    chomp;
    my ($tax_id, $gene_id, $article_id) = split /\t/;
    print AG join("\t", ++$article_gene_id, $article_id, $gene_id), "\n";
    ++$article_id{$article_id};
    ++$gene_id{$gene_id};
  }
  print STDERR $article_gene_id, "\n";
  print STDERR "ARTICLE: ", scalar(keys %article_id), "\n";
  print STDERR "GENE: ", scalar(keys %gene_id), "\n";
  close AG;
  close FH;
  return (\%article_id, \%gene_id);
}

sub do_gene_info {
  my $gene_ids = shift;
  open(FH, "< tmp/gene_info") or die("Can't read tmp/gene_info: $!\n");
  open(GE, "> tmp/genes.dat") or die("Can't write tmp/genes.dat: $!\n");
  print STDERR "WRITE genes.dat ... ";
  my $head = <FH>;
  while (<FH>) {
    chomp;
    my ($taxonomy_id, $gene_id, $symbol, $locus_tag, $synonyms, $dbXrefs, $chromosome, $map_location, $description, $type_of_gene, $symbol_from_nomenclature_authority, $full_name_from_nomenclature_authority, $nomenclature_status, $other_designations, $modification_date) = split /\t/;
    if ($gene_ids->{$gene_id}) {
      print GE join("\t", $gene_id, $taxonomy_id, $symbol, $description, $chromosome, $map_location, $gene_ids->{$gene_id}), "\n";
    }
  }
  print STDERR "done\n";
  close GE;
  close FH;
}

sub do_dbin {
  my $year = shift;
  my $desc = read_bin("tmp/d$year.bin");
  print STDERR "WRITE subjects.dat, mesh_entry_terms.dat ... ";
  open(SU, "> tmp/subjects.dat") or die("Can't write tmp/subjects.dat: $!\n");
  open(EN, "> tmp/mesh_entry_terms.dat") or die("Can't write tmp/mesh_entry_terms.dat: $!\n");
  my $mesh_entry_term_id = 0;
  foreach my $d (@$desc) {
    if ($d->{mn}) {
      my $tree_numbers = join(";", @{ $d->{mn} });
      if ($tree_numbers !~ /V/g) {
        my $term = $d->{mh}->[0];
        my $subject_id = $d->{ui}->[0]; $subject_id =~ s/^D0*//g;
        print SU join("\t", $subject_id, $term), "\n";
        foreach my $i (($term, @{$d->{entry}}, @{$d->{"print entry"}})) {
          $i =~ s/\|.+$//g;
          print EN join("\t", ++$mesh_entry_term_id, $subject_id, $i), "\n";
        }
      }
    }
  }
  close EN;
  close SU;
  print STDERR "done\n";
}
sub read_bin {
  my $file = shift;
  print STDERR "READ $file ... ";
  open(FH, "< $file") or die("Can't open $file: $!\n");;
  my (@file, %rec);
  while (<FH>) {
    chomp;
    if (/\*NEWRECORD/ || $_ eq "") {
      if (scalar(keys %rec) > 0) {
        my %record = %rec;
        push @file, \%record;
        %rec = ();
      }
    } elsif ($_ ne "") {
      my ($key, $val) = split / = /, $_, 2;
      $key =~ s/^\s+//g;
      $key =~ s/\s+$//g;
      $val =~ s/^\s+//g;
      $val =~ s/\s+$//g;
      push @{$rec{lc($key)}}, $val;
    }
  }
  close FH;
  print STDERR scalar(@file),  " records\n";
  return \@file;
}

