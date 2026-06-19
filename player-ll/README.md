# Low Latency Player + Nginx

Laboratorio local para servir HLS, LL-HLS ou DASH/CMAF com Nginx e testar no navegador com metricas de latencia.

## Subir o servidor

```bash
cd player
docker compose up
```

Em outro terminal, suba o servidor de controle que permite iniciar/parar a stream pelo player:

```bash
cd player
python3 control-server.py
```

Abra:

```text
http://localhost:8080
```

O Nginx serve arquivos em:

```text
player/www/media/
```

Use no player:

```text
/media/hls/master.m3u8
/media/dash/manifest.mpd
```

## Iniciar a stream pelo player

Clique em `Iniciar stream`.

O botao chama o servidor local em `http://127.0.0.1:8090`, que executa:

```bash
bash player/start-stream-lowlatency-player.sh
```

Configure o OBS para enviar SRT para:

```text
srt://localhost:9999?mode=caller
```

O script publica as saidas em:

```text
player/www/media/hls/master.m3u8
player/www/media/dash/manifest.mpd
```

Logs:

```text
player/lab/logs/ffmpeg.log
player/lab/logs/shaka.log
player/lab/logs/control-server.log
```

## Gerar HLS de baixa latencia com FFmpeg

Exemplo a partir do `video.mp4` do repositorio:

```bash
mkdir -p player/www/media

ffmpeg -re -stream_loop -1 -i video.mp4 \
  -c:v libx264 -preset veryfast -tune zerolatency \
  -b:v 2500k -maxrate 2500k -bufsize 2500k \
  -g 60 -keyint_min 60 -sc_threshold 0 \
  -c:a aac -b:a 128k -ar 48000 \
  -f hls \
  -hls_time 1 \
  -hls_list_size 6 \
  -hls_flags delete_segments+append_list+program_date_time+independent_segments \
  -hls_segment_type fmp4 \
  -hls_fmp4_init_filename init.mp4 \
  -hls_segment_filename player/www/media/stream_%05d.m4s \
  player/www/media/stream.m3u8
```

Notas:

- `-g 60` em video de 60 FPS produz GOP de 1 segundo.
- `-sc_threshold 0` evita keyframes extras por scene cut e melhora o alinhamento dos segmentos.
- `-hls_time 1` reduz o tempo de disponibilidade de segmento. Para LL-HLS real com partial segments, use um packager/servidor que publique partes progressivamente.
- O Nginx esta com cache desativado, `sendfile off`, `tcp_nodelay on`, CORS e `X-Accel-Buffering: no` para evitar buffers desnecessarios no laboratorio.

## Gerar DASH/CMAF com Shaka Packager

Se ja houver uma entrada CMAF/fragmentada, publique o manifest e os segmentos em `player/www/media/`.
Exemplo conceitual:

```bash
packager \
  in=input.mp4,stream=video,init_segment=player/www/media/video_init.mp4,segment_template=player/www/media/video_$Number$.m4s \
  in=input.mp4,stream=audio,init_segment=player/www/media/audio_init.mp4,segment_template=player/www/media/audio_$Number$.m4s \
  --segment_duration 1 \
  --fragment_duration 0.5 \
  --time_shift_buffer_depth 20 \
  --minimum_update_period 1 \
  --suggested_presentation_delay 2 \
  --mpd_output player/www/media/stream.mpd
```

## Medir

No player acompanhe:

- `Live edge delay`: distancia aproximada entre o tempo atual e a borda ao vivo.
- `Buffer`: segundos disponiveis a frente do playhead.
- `Stalls`: eventos `waiting`, bom indicador de agressividade excessiva nos buffers.
- `Playback rate`: ajuste automatico de catch-up quando o player tenta voltar para a borda ao vivo.
