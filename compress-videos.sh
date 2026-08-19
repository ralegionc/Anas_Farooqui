#!/usr/bin/env bash
# Turns the raw portrait exports in assets/ into web-sized -bg.mp4 files.
#
#   winget install Gyan.FFmpeg     # once, then reopen the terminal
#   ./compress-videos.sh           # from the project root, in Git Bash
#
# Settings, and why:
#
#   -t 9            nothing plays longer than nine seconds. Only the fluid
#                   clip is affected; it runs 57.9s and everything else is
#                   already under.
#
#   scale=1080:-2   the panel is 600 CSS px wide, so 1080 covers a 2x
#                   display. Three sources are already 1080 and pass through
#                   untouched; the two 4K ones come down from 2160, where
#                   they were carrying nearly four times the pixels that can
#                   ever be shown.
#
#   -crf 20         visually transparent. The earlier draft of this script
#                   used 30, which is fine for something hidden behind a
#                   scrim but is a real quality cut. 20 is the point where
#                   further bitrate stops buying anything the eye can find.
#
#   -preset veryslow  spends encoder time to hit that quality in fewer bits.
#                   It costs minutes here and nothing at playback.
#
#   -an             drops the audio track. They play muted, so it is waste.
#
#   +faststart      moves the index to the front so playback can start
#                   before the file has finished downloading.
set -u

command -v ffmpeg >/dev/null 2>&1 || {
  echo "ffmpeg not found on PATH."
  echo "  winget install Gyan.FFmpeg    then reopen this terminal and re-run."
  exit 1
}

pairs=(
  "assets/dna2.mp4|assets/dna-bg.mp4"
  "assets/neuralode-video2.mp4|assets/neuralode-bg.mp4"
  "assets/sleepatlas-video2.mp4|assets/sleepatlas-bg.mp4"
  "assets/fluidsr-video2.mp4|assets/fluidsr-bg.mp4"
  "assets/heliostream-video2.mp4|assets/heliostream-bg.mp4"
)

total_in=0; total_out=0; failed=0
for row in "${pairs[@]}"; do
  IFS='|' read -r src out <<< "$row"
  [ -f "$src" ] || { echo "skip: $src not found"; continue; }
  printf '%-28s -> %-24s ' "$(basename "$src")" "$(basename "$out")"
  if ffmpeg -y -loglevel error -i "$src" \
       -t 9 -vf "scale=1080:-2" \
       -c:v libx264 -crf 20 -preset veryslow -profile:v high -pix_fmt yuv420p \
       -movflags +faststart -an "$out"; then
    a=$(wc -c < "$src"); b=$(wc -c < "$out")
    total_in=$((total_in+a)); total_out=$((total_out+b))
    awk -v a="$a" -v b="$b" 'BEGIN{printf "%7.1f MB -> %6.2f MB  (%.0fx)\n", a/1048576, b/1048576, a/b}'
  else
    echo "FAILED"; failed=$((failed+1))
  fi
done

echo
awk -v a="$total_in" -v b="$total_out" 'BEGIN{printf "TOTAL  %.1f MB -> %.2f MB\n", a/1048576, b/1048576}'
[ "$failed" -gt 0 ] && echo "$failed file(s) failed."
echo
echo "If any clip still looks soft, drop -crf to 18 and re-run."
echo "Then point the five VID constants in index.html at the new -bg.mp4 files."
