# Otimização do Encoder - Tunagem Zero Latency no FFmpeg

## Objetivo

Avaliar o impacto do parâmetro `-tune zerolatency` no encoder H.264 (`libx264`), comparando características relacionadas a latência e processamento.

---

# O que é Latência em Vídeo

Latência é o tempo que um frame leva desde sua captura até sua exibição ao usuário.

## Pipeline de vídeo

Captura → Encoding → Packaging → Distribuição → Player

## Tipos de latência

- Capture Latency
- Encoding Latency
- Network Latency
- Buffer Latency
- Playback Latency

### Por que uma live pode ter atraso mesmo com internet rápida?

Porque a latência não depende apenas da rede. Processos como encoding, segmentação, buffers e player também contribuem para o atraso.

---

# Frame Reordering

Técnica onde os frames são codificados, transmitidos e decodificados em uma ordem diferente da ordem de exibição.

## Conceitos

O H.264 utiliza B-Frames para melhorar a compressão.

Exemplo:

```
I B B P
```

Para gerar um B-Frame, o encoder precisa conhecer frames futuros.

### Por que B-Frames aumentam a latência?

Porque o encoder precisa esperar frames futuros antes de codificar os frames atuais.

---

# Lookahead

Lookahead é a análise antecipada de frames futuros.

Exemplo:

- Frame atual + 40 frames futuros

## Benefícios

- Melhor qualidade
- Melhor compressão
- Melhor controle de bitrate

## Desvantagens

- Mais uso de memória
- Mais uso de CPU
- Mais latência

### Por que o Lookahead aumenta a latência?

Porque o encoder precisa armazenar e analisar vários frames antes da codificação.

---

# Buffers Internos do Encoder

O encoder utiliza buffers para:

- Reordenação de frames
- Lookahead
- Controle de bitrate
- Processamento paralelo

## Fluxo

```
Frame
 ↓
Buffer
 ↓
Análise
 ↓
Codificação
 ↓
Saída
```

### Relação entre buffer e latência

Quanto maior o buffer:

- Maior a latência
- Melhor a eficiência da compressão

---

# Throughput vs Latência

## Throughput

Quantidade de frames processados por segundo.

Exemplo:

- 300 FPS

## Latência

Tempo necessário para um frame atravessar todo o pipeline.

Exemplo:

- 50 ms

### Mais FPS significa menor latência?

Não.

Um encoder pode processar muitos frames por segundo e ainda apresentar alta latência.

---

# Presets vs Tune

## Presets

Controlam a velocidade e eficiência da compressão.

Exemplos:

- ultrafast
- superfast
- veryfast
- faster
- fast
- medium
- slow
- slower
- veryslow

## Tune

Controla comportamentos específicos do encoder.

Exemplos:

- film
- animation
- grain
- stillimage
- fastdecode
- zerolatency

### Diferença

| Preset | Tune |
|----------|----------|
| Controla velocidade e compressão | Controla comportamentos específicos do encoder |

---

# Casos Reais

## Streaming Tradicional

```
Encoder
 ↓
HLS
 ↓
CDN
 ↓
Player
```

Latência típica:

- 15 a 30 segundos

---

## Low Latency Streaming

```
Encoder
 ↓
LL-HLS
 ↓
CDN
 ↓
Player
```

Latência típica:

- 2 a 5 segundos

---

## WebRTC

```
Encoder
 ↓
Rede
 ↓
Player
```

Latência típica:

- Menor que 500 ms

---

# Prática

## Encoding com Zero Latency

```bash
ffmpeg -i video.mp4 \
-c:v libx264 \
-tune zerolatency \
output.mp4
```

---

## Encoding com GOP de 1 segundo

Para um vídeo de 60 FPS:

- GOP = 60
- 1 I-Frame a cada segundo

```bash
ffmpeg -i video.mp4 \
-c:v libx264 \
-g 60 \
output.mp4
```

---

# Conclusões

- A maior parte da latência de um encoder está relacionada a B-Frames, Lookahead e Buffers.
- O parâmetro `-tune zerolatency` reduz mecanismos internos que aumentam a latência.
- Menor latência normalmente implica menor eficiência de compressão.
- Throughput e latência são métricas diferentes e não devem ser confundidas.
- Presets definem velocidade/compressão, enquanto Tunes ajustam comportamentos específicos do encoder.
- Para aplicações em tempo real, como WebRTC e transmissões interativas, reduzir a latência é mais importante que maximizar a compressão.