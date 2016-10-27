#!/opt/local/bin/perl

#use warnings;
use LWP::Simple;
use HTML::Strip;
use HTML::LinkExtor;
use WWW::Mechanize;
use Lingua::Stem::En;

#make directories for saving web document and processed web documents
# 0755 = permisson level
mkdir("documents", 0755);
mkdir("processed_documents", 0755);

my $baseUrl = "http://www.cs.memphis.edu/~vrus/teaching/ir-websearch/"; # where the crawling will start
my $fileLocation = "./documents/";                                      # web documents will be stored in this directory
my $processedFileLocation = "./processed_documents/";                   # processed web documents will be stored in this directory
my $fileExtension = ".txt";                                             # web documents will be stored as text files
my %stopWordHash;                                                       # hash for stop words
my $totalDocument;                                                      # total # of web documents stored
my @fileList;
my %invertedIndex;


&crawlBaseUrl($baseUrl);
&initStopWordHash;
&preProcessContent;
&createInvertedIndex;
&printInvertedIndex;


# crawl the links found the $baseUrl and save the contents
sub crawlBaseUrl {
  #get all the one-click links (in the baseUrl) and push to $one_click_links
  my ($url) = @_;
  my @one_click_links = ();
  push(@one_click_links, $url);
  my $mechanize = WWW::Mechanize->new();
  $mechanize->get($url);

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
      if ($link =~ /txt/ or $link =~ /html/) { # if $link contains  ".txt", it is a text document
        $linkType = "relative";
      }
    }

    $content = &getContent($link, $linkType);

    if (defined($content)) { # if content retrieval is successful
      &saveContent($content, $documentNo + 1);
      $documentNo++;
    }
    else { # else content cannot be retrieved, go to the next link
      #print ("Failure");
      next;
    }

    $totalDocument = $documentNo;
  } # foreach - link
}

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

sub preProcessContent {
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
        $line =~ s/((?<=[^a-zA-Z0-9])(?:https?\:\/\/|[a-zA-Z0-9]{1,}\.{1}|\b)(?:\w{1,}\.{1}){1,5}(?:com|org|edu|gov|uk|net|ca|de|jp|fr|au|us|ru|ch|it|nl|se|no|es|mil|iq|io|ac|ly|sm){1}(?:\/[a-zA-Z0-9]{1,})*)//g; # Remove HTML/HTTP or any kind of URL type lines.
        $line =~ s/[[:punct:]]//g; # Remove punctuations
        $line =~ s/\d//g;          # Remove digits
        $line =~ s/^\s+//;         # Remove leading whitespaces
        $line = lc $line;          # Convert uppercases to lowercases

        $line = &removeStopWordsAndStem($line); # Remove stopwords and do stemming

        print OUTFILE $line;
        $i++;
      }
    }
    close(OUTFILE);

    push(@fileList, $writefileName);
    $documentNo++;
  }
}

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
      my @words = split(" ", $array[$i]);
      foreach my $word (@words) {
        $invertedIndex{$word}{$docName}++;
      }
      $i++;
    } # while @array
    $documentNo++;
  } # foreach @fileList
}

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
}