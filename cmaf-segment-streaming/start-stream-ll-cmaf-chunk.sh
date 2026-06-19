#!/bin/bash

set -euo pipefail

#################################################
# COPYING PLAYER
#################################################

cp -r ../player-ll ./lab/player

BASE_DIR="$(pwd)/lab"
MEDIA_DIR="$BASE_DIR/player/www/media"

PIPES_DIR="$MEDIA_DIR/pipes"
HLS_DIR="$MEDIA_DIR/hls"
DASH_DIR="$MEDIA_DIR/dash"
MANIFEST_DIR="$MEDIA_DIR/manifests"
CONTENT_DIR="$MANIFEST_DIR/content"
LOG_DIR="$MEDIA_DIR/logs"

SRT_PORT=9999
CHUNK_MAX_AGE_SECONDS=10
PRESERVED_SEGMENTS_OUTSIDE_LIVE_WINDOW=1

mkdir -p "$PIPES_DIR"
mkdir -p "$LOG_DIR"
mkdir -p "$MANIFEST_DIR"
mkdir -p "$CONTENT_DIR"


cleanup() {
    echo ""
    echo "Finalizando..."
 	docker compose -f "$BASE_DIR/player/docker-compose-cmaf-chunk.yml" down

    jobs -p | xargs -r kill 2>/dev/null || true

    rm -rf \
        "$PIPES_DIR/video.ts" \
        "$PIPES_DIR/audio.ts" \


	rm -rf "$BASE_DIR/player"
	
    echo "Limpeza concluída."
}


#################################################
# INTIALIZING PLAYER
#################################################
echo ""
echo "======================================="
echo "PLAYER HTTP URL"
echo "http://localhost:8080/"
echo "======================================="
echo ""

docker compose -f "$BASE_DIR/player/docker-compose-cmaf-chunk.yml" up -d

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
cd "$MEDIA_DIR"


# packager \
# "in=pipes/audio.ts,stream=audio,init_segment=manifests/content/audio-init.mp4,segment_template=manifests/content/audio-\$Number\$.m4s,playlist_name=manifests/content/audio.m3u8,hls_group_id=audio,hls_name=AAC" \
# "in=pipes/video.ts,stream=video,init_segment=manifests/content/video-init.mp4,segment_template=manifests/content/video-\$Number\$.m4s,playlist_name=manifests/content/video.m3u8,hls_name=720p" \
# --hls_master_playlist_output "manifests/master.m3u8" \
# --hls_playlist_type LIVE \
# --mpd_output "manifests/manifest.mpd" \
# --minimum_update_period 1 \
# --segment_duration 6 \
# --fragment_duration 0.5 \
# --time_shift_buffer_depth "$CHUNK_MAX_AGE_SECONDS" \
# --preserved_segments_outside_live_window "$PRESERVED_SEGMENTS_OUTSIDE_LIVE_WINDOW" \
# > logs/shaka.log 2>&1

packager \
"in=pipes/audio.ts,stream=audio,init_segment=manifests/content/audio-init.mp4,segment_template=manifests/content/audio-\$Number\$.m4s,playlist_name=manifests/content/audio.m3u8,hls_group_id=audio,hls_name=AAC" \
"in=pipes/video.ts,stream=video,init_segment=manifests/content/video-init.mp4,segment_template=manifests/content/video-\$Number\$.m4s,playlist_name=manifests/content/video.m3u8,hls_name=720p" \
--io_block_size 65536 \
--segment_duration 2 \
--low_latency_dash_mode=true \
--utc_timings "urn:mpeg:dash:utc:http-xsdate:2014"="https://time.akamai.com/?iso" \
--mpd_output "manifests/manifest.mpd" \
> logs/shaka.log 2>&1

) &

# --hls_master_playlist_output "manifests/master.m3u8" \
# --hls_playlist_type LIVE \
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
