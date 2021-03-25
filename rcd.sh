#!/bin/sh
output=${1:-output.mkv}
timestamp=$(date -Iseconds)
sz=$(xwininfo -root | awk '/geometry/ {print $2}' | awk -F+ '{print $1}')

if [ -a $output ]; then
  echo "moving: "$output" to "$output$timestamp
  mv -v $output $output$timestamp
fi

echo "output["$output"]"
echo "size["$sz"]"


ffmpeg -f x11grab -video_size $sz -framerate 25 -i $DISPLAY -vcodec libx264 -threads 0 output.mkv

