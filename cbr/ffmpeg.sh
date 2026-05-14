ffmpeg -i ../video.mp4 \
-c:v libx264 \
-b:v 5M \
-minrate 5M \
-maxrate 5M \
-bufsize 10M \
-x264-params nal-hrd=cbr \
-c:a aac \
-b:a 128k \
output_cbr.mp4