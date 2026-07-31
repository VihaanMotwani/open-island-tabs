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
render_fps=60
working_size="3840:2160"
agents_frame_count=$((3 * render_fps))

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
    "Open Island keeps your coding agents in the notch." \
    "$captions_dir/hook.png"
CLANG_MODULE_CACHE_PATH="$module_cache" xcrun swift "$caption_renderer" \
    supporting \
    "Now Spotify lives there too." \
    "$captions_dir/supporting.png"
CLANG_MODULE_CACHE_PATH="$module_cache" xcrun swift "$caption_renderer" \
    end \
    "Agent updates and music controls. No app switching." \
    "$captions_dir/end.png"

filter_complex="
[0:v]trim=start=3.7:end=6.7,setpts=PTS-STARTPTS,
crop=2940:1654:0:0,scale=${working_size}:flags=lanczos,fps=$render_fps,
zoompan=z='1+0.22*(1-cos(PI*min(on,60)/60))/2-0.04*(1-cos(PI*max(min(on-60,119),0)/119))/2':
x='iw*0.5-(iw/zoom)*0.5':y=0:
d=1:s=1920x1080:fps=${render_fps}[notification];
[0:v]trim=start=16.4:end=19.4,setpts=PTS-STARTPTS,
crop=2940:1654:0:0,scale=${working_size}:flags=lanczos,fps=$render_fps,
zoompan=z='1.18+0.04*(1-cos(PI*min(on,120)/120))/2':
x='iw*0.5-(iw/zoom)*0.5':y=0:
d=1:s=1920x1080:fps=${render_fps},
tpad=stop_mode=clone:stop=1,trim=end_frame=${agents_frame_count},setpts=PTS-STARTPTS[agents];
[0:v]trim=start=34.2:end=39.8,setpts=(PTS-STARTPTS)*15/14,
crop=2940:1654:0:0,scale=${working_size}:flags=lanczos,fps=$render_fps,
zoompan=z='1.22+0.08*(1-cos(PI*min(on,120)/120))/2-0.10*(1-cos(PI*max(min(on-120,239),0)/239))/2':
x='iw*0.5-(iw/zoom)*0.5':y=0:
d=1:s=1920x1080:fps=${render_fps}[expanded_spotify];
[0:v]trim=start=43.8:end=44.5,setpts=(PTS-STARTPTS)*30/7,
crop=2940:1654:0:0,scale=${working_size}:flags=lanczos,fps=$render_fps,
zoompan=z='1.20+0.08*(1-cos(PI*min(on,120)/120))/2':
x='iw*0.5-(iw/zoom)*0.5':y=0:
d=1:s=1920x1080:fps=${render_fps}[compact_spotify];
[notification][agents][expanded_spotify][compact_spotify]concat=n=4:v=1:a=0,
fade=t=in:st=0:d=0.15,fade=t=out:st=14.8:d=0.2[base];

[1:v]trim=duration=5.9,setpts=PTS-STARTPTS,format=rgba,
fade=t=in:st=0.15:d=0.2:alpha=1,fade=t=out:st=5.6:d=0.2:alpha=1[hook];
[2:v]trim=duration=5.9,setpts=PTS-STARTPTS,format=rgba,
fade=t=in:st=0:d=0.2:alpha=1,fade=t=out:st=5.6:d=0.2:alpha=1,
setpts=PTS+6/TB[supporting];
[3:v]trim=duration=2.9,setpts=PTS-STARTPTS,format=rgba,
fade=t=in:st=0:d=0.2:alpha=1,fade=t=out:st=2.6:d=0.2:alpha=1,
setpts=PTS+12/TB[end];

[base][hook]overlay=x=0:y='32*max(0,1-t/0.32)':eof_action=pass[with_hook];
[with_hook][supporting]overlay=x=0:y='32*max(0,1-(t-6)/0.28)':eof_action=pass[with_supporting];
[with_supporting][end]overlay=x=0:y='32*max(0,1-(t-12)/0.28)':eof_action=pass,
format=yuv420p[out]
"

ffmpeg -hide_banner -loglevel warning -y \
    -i "$source_recording" \
    -loop 1 -framerate "$render_fps" -i "$captions_dir/hook.png" \
    -loop 1 -framerate "$render_fps" -i "$captions_dir/supporting.png" \
    -loop 1 -framerate "$render_fps" -i "$captions_dir/end.png" \
    -filter_complex "$filter_complex" \
    -map "[out]" \
    -an \
    -c:v libx264 \
    -preset slow \
    -crf 17 \
    -r "$render_fps" \
    -movflags +faststart \
    -t 15 \
    "$output_path"

print "Launch video written to $output_path"
