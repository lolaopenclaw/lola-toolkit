---
name: video-frames
description: Extract frames or short clips from videos using ffmpeg.
homepage: https://ffmpeg.org
metadata: {"clawdbot":{"emoji":"🎞️","requires":{"bins":["ffmpeg"]},"install":[{"id":"brew","kind":"brew","formula":"ffmpeg","bins":["ffmpeg"],"label":"Install ffmpeg (brew)"}]}}
---

# Video Frames (ffmpeg)

Extract a single frame from a video, or create quick thumbnails for inspection.

## Quick start

First frame:

```bash
{baseDir}/scripts/frame.sh /path/to/video.mp4 --out /tmp/frame.jpg
```

At a timestamp:

```bash
{baseDir}/scripts/frame.sh /path/to/video.mp4 --time 00:00:10 --out /tmp/frame-10s.jpg
```

## Complete Command Reference

```bash
# Single frame at start
frame.sh <video> --out <image.jpg>

# Frame at specific time (HH:MM:SS or seconds)
frame.sh <video> --time 00:00:10 --out <image.jpg>
frame.sh <video> --time 30 --out <image.jpg>

# Clip extraction (from time1 to time2, duration format)
frame.sh <video> --clip --start 00:00:05 --end 00:00:15 --out <clip.mp4>
frame.sh <video> --clip --start 5 --duration 10 --out <clip.mp4>
```

## Usage Tips

- Prefer `--time` for "what is happening around here?"
- Use `.jpg` for quick share; `.png` for crisp UI frames
- For multiple frames, loop with `--time 0 10 20 30` (one at a time)
- Clips are H.264 + AAC audio (compatible with most players)
- Large videos: use `--time` with specific moment to avoid long processing

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| `ffmpeg: command not found` | ffmpeg not installed | `brew install ffmpeg` |
| `Invalid time format` | HH:MM:SS not parsed correctly | Use `--time 10` (seconds) instead of `--time 00:00:10` |
| `Output file exists` | Trying to overwrite | Use `--out /tmp/frame-new.jpg` with unique name |
| `Video not found` | Path is relative or wrong | Use absolute path: `/full/path/to/video.mp4` |
| Clip has no audio | Extraction issue | Verify source video has audio track with `ffmpeg -i <video>` |
