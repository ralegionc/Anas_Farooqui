#!/usr/bin/env bash
# Compresses the raw portrait exports down to something a web page can serve.
#
# Run from the project root in Git Bash:   ./compress-videos.sh
# Needs ffmpeg on PATH:                    winget install Gyan.FFmpeg
#
# Why these settings:
#   scale=1080:-2   the panel is 600 CSS px wide, so 1080 covers a 2x display
#                   with room to spare. The 4K sources are 3.6x past useful.
#   crf 30          the video sits behind a dark scrim under body text; the
#                   difference from crf 18 is invisible there and roughly 8x
#                   the file size.
#   -an             strips audio. They play muted, so it is pure waste.
#   +faststart      moves the index to the front so playback can begin before
#                   the download finishes.
set -u

pairs=(
  "assets/dna2.mp4|assets/dna-bg.mp4|"
  "assets/neuralode-video2.mp4|assets/neuralode-bg.mp4|"
  "assets/sleepatlas-video2.mp4|assets/sleepatlas-bg.mp4|"
  "assets/heliostream-video2.mp4|assets/heliostream-bg.mp4|"
  # 58s is far too long to loop; 12s is plenty behind text.
  "assets/fluidsr-video2.mp4|assets/fluidsr-bg.mp4|-t 12"
)

command -v ffmpeg >/dev/null 2>&1 || { echo "ffmpeg not found. Install it, then re-run."; exit 1; }

total_in=0; total_out=0
for row in "${pairs[@]}"; do
  IFS='|' read -r src out extra <<< "$row"
  [ -f "$src" ] || { echo "skip: $src not found"; continue; }
  printf '%-30s -> %s\n' "$(basename "$src")" "$(basename "$out")"
  # shellcheck disable=SC2086
  ffmpeg -y -loglevel error -i "$src" $extra \
    -vf scale=1080:-2 -c:v libx264 -crf 30 -preset slow \
    -pix_fmt yuv420p -movflags +faststart -an "$out" || { echo "  FAILED"; continue; }
  in=$(wc -c < "$src"); on=$(wc -c < "$out")
  total_in=$((total_in+in)); total_out=$((total_out+on))
  awk -v a="$in" -v b="$on" 'BEGIN{printf "  %.1f MB -> %.2f MB  (%.0fx smaller)\n", a/1048576, b/1048576, a/b}'
done

echo
awk -v a="$total_in" -v b="$total_out" 'BEGIN{printf "TOTAL  %.1f MB -> %.2f MB\n", a/1048576, b/1048576}'
echo "Then tell Claude the compression is done and the five -bg.mp4 files will be wired in."
