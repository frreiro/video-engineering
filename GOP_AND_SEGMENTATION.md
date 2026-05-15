# GOP e Segmentação

## Objetivo

Resumo do estudo realizado sobre GOP (Group of Pictures), tipos de frames e scene-cut detection em processos de encoding de vídeo.

Fonte do estudo: arquivo enviado pelo usuário. 

---

# GOP

GOP significa:

> Group of Pictures

Representa quantos frames existem entre keyframes (I-frames).

Exemplo apresentado:

```bash
ffmpeg -i input.mp4 -codec:v libx264 -g 60 output.mp4
```

Onde:

* `-g` define o tamanho do GOP

---

# Tipos de Frames

Os frames citados foram:

## I-Frame

* Keyframe
* Frame completo
* Independente dos demais frames

## P-Frame

* Predicted
* Usa informações de frames anteriores

## B-Frame

* Bidirectional
* Usa informações de frames anteriores e futuros

---

# GOP Pequeno

Exemplo citado:

* `-g 30`

## Vantagens

* Seek mais otimizado
* Melhor para streaming
* Melhor recuperação após perda
* Menor latência

## Desvantagens

* Bitrate maior
* Arquivos maiores
* Compressão pior

---

# GOP Grande

## Vantagens

* Melhor compressão
* Arquivos menores

## Desvantagens

* Seek menos otimizado
* Maior latência
* Pior recuperação
* Maior dependência entre frames

---

# Como identificar o GOP atual

Foi citado que é possível identificar o GOP:

* Contando quantos frames existem entre os I-frames

# Tipos de Frames

| Tipo    | Nome          | O que guarda                                  |
| ------- | ------------- | --------------------------------------------- |
| I-frame | Keyframe      | imagem completa                               |
| P-frame | Predicted     | diferenças do frame anterior                  |
| B-frame | Bidirectional | diferenças usando frames anteriores e futuros |

---

# Scene-Cut Detection

Scene-cut detection é uma lógica do encoder que detecta mudanças bruscas entre frames.

Normalmente:

* Detecta troca de cena
* Cria um novo I-frame automaticamente
* Pode quebrar o GOP configurado

## Impactos citados

* Garante melhor adaptação às cenas
* Impacta o bitrate
* Mesmo com CBR e GOP fixo ainda podem ocorrer variações

## Desabilitando

Foi citado que a desativação depende do encoder utilizado.

Exemplo no `libx264`:

```bash
-sc_threshold 0
```
### Validação

No teste realizado, conseguimos ver na prático comparando o arquivo scene-cut-detection/gop_frames.csv e o scene-cut-detection/scene_cut_disable_frames.csv
No primeiro arquivo, que foi encodado com o scene cut detection ativado, vemos um I-Frame na linha 1 e outro logo na linha 5, ou seja, houve um corte de cena nesse momento, onde a difereça deveria ter sido de 120.

No segundo arquivo, com o scene-cut-detection desativado, podemos avaliar que o GOP foi fixado em 120, conforme requisitado. Ou seja, temos um I-Frame na linha 1, e outro somente na linha 121.