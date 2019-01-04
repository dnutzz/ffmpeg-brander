# ffmpeg-brander
Simple python script that allows you to append intro+outro files and overlay images to an exisiting video file.

## Dependencies
Minimum Python 3.5 is required.
Also make sure to install the ffmpeg-python lib.
```python
pip install ffmpeg-python
```

## Usage

```python
python brander.py -i file 
```
`-i file/filelist`
>video file or a list of video files, which should be branded.

## Optional Flags
`-intro file`
>the intro video file, which should be prepended.

`-istart t -iend t`
>exact time which should be used from the intro input

`-outro file`
>outro video file, which should be appended.

`-ostart t -oend t`
>exact time which should be used from the outro input

`-overlay file`
>png file which should be overlayed.

`-opacity #`
>opacity between 0 (visible) to 100 (transparent) for the png file.

`-timestamps list`
>timestamps for the overlay, when it should be displayed