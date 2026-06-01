echo "Normal MP4:"
ffprobe \
-select_streams v \
-show_frames \
-of compact \
output_normal.mp4 | grep pict_type=B | head


echo "Zero Latency MP4:"
ffprobe \
-select_streams v \
-show_frames \
-of compact \
output_zerolatency.mp4 | grep pict_type=B | head