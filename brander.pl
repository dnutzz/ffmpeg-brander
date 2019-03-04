#! /usr/local/bin/perl -w
use strict;
use warnings;
use 5.010;
use Getopt::Long qw(GetOptions);

my $debug;
my $input;
my $outro;
my $outro_t = 4;
my $intro;
my $intro_t = 8;
my $overlay;
my $timestamps;
my $padding = 30;
my $crf = 17;
my $output = "";
my @chars = ("A".."Z", "a".."z");
my $tmp_filename = "_tmp";
$tmp_filename .= $chars[rand @chars] for 1..10;
$tmp_filename .= ".mp4";

my $usage = "Usage: $0 -input FILE/DIR -intro FILE [-it hh:mm:ss] -outro FILE [-ot hh:mm:ss] -overlay FILE [-overlay FILE][-timestamps FILE][-padding UINT][-crf UINT]\n";
GetOptions(
    'input=s' => \$input,
    'outro=s' => \$outro,
    'intro=s' => \$intro,
    'overlay=s' => \$overlay,
    'timestamps=s' => \$timestamps,
    'padding=s' => \$padding,
    'crf=s' => \$crf,
    'it=s' => \$intro_t,
    'ot=s' => \$outro_t
) or die $usage;
say $input && $outro && $intro ? "Starting branding.." : $usage;

#check if given input is a directory
if (-d $input){
  say ("Input is a directory! Starting batch processing...");
  my $dir = $input;
  opendir (DIR, $input) or die $!;
  while (my $file = readdir (DIR)){
    next if ($file =~ m/^\./);
    $input = $dir."/".$file;
    brandVideo();
  }
}
elsif (-e $input){
  say ("Input is not a directory - might be a file! Starting with single file...");
  brandVideo();
}
else{
  die ("No valid input given.\n");
}

sub brandVideo {
  updateOutputFileName();
  system ("ffmpeg -i $input -i $overlay -filter_complex \"overlay=W-w-$padding:$padding\" -codec:a copy -c:v libx264 $tmp_filename") == 0
    or die ("Cannot produce the overlay part.\n");

  say ("Starting concatenating of intro and outro..");
  system("ffmpeg -t $intro_t -i $intro -i $tmp_filename -t $outro_t -i $outro -filter_complex \"[0:v] [0:a] [1:v] [1:a] [2:v] [2:a] concat=n=3:v=1:a=1 [v] [a]\" -map \"[v]\" -map \"[a]\" -crf $crf $output") == 0
    or die ("Cannot concat intro and outro..\n");

  say ("Everything done - cleaning up of temp files incoming!");
  unlink $tmp_filename;
  if(-e $tmp_filename)
  {
      say "temporary file ".$tmp_filename." could not be deleted - please delete manually!";
  }
  else
  {
      say "Cleaning up done, bye!";
  }
}

sub updateOutputFileName {
    say ("appending suffix to output filename...");
    $output = $input;
    substr($output, -4)= "_BRAND.mp4";
    my $find = "^[^/]*/";
    $output =~ s/$find//;
    say $output;
}
