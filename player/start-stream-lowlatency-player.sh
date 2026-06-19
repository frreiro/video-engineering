#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR/lab"
MEDIA_DIR="$SCRIPT_DIR/www/media"

PIPES_DIR="$BASE_DIR/pipes"
HLS_DIR="$MEDIA_DIR/hls"
DASH_DIR="$MEDIA_DIR/dash"
LOG_DIR="$BASE_DIR/logs"

SRT_PORT=9999
CHUNK_MAX_AGE_SECONDS=10
PRESERVED_SEGMENTS_OUTSIDE_LIVE_WINDOW=1

mkdir -p "$PIPES_DIR"
mkdir -p "$HLS_DIR"
mkdir -p "$DASH_DIR"
mkdir -p "$LOG_DIR"

cleanup() {
    echo ""
    echo "Finalizando..."

    jobs -p | xargs -r kill 2>/dev/null || true

    rm -f "$PIPES_DIR/video.ts" "$PIPES_DIR/audio.ts"
    rm -rf "$HLS_DIR" "$DASH_DIR"

    echo "Limpeza concluída."
}

trap cleanup EXIT INT TERM

rm -f "$PIPES_DIR/video.ts"
rm -f "$PIPES_DIR/audio.ts"

mkfifo "$PIPES_DIR/video.ts"
mkfifo "$PIPES_DIR/audio.ts"

echo ""
echo "======================================="
echo "OBS SRT URL"
echo "srt://localhost:${SRT_PORT}?mode=caller"
echo "======================================="
echo ""

#################################################
# SHAKA PACKAGER
#################################################

(
cd "$BASE_DIR"

packager \
"in=pipes/audio.ts,stream=audio,init_segment=${HLS_DIR}/audio-init.mp4,segment_template=${HLS_DIR}/audio-\$Number\$.m4s,playlist_name=audio.m3u8,hls_group_id=audio,hls_name=AAC" \
"in=pipes/video.ts,stream=video,init_segment=${HLS_DIR}/video-init.mp4,segment_template=${HLS_DIR}/video-\$Number\$.m4s,playlist_name=video.m3u8,hls_name=720p" \
--hls_master_playlist_output "$HLS_DIR/master.m3u8" \
--hls_playlist_type LIVE \
--mpd_output "$DASH_DIR/manifest.mpd" \
--minimum_update_period 1 \
--segment_duration 2 \
--fragment_duration 0.5 \
--time_shift_buffer_depth "$CHUNK_MAX_AGE_SECONDS" \
--preserved_segments_outside_live_window "$PRESERVED_SEGMENTS_OUTSIDE_LIVE_WINDOW" \
> logs/shaka.log 2>&1

) &

sleep 1

#################################################
# FFMPEG
#################################################

ffmpeg -y \
    -loglevel info \
    -i "srt://0.0.0.0:${SRT_PORT}?mode=listener&latency=10" \
    -map 0:v:0 \
    -c:v copy \
    -f mpegts \
    "$PIPES_DIR/video.ts" \
    -map 0:a:0 \
    -c:a copy \
    -f mpegts \
    "$PIPES_DIR/audio.ts" \
    > "$LOG_DIR/ffmpeg.log" 2>&1

wait
