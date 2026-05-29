# HLS
ffmpeg -i ../video.mp4 \
-c copy \
-f hls \
-hls_time 6 \
-hls_playlist_type vod \
hls/playlist.m3u8

## DASH
ffmpeg -i ../video.mp4 \
-c copy \
-f dash \
dash/manifest.mpd




