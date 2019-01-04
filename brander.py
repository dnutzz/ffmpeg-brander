import argparse
import ffmpeg


## Specifying arguments
parser = argparse.ArgumentParser()
parser.add_argument("-i", help="video file or a list of video files, which should be branded.")
parser.add_argument("-overlay", help="png file which should be overlayed.")

args = parser.parse_args()

in_file = ffmpeg.input(args.i)
overlay_file = ffmpeg.input(args.overlay)
(
    ffmpeg
    .concat(
        in_file['v'], 
        in_file['a'], 
        v=1, 
        a=1
    )
    .overlay(overlay_file)
    .output('out.mp4')
    .run()
)

