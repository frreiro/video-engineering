echo "Iniciando veryslow"
time {
	ffmpeg -i ../video.mp4 -c:v libx264 -preset veryslow -crf 23 preset_slow_output.mp4
}
echo "Finalizado veryslow"


echo "Iniciando ultrafast"
time {
	ffmpeg -i ../video.mp4 -c:v libx264 -preset ultrafast -crf 23 preset_ultrafast_output.mp4
}
echo "Finalizado ultrafast"
ls -lah
