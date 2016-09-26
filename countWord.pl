#!/opt/local/bin/perl

#use warnings;
use LWP::Simple;
use HTML::Strip;
use HTML::LinkExtor;

$mainPageContent = get("http://www.cs.memphis.edu/~vrus/teaching/ir-websearch/"); # get the content of the website enlosed in html marker.

die "Couldn't get content!" unless defined $mainPageContent;

# parse the mainPageContent and get the links in the website
$LinkExtor = HTML::LinkExtor->new(\&getLinks);
$LinkExtor->parse($mainPageContent);

# parse the "mainPageContent" and strip off the HTML marker
$hs = HTML::Strip->new();
$page_text = $hs->parse($mainPageContent);

$wordCount = 0;
foreach $line (split /\n/, $page_text) {
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
  } # while
} # foreach

# print("\nTotal number of words: ", $wordCount, "\n");

foreach $key (sort keys %wordFrequency) {
  print "\"$key\" appeared $wordFrequency{$key} times\n";
}

sub getLinks {
  ($tag, %links) = @_;
  if ($tag eq "a") {
    foreach $key (keys %links) {
      if ($key eq "href") {
        print "$links{$key}\n";
        $mainPageContent = get("http://www.cs.memphis.edu/~vrus/teaching/ir-websearch/"); # get the content of the website enlosed in html marker.

        die "Couldn't get content!" unless defined $mainPageContent;
      }
    }
  }
}