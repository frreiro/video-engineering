ffprobe \
-show_frames \
-select_streams v \
-print_format csv \
output_cbr.mp4 > cbr_frames.csv