ffmpeg -i ../video.mp4 \
-c:v libx264 \
-b:v 5M \
-maxrate 8M \
-bufsize 10M \
-c:a aac \
-b:a 128k \
output_vbr.mp4