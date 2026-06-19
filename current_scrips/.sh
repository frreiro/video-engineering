#!/bin/sh

###############################################################################
# LOW LATENCY DASH - Shaka Packager
# Bitmovin Player + Akamai CDN + Portainer/Docker
# Compatível com BusyBox v1.36.1
###############################################################################

set -eu

###############################################################################
# VALIDACAO DE AMBIENTE
###############################################################################

: "${CHANNEL_NAME:?CHANNEL_NAME nao definido}"
: "${MANIFEST_MPD:?MANIFEST_MPD nao definido}"
: "${IP_INTERFACE:?IP_INTERFACE nao definido}"
: "${IP_UDP_AUDIO:?IP_UDP_AUDIO nao definido}"
: "${PORTA_UDP_AUDIO:?PORTA_UDP_AUDIO nao definido}"
: "${IP_UDP_1080:?IP_UDP_1080 nao definido}"
: "${PORTA_UDP_1080:?PORTA_UDP_1080 nao definido}"
: "${IP_UDP_720:?IP_UDP_720 nao definido}"
: "${PORTA_UDP_720:?PORTA_UDP_720 nao definido}"
: "${IP_UDP_540:?IP_UDP_540 nao definido}"
: "${PORTA_UDP_540:?PORTA_UDP_540 nao definido}"
: "${IP_UDP_480:?IP_UDP_480 nao definido}"
: "${PORTA_UDP_480:?PORTA_UDP_480 nao definido}"
: "${KEY_ID:?KEY_ID nao definido}"          # key_id em hex/UUID
: "${KEY:?KEY nao definido}"                # chave em hex/base64 dependendo da EZDRM
: "${PLAYREADY_PX:?PLAYREADY_PX nao definido}"
: "${CDN_BASE_URL:?CDN_BASE_URL nao definido}"
: "${PRESERVED_SEGMENTS_OUTSIDE_LIVE_WINDOW:?PRESERVED_SEGMENTS_OUTSIDE_LIVE_WINDOW nao definido}"
: "${SEGMENT_DURATION:?SEGMENT_DURATION nao definido}"

###############################################################################
# GLOBALS
###############################################################################

CLEANED=0
OUTPUT_DIR="/var/www/origin/watchtv/dash/${CHANNEL_NAME}"
BASE_DIR="/var/www/origin/watchtv/dash/${CHANNEL_NAME}"
PACKAGER_PID=""
CLEANUP_PID=""

###############################################################################
# LOGGING
###############################################################################

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

###############################################################################
# CLEANUP
###############################################################################

cleanup() {
  [ "$CLEANED" -eq 1 ] && return
  CLEANED=1

  log "[SHUTDOWN] Stopping cleanup loop..."
  if [ -n "$CLEANUP_PID" ]; then
    kill "$CLEANUP_PID" 2>/dev/null || true
    wait "$CLEANUP_PID" 2>/dev/null || true
  fi

  log "[SHUTDOWN] Stopping packager..."
  if [ -n "$PACKAGER_PID" ]; then
    kill -TERM "$PACKAGER_PID" 2>/dev/null || true
    wait "$PACKAGER_PID" 2>/dev/null || true
  fi

  log "[SHUTDOWN] Finished."
}

trap 'log "[SIGNAL] TERM"; cleanup' TERM
trap 'log "[SIGNAL] INT"; cleanup' INT
trap 'cleanup' EXIT

###############################################################################
# PREPARE OUTPUT
###############################################################################

log "[INIT] Preparing output directories..."

mkdir -p "${OUTPUT_DIR}"
find "${OUTPUT_DIR}" -mindepth 1 -delete 2>/dev/null || true

mkdir -p \
  "${OUTPUT_DIR}/audio" \
  "${OUTPUT_DIR}/1080p" \
  "${OUTPUT_DIR}/720p" \
  "${OUTPUT_DIR}/540p" \
  "${OUTPUT_DIR}/480p"

###############################################################################
# GERAR PSSH WIDEVINE (HEX)
###############################################################################

log "[INIT] Generating Widevine PSSH..."

# content-id = CHANNEL_NAME em hex; od é compatível com BusyBox
CONTENT_ID=$(echo -n "${CHANNEL_NAME}" | od -A n -t x1 | tr -d ' \n')

WIDEVINE_PSSH=$(pssh-box.py \
  --hex \
  --widevine \
  --content-id "${CONTENT_ID}" \
  --key-id "${KEY_ID}")

