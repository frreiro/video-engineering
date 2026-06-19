# Estudo de Baixa Latência - Resumo Executivo e Agentes

## 1. Visão Geral do Estudo

Este estudo tem como objetivo compreender e implementar arquiteturas de streaming de vídeo com foco em redução de latência ponta-a-ponta (End-to-End Latency).

O trabalho vem explorando todas as etapas da cadeia de distribuição de vídeo:

1. Captura e codificação (OBS Studio)
2. Transporte (RTMP e SRT)
3. Processamento (FFmpeg)
4. Packaging (HLS, DASH e CMAF)
5. Distribuição HTTP
6. Reprodução no Player

O principal problema investigado é a redução da latência acumulada em workflows tradicionais de streaming, identificando gargalos em:

* GOPs excessivamente longos
* Segmentação HLS/DASH inadequada
* Buffers excessivos
* Protocolos orientados à confiabilidade (TCP)
* Empacotamento tardio dos segmentos
* Servidores HTTP sem suporte a transferência progressiva

O estudo possui caráter prático, utilizando laboratórios locais para simular redes com perda de pacotes, jitter e atraso artificial.

---

## 2. Métricas e KPIs Alvo

### Métricas Primárias

| Métrica                   | Objetivo  |
| ------------------------- | --------- |
| End-to-End Latency        | Minimizar |
| Glass-to-Glass Latency    | Minimizar |
| Startup Time              | Minimizar |
| Segment Availability Time | Minimizar |
| Rebuffer Events           | Minimizar |
| Packet Loss Recovery Time | Minimizar |

### Indicadores Operacionais

| Indicador        | Observação                                  |
| ---------------- | ------------------------------------------- |
| GOP Duration     | Alinhada ao tamanho do segmento             |
| Segment Duration | Reduzida para baixa latência                |
| Buffer Size      | Menor possível sem comprometer estabilidade |
| Encoder Latency  | Minimizada                                  |
| Network RTT      | Monitorado                                  |
| Throughput       | Deve exceder bitrate configurado            |

### Valores Estudados

* HLS tradicional: segmentos de 6s
* GOP observado: 120 frames
* Vídeo de referência: 60 FPS
* Target Duration observada: 8s mesmo com hls_time=6
* SRT Latency: ajustável conforme condições da rede
* Buffers OBS: minimizar para cenários Low Latency

---

## 3. Arquitetura e Padrões de Projeto Identificados

### Pipeline Principal

```text
OBS
 │
 ▼
SRT Caller
 │
 ▼
FFmpeg
 │
 ├── HLS
 │
 └── DASH/CMAF
      │
      ▼
Shaka Packager
      │
      ▼
HTTP Server
      │
      ▼
Player
```

---

### Protocolos Estudados

#### RTMP

Características:

* Baseado em TCP
* Maior compatibilidade
* Recuperação automática de pacotes
* Latência moderada

Uso:

```text
OBS -> RTMP -> Servidor
```

---

#### SRT

Características:

* Baseado em UDP
* ARQ (Automatic Repeat reQuest)
* Controle de jitter
* Melhor desempenho em redes degradadas
* Menor latência

Uso:

```text
OBS -> SRT Caller -> FFmpeg
```

Comparação resumida:

| Critério               | RTMP   | SRT         |
| ---------------------- | ------ | ----------- |
| Transporte             | TCP    | UDP         |
| Latência               | Média  | Baixa       |
| Robustez               | Média  | Alta        |
| Recuperação de Pacotes | TCP    | ARQ         |
| Uso Atual              | Legado | Recomendado |

---

### Packaging

#### FFmpeg

Responsável por:

* Transcoding
* Transmuxing
* Geração de HLS
* Geração de DASH

Exemplos estudados:

```bash
ffmpeg -i input.mp4 \
-c copy \
output.mp4
```

Transmuxing.

```bash
ffmpeg -i input.mov \
-c:v libx264 \
output.mp4
```

Transcoding.

---

#### Shaka Packager

Responsável por:

* Packaging DASH
* Packaging HLS
* CMAF
* Geração de manifests

Não realiza encoding.

Arquitetura:

```text
Encoded Media
      │
      ▼
Shaka Packager
      │
      ├── DASH
      ├── HLS
      └── CMAF
```

---

### CMAF

Common Media Application Format.

Objetivo:

Permitir interoperabilidade entre DASH e HLS utilizando fragmentos comuns.

Benefícios:

* Menor latência
* Reutilização dos mesmos chunks
* Compatibilidade multi-player

Arquitetura:

```text
fMP4 Chunk
    │
    ├── DASH
    └── HLS
```

---

### Chunked Transfer Encoding

Tema central do estudo.

Objetivo:

Permitir que o player inicie o download de um segmento antes que ele esteja completamente gerado.

Fluxo tradicional:

```text
Encoder
   │
   ▼
Segmento Completo
   │
   ▼
Servidor
   │
   ▼
Player
```

Fluxo com Chunk Transfer:

```text
Encoder
   │
   ▼
Chunk
   │
   ▼
Servidor
   │
   ▼
Player
```

