ffprobe \
-show_frames \
-select_streams v \
-print_format csv \
output_gop.mp4 > gop_frames.csv

ffprobe \
-show_frames \
-select_streams v \
-print_format csv \
../video.mp4 > video_frames.csv