# Encoding e Bitrate

## Objetivo

Resumo do estudo realizado sobre bitrate, tipos de controle de bitrate e fluxo de encoding de vídeo utilizando FFmpeg.

---

# O que é Bitrate

Bitrate é a quantidade de bits processados por segundo em um vídeo.

Quanto maior o bitrate:

* Maior tende a ser a qualidade do vídeo
* Maior tende a ser o tamanho do arquivo

---

# CBR (Constant Bitrate)

No modo CBR, o bitrate permanece constante independentemente da complexidade da cena.

Exemplo:

* Segundo 1 → 4 Mbps
* Segundo 2 → 4 Mbps
* Segundo 3 → 4 Mbps

## Vantagens

* Mais previsível
* Melhor para transmissões ao vivo

## Desvantagens

* Pode desperdiçar bitrate em cenas simples
* Eficiência menor

---

# VBR (Variable Bitrate)

No modo VBR, o bitrate varia dinamicamente de acordo com a complexidade do vídeo.

Cenas mais complexas recebem mais bitrate e cenas simples recebem menos.

## Vantagens

* Melhor eficiência de armazenamento
* Melhor qualidade percebida

## Desvantagens

* Menor previsibilidade
* Pode ter maior latência

---

# Fluxo de Encoding

O fluxo básico apresentado foi:

1. Arquivo original
2. Demux
3. Decoder
4. Frames brutos
5. Encoder
6. Mux
7. Novo arquivo

---

# FFmpeg

O FFmpeg foi apresentado como ferramenta responsável por:

* Detectar codecs
* Fazer demux
* Fazer decode
* Fazer encode
* Fazer mux

Exemplo citado:

```bash
ffmpeg -i input.mp4 -c:v libx264 output.mp4
```

Onde:

* `-i` define o arquivo de entrada
* `-c:v` define o codec de vídeo
* `libx264` é o encoder utilizado

---

# Presets

Presets são configurações pré-definidas do encoder.

Eles influenciam:

* Velocidade do encode
* Taxa de compressão
* Uso de CPU
* Tamanho do arquivo final

Relação geral apresentada:

* Mais compressão → menor bitrate
* Mais velocidade → arquivos maiores
* Mais qualidade → maior processamento

---

# Conceitos citados

* Codec
* Decode
* Encode
* Mux
* Demux
* Frames
* Compressão
* Bitrate
* Presets
