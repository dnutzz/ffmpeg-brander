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
my $padding = 10;
my $crf = 17;
my $usage = "Usage: $0 -input FILE -intro FILE [-it hh:mm:ss] -outro FILE [-ot hh:mm:ss] -overlay FILE [-overlay FILE][-timestamps FILE][-padding UINT][-crf UINT]\n";
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
say $input && $outro && $intro ? "Starting branding..\n" : $usage;

system ("ffmpeg -i $input -i $overlay -filter_complex \"overlay=W-w-$padding:$padding\" -codec:a copy -c:v libx264 tmp_branded.mp4") == 0
  or die ("Cannot produce the overlay part.\n");

say ("Starting concatenating of intro and outro..\n");
system("ffmpeg -t $intro_t -i $intro -i tmp_branded.mp4 -t $outro_t -i $outro -filter_complex \"[0:v] [0:a] [1:v] [1:a] [2:v] [2:a] concat=n=3:v=1:a=1 [v] [a]\" -map \"[v]\" -map \"[a]\" -crf $crf final.mp4");

say ("Everything done - bye!\n");
