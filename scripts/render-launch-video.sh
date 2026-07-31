#!/bin/zsh

set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
    print -u2 "Usage: render-launch-video.sh <physical-notch-screen-recording.mov> [output.mp4]"
    exit 1
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source_recording="$1"
output_path="${2:-$repo_root/output/launch-video/open-island-launch-real-15s.mp4}"
captions_dir="${output_path:h}/captions"
module_cache="${output_path:h}/swift-module-cache"
caption_renderer="$repo_root/scripts/render-launch-caption.swift"

if [[ ! -f "$source_recording" ]]; then
    print -u2 "Missing source recording: $source_recording"
    exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
    print -u2 "ffmpeg is required to render the launch video"
    exit 1
fi

mkdir -p "$captions_dir" "$module_cache"

CLANG_MODULE_CACHE_PATH="$module_cache" xcrun swift "$caption_renderer" \
    hook \
    "Vibe coding shouldn’t mean babysitting tabs." \
    "$captions_dir/hook.png"
CLANG_MODULE_CACHE_PATH="$module_cache" xcrun swift "$caption_renderer" \
    supporting \
    "Keep doing your thing. They’ll tell you when they need you." \
    "$captions_dir/supporting.png"
CLANG_MODULE_CACHE_PATH="$module_cache" xcrun swift "$caption_renderer" \
    end \
    "Agents and music. One glance." \
    "$captions_dir/end.png"

filter_complex="
[0:v]trim=start=16.55:end=20.65,setpts=PTS-STARTPTS,
crop=2940:1654:0:0,scale=1920:1080:flags=lanczos,fps=30,
zoompan=z='1+0.18*(1-cos(PI*min(on,32)/32))/2-0.04*(1-cos(PI*max(min(on-32,38),0)/38))/2+0.015*(1-cos(PI*max(min(on-70,53),0)/53))/2':
x='iw*0.5-(iw/zoom)*0.5':y=0:
d=1:s=1920x1080:fps=30[first_agents];
[0:v]trim=start=22:end=33.6,setpts=(PTS-STARTPTS)/2,
crop=2940:1654:0:0,scale=1920:1080:flags=lanczos,fps=30,
zoompan=z='1.11-0.11*(1-cos(PI*min(on,150)/150))/2':
x='iw*0.5-(iw/zoom)*0.5':y=0:
d=1:s=1920x1080:fps=30[multitasking];
[0:v]trim=start=33.6:end=36.7,setpts=PTS-STARTPTS,
crop=2940:1654:0:0,scale=1920:1080:flags=lanczos,fps=30,
zoompan=z='1+0.23*(1-cos(PI*min(on,28)/28))/2-0.03*(1-cos(PI*max(min(on-28,30),0)/30))/2':
x='iw*0.5-(iw/zoom)*0.5':y=0:
d=1:s=1920x1080:fps=30[return_to_island];
[0:v]trim=start=36.7:end=38.9,setpts=PTS-STARTPTS,
crop=2940:1654:0:0,scale=1920:1080:flags=lanczos,fps=30,
zoompan=z='1.20+0.08*(1-cos(PI*min(on,45)/45))/2':
x='iw*0.5-(iw/zoom)*0.5':y=0:
d=1:s=1920x1080:fps=30[spotify];
[first_agents][multitasking][return_to_island][spotify]
concat=n=4:v=1:a=0,fade=t=in:st=0:d=0.15,fade=t=out:st=15:d=0.15[base];

[1:v]trim=duration=4.1,setpts=PTS-STARTPTS,format=rgba,
fade=t=in:st=0.15:d=0.2:alpha=1,fade=t=out:st=3.75:d=0.2:alpha=1[hook];
[2:v]trim=duration=4.7,setpts=PTS-STARTPTS,format=rgba,
fade=t=in:st=0:d=0.2:alpha=1,fade=t=out:st=4.35:d=0.2:alpha=1,
setpts=PTS+4.3/TB[supporting];
[3:v]trim=duration=2.6,setpts=PTS-STARTPTS,format=rgba,
fade=t=in:st=0:d=0.2:alpha=1,fade=t=out:st=2.35:d=0.2:alpha=1,
setpts=PTS+12.6/TB[end];

[base][hook]overlay=x=0:y='32*max(0,1-t/0.32)':eof_action=pass[with_hook];
[with_hook][supporting]overlay=x=0:y='32*max(0,1-(t-4.3)/0.28)':eof_action=pass[with_supporting];
[with_supporting][end]overlay=x=0:y='32*max(0,1-(t-12.6)/0.28)':eof_action=pass,
format=yuv420p[out]
"

ffmpeg -hide_banner -loglevel warning -y \
    -i "$source_recording" \
    -loop 1 -framerate 30 -i "$captions_dir/hook.png" \
    -loop 1 -framerate 30 -i "$captions_dir/supporting.png" \
    -loop 1 -framerate 30 -i "$captions_dir/end.png" \
    -filter_complex "$filter_complex" \
    -map "[out]" \
    -an \
    -c:v libx264 \
    -preset slow \
    -crf 17 \
    -movflags +faststart \
    -t 15.2 \
    "$output_path"

print "Launch video written to $output_path"
