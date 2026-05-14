ffprobe \
-show_frames \
-select_streams v \
-print_format csv \
output_vbr.mp4 > vbr_frames.csv