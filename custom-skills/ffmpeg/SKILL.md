---
name: ffmpeg
description: >
  FFmpeg video and audio processing. Use when the user works with video,
  audio, transcoding, encoding, filters, streaming, or mentions "ffmpeg",
  "transcode", "encode", "video convert", "extract audio", "filter graph",
  "HLS", "RTMP", "mux", "demux", "codec".
---

# FFmpeg

Assist with FFmpeg commands for video and audio processing.

## Core Concepts
- Container (mp4, mkv, mov) is separate from Codec (H.264, H.265, VP9, AAC).
- `-c copy` = remux without re-encoding (fast, no quality loss).
- `-c:v` = video codec, `-c:a` = audio codec.
- `-crf` = quality control (lower = better; H.264: 18-28, H.265: 24-28).
- `-preset` = speed vs compression (slow/medium/fast/veryfast).

## Common Operations

### Convert / Re-encode
```bash
# H.264 MP4, good quality
ffmpeg -i input.mov -c:v libx264 -crf 22 -preset medium -c:a aac -b:a 192k output.mp4

# H.265 (smaller file, slower encode)
ffmpeg -i input.mp4 -c:v libx265 -crf 28 -preset slow -c:a copy output.mp4

# WebM for web
ffmpeg -i input.mp4 -c:v libvpx-vp9 -crf 30 -b:v 0 -c:a libopus output.webm

# AV1 (best compression, slow)
ffmpeg -i input.mp4 -c:v libaom-av1 -crf 35 -b:v 0 -c:a libopus output.mp4
```

### Trim / Cut (no re-encode)
```bash
# Put -ss BEFORE -i for fast keyframe seek
ffmpeg -ss 00:01:30 -to 00:02:45 -i input.mp4 -c copy output.mp4
```

### Extract Audio
```bash
ffmpeg -i input.mp4 -vn -c:a copy output.aac
ffmpeg -i input.mp4 -vn -c:a libmp3lame -q:a 2 output.mp3
ffmpeg -i input.mp4 -vn -c:a flac output.flac
```

### Scale / Resize
```bash
# Scale to 1080p, preserve aspect ratio
ffmpeg -i input.mp4 -vf "scale=-2:1080" -c:v libx264 -crf 22 output.mp4

# Scale + letterbox to exact 1920x1080
ffmpeg -i input.mp4 -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" output.mp4
```

### Concatenate
```bash
# Create filelist.txt with entries like: file 'part1.mp4'
ffmpeg -f concat -safe 0 -i filelist.txt -c copy output.mp4
```

### Extract Frames
```bash
ffmpeg -i input.mp4 -vf "fps=1" frames/frame_%04d.png        # 1 frame per second
ffmpeg -ss 00:00:05 -i input.mp4 -frames:v 1 screenshot.png  # single frame
```

### High-Quality GIF
```bash
ffmpeg -i input.mp4 -vf "fps=15,scale=640:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" output.gif
```

## Filter Graphs
```bash
# Multiple simple filters
ffmpeg -i input.mp4 -vf "scale=1280:720,fps=30" output.mp4

# Complex filter: overlay logo on video
ffmpeg -i video.mp4 -i logo.png \
  -filter_complex "[0:v][1:v]overlay=10:10" output.mp4

# Stack two videos side by side
ffmpeg -i left.mp4 -i right.mp4 \
  -filter_complex "[0:v][1:v]hstack" output.mp4
```

## HLS Streaming
```bash
ffmpeg -i input.mp4 -c:v libx264 -crf 22 \
  -hls_time 6 -hls_playlist_type vod \
  -hls_segment_filename "segment_%03d.ts" playlist.m3u8
```

## Batch Processing
```bash
for f in *.mov; do
    ffmpeg -i "$f" -c:v libx264 -crf 22 -c:a aac "${f%.mov}.mp4"
done
```

## Debugging
- `ffprobe input.mp4` — inspect streams, codecs, duration, bitrate.
- `ffmpeg -i input.mp4` — quick info (stderr).
- `-v verbose` for detailed encoding logs.
- `-progress pipe:1` for machine-readable progress output.
