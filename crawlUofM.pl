#!/opt/local/bin/perl

#use warnings;
use LWP::Simple;
use HTML::Strip;
use HTML::LinkExtor;
use WWW::Mechanize;
use Lingua::Stem::En;

use open ':std', ':encoding(UTF-8)';

#make directories for saving web document and processed web documents
# 0755 = permisson level
mkdir("documents", 0755);
mkdir("processed_documents", 0755);

my $baseUrl = "http://www.memphis.edu";                       # where the crawling will start
my $fileLocation = "./documents/";                            # web documents will be stored in this directory
my $processedFileLocation = "./processed_documents/";         # processed web documents will be stored in this directory
my $fileExtension = ".txt";                                   # web documents will be stored as text files
my %stopWordHash;                                             # hash for stop words
my $totalDocument;                                            # total # of web documents stored
my @fileList;                                                 # it has name of all the preprocessed files/ documents
my %invertedIndex;                                            # word to document matrix
my $maxNoOfWebDocs = 10000;

&crawlBaseUrl($baseUrl);
&initStopWordHash;
&preProcessContent;
&createInvertedIndex;
&printInvertedIndex;
print("Crawling completed for memphis.edu domain.\n");

# Start Crawling from the url provided in the parameter
# First get all the links (using getAllLinks())
# Then, get content from each link (using getContent())

sub crawlBaseUrl {
  my ($url) = @_;
  my @one_click_links = ();
  push(@one_click_links, $url);
  my $mechanize = WWW::Mechanize->new();
  $mechanize->get($url);

  my $documentNo = 0;
  my @allLinks = getAllLinks($url);

  open(WRITEFILE, ">all-links.txt");
  print WRITEFILE $link;   #
  print WRITEFILE ( "\n");

  foreach $link (@allLinks) {
    #print $link, "\n";
    my $content;
    my $linkType = "absolute";

    $content = &getContent($link, $linkType);

    if (defined($content)) { # if content retrieval is successful
      &saveContent($link, $content, $documentNo + 1);
      $documentNo++;
    }
    else { # else content cannot be retrieved, go to the next link
      #print ("Failure");
      next;
    }

    $totalDocument = $documentNo;

    print WRITEFILE $link;
    print WRITEFILE ( "\n");
  } # foreach - link
} # crawlBaseUrl


sub getAllLinks {
  print("Crawling ....\n");
  my ($url) = @_;

  my @urlQueue = ();                                    # Queue for visiting the urls in BFS order
  my %urlIsVisited;                                     # if a url is visited give it value of 1, otherwise 0
  my @allUrls = ();

  push(@urlQueue, $url);
  $urlIsVisited{$url} = 1;

  $i = 1;
  while(@urlQueue) {
    my $currentUrl = shift @urlQueue;

    my $mechanize = WWW::Mechanize->new(autocheck => 0);
    $mechanize->get($currentUrl);

    if ($mechanize->res->is_success) {                   # if $mechanize->get($currentUrl) is successful
      my @childrenLinks = $mechanize->links();

      foreach my $link (@childrenLinks) {
        my $childUrl = $link->url;

        if (!($childUrl =~ /\#/) and ($childUrl ne "") and (index($childUrl, "ppt") == -1)
            and (index($childUrl, "pdf") == -1) and ($childUrl =~ /^http/) and ($childUrl =~ /memphis.edu/)) {
          if ($urlIsVisited{$childUrl} != 1) {           # if the childUrl is not visited
                push(@urlQueue, $childUrl);              # push the child url in the queue
                $urlIsVisited{$childUrl} = 1;            # mark the child url as visited
                push(@allUrls, $childUrl);
          }
        }
        if (@urlQueue > $maxNoOfWebDocs) {
          last;
        }
      }

      if (@urlQueue > $maxNoOfWebDocs) {
          last;
      }
    }
    if (@urlQueue > $maxNoOfWebDocs) {
      last;
    }
  } # while - url queue
  return @allUrls;
} #getAllLinks

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
} # getContent

