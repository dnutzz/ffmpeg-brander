#-----------------------------------------------------------------------------
# brander.pl
#
# This script utilizes ffmpeg functions to create
# videosfiles with the iMooX branding, which consists of 
# intro, outro and an png logo in the upper-right corner.
#


#! /usr/local/bin/perl -w
use strict;
use warnings;
use 5.010;
use Getopt::Long qw(GetOptions);
use lib qw(..);
use JSON qw( );
use POSIX;

# globals - change to your needs. 
# ffprobe detects the correct fps and uses the corresponding
# file in the assets folder. for example:, you want to brand
# a 30fps video, then place your intro like this:
# assets/intro_30fps.mp4

my $global_intro = "assets/intro_";
my $global_outro = "assets/outro_";

# I recommend not more than 200px width at a 1920x1080 video
my $overlay = "assets/overlay.png";

# some cool globals
my $debug;
my $input = "";
my $outro = "";
my $outro_t = 4;
my $intro = "";
my $intro_t = 8;
my $timestamps;
my $padding = 30;
my $crf = 17;
my $fps = 25;
my $output = "";
my $smooth = 0;
my $filter_complex = "";
my $fc_overlay = "";
my $customs = "";
# for the random temp name of the file
my @chars = ("A".."Z", "a".."z");
my $tmp_filename = "_tmp";
my $real_filename = "";
$tmp_filename .= $chars[rand @chars] for 1..10;
$tmp_filename .= ".mp4";

my $usage = "Usage: $0 -input videofile/dir <optional>\nOptional args:\n\t-timestamp file.json:\tTakes custom timestamps for multiple or single video files.\n";
GetOptions(
    'input=s' => \$input,
    'outro=s' => \$outro,
    'intro=s' => \$intro,
    'overlay=s' => \$overlay,
    'timestamps=s' => \$timestamps,
    'padding=s' => \$padding,
    'crf=s' => \$crf,
    'it=s' => \$intro_t,
    'ot=s' => \$outro_t,
    'smooth' => \$smooth,
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
    $real_filename = $file;
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

#-----------------------------------------------------------------------------
##
## brandVideo()
## Utilizes the filter_complex and concat functions from ffmpeg. At first,
## this function produces the overlay part and stores the result in $tmp_filename.
## When this is finished, the concatination of $intro, $tmp_filename, $outro will start.
sub brandVideo {
  preliminaryChecks();
  updateOutputFileName();

  if($timestamps){
    say ("Custom timestamps for logo displaying are present, processing them now...");
    processCustoms();
  }
  else{
    $filter_complex = "-filter_complex \"overlay=W-w-$padding:$padding\"";
  }

  # produce overlay part
  qx{ffmpeg -i $input -i $overlay $filter_complex -codec:a copy -c:v libx264 $tmp_filename};
    #or die ("Cannot produce the overlay part.\n");

  say ("Starting concatenating of intro and outro..");
  qx{ffmpeg -t $intro_t -i $intro -i $tmp_filename -t $outro_t -i $outro -filter_complex "[0:v] [0:a] [1:v] [1:a] [2:v] [2:a] concat=n=3:v=1:a=1:unsafe=1 [v] [a]" -map "[v]" -map "[a]" -crf $crf $output};
    #or die ("Cannot concat intro and outro..\n");

  say ("Branding done!");
  unlink $tmp_filename;
  if(-e $tmp_filename)
  {
      say "temporary file ".$tmp_filename." could not be deleted - please delete manually!";
  }
  else
  {
      say "Cleaning done, bye!";
  }
}

#-----------------------------------------------------------------------------
##
## updateOutputFileName()
## Uses simple regex to append a suffix to the original filename.
sub updateOutputFileName {
  say ("Appending suffix to output filename...");
  $output = $input;
  substr($output, -4)= "_BRAND.mp4";
  my $find = "^[^/]*/";
  $output =~ s/$find//;
  say $output;
}

#-----------------------------------------------------------------------------
##
## preliminaryChecks()
## Does important checks of correct framerate and dimensions of the video, 
## since not all input formats are supported.
sub preliminaryChecks {
  my $tmp_fps = qx(ffprobe -v error -select_streams v -of default=noprint_wrappers=1:nokey=1 -show_entries stream=r_frame_rate $input);

  my $denominator = $tmp_fps;
  my $numerator = $tmp_fps;

  # get the numerator and denominator of the frame rate
  my $find = "\/+[0-9]+";
  $numerator =~ s/$find//;
  chomp $numerator;

  $find = "[0-9]+\/";
  $denominator =~ s/$find//;
  chomp $denominator;

  $tmp_fps = ($numerator/$denominator);
  
  # check if the framerate is supported, if not die
  if (($tmp_fps > 24.9 && $tmp_fps < 25.1)  || ($tmp_fps > 29.9 && $tmp_fps < 30.1)){
    $fps = $tmp_fps;
    say ("Framerate is $fps, we can continue now."); 
    setAssetsToFrameRate();
  }
  else { 
      say ("Framerate $tmp_fps from file $input is not supported, gonna die now..");
      die; 
    };
}

#-----------------------------------------------------------------------------
##
## setAssetsToFrameRate()
## Sets the correct filename of intro and outro according the framerates from
## preliminaryChecks()..
sub setAssetsToFrameRate {
  $fps = ceil($fps);
  $intro = $global_intro.$fps."fps.mp4";
  $outro = $global_outro.$fps."fps.mp4";
  if(-e $intro && -e $outro){
    say ("Intro and Outro files\n$intro\n$outro\nexist, continue with operations..");
  }
  else { die; };
}

#-----------------------------------------------------------------------------
##
## processCustoms()
## Sets the correct filename of intro and outro according the framerates from
## preliminaryChecks()..
sub processCustoms {
  my $json_text = do {
   open(my $json_fh, "<:encoding(UTF-8)", $timestamps)
      or die("Can't open $timestamps: $!\n");
   local $/;
   <$json_fh>
  };

  my $json = JSON->new;
  my $data = $json->decode($json_text);

  my @local_timestamps;

  my @betweens = ();
  for ( @{$data->{$real_filename}} ) {
    push @betweens, $_;
  }
  my $count = @betweens;
  my $i = 0;
  foreach my $between (@betweens){
    # construct first between
    if($i == 0){
       $fc_overlay = "[0][1]overlay=W-w-$padding:$padding:enable='$between'[tmp]";
    }
    # cover more than one between, but only if it's not the last one
    elsif($i < ($count-1)){
      $fc_overlay = $fc_overlay."; [tmp][1]overlay=W-w-$padding:$padding:enable='$between'[tmp]";
    }
    # handle last command
    elsif($i == ($count-1)){
      $fc_overlay = $fc_overlay."; [tmp][1]overlay=W-w-$padding:$padding:enable='$between'";
    }
    $i++;
  }
  $filter_complex = "-filter_complex \"".$fc_overlay."\"";
}
