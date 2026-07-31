#!/bin/zsh

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    print -u2 "Usage: render-tabs-demo-captions.sh <tabs-demo.mov> [output.mp4]"
    exit 1
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source_recording="$1"
output_path="${2:-$repo_root/output/launch-video/open-island-tabs-demo-captioned.mp4}"
assets_dir="${output_path:h}/tabs-demo-caption-assets"
module_cache="${output_path:h}/swift-module-cache"
caption_renderer="$repo_root/scripts/render-launch-caption.swift"
render_fps="30000/1001"

if [[ ! -f "$source_recording" ]]; then
    print -u2 "Missing source recording: $source_recording"
    exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
    print -u2 "ffmpeg is required to render the captioned demo"
    exit 1
fi

mkdir -p "$assets_dir" "$module_cache" "${output_path:h}"

caption_texts=(
    "Your agents are already handling the code."
    "Open Island keeps them one glance away."
    "Codex + Claude. Right in your notch."
    "Now Spotify lives there too."
    "Approve. Check progress. Change tracks."
    "Without leaving your flow."
    "Open Island — now with Spotify."
)

caption_styles=(hook supporting supporting supporting supporting supporting end)

for index in {1..7}; do
    CLANG_MODULE_CACHE_PATH="$module_cache" xcrun swift "$caption_renderer" \
        "$caption_styles[$index]" \
        "$caption_texts[$index]" \
        "$assets_dir/caption-$index.png"
done

filter_complex="
[0:v:0]setpts=PTS-STARTPTS,format=yuv420p[base];
[1:v]trim=duration=2.2,setpts=PTS-STARTPTS,format=rgba,
fade=t=in:st=0.08:d=0.16:alpha=1,fade=t=out:st=1.94:d=0.16:alpha=1[c1];
[2:v]trim=duration=2.1,setpts=PTS-STARTPTS,format=rgba,
fade=t=in:st=0:d=0.16:alpha=1,fade=t=out:st=1.84:d=0.16:alpha=1,
setpts=PTS+2.2/TB[c2];
[3:v]trim=duration=2.0,setpts=PTS-STARTPTS,format=rgba,
fade=t=in:st=0:d=0.16:alpha=1,fade=t=out:st=1.74:d=0.16:alpha=1,
setpts=PTS+4.3/TB[c3];
[4:v]trim=duration=2.5,setpts=PTS-STARTPTS,format=rgba,
fade=t=in:st=0:d=0.16:alpha=1,fade=t=out:st=2.24:d=0.16:alpha=1,
setpts=PTS+6.3/TB[c4];
[5:v]trim=duration=2.4,setpts=PTS-STARTPTS,format=rgba,
fade=t=in:st=0:d=0.16:alpha=1,fade=t=out:st=2.14:d=0.16:alpha=1,
setpts=PTS+8.8/TB[c5];
[6:v]trim=duration=2.2,setpts=PTS-STARTPTS,format=rgba,
fade=t=in:st=0:d=0.16:alpha=1,fade=t=out:st=1.94:d=0.16:alpha=1,
setpts=PTS+11.2/TB[c6];
[7:v]trim=duration=2.18,setpts=PTS-STARTPTS,format=rgba,
fade=t=in:st=0:d=0.16:alpha=1,fade=t=out:st=1.92:d=0.16:alpha=1,
setpts=PTS+13.4/TB[c7];
[base][c1]overlay=eof_action=pass[with_c1];
[with_c1][c2]overlay=eof_action=pass[with_c2];
[with_c2][c3]overlay=eof_action=pass[with_c3];
[with_c3][c4]overlay=eof_action=pass[with_c4];
[with_c4][c5]overlay=eof_action=pass[with_c5];
[with_c5][c6]overlay=eof_action=pass[with_c6];
[with_c6][c7]overlay=eof_action=pass,format=yuv420p[out]
"

ffmpeg -hide_banner -loglevel error -y \
    -i "$source_recording" \
    -loop 1 -framerate "$render_fps" -i "$assets_dir/caption-1.png" \
    -loop 1 -framerate "$render_fps" -i "$assets_dir/caption-2.png" \
    -loop 1 -framerate "$render_fps" -i "$assets_dir/caption-3.png" \
    -loop 1 -framerate "$render_fps" -i "$assets_dir/caption-4.png" \
    -loop 1 -framerate "$render_fps" -i "$assets_dir/caption-5.png" \
    -loop 1 -framerate "$render_fps" -i "$assets_dir/caption-6.png" \
    -loop 1 -framerate "$render_fps" -i "$assets_dir/caption-7.png" \
    -filter_complex "$filter_complex" \
    -map "[out]" \
    -map 0:a:0 \
    -c:v libx264 \
    -preset slow \
    -crf 17 \
    -r "$render_fps" \
    -c:a aac \
    -b:a 192k \
    -movflags +faststart \
    -shortest \
    "$output_path"

print "Captioned demo written to $output_path"
