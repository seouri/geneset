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
my ($subject_ids, $ancestor_ids) = do_dbin($year);
download_medline($article_ids);
do_medline();
do_gene_subjects();

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
    ++$article_id{$article_id}->{$gene_id};
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
  unless (-e "tmp/genes.dat") {
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
}

sub do_dbin {
  my $year = shift;
  my (%subject_id, %ancestor_id, %tree2subject_id);
  my $desc = read_bin("tmp/d$year.bin");
  print STDERR "WRITE subjects.dat, mesh_entry_terms.dat ... ";
  open(SU, "> tmp/subjects.dat") or die("Can't write tmp/subjects.dat: $!\n");
  open(EN, "> tmp/mesh_entry_terms.dat") or die("Can't write tmp/mesh_entry_terms.dat: $!\n");
  my $mesh_entry_term_id = 0;
  foreach my $d (@$desc) {
    if ($d->{mn}) {
      my $subject_id = $d->{ui}->[0]; $subject_id =~ s/^D0*//g;
      my @tree_number = grep { $_ !~ /V/ } @{ $d->{mn} };
      if ($#tree_number >= 0) {
        my $term = $d->{mh}->[0];
        print SU join("\t", $subject_id, $term), "\n";
        foreach my $i (($term, @{$d->{entry}}, @{$d->{"print entry"}})) {
          $i =~ s/\|.+$//g;
          print EN join("\t", ++$mesh_entry_term_id, $subject_id, $i), "\n";
        }
        $subject_id{$term} = $subject_id;
      }
      foreach my $t (@tree_number) {
        $tree2subject_id{$t} = $subject_id;
      }
    }
  }
  close EN;
  close SU;
  print STDERR "done\n";
  foreach my $d (@$desc) {
    if ($d->{mn}) {
      my $term = $d->{mh}->[0];
      my $subject_id = $subject_id{$term};
      foreach my $t (grep { $_ !~ /V/ } @{ $d->{mn} }) {
        my @tree_part = split(/\./, $t);
        pop @tree_part;
        while ($#tree_part >= 0) {
          my $tree_number = join(".", @tree_part);
          my $ancestor_id = $tree2subject_id{$tree_number};
          ++$ancestor_id{$subject_id}->{$ancestor_id};
          pop @tree_part;
        }
      }
    }
  }
  return (\%subject_id, \%ancestor_id);
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

sub download_medline {
  my $article_ids = shift;
  my $epost = "http://www.ncbi.nlm.nih.gov/entrez/eutils/epost.fcgi";
  my $efetch = "http://www.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi";
  my @pmids = sort { $a <=> $b } keys %$article_ids;
  for (my $begin = 0; $begin <= $#pmids; $begin += 10000) {
    my $end = $begin + 9999;
    $end = $#pmids if $end > $#pmids;
    print STDERR "DOWNLOAD pubmed [", $begin + 1, " - ", $end + 1, "] ... ";
    my $output = "tmp/" . join(".", "geneset", $begin + 1, $end + 1, "medline",  "txt");
    unless (-e $output) {
      my $id = join(",", @pmids[$begin .. $end]);
      my $response = `curl -s -F "db=pubmed" -F "tool=medvane" -F "email=joon\@medvane.org" -F "id=$id" "$epost"`;
      if ($response =~ /<WebEnv>(.+)<\/WebEnv>/) {
        my $webenv = $1;
        my $response = `curl -s -o "$output" -F "rettype=medline" -F "retmode=text" -F "db=pubmed" -F "tool=medvane" -F "email=joon\@medvane.org" -F "WebEnv=$webenv" -F "query_key=1" "$efetch"`;
      }
    }
    my $count = `grep "^PMID" $output | wc -l`; $count =~ s/^\s*(\d+)\s*$/$1/;
    if ($count == ($end - $begin + 1)) {
      print STDERR "OK\n";
    } else {
      print STDERR "ERROR [$count]\n";
      #`rm $output`;
    }
  }
}

sub do_medline {
  open(AR, "> tmp/articles.dat") or die("Can't write tmp/articles.dat: $!\n");
  open(AS, "> tmp/article_subjects.dat") or die("Can't write tmp/article_subjects.dat: $!\n");
  my $article_subject_id = 0;
  foreach my $i (<tmp/geneset*.medline.txt>) {
    print STDERR "PARSE $i ... ";
    open(FH, "< $i") or die("Can't read $i: $!\n");
    $/ = "\n\n";
    while (<FH>) {
      my $record = $_;
      my $rec = parse_medline($_);
      my $pmid = $rec->{PMID}->[0];
      my $ti = $rec->{TI}->[0] || "[No title available]";
      my $dp = $rec->{DP}->[0]; $dp =~ s/^(\d{4}).+$/$1/g;
      my $so = $rec->{SO}->[0] || $rec->{BTI}->[0];
      if ($pmid && $ti && $so && $dp) {
        print AR join("\t", $pmid, $ti, $so, $dp), "\n";
      } else {
        print STDERR "ERROR [$pmid|$ti|$so|$dp][$record]\n" 
      }
      my @subject_id = subject_id($rec->{MH});
      print AS join("\n", map { join("\t", ++$article_subject_id, $pmid, $_) } @subject_id), "\n";
    }
    $/ = "\n";
    close FH;
    print STDERR "done\n";
  }
  close AS;
  close AR;
  print STDERR "done\n";
}

sub do_gene_subjects {
  open(GS, "> tmp/gene_subjects.dat") or die("Can't write tmp/gene_subjects.dat: $!\n");
  my $gene_subject_id = 0;
  my $parts = 2;
  foreach my $part (0 .. ($parts - 1)) {
    my %gene_subject;
    foreach my $i (<tmp/geneset*.medline.txt>) {
      print STDERR "PARSE $i ... ";
      open(FH, "< $i") or die("Can't read $i: $!\n");
      $/ = "\n\n";
      while (<FH>) {
        my $record = $_;
        my $rec = parse_medline($_);
        my $pmid = $rec->{PMID}->[0];
        my @subject_id = subject_id($rec->{MH});
        my @gene_id = sort keys %{ $article_ids->{$pmid} } if $pmid;
        foreach my $s (@subject_id) {
          foreach my $g (@gene_id) {
            ++$gene_subject{$s}->{$g} if $g % $parts == $part;
          }
        }
      }
      $/ = "\n";
      close FH;
      print STDERR "done\n";
    }
    print STDERR "WRITE tmp/gene_subjects.dat ... ";
    foreach my $s (keys %gene_subject) {
      foreach my $g (keys %{ $gene_subject{$s} }) {
        if ($gene_subject{$s}->{$g}) {
          print GS join("\t", ++$gene_subject_id, $g, $s, $gene_subject{$s}->{$g}), "\n";
          #delete $gene_subject{$g};
        }
      }
    }
    print STDERR "done\n";
  }
  close GS;
}

sub parse_medline {
  my $str = shift;
  my %rec;
  my @line = split /\n/, $str;
  my $last_key = "";
  foreach my $l (@line) {
    my $key = substr($l, 0, 4);
    $key =~ s/\s+$//g;
    my $val = substr($l, 6);
    if ($key) {
      push @{ $rec{$key} }, $val;
      $last_key = $key;
    } elsif ($val) {
      my $last_idx = $#{ $rec{$last_key} };
      $rec{$last_key}->[$last_idx] .= " " . $val;
    }
  }
  return \%rec;
}

sub subject_id {
  my $subjects = shift;
  my @majr = map { s/\/.+$//g; s/\*//g; $_ } grep { /\*/ } @$subjects;
  my %subject_id;
  foreach my $m (@majr) {
    my $subject_id = $subject_ids->{$m};
    ++$subject_id{$subject_id};
    my @ancestor_id = keys %{ $ancestor_ids->{$subject_id} };
    foreach my $a (@ancestor_id) {
      ++$subject_id{$a};
    }
  }
  my @subject_id = sort { $a <=> $b } keys %subject_id;
  return @subject_id;
}
