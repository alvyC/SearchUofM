#!/opt/local/bin/perl

#use strict;
#use warnings;

use LWP::Simple;
use HTML::Strip;
use HTML::LinkExtor;
use WWW::Mechanize;
use Lingua::Stem::En;
use CGI;

my $totalNoDocs = 8393;
my $processedFileLocation = "./processed_documents/";
my $fileExtension = ".txt";
my %invertedIndex;
my %idf;
my %stopWordHash;
my $cgi = CGI->new;
my $query = $cgi->param("firstname");
#my $query = "Software Engineering Research";
my %docVectorLength;
my $queryVectorLength;
my %score;
my %outputLinks;

&createInvertedIndex;
#&computeIdf;
#&printInvertedIndex;
&computeDocumentVectorLength();
&rankDoc();
print "\n";

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
  print OUTFILE ("----------------------------------------------------\n");
  foreach my $word (sort keys %invertedIndex) {
    print OUTFILE ($word, " (");
    #print OUTFILE ($idf{$word}, ") ---> ");
    foreach my $doc (keys %{$invertedIndex{$word}}) {
      print OUTFILE ($doc, "|", $invertedIndex{$word}{$doc}, "; ");
    }
    print OUTFILE ("\n");
  }
}

sub initStopWordHash {
  my $stopWords = get("http://www.cs.memphis.edu/~vrus/teaching/ir-websearch/papers/english.stopwords.txt") || die "Cannot get stopwordSite" ;
  my @stopWordList = split("\n", $stopWords);
  push(@stopWordList, "memphis");
  push(@stopWordList, "university");
  foreach my $stopWord (@stopWordList) {
    $stopWordHash{$stopWord} = 1;
  }
}

sub removeStopWordsAndStem {
  my ($line) = @_;
  my @words = split(" ", $line);

  my $stemmed_words = Lingua::Stem::En::stem({-words => \@words,
                                              -locale => 'en',
                                              -exceptions => \%exceptions});
  my $processedLine = "";
  foreach my $word(@$stemmed_words) {
    if ($stopWordHash{$word} == 0) {
      $processedLine = $processedLine . " " . $word;
    }
  }

  return $processedLine;
}

sub processQueryString {
  my ($line) = @_;

  &initStopWordHash;

  $line =~ s/((?<=[^a-zA-Z0-9])(?:https?\:\/\/|[a-zA-Z0-9]{1,}\.{1}|\b)(?:\w{1,}\.{1}){1,5}(?:com|org|edu|gov|uk|net|ca|de|jp|fr|au|us|ru|ch|it|nl|se|no|es|mil|iq|io|ac|ly|sm){1}(?:\/[a-zA-Z0-9]{1,})*)//g; # Remove HTML/HTTP or any kind of URL type lines.
  $line =~ s/[[:punct:]]//g; # Remove punctuations
  $line =~ s/\d//g;          # Remove digits
  $line =~ s/^\s+//;         # Remove leading whitespaces
  $line = lc $line;          # Convert uppercases to lowercases

  $line = &removeStopWordsAndStem($line); # Remove stopwords and do stemming

  return $line;
}

sub computeDocumentVectorLength {
  $query = &processQueryString($query);

  my @queryWords = split(" ", $query);

  for(my $i = 0; $i < @queryWords; $i++) {
    my $df = keys %{$invertedIndex{$queryWords[$i]}};
    my $idf = log($totalNoDocs/ $df)/ log(10);

    # compute document vector length
    foreach my $doc (keys %{$invertedIndex{$queryWords[$i]}}) {
      my @array;
      my $fullPath = $processedFileLocation . $doc;
      #print $fullPath;
      if (open(INFILE, $fullPath) || die("Can't open ", $fullPath, " for reading")) {
        @array = <INFILE>;
      }
      close(INFILE);
      #print @array;
      my $j = 0;
      while($j < @array) {
        if ($j > 1) {
          my @tokens = split(" ", $array[$j]);
          foreach my $token (@tokens) {
            my $tf = $invertedIndex{$token}{$doc};
            #print "tf: ", $tf;
            $docVectorLength{$doc} += (($tf * $idf)**2);
          }
        }
        $j++;
        #print "\n";
      }
    }
  }

  for(my $i = 0; $i < @queryWords; $i++) {
    foreach my $doc (keys %{$invertedIndex{$queryWords[$i]}}) {
      $docVectorLength{$doc} = sqrt($docVectorLength{$doc});
      #print $docVectorLength{$doc}, " ";
    }
    #print "\n";
  }
}

sub rankDoc {
  @queryString = split(" ", $query);
  foreach my $word (@queryString) {
    my $df = keys %{$invertedIndex{$word}};
    my $idf = log($totalNoDocs/ $df)/ log(10);
    my $count = grep (/$word/, @queryString);
    my $w = $count * $idf;
    #print "w = ", $w, ", count = ", $count, ", idf: ", $idf;
    foreach my $doc (keys %{$invertedIndex{$word}}) {
      my $tf = $invertedIndex{$word}{$doc};
      $score{$doc} += ($w * $idf * $tf);
    }
  }

  #print "\n";

  foreach my $doc (%score) {
    if ($docVectorLength{$doc}) {
      $score{$doc} = $score{$doc}/ $docVectorLength{$doc};
    }
  }

  foreach my $doc (sort { $score{$b} <=> $score{$a} } keys %score) {
    my @array;
    if (open(INFILE, $processedFileLocation . $doc) || die ("Can't open ", $doc, " for reading.")) {
      @array = <INFILE>;
    }
    #print $array[0], "    score: ", $score{$doc}, "\n";
    #push(@outputLinks, $array[0]); # first line of the file is the link
    $outputLinks{$array[0]} = $score{$doc};
  }
}

  print "<html><head><title>Search Result<\/title><\/head><body>
  <DIV id=\"loginContent\" style=\"text-align:center;\">
         <div id=\"loginResult\" style=\"display:none;\"></div>";
  print "
    <form id=\"loginForm\" name=\"loginForm\" method=\"post\" action=\"rankDocs.pl\">
        <fieldset>
            <legend><b><font size=\"6\">Search UofM</font></legend>
            <p>
            <label for=\"firstname\"><b><font size=\"3\">Enter Query</font></b></label>
            <br>
            <input type=\"text\" id=\"firstname\" name=\"firstname\" class=\"text\" size=\"50\" />
            </p>
            <p>
            <button type=\"submit\" class=\"button positive\">
             Bravo Tiger
            </button>
            </p>
        </fieldset>
        </form>
  ";

 print "<table border=\"1\" align=\"center\">";
 print "<tr><th>Score</th><th>Links</th></tr>";
 for my $link (keys %outputLinks) {
    print "<tr><td>$outputLinks{$link}</td>";
    print "<td><a href=\"$link\">$link</a></td></tr>";
 }
 print "</table>";
 print "<\/DIV><\/body><\/html>";