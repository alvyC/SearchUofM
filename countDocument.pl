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

# get only links which are not in the same page,
my $documentNo = 1;
my @allLinks = $mechanize->links();
foreach my $link (@allLinks) {
  if (!($link->url =~ /\#/) and ($link->url ne "")
      and (index($link->url, "ppt") == -1)
      and (index($link->url, "pdf") == -1)) { # don't add the links which are in the same page, empty line and ppt file
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
    &saveContent($content, $documentNo);
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

print("\nTotal number of words: ", $wordCount, "\n");

sub getContent {
  my ($link, $isAbsolute) = @_;
  if($isAbsolute ne "absolute") {
    $link = $baseUrl . $link;
  }

  my $mechanize = WWW::Mechanize->new(autocheck => 0);
  my $content = $mechanize->get($link);
  if ($content->is_success) { # if the content retrieval is successful
    print("Success: This is link to text/html file (relative path): ", $baseUrl . $link, "\n");
    $content = $mechanize->content();
    $hs = HTML::Strip->new();
    $page_text = $hs->parse($content);
    return $page_text;
  }
  else {
    print("Failure: ", $baseUrl . $link, "\n");
    return undef;
  }
}

sub saveContent {
  my ($content, $documentNo) = @_;
  $fileAbsolutePath = $fileLocation . $documentNo . $fileExtension;
  open(WRITEFILE, ">", $fileAbsolutePath);
  print WRITEFILE $content;
}

sub processContent {
  my $totalDocument = @_;

}
