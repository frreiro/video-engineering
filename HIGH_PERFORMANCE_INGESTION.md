# Estudo: SRT (Secure Reliable Transport) vs RTMP

## Objetivo

Estudar o protocolo SRT e compará-lo ao RTMP, entendendo suas características, vantagens e comportamento em cenários de rede instável.

---

## Conceitos Estudados

### RTMP (Real-Time Messaging Protocol)

* Protocolo tradicional de ingestão de streams.
* Baseado em TCP.
* Amplamente utilizado por plataformas de streaming.
* Fácil de configurar.
* Sensível a perda de pacotes e jitter.

### SRT (Secure Reliable Transport)

* Protocolo moderno para transporte de vídeo.
* Baseado em UDP.
* Possui mecanismos próprios de confiabilidade.
* Suporta retransmissão seletiva de pacotes.
* Permite criptografia e controle de latência.
* Mais adequado para redes instáveis.

---

## Comparação SRT x RTMP

| Característica                | RTMP       | SRT               |
| ----------------------------- | ---------- | ----------------- |
| Transporte                    | TCP        | UDP               |
| Latência                      | Média      | Baixa             |
| Tolerância a perda de pacotes | Baixa      | Alta              |
| Tolerância a jitter           | Baixa      | Alta              |
| Retransmissão                 | TCP        | Própria (ARQ)     |
| Redes instáveis               | Sofre mais | Melhor desempenho |

### Conclusão

Em ambientes sujeitos a perda de pacotes, jitter e alta latência, o SRT tende a apresentar melhor estabilidade e menor impacto visual quando comparado ao RTMP.

---

## Prática Realizada

### Uso do OBS como Fonte

Foi estudada a utilização do OBS como transmissor de stream em tempo real.

Fluxo utilizado:

```text
OBS
 ↓
SRT
 ↓
FFplay
```

Configuração de envio:

```text
srt://127.0.0.1:9999?mode=caller
```

Configuração de recepção:

```bash
ffplay "srt://0.0.0.0:9999?mode=listener"
```

---

## Monitoramento do Stream

Ferramentas utilizadas:

### FFplay

```bash
ffplay -stats "srt://0.0.0.0:9999?mode=listener"
```

### Verificação de portas

```bash
ss -lun
```

---

## Simulação de Rede

Foi estudada a utilização do `tc` e `netem` para simular condições adversas de rede.

### Perda de Pacotes

```bash
sudo tc qdisc add dev veth0 root netem loss 10%
```

### Latência

```bash
sudo tc qdisc add dev veth0 root netem delay 100ms
```

### Latência e Perda

```bash
sudo tc qdisc add dev veth0 root netem delay 100ms loss 10%
```

---

## Interfaces Virtuais (veth)

Para realizar testes na mesma máquina foi estudada a criação de pares de interfaces virtuais.

Exemplo:

```bash
ip link add veth0 type veth peer name veth1
```

Configuração de endereços:

```text
veth0 -> 10.0.0.1
veth1 -> 10.0.0.2
```

Essas interfaces permitem simular comunicação entre transmissor e receptor sem necessidade de máquinas adicionais.

---

## Cenários de Teste

### Stream sem degradação

```text
OBS
 ↓
SRT
 ↓
FFplay
```

### Stream com perda de pacotes

```text
OBS
 ↓
SRT
 ↓
veth + netem
 ↓
FFplay
```

O objetivo é comparar visualmente o comportamento do protocolo em condições normais e degradadas.

---

## Aprendizados

* O SRT é uma alternativa moderna ao RTMP para contribuição de vídeo.
* O protocolo utiliza UDP com mecanismos próprios de confiabilidade.
* O OBS pode ser utilizado como encoder/transmissor SRT.
* O FFplay pode atuar como receptor para validação dos testes.
* O `tc/netem` permite simular cenários reais de perda de pacotes e latência.
* Interfaces virtuais (`veth`) possibilitam a realização dos testes em uma única máquina.
* O SRT apresenta maior resiliência em ambientes de rede degradados quando comparado ao RTMP.
