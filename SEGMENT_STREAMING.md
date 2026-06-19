# Streaming Segmentado, Chunked Transfer e CMAF

## 1. Chunked Transfer Encoding

O **Chunked Transfer Encoding** é um mecanismo do protocolo HTTP que permite que um servidor envie uma resposta em partes (*chunks*) sem precisar conhecer o tamanho total da resposta antecipadamente.

### Headers na prática

Ao invés de:

```http
Content-Length: 384941
```

O servidor envia:

```http
Transfer-Encoding: chunked
```

### Funcionamento

Exemplo de resposta HTTP:

```http
HTTP/1.1 200 OK
Transfer-Encoding: chunked

A
HelloWorld

5
12345

0
```

Onde:

| Valor | Significado |
|---------|------------|
| `A` | Tamanho hexadecimal do primeiro chunk (10 bytes) |
| `HelloWorld` | Dados do primeiro chunk |
| `5` | Tamanho hexadecimal do segundo chunk (5 bytes) |
| `12345` | Dados do segundo chunk |
| `0` | Fim da transmissão |

### Benefícios

- Permite envio de dados imediatamente após serem gerados.
- Elimina a necessidade de conhecer o tamanho final do arquivo.
- Reduz a latência em aplicações de streaming.

---

# 2. Streaming Tradicional vs Chunked Streaming

## Streaming Tradicional

Fluxo:

1. Encoder gera um segmento completo.
2. Arquivo é fechado.
3. Servidor disponibiliza o segmento.
4. Player inicia o download.

Exemplo:

```text
Encoder
  ↓
Gera segmento de 6s
  ↓
Fecha arquivo
  ↓
Servidor publica
  ↓
Player baixa
```

Tempo mínimo para início da reprodução:

```text
≈ 6 segundos
```

---

## Streaming com Chunked Transfer

Fluxo:

1. Encoder começa a gerar um segmento.
2. Pequenos pedaços ficam prontos.
3. Servidor envia imediatamente.
4. Player já inicia o download.

Exemplo:

```text
Encoder
  ↓
Começa a gerar segmento de 2s
  ↓
Primeiro chunk fica pronto em 200ms
  ↓
Servidor envia imediatamente
  ↓
Player baixa
```

Tempo para início da reprodução:

```text
≈ 200ms
```

---

# 3. CMAF (Common Media Application Format)

O **CMAF** é um padrão criado para unificar a forma como áudio e vídeo são empacotados para streaming adaptativo.

## Antes do CMAF

Era necessário gerar dois conjuntos de segmentos:

```text
Vídeo
  ↓
Encoder
 ├─ HLS Packaging
 └─ DASH Packaging
```

Resultado:

- Segmentos HLS
- Segmentos DASH

Duplicação de armazenamento e processamento.

---

## Com CMAF

Passa a existir um único conjunto de segmentos:

```text
Vídeo
  ↓
Encoder
  ↓
CMAF Packaging
  ↓
CDN
  ↓
Player
```

Apenas os manifestos são diferentes:

```text
Manifest HLS (.m3u8)
Manifest DASH (.mpd)
```

Benefícios:

- Menor armazenamento.
- Menor processamento.
- Infraestrutura simplificada.
- Compatibilidade com HLS e DASH.

---

# 4. Segmento vs CMAF Chunk

## Segmento Tradicional

O player só começa o download quando o segmento está completo.

Exemplo com segmento de 2 segundos:

```text
Encoder
  ↓
Gera 2 segundos completos
  ↓
Fecha arquivo
  ↓
Servidor publica
  ↓
Player baixa
```

---

## CMAF Chunk

O segmento é dividido em partes menores chamadas **chunks**.

Exemplo:

```text
Segmento: 2 segundos
Chunk: 0,5 segundo
```

Fluxo:

```text
0 ms    -> Chunk 1 pronto
500 ms  -> Chunk 2 pronto
1000 ms -> Chunk 3 pronto
1500 ms -> Chunk 4 pronto
2000 ms -> Segmento finalizado
```

Assim que cada chunk fica pronto:

```text
Encoder
   ↓
Chunk pronto
   ↓
Chunked Transfer
   ↓
Player recebe
```

O player não precisa aguardar o término completo do segmento.

---

# 5. CMAF Chunk no Shaka Packager

Para gerar CMAF Chunks, configure:

```bash
--segment_duration 2 \
--fragment_duration 0.5
```

## Explicação

### Segment Duration

Define o tamanho lógico do segmento:

```bash
--segment_duration 2
```

Resultado:

```text
Segmento = 2 segundos
```

### Fragment Duration

Define o tamanho de cada chunk interno:

```bash
--fragment_duration 0.5
```

Resultado:

```text
Chunk = 500 ms
```

### Estrutura gerada

```text
Segmento 2s
├── Chunk 0.5s
├── Chunk 0.5s
├── Chunk 0.5s
└── Chunk 0.5s
```

---

# 6. Relação com Low Latency DASH (LL-DASH)

O LL-DASH combina:

## CMAF

Segmentos compatíveis com DASH e HLS.

## Chunked Transfer Encoding

Permite envio antes do término do segmento.

## Fragmentação

Segmentos divididos em chunks menores.

## Player Compatível

Exemplos:

- dash.js
- Shaka Player

---

# Fluxo Completo LL-DASH

```text
Encoder
   ↓
Produz Chunk CMAF
   ↓
Chunked Transfer Encoding
   ↓
Nginx/CDN
   ↓
Manifest DASH (.mpd)
   ↓
dash.js
   ↓
Player reproduz imediatamente
```

---

# Resumo

| Tecnologia | Função |
|------------|---------|
| Chunked Transfer Encoding | Envia dados antes do arquivo terminar |
| CMAF | Formato unificado para HLS e DASH |
| Chunk CMAF | Fragmento interno de um segmento |
| Segmento | Unidade lógica de streaming |
| LL-DASH | DASH com baixa latência |
| dash.js | Player compatível com LL-DASH |
| Shaka Packager | Gerador de segmentos CMAF |

Quando combinados:

```text
CMAF
+
Chunked Transfer
+
LL-DASH
+
dash.js

= Streaming com latência próxima de tempo real
```