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
my $query = "Muktadir Chowdhury Computer Science";
my $cgi = CGI->new;
#my $query = $cgi->param("firstname");
my %docVectorLength;
my @outputLinks;

&createInvertedIndex;
#&computeIdf;
#&printInvertedIndex;
&computeDocumentVectorLength($query);

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

sub initStopWordHash {
  my $stopWords = get("http://www.cs.memphis.edu/~vrus/teaching/ir-websearch/papers/english.stopwords.txt") || die "Cannot get stopwordSite" ;
  my @stopWordList = split("\n", $stopWords);
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
  my ($query) = @_;
  $query = &processQueryString($query);

  my @queryWords = split(" ", $query);

  my $i = 0;
  # foreach my $word (sort keys %invertedIndex) {
  #   if (lc($queryWords[$i]) eq $word) {
  #     print $word, ": \n";
  #     my $df = keys %{$invertedIndex{$word}};
  #     my $idf = log($totalNoDocs/$df);
  #     #print "df = ", $df, "\n";
  #     foreach my $doc (keys %{$invertedIndex{$word}}) {
  #       print $doc, " | ";
  #       my $tf = $invertedIndex{$word}{$doc};
  #       #print $tf, ", ";
  #       $docVectorLength{$doc} += ($tf * $idf)
  #     }
  #     print "\n";
  #     $i++;
  #   }

  #   if ($i == @queryWords) {
  #     last;
  #   }
  # }

  for($i = 0; $i < @queryWords; $i++) {
    print $queryWords[$i], "(df) = ";
    my $df = keys %{$invertedIndex{$queryWords[$i]}};
    print $df, "\n";
  }

  foreach my $doc (sort keys %docVectorLength) {
    $docVectorLength{$doc} = sqrt($docVectorLength{$doc});
    #print $doc, ": " ,$docVectorLength{$doc}, ", ";
    my @array;
    if (open(INFILE, $processedFileLocation . $doc) || die ("Can't open ", $doc, " for reading.")) {
      @array = <INFILE>;
    }
    #print $array[0], "\n";
    push(@outputLinks, $array[0]); # first line of the file is the link
  }
  #print "\n";
}

#Html Code
# print $cgi->header( "text/html" );
#   print "<HTML><HEAD><TITLE>Search Result<\/TITLE><\/HEAD>
#   <DIV id=\"loginContent\" style=\"text-align:center;\">
#          <div id=\"loginResult\" style=\"display:none;\"></div>";
#   print "
#   <form id=\"loginForm\" name=\"loginForm\" method=\"post\" action=\"rankDocs.pl\">
#         <fieldset>
#             <legend><b><font size=\"6\">Search Engine</font></legend>
#             <p>
#             <label for=\"firstname\"><b><font size=\"3\">Enter Query</font></b></label>
#             <br>
#             <input type=\"text\" id=\"firstname\" name=\"firstname\" class=\"text\" size=\"50\" />
#             </p>
#             <p>
#             <button type=\"submit\" class=\"button positive\">
#              Bravo Tiger
#             </button>
#             </p>
#         </fieldset>
#         </form>
#   ";

#   print "<table border=\"1\" align=\"center\">";
#   print "<tr><th>Scores</th><th>Links</th></tr>";
#   for($s=0; $s < @outputLinks; $s++) {
#            print "<tr><td>$outputLinks[$s]</td>";
#            print "<td><a href=\"$outputLinks[$s]\">$outputLinks[$s]</a></td></tr>";
#       }
#          print "</table>";
# print "<\/DIV><\/body><\/HTML>";