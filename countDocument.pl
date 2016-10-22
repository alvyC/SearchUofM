#!/opt/local/bin/perl

#use warnings;
use LWP::Simple;
use HTML::Strip;
use HTML::LinkExtor;
use WWW::Mechanize;

#make directories for saving web document and processed web documents
mkdir("documents", 0755);
mkdir("processed_documents", 0755);

my $baseUrl = 'http://www.cs.memphis.edu/~vrus/teaching/ir-websearch/';
my $fileLocation = "./documents/";
my $processedFileLocation = "./processed_documents/";
my $fileExtension = ".txt";
my $totalDocument;

#get all the one-click links (in the baseUrl) and push to $one_click_links
my @one_click_links = ();
push(@one_click_links, $baseUrl);
my $mechanize = WWW::Mechanize->new();
$mechanize->get($baseUrl);

my $documentNo = 0;
my @allLinks = $mechanize->links();
foreach my $link (@allLinks) {
  # don't add the links which lead to the same page or are empty line or ppt/ pdf file
  if (!($link->url =~ /\#/) and ($link->url ne "")
      and (index($link->url, "ppt") == -1)
      and (index($link->url, "pdf") == -1)) {
    push(@one_click_links, $link->url);
  }
}

foreach $link (@one_click_links) {
  #print $link, "\n";
  my $content;
  my $linkType = "absolute";
  if (($link !~ /^http/)) { # if $link is a relative path
    if ($link =~ /txt/ or $link =~ /html/) { # if $link contains the substring ".txt", it is a text document
      $linkType = "relative";
    }
  }

  $content = &getContent($link, $linkType);
  if (defined($content)) { # if content retrieval is successful
    &saveContent($content, $documentNo+1);
    $documentNo++;
  }
  else { # if content cannot be retrieved
    #print ("Failure");
    next;
  }

  $totalDocument = $documentNo;

  $wordCount = 0;
  foreach $line (split /\n/, $content) {
    @words = split(/[\s\t]+/, $line);
    $w = 0;
    while($w < @words) {
      if ($words[$w] !~ /^\s*$/) { # if the string is not only consist of spaces.
        if($words[$w] =~ /[[:punct:]]$/) { # if the word contains a punctuation at the end, only count the original word without punctuation
          #print(substr($words[$w], 0, @words[$w]-1), "\n"); # print the punctuated word
          $temp = substr($words[$w], 0, @words[$w]-1); # # if the string is a punctuation, then getting rid of it will leave us with whitespace
          if ($temp !~ /^\s*$/) { # if "temp" is not only whitespaces
            $wordFrequency{substr($words[$w], 0, @words[$w]-1)}++;
            $wordCount++;
            if (exists($words[$key])) {
              if (undef($wordFrequency{$words[$w]})) {
                $documentFrequency{$words[$w]}++;
              }
            }
          }
        }
        else {
          $wordFrequency{$words[$w]}++;
          $wordCount++;
        }
      }
      $w++;
    } # while - words
  } # foreach - line
} # foreach - link

#print("\nTotal number of words: ", $wordCount, "\n");

&preProcessContent;

sub getContent {
  my ($link, $isAbsolute) = @_;
  if($isAbsolute ne "absolute") {
    $link = $baseUrl . $link;
  }

  my $mechanize = WWW::Mechanize->new(autocheck => 0);
  my $content = $mechanize->get($link);
  if ($content->is_success) { # if the content retrieval is successful
    #print("Success: This is link to text/html file (relative path): ", $baseUrl . $link, "\n");
    $content = $mechanize->content();
    $hs = HTML::Strip->new();
    $page_text = $hs->parse($content);
    return $page_text;
  }
  else {
    #print("Failure: ", $baseUrl . $link, "\n");
    return undef;
  }
}

sub saveContent {
  my ($content, $documentNo) = @_;
  my $fileAbsolutePath = $fileLocation . $documentNo . $fileExtension;
  open(WRITEFILE, ">", $fileAbsolutePath);
  print WRITEFILE $content;
}

sub preProcessContent {
  my $documentNo = 1;
  while ($documentNo <= $totalDocument) {
    my $readFileName = $fileLocation. $documentNo . $fileExtension;
    my $writefileName = $processedFileLocation . $documentNo . $fileExtension;

    if (open(INFILE, $readFileName) || die("Can't open ", $readFileName, " for reading.")) {
       @array = <INFILE>;
    }
    close(INFILE);

    if (open(OUTFILE, ">", $writefileName) || die("Can't open ", $writefileName, " for writing.")) {
      my $i = 0;
      while ($i < @array) {
        $string = $array[i];
        $string =~ s/((?<=[^a-zA-Z0-9])(?:https?\:\/\/|[a-zA-Z0-9]{1,}\.{1}|\b)(?:\w{1,}\.{1}){1,5}(?:com|org|edu|gov|uk|net|ca|de|jp|fr|au|us|ru|ch|it|nl|se|no|es|mil|iq|io|ac|ly|sm){1}(?:\/[a-zA-Z0-9]{1,})*)//g; # Remove HTML/HTTP or any kind of URL type strings.
        $string =~ s/[[:punct:]]//g; # Remove punctuations
        $string =~ s/\d//g;          # Remove digits
        $string =~ s/^\s+//;         # Remove leading and lagging whitespaces
        $string = lc $string;        # Convert uppercases to lowercases

        print OUTFILE $string;
        $i++
      }
    }
    close(OUTFILE);

    $documentNo++;
  }
}
