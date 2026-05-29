# Transcoding e Transmuxing

## Conceitos

### Transcoding

Transcoding é o processo de decodificar um arquivo de mídia e codificá-lo novamente, normalmente alterando alguma característica do vídeo ou áudio.

Exemplos de alterações que exigem transcode:

* Mudança de codec (ProRes → H.264)
* Mudança de resolução (1080p → 720p)
* Mudança de bitrate
* Mudança de FPS
* Aplicação de filtros (crop, watermark, etc.)

Fluxo:

```text
Arquivo Original
      ↓
 Decodificação
      ↓
 Processamento
      ↓
 Codificação
      ↓
 Arquivo Final
```

Exemplo FFmpeg:

```bash
ffmpeg -i video.mov -c:v libx264 output.mp4
```

### Características do Transcode

* Consome CPU/GPU
* Processo mais lento
* Pode gerar perda de qualidade
* Permite alterar características do vídeo

---

## Transmuxing (Remuxing)

Transmuxing é a troca do container sem alterar os codecs dos streams internos.

Exemplo:

```text
video.mkv
├── H.264
└── AAC

      ↓

video.mp4
├── H.264
└── AAC
```

Os codecs permanecem exatamente os mesmos.

Exemplo FFmpeg:

```bash
ffmpeg -i video.mkv -c copy video.mp4
```

ou

```bash
ffmpeg -i video.mkv -c:v copy -c:a copy video.mp4
```

Fluxo:

```text
Arquivo Original
      ↓
 Cópia dos Streams
      ↓
 Novo Container
```

### Características do Transmuxing

* Não utiliza codificação
* Uso mínimo de CPU
* Muito rápido
* Sem perda de qualidade
* Mantém bitrate original

---

## Comparação

| Característica     | Transcode      | Transmux   |
| ------------------ | -------------- | ---------- |
| Muda codec         | Sim            | Não        |
| Muda container     | Pode mudar     | Sim        |
| Re-encoda          | Sim            | Não        |
| Consome CPU        | Alto           | Baixo      |
| Perda de qualidade | Possível       | Não        |
| Velocidade         | Baixa/Moderada | Muito alta |

---

## Verificando os Codecs

Utilizar FFprobe:

```bash
ffprobe -v error \
-show_entries stream=codec_name \
-of default=noprint_wrappers=1 \
video.mp4
```

Exemplo de saída:

```text
codec_name=h264
codec_name=aac
```

---

## Prática Realizada

### Transcode

Conversão de codec:

```bash
ffmpeg -i video_prores.mov \
-c:v libx264 \
-c:a aac \
output.mp4
```

### Transmux

Troca apenas do container:

```bash
ffmpeg -i video.mkv \
-c copy \
output.mp4
```

---

## Conclusão

* **Transcode** altera o conteúdo do vídeo e exige recodificação.
* **Transmux** altera apenas a embalagem (container), mantendo o conteúdo intacto.
* Em pipelines de streaming, sempre que possível, utiliza-se **transmuxing** devido ao menor custo computacional.
