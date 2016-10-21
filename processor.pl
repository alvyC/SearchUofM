#!/opt/local/bin/perl

use LWP::Simple;
use WWW::Mechanize; #Generate links from main page
use porter;


my $stopWords = get("http://www.cs.memphis.edu/~vrus/teaching/ir-websearch/papers/english.stopwords.txt");
my @stopWordList = split("\n", $stopWords);
#&printArray(@stopWordList);

# get all the one-click url (in the baseUrl) and push to $one_click_links
my @one_click_links = ();
my $baseUrl = 'http://www.cs.memphis.edu/~vrus/teaching/ir-websearch/';
my $mechanize = WWW::Mechanize->new();
$mechanize->get($baseUrl);
my @allLinks = $mechanize->links();
foreach my $link (@allLinks) {
  if (!($link->url =~ m/\#/) && ($link->url ne "")) { # don't add the links which are in the same page and empty line
    push(@one_click_links, $link->url);
  }
}

#&printArray(@one_click_links);
$fileCount = 1;
foreach my $link (@one_click_links) {
  print($link, "\n");
  if (index($link, "txt") != -1) { # if "link" leads to a text document, retrieve the text documents
    my $textContent = get($baseUrl.$link); # get the content from the text
    if ($textContent ne "") { # if "textContent is not empty"
      # write content to input file
      #my $input_location = $ARGV[0];
      my $input_location = "/Users/alvy/Desktop/IR-input/";
      my $input_extension = ".txt";
      my $writeInFileName = $input_location . $fileCount . $input_extension;

      open (OUTPUTFILE, ">", $writeInFileName) or die("Can't open ", $writeInFileName, "\n");
      print OUTPUTFILE ("$textContent\n"); # write content to file

      # write processed content to output file
      my $output_location = "/Users/alvy/Desktop/IR-output/";
      my $output_extension = ".txt";
      my $writeOutFileName = $output_location . $fileCount . $output_extension;
      open (OUTPUTFILE2, ">", $writeOutFileName) or die "Could not open, same named file already present";

      open (INPUTFILE, "<", \$textContent);
      while (my $string = <INPUTFILE>) {
        chomp($string);
        my @fileContentArray=split(" ", $string);
        $string="";
        foreach my $word(@fileContentArray){
          $word = porter($word);
          if ($stopWordsHash{$word} == 0){
            $string= $string." ".$word; # (1 and 2) Remove stopwords and morphological variations
          }
        }
        $string =~ s/((?<=[^a-zA-Z0-9])(?:https?\:\/\/|[a-zA-Z0-9]{1,}\.{1}|\b)(?:\w{1,}\.{1}){1,5}(?:com|org|edu|gov|uk|net|ca|de|jp|fr|au|us|ru|ch|it|nl|se|no|es|mil|iq|io|ac|ly|sm){1}(?:\/[a-zA-Z0-9]{1,})*)//g; # Remove HTML/HTTP or any kind of URL type strings.
        $string =~ s/[[:punct:]]//g; # (3) Remove punctuations
        $string =~ s/\d//g;          # (2) Remove digits
        $string =~ s/^\s+//;         # (4) Remove leading and lagging whitespaces
        $string = lc $string;        # (5) Convert uppercases to lowercases

        print OUTPUTFILE2 ($link, "\n");
        print OUTPUTFILE2 ("$string\n");  # Print processed document.
      }
      $fileCount++;
    }
  }
  else { # else the link is web document
    my $textContent = get($link);
    $textContent =~ s/<.*?>//g;
    if ($textContent ne "") {
      my $input_location = "/Users/alvy/Desktop/IR-input/";
      my $input_extension = ".txt";
      my $writeInFileName = $input_location . $fileCount . $input_extension;
      open (OUTPUTFILE3, ">", $writeInFileName) or die("Can't open ", $writeInFileName, "\n");
      print OUTPUTFILE3 ("$textContent\n"); # write content to file
    }
    $fileCount++;
  }
} # for-each

# helper method for printing arrays
sub printArray {
  my @array = @_;
  foreach $item (@array) {
    print($item, "\n");
  }
}