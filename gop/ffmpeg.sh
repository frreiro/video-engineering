ffmpeg -i ../video.mp4 \
-c:v libx264 \
-g 120 \
output_gop.mp4