#!/opt/local/bin/perl

use strict;
use warnings;

my $totalNoDocs = 8393;
my $processedFileLocation = "./processed_documents/";
my $fileExtension = ".txt";
my %invertedIndex;
my %idf;
my @queryWords;

sub createInvertedIndex {
  my $documentNo = 1;
  while ($documentNo <= $totalNoDocs) {
    my @array;
    my $docName = $documentNo . $fileExtension;
    my $fullPath = $processedFileLocation . $docName;
    if (open(INFILE, $fullPath) || die("Can't open ", $fullPath, " for reading")) {
      @array = <INFILE>;
    }
    close(INFILE);

    my $i = 0;
    while($i < @array) {
      if ($i > 1) { # ignore the first two line which are metadata
        my @words = split(" ", $array[$i]);
        foreach my $word (@words) {
          $invertedIndex{$word}{$docName}++;
        }
      } # if
      $i++;
    } # while @array
    $documentNo++;
  } # while
}

sub printInvertedIndex {
  open(OUTFILE, ">inverted-index.txt");
  print OUTFILE ("   Word (idf) ----> Document No | Term Frequency\n");
  print OUTFILE ("----------------------------------------------\n");
  foreach my $word (sort keys %invertedIndex) {
    print OUTFILE ($word, " (");
    print OUTFILE ($idf{$word}, ") ---> ");
    foreach my $doc (keys %{$invertedIndex{$word}}) {
      print OUTFILE ($doc, "|", $invertedIndex{$word}{$doc}, "; ");
    }
    print OUTFILE ("\n");
  }
}

# df = keys %invertedIndex;
# tf = keys %invertedIndex{$word}

# Let N be the total number of Documents;
# For each token, T, in V:
#       Determine the total number of documents, m,
#           in which T occurs
#       Set the IDF for T to log(N/m);
sub computeIdf {
  foreach my $word (sort keys %invertedIndex) {
    my $df = keys %invertedIndex;
    my $tf = keys %{$invertedIndex{$word}};
    $idf{$word} = log($totalNoDocs/$df);

    foreach my $doc (keys %{$invertedIndex{$word}}) {
      # do nothing for now

    }
  }
}

&createInvertedIndex;
&computeIdf;
&printInvertedIndex;
