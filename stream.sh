#!/bin/bash
set -e

# ---------- Configuration ----------
GOOGLE_DRIVE_LINK="https://drive.google.com/file/d/1ab1v4-z-7ZAQ6pI4-qs6Rx-chC4UmqVZ/view?usp=sharing"
LOCAL_VIDEO_PATH="video.mp4"

FACEBOOK_STREAM_KEY="FB-122193920732780799-0-Ab4JgxUm67HqqOAuoVJlmviL"
FACEBOOK_RTMP_URL="rtmps://live-api-s.facebook.com:443/rtmp/${FACEBOOK_STREAM_KEY}"

YOUTUBE_STREAM_KEY="2zjw-jyhg-bpx7-2e47-fj6m"
YOUTUBE_RTMP_URL="rtmp://a.rtmp.youtube.com/live2/${YOUTUBE_STREAM_KEY}"

# ---------- Google Drive سے ویڈیو ڈاؤن لوڈ کریں ----------
FILE_ID=$(echo "$GOOGLE_DRIVE_LINK" | grep -oP '(?<=/d/)[a-zA-Z0-9_-]+')

echo "Google Drive سے ویڈیو ڈاؤن لوڈ ہو رہی ہے..."
gdown "$FILE_ID" -O "$LOCAL_VIDEO_PATH"
echo "ڈاؤن لوڈ مکمل: $LOCAL_VIDEO_PATH"

# ---------- بیک وقت Facebook (vertical) اور YouTube (vertical) پر لائیو ----------
echo "لائیو اسٹریم شروع ہو رہی ہے..."

ffmpeg -re -stream_loop -1 -i "$LOCAL_VIDEO_PATH" \
  -filter_complex "[0:v]split=2[fb_v][yt_pre];[yt_pre]scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=gold[yt_v]" \
  -map "[fb_v]" -map 0:a? \
  -c:v libx264 -preset veryfast -b:v 3000k -maxrate 3500k -bufsize 6000k -pix_fmt yuv420p -g 60 \
  -c:a aac -b:a 160k -ar 44100 \
  -f flv "$FACEBOOK_RTMP_URL" \
  -map "[yt_v]" -map 0:a? \
  -c:v libx264 -preset veryfast -b:v 3000k -maxrate 3500k -bufsize 6000k -pix_fmt yuv420p -g 60 \
  -c:a aac -b:a 160k -ar 44100 \
  -f flv "$YOUTUBE_RTMP_URL"
