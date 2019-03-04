# ffmpeg-brander
Simple perl script that allows you to append intro+outro files and overlay images to an exisiting video file.

## Dependencies
Minimum Perl 5.1 is required.

## Usage

```perl
perl brander.pl -input FILE -intro FILE -outro FILE
```
`-input FILE/DIRECTORY`
>video file or a directory of video files, which should be branded.

`-intro FILE`
>the intro video file, which should be prepended.

`-outro FILE`
>outro video file, which should be appended.

## Optional Flags
`-overlay FILE`
>png file which should be overlayed.

`-it NUMBER`
>time in seconds which should be used from the intro input

`-ot NUMBER`
>exact time which should be used from the outro input

## Basic usage example
```perl
perl brander.pl -input files_to_be_branded -intro intro.mp4 -outro outro.mp4 -overlay watermark.png
```
>Prepends intro.mp4, Appends outro.mp4 and puts the watermark.png on all files in the directory files_to_be_branded/
