#!/opt/local/bin/perl

#use warnings;
use LWP::Simple;
use HTML::Strip;

$content = get("http://www.cs.memphis.edu/~vrus/teaching/ir-websearch/");

die "Couldn't get content!" unless defined $content;

$hs = HTML::Strip->new();
$page_text = $hs->parse($content);

$wordCount = 0;
foreach $line (split /\n/, $page_text) {
  @words = split(/[\s\t]+/, $line);
  $w = 0;
  while($w < @words) {
      if($words[$w] =~ /[[:punct:]]$/) { # if the word contains a punctuation at the end, only count the original word without punctuation
        #print(substr($words[$w], 0, @words[$w]-1), "\n"); # print the punctuated word
        #if (@words[$w] > 1) { # If the word is just a space, do not include it
          $wordFrequency{substr($words[$w], 0, @words[$w]-1)}++;
          $wordCount++;
        #}
      }
      else {
        #print $words[$w]; # print the words that don't contain punctuation
        $wordFrequency{$words[$w]}++;
        $wordCount++;
      }
    $w++;
  }
}

#print("\nTotal number of words: ", $wordCount, "\n");

foreach $key (sort keys %wordFrequency) {
  print "\"$key\" appeared $wordFrequency{$key} times\n";
}