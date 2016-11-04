#!/opt/local/bin/perl
use WWW::Mechanize;

sub crawler {
  my ($url) = @_;

  my @urlQueue = (); # Queue for visiting the urls in BFS order
  my %urlIsVisited;  # if a url is visited give it value of 1, otherwise 0

  push(@urlQueue, $url);
  $urlIsVisited{$url} = 1;

  # if(!$urlIsVisited{$url}) {
  #   print("undef\n");
  # }
  # else {
  #   print("def\n");
  # }

  while(@urlQueue) {
    my $currentUrl = shift @urlQueue;

    my $mechanize = WWW::Mechanize->new(autocheck => 0);
    $mechanize->get($currentUrl);

    if ($mechanize->res->is_success) {
      my @childrenLinks = $mechanize->links();

        foreach my $link (@childrenLinks) {
          my $childUrl = $link->url;

          if (!($childUrl =~ /\#/) and ($childUrl ne "") and (index($childUrl, "ppt") == -1)
              and (index($childUrl, "pdf") == -1) and ($childUrl =~ /^http/) and ($childUrl =~ /memphis.edu/)) {
            if ($urlIsVisited{$childUrl} != 1) {           # if the childUrl is not visited
                  push(@urlQueue, $childUrl);              # push the child url in the queue
                  $urlIsVisited{$childUrl} = 1;            # mark the child url as visited
            }
          }

        }

      print($currentUrl, "\n");
    }
  } # while - url queue
}

crawler("http://www.memphis.edu");