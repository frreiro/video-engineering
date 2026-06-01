#!/bin/bash
{

echo "Iniciando encoding normal"
# Envelopamos o "time" dentro de parênteses (subshell) e redirecionamos tudo
( time ffmpeg -i ../video.mp4 \
	-c:v libx264 \
	output_normal.mp4 ) > output_normal.log 2>&1 | tee output_normal.log
echo "Finalizado encoding normal"


echo "Iniciando encoding zero latency"
( time ffmpeg -i ../video.mp4 \
	-c:v libx264 \
	-tune zerolatency \
	output_zerolatency.mp4 ) > output_zerolatency.log 2>&1 | tee output_zerolatency.log
echo "Finalizado encoding zero latency"


echo "Iniciando encoding GOP 10"
## GOP de 10 segundos (600 frames a 60 fps)
( time ffmpeg -i ../video.mp4 \
	-c:v libx264 \
	-g 600 \
	output_gop10.mp4 ) > output_gop10.log 2>&1 | tee output_gop10.log
echo "Finalizado encoding GOP 10"


echo "Iniciando encoding GOP 1"
## GOP de 1 segundo (60 frames a 60 fps)
( time ffmpeg -i ../video.mp4 \
	-c:v libx264 \
	-g 60 \
	output_gop1.mp4 ) > output_gop1.log 2>&1 | tee output_gop1.log
echo "Finalizado encoding GOP 1"

ls -lah

} > output.log 2>&1
