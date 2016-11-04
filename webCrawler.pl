#!/opt/local/bin/perl

use WWW::Mechanize;

sub crawler {
  my ($url) = @_;

  my @urlQueue = ();                                    # Queue for visiting the urls in BFS order
  my %urlIsVisited;                                     # if a url is visited give it value of 1, otherwise 0

  push(@urlQueue, $url);
  $urlIsVisited{$url} = 1;

  open(WRITEFILE, ">all-links.txt");

  my $progress = 100;
  my $count = 0;

  $i = 0;
  while(@urlQueue) {
    my $currentUrl = shift @urlQueue;

    my $mechanize = WWW::Mechanize->new(autocheck => 0);
    $mechanize->get($currentUrl);

    if ($mechanize->res->is_success) {                    # if $mechanize->get($currentUrl) is successful
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

      print WRITEFILE $currentUrl;
      print WRITEFILE ("\n");


      #print($currentUrl, "\n");
      # if ($i == 10) { # get the first 500 links
      #   last;
      # }
      # $i++;
    }
  } # while - url queue
}

sub show_progress {
  print "*";
}

sub progress_completed {
  print " Crawling completed\n.";
}

crawler("http://www.memphis.edu");