Benefícios:

* Menor Startup Time
* Menor Live Edge Delay
* Menor End-to-End Latency

---

### HTTP Distribution

Servidor estudado:

```bash
python3 -m http.server 8080
```

Limitação identificada:

* Não implementa streaming otimizado para CMAF chunks
* Não é adequado para LL-HLS produção
* Pode acumular buffering

[Pendente de Discussão]

Avaliar:

* Nginx
* Caddy
* Envoy
* Apache com módulos adequados

---

### GOP e Segmentação

Conceitos estudados:

#### GOP

Grupo de imagens composto por:

* I-Frames
* P-Frames
* B-Frames

Exemplo:

```text
I B B P B B P
```

Comando utilizado:

```bash
ffmpeg -i video.mp4 \
-c:v libx264 \
-g 120 \
output.mp4
```

Observação importante:

`-g 120` define o GOP máximo.

Não altera FPS.

---

### Scene Cut Detection

Estudado:

* Pode quebrar alinhamento dos segmentos
* Introduz keyframes extras

Recomendação para segmentação determinística:

```bash
-scenecut 0
```

ou equivalente do encoder.

---

## 4. Gargalos (Bottlenecks) Detectados

### 1. Segmentos Longos

Problema:

```text
Segmento = 6s
```

Impacto:

* Aumento da latência
* Player aguarda mais conteúdo

---

### 2. Target Duration Superior ao Esperado

Observação encontrada:

```text
hls_time = 6
target duration = 8
```

Possível causa:

* Ajuste automático para o maior segmento gerado
* Desalinhamento entre GOP e segmentação

---

### 3. GOP Não Alinhado

Impactos:

* Segmentos inconsistentes
* Aumento do buffering
* Dificuldade de Low Latency

---

### 4. Uso de HTTP Server Simples

Servidor:

```bash
python3 -m http.server
```

Problemas:

* Sem otimizações de streaming
* Sem Chunked CMAF eficiente
* Sem controle de cache

---

### 5. Buffers Excessivos

Locais identificados:

* OBS
* SRT
* FFmpeg
* Player

Impacto:

* Acúmulo de latência

---

### 6. Perda de Pacotes

Estudado através de:

* Interfaces virtuais
* Simulação de degradação
* Latência artificial
* Packet loss

Objetivo:

Comparar RTMP e SRT.

---

## 5. Decisões Tomadas e Próximos Passos

### Decisões

✔ Priorizar SRT em vez de RTMP para cenários Low Latency.

✔ Utilizar Shaka Packager para aprofundar estudo de DASH e CMAF.

✔ Estudar Chunked Transfer Encoding.

✔ Estudar CMAF Chunks.

✔ Avaliar alinhamento entre GOP e segmentação.

✔ Simular redes degradadas usando interfaces virtuais Linux.

---

### Próximos Experimentos

#### Experimento 1

Gerar DASH com CMAF:

```bash
ffmpeg
    ↓
shaka-packager
    ↓
DASH + CMAF
```

---

#### Experimento 2

Avaliar Chunked Transfer Encoding real.

Comparar:

```text
Segmento completo
vs
CMAF Chunk
```

---

#### Experimento 3

Trocar:

```bash
python3 -m http.server
```

por:

```text
Nginx
Caddy
```

e medir diferenças.

---

#### Experimento 4

Avaliar configurações do OBS:

* Bitrate
* Buffer Size
* Keyframe Interval
* B-Frames

---

#### Experimento 5

Estudar Low-Latency HLS (LL-HLS).

Itens:

* Partial Segments
* Preload Hints
* CMAF Chunks

---

#### Experimento 6

Criar benchmark comparando:

| Transporte | Cenário          |
| ---------- | ---------------- |
| RTMP       | Rede normal      |
| RTMP       | Perda de pacotes |
| SRT        | Rede normal      |
| SRT        | Perda de pacotes |

---

## 6. Contexto para Agentes CLI (System Prompts/Instruções)

Este repositório representa um laboratório de estudo sobre streaming de baixa latência. Ao responder comandos, priorize conhecimento relacionado a FFmpeg, SRT, RTMP, DASH, HLS, CMAF, LL-HLS, Shaka Packager, GOP, segmentação, chunked transfer encoding e otimizações de transporte de mídia em tempo real. Considere sempre o impacto de qualquer alteração sobre a latência ponta-a-ponta. Sempre que possível, proponha experimentos mensuráveis, comandos reproduzíveis e métricas comparativas. Assuma ambiente Linux, uso extensivo de FFmpeg e foco em arquiteturas práticas para streaming de vídeo de baixa latência.

---

## Referências Conceituais Estudadas

* Encoding
* Bitrate
* GOP
* I/P/B Frames
* Segmentação HLS
* Segmentação DASH
* Transcoding
* Transmuxing
* RTMP
* SRT
* CMAF
* LL-HLS
* Chunked Transfer Encoding
* Shaka Packager
* Simulação de rede degradada
* HTTP Distribution
* Packaging Pipeline
