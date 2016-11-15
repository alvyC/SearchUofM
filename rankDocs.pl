#!/opt/local/bin/perl

my $totalNoDocs = 8393;
my $processedFileLocation = "./processed_documents/";
my $fileExtension = ".txt";
my %invertedIndex;
my %idf;

&createInvertedIndex;

sub createInvertedIndex {
  my $documentNo = 1;
  foreach my $file (@fileList) {
    my $docName = "./processed_documents/";
    $docName = $docName . $documentNo . $fileExtension;
    if (open(INFILE, $file) || die("Can't open ", $file, " for reading")) {
      @array = <INFILE>;
    }
    close(INFILE);

    my $i = 0;
    while($i < @array) {
      my @words = split(" ", $array[$i]);
      foreach my $word (@words) {
        $invertedIndex{$word}{$docName}++;
      }
      $i++;
    } # while @array
    $documentNo++;
  } # foreach @fileList
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
    my $tf = keys %invertedIndex{$word};
    my $idf{$word} = log($totalNoDocs/$df);

    foreach my $doc (keys %{$invertedIndex{$word}}) {
      # do nothing for now

    }
  }
}


print log(2/ 2);
print ("\n");