sub saveContent {
  my ($link, $content, $documentNo) = @_;
  my $fileAbsolutePath = $fileLocation . $documentNo . $fileExtension;
  open(WRITEFILE, ">", $fileAbsolutePath);
  print WRITEFILE $link;
  print WRITEFILE ("\n=======================================================================================\n");
  print WRITEFILE $content;
} # saveContent

sub initStopWordHash {
  my $stopWords = get("http://www.cs.memphis.edu/~vrus/teaching/ir-websearch/papers/english.stopwords.txt") || die "Cannot get stopwordSite" ;
  my @stopWordList = split("\n", $stopWords);
  foreach my $stopWord (@stopWordList) {
    $stopWordHash{$stopWord} = 1;
  }
} # initStopWordHash

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
} # removeStopWordsAndStem

#preprocess content and save the processed content to a file
sub preProcessContent {
  print ("Processing contents ......\n");
  my $documentNo = 1;
  while ($documentNo <= $totalDocument) {
    my $readFileName = $fileLocation. $documentNo . $fileExtension;
    my $writefileName = $processedFileLocation . $documentNo . $fileExtension;

    if (open(INFILE, $readFileName) || die("Can't open ", $readFileName, " for reading.")) {
       @array = <INFILE>;
    }
    close(INFILE);

    # print(@array);
    if (open(OUTFILE, ">", $writefileName) || die("Can't open ", $writefileName, " for writing.")) {
      my $i = 0;
      while ($i < @array) {
        my $line = $array[$i];
        if ($i > 1) { # don't process the first two lines
          $line =~ s/((?<=[^a-zA-Z0-9])(?:https?\:\/\/|[a-zA-Z0-9]{1,}\.{1}|\b)(?:\w{1,}\.{1}){1,5}(?:com|org|edu|gov|uk|net|ca|de|jp|fr|au|us|ru|ch|it|nl|se|no|es|mil|iq|io|ac|ly|sm){1}(?:\/[a-zA-Z0-9]{1,})*)//g; # Remove HTML/HTTP or any kind of URL type lines.
          $line =~ s/[[:punct:]]//g; # Remove punctuations
          $line =~ s/\d//g;          # Remove digits
          $line =~ s/^\s+//;         # Remove leading whitespaces
          $line = lc $line;          # Convert uppercases to lowercases

          $line = &removeStopWordsAndStem($line); # Remove stopwords and do stemming
        }

        print OUTFILE $line;

        $i++;
      }
    }
    close(OUTFILE);

    push(@fileList, $writefileName);
    $documentNo++;
  }
  print ("Finsihed processing contents.\n Processed contents can be found at \"processed_documents\" directory.\n");
} # preProcessContent

# Create inverted index from each file in @fileList (global variable)
sub createInvertedIndex {
  my $documentNo = 1;
  foreach my $file (@fileList) {
    my $docName = "Documnent#";
    $docName = $docName . $documentNo;
    if (open(INFILE, $file) || die("Can't open ", $file, " for reading")) {
      @array = <INFILE>;
    }
    close(INFILE);

    my $i = 0;
    while($i < @array) {
      if ($i > 1) { # ignore the first two lines
        my @words = split(" ", $array[$i]);
        foreach my $word (@words) {
          $invertedIndex{$word}{$docName}++;
        }
      }
      $i++;
    } # while @array
    $documentNo++;
  } # foreach @fileList
} # createInvertedIndex

sub printInvertedIndex {
  open(OUTFILE, ">inverted-index.txt");
  print OUTFILE ("Word --> Document No | Term Frequency\n");
  print OUTFILE ("-----------------------------------------\n");
  foreach my $word (sort keys %invertedIndex) {
    print OUTFILE ($word, " --> ");
    foreach my $doc (keys %invertedIndex{$word}) {
      print OUTFILE ($doc, "|", $invertedIndex{$word}{$doc}, "; ");
    }
    print OUTFILE ("\n");
  }
} # printInvertedIndex