#!/opt/local/bin/perl

# check number of arguments provided by user
if (@ARGV != 2) {
  die("Usage:  ./ir-assignment-1-1.pl inputFileName outputFileName");
}

# read the given file to an array
if (open(INFILE,  $ARGV[0]) ||  die("Can't open ", $ARGV[0], "\n")) {
  @array = <INFILE>;
}
close(INFILE); # close the input file

# write the content of the array to the output file
# if the output file exists and nonempty, ask user whether he wants to overwrite it or exit.
# else create the file and write the content in it.

if (-e $ARGV[1] && -s $ARGV[1]) {
  print STDERR ("A File named ", $ARGV[1], " already exists and it is not empty.
                 \nDo you want to overwrite? (y/n): ");
  $choice = <STDIN>;
  chop($choice);

  if ($choice eq "y" || $choice eq "yes") {
    print("Overwriting the file...\n");
    &writeToFile;
  }
  else {
    print("Exiting...\n");
  }
}
else
{
  &writeToFile;
}

# function that writes to a file
sub writeToFile() {
  if (open(OUTFILE, ">".$ARGV[1]) || die("Can't open ", $ARGV[1], "\n")) {
    $count = 0;
    while ($count < @array) {
      print OUTFILE $array[$count];
      $count++;
    }
  }
  close(OUTFILE); # close the output file
}