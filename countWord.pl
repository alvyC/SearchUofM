#!/opt/local/bin/perl

#use warnings;
use LWP::Simple;
use HTML::Strip;

my $content = get("http://www.cs.memphis.edu/~vrus/teaching/ir-websearch/");
#print($content);
die "Couldn't get content!" unless defined $content;
my $hs = HTML::Strip->new();
my $page_text = $hs->parse($content);
#print $page_text;

foreach my $line (split /\n/, $page_text) {
  #print $line, "\n";
  @words = split(/[\s\t]+/, $line);
  $w = 0;
  while($w < @words) {
    my @letters = split(/\s*/, $words[$w]);
    if ($letters[@letters - 1] eq "." || $letters[@letters - 1] eq ","
        || $letters[@letters - 1] eq ":" || $letters[@letters - 1] eq "}"
        || $letters[@letters - 1] eq ")" || $letters[@letters - 1] eq "("
        || $letters[@letters - 1] eq "!") {
      # print substr($words[$w], 0, @words-2), "\n"; #note: for testing
      $wordFrequency{$words[$w]}++;
      # $wordFrequency{substr($words[$w], 0, @words)}++;
    }
    $w++;
    $wordFrequency{$words[$w]}++;
  }
  #print("\n");
  $wordCount += $w;
}

print("\nTotal number of words: ", $wordCount, "\n");

foreach $key (sort keys %wordFrequency) {
  print "\"$key\" appeared $wordFrequency{$key} times\n";
}