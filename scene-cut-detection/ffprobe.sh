ffprobe \
-show_frames \
-select_streams v \
-print_format csv \
output_scene_cut_disabled.mp4 > scene_cut_disable_frames.csv