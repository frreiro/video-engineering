# Packaging, HLS e DASH

## Objetivo

Entender como um vídeo já codificado é preparado para distribuição via streaming adaptativo utilizando HLS e DASH.

---

# O que é Packaging?

Packaging é a etapa do pipeline de vídeo responsável por transformar um arquivo codificado em um formato adequado para streaming.

Fluxo:

```text
Vídeo Original
      ↓
Encoding/Transcoding
      ↓
Packaging
      ↓
CDN / Player
```

O processo consiste em:

* Dividir o vídeo em segmentos.
* Gerar manifestos/playlists.
* Organizar diferentes qualidades para Adaptive Bitrate Streaming (ABR).

---

# HLS (HTTP Live Streaming)

## Gerando um pacote HLS

Comando:

```bash
ffmpeg -i video.mp4 \
-c copy \
-f hls \
-hls_time 6 \
-hls_playlist_type vod \
playlist.m3u8
```

## Arquivos gerados

```text
playlist.m3u8
playlist0.ts
playlist1.ts
playlist2.ts
...
```

### Parâmetros utilizados

| Parâmetro                | Função                              |
| ------------------------ | ----------------------------------- |
| `-c copy`                | Não reencoda o vídeo                |
| `-f hls`                 | Ativa o muxer HLS                   |
| `-hls_time 6`            | Define o tamanho alvo dos segmentos |
| `-hls_playlist_type vod` | Conteúdo sob demanda                |

---

# DASH (Dynamic Adaptive Streaming over HTTP)

## Gerando um pacote DASH

Comando:

```bash
ffmpeg -i video.mp4 \
-c copy \
-f dash \
manifest.mpd
```

## Arquivos gerados

```text
manifest.mpd
init-stream0.m4s
chunk-stream0-00001.m4s
chunk-stream0-00002.m4s
...
```

---

# Diferenças entre HLS e DASH

| Característica       | HLS           | DASH   |
| -------------------- | ------------- | ------ |
| Manifesto            | `.m3u8`       | `.mpd` |
| Segmentos            | `.ts`         | `.m4s` |
| Formato do manifesto | Texto simples | XML    |
| Criador              | Apple         | MPEG   |

---

# Estrutura do Manifesto HLS

Exemplo:

```text
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:6
#EXT-X-MEDIA-SEQUENCE:0

#EXTINF:6.000000,
playlist0.ts

#EXTINF:6.000000,
playlist1.ts

#EXT-X-ENDLIST
```

---

## #EXT-X-TARGETDURATION

Indica a duração máxima esperada dos segmentos.

Exemplo:

```text
#EXT-X-TARGETDURATION:6
```

O player utiliza essa informação para:

* Planejamento de buffer.
* Controle de latência.
* Busca de novos segmentos.

---

## #EXTINF

Indica a duração real do segmento seguinte.

Exemplo:

```text
#EXTINF:5.875000,
playlist2.ts
```

Significa que o segmento possui 5,875 segundos de duração.

---

# Por que TARGETDURATION pode ser maior que hls_time?

Exemplo:

```bash
-hls_time 6
```

e manifesto:

```text
#EXT-X-TARGETDURATION:8
```

Isso acontece porque:

* `hls_time` é apenas um valor alvo.
* O FFmpeg normalmente corta segmentos apenas em keyframes (I-Frames).
* Se não existir um keyframe exatamente aos 6 segundos, ele espera até o próximo.

Exemplo:

```text
0s     4s     8s
|------I------I
```

O corte ocorrerá em 8 segundos.

Consequentemente:

```text
#EXTINF:7.98
segment0.ts
```

resultará em:

```text
#EXT-X-TARGETDURATION:8
```

---

# Relação entre GOP e Segmentação

O tamanho do GOP influencia diretamente os segmentos gerados.

Para alinhar segmentos de 6 segundos em um vídeo de 30 FPS:

```bash
ffmpeg -i video.mp4 \
-c:v libx264 \
-g 180 \
-keyint_min 180 \
-sc_threshold 0 \
-f hls \
-hls_time 6 \
playlist.m3u8
```

Onde:

```text
180 = 30 fps × 6 segundos
```

Parâmetros:

| Parâmetro         | Função                       |
| ----------------- | ---------------------------- |
| `-g 180`          | GOP de 6 segundos            |
| `-keyint_min 180` | Impede GOPs menores          |
| `-sc_threshold 0` | Desativa Scene Cut Detection |

Isso ajuda a produzir segmentos mais próximos de 6 segundos.

---

# Conceitos Estudados

```text
Vídeo Original
      ↓
Transcoding
      ↓
GOP (I, P e B Frames)
      ↓
Segmentação
      ↓
Packaging (HLS/DASH)
      ↓
Manifesto (.m3u8/.mpd)
      ↓
Player/CDN
```

## Resumo

* Packaging prepara um vídeo para streaming.
* HLS utiliza playlists `.m3u8` e segmentos `.ts`.
* DASH utiliza manifestos `.mpd` e segmentos `.m4s`.
* `#EXTINF` representa a duração real dos segmentos.
* `#EXT-X-TARGETDURATION` representa a duração máxima esperada.
* O valor de `hls_time` é um alvo, não uma garantia.
* O posicionamento dos keyframes e o tamanho do GOP afetam diretamente a duração dos segmentos.