# valida que é hex puro
echo "${WIDEVINE_PSSH}" | grep -qE '^[0-9a-fA-F]+$' \
  && log "[INIT] PSSH hex OK: ${WIDEVINE_PSSH}" \
  || { log "[ERROR] PSSH invalido ou vazio — abortando"; exit 1; }

###############################################################################
# START PACKAGER
###############################################################################

log "[INIT] Starting LOW LATENCY DASH for ${CHANNEL_NAME}..."

packager \
"in=udp://${IP_UDP_AUDIO}:${PORTA_UDP_AUDIO}?interface=${IP_INTERFACE}&reuse=1,stream=audio,init_segment=${OUTPUT_DIR}/audio/audio_init.mp4,segment_template=${OUTPUT_DIR}/audio/audio_\$Number\$.m4s,lang=pt,drm_label=audio" \
"in=udp://${IP_UDP_1080}:${PORTA_UDP_1080}?interface=${IP_INTERFACE}&reuse=1,stream=video,init_segment=${OUTPUT_DIR}/1080p/1080p_init.mp4,segment_template=${OUTPUT_DIR}/1080p/1080p_\$Number\$.m4s,drm_label=video" \
"in=udp://${IP_UDP_720}:${PORTA_UDP_720}?interface=${IP_INTERFACE}&reuse=1,stream=video,init_segment=${OUTPUT_DIR}/720p/720p_init.mp4,segment_template=${OUTPUT_DIR}/720p/720p_\$Number\$.m4s,drm_label=video" \
"in=udp://${IP_UDP_540}:${PORTA_UDP_540}?interface=${IP_INTERFACE}&reuse=1,stream=video,init_segment=${OUTPUT_DIR}/540p/540p_init.mp4,segment_template=${OUTPUT_DIR}/540p/540p_\$Number\$.m4s,drm_label=video" \
"in=udp://${IP_UDP_480}:${PORTA_UDP_480}?interface=${IP_INTERFACE}&reuse=1,stream=video,init_segment=${OUTPUT_DIR}/480p/480p_init.mp4,segment_template=${OUTPUT_DIR}/480p/480p_\$Number\$.m4s,drm_label=video" \
--low_latency_dash_mode=true \
--segment_duration "${SEGMENT_DURATION}" \
--io_block_size 131072 \
--minimum_update_period 1 \
--suggested_presentation_delay 6 \
--time_shift_buffer_depth 30 \
--preserved_segments_outside_live_window "${PRESERVED_SEGMENTS_OUTSIDE_LIVE_WINDOW}" \
--base_urls "${CDN_BASE_URL}" \
--protection_scheme cenc \
--allow_approximate_segment_timeline \
--enable_raw_key_encryption \
--keys label=audio:key_id=${KEY_ID}:key=${KEY},label=video:key_id=${KEY_ID}:key=${KEY} \
--pssh "${WIDEVINE_PSSH}" \
--protection_systems PlayReady \
--playready_extra_header_data "<LA_URL>https://playready.ezdrm.com/cency/preauth.aspx?pX=${PLAYREADY_PX}</LA_URL>" \
--utc_timings "urn:mpeg:dash:utc:http-xsdate:2014"="https://time.akamai.com/?iso" \
--mpd_output "${OUTPUT_DIR}/${MANIFEST_MPD}.mpd" \
2>&1 &

PACKAGER_PID=$!
log "[INFO] Packager PID: ${PACKAGER_PID}"

###############################################################################
# CLEANUP LOOP (BACKGROUND, NÃO BLOQUEIA)
###############################################################################

# tempo em segundos e em minutos
duration=$(( PRESERVED_SEGMENTS_OUTSIDE_LIVE_WINDOW * SEGMENT_DURATION ))
duration_min=$(( duration / 60 ))
[ "$duration_min" -lt 1 ] && duration_min=1

(
  # loop termina quando o packager termina
  while kill -0 "${PACKAGER_PID}" 2>/dev/null; do
    for dir in "${BASE_DIR}"/*/; do
      [ -d "$dir" ] || continue
      # BusyBox find suporta -mmin e ! -regex (como você testou)
      find "$dir" -maxdepth 1 -type f \
        ! -regex ".*_init.*" \
        -mmin "+${duration_min}" \
        -delete 2>/dev/null || true
    done
    sleep 60
  done
) &

CLEANUP_PID=$!
log "[INFO] Cleanup loop PID: ${CLEANUP_PID}"

###############################################################################
# AGUARDA O PACKAGER
###############################################################################

EXIT_CODE=0
wait "${PACKAGER_PID}" || EXIT_CODE=$?

log "[EXIT] Packager exited with code ${EXIT_CODE}"