#!/bin/zsh

set -euo pipefail

if [[ $# -lt 1 || $# -gt 3 ]]; then
    print -u2 "Usage: render-launch-video.sh <physical-notch-screen-recording.mov> [output.mp4] [wallpaper]"
    exit 1
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source_recording="$1"
output_path="${2:-$repo_root/output/launch-video/open-island-launch-real-15s.mp4}"
wallpaper_path="${3:-/System/Library/Desktop Pictures/.thumbnails/Big Sur Graphic Dark.heic}"
captions_dir="${output_path:h}/captions"
masks_dir="${output_path:h}/masks"
module_cache="${output_path:h}/swift-module-cache"
wallpaper_image="${output_path:h}/wallpaper.png"
caption_renderer="$repo_root/scripts/render-launch-caption.swift"
mask_renderer="$repo_root/scripts/render-launch-mask.swift"
render_fps=60
working_size="3840:2160"
short_beat_frame_count=$((7 * render_fps / 2))
spotify_beat_frame_count=$((6 * render_fps))
final_frame_count=$((15 * render_fps))

if [[ ! -f "$source_recording" ]]; then
    print -u2 "Missing source recording: $source_recording"
    exit 1
fi

if [[ ! -f "$wallpaper_path" ]]; then
    print -u2 "Missing wallpaper: $wallpaper_path"
    exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
    print -u2 "ffmpeg is required to render the launch video"
    exit 1
fi

mkdir -p "$captions_dir" "$masks_dir" "$module_cache"

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

CLANG_MODULE_CACHE_PATH="$module_cache" xcrun swift "$mask_renderer" \
    2940 1654 1050 0 840 715 48 \
    "$masks_dir/notification.png"
CLANG_MODULE_CACHE_PATH="$module_cache" xcrun swift "$mask_renderer" \
    2940 1654 1050 0 840 645 48 \
    "$masks_dir/agents.png"
CLANG_MODULE_CACHE_PATH="$module_cache" xcrun swift "$mask_renderer" \
    2940 1654 950 0 1040 465 48 \
    "$masks_dir/spotify.png"

ffmpeg -hide_banner -loglevel error -y \
    -i "$wallpaper_path" \
    -map 0:v:0 \
    -frames:v 1 \
    "$wallpaper_image"

filter_complex="
[4:v]scale=2940:1654:force_original_aspect_ratio=increase:flags=lanczos,
crop=2940:1654,gblur=sigma=1.6,eq=brightness=-0.10:contrast=0.94:saturation=0.58,
fps=$render_fps,format=yuv420p,split=4[notification_wallpaper][agents_wallpaper][expanded_wallpaper][compact_wallpaper];
[5:v]fps=$render_fps,format=gray,trim=duration=3.5,setpts=PTS-STARTPTS[notification_mask];
[6:v]fps=$render_fps,format=gray,trim=duration=3.5,setpts=PTS-STARTPTS[agents_mask];
[7:v]fps=$render_fps,format=gray,split=2[expanded_mask_source][compact_mask_source];
[expanded_mask_source]trim=duration=6,setpts=PTS-STARTPTS[expanded_mask];
[compact_mask_source]trim=duration=3.5,setpts=PTS-STARTPTS[compact_mask];

[0:v]trim=start=5.15:end=6.65,setpts=(PTS-STARTPTS)*7/3,
crop=2940:1654:0:0,fps=$render_fps,format=yuv420p[notification_source];
[notification_source][notification_mask]alphamerge[notification_cutout];
[notification_wallpaper][notification_cutout]overlay=shortest=1:format=auto,
scale=${working_size}:flags=lanczos,fps=$render_fps,
zoompan=z='1+0.22*(1-cos(PI*min(on,60)/60))/2-0.04*(1-cos(PI*max(min(on-60,119),0)/119))/2':
x='iw*0.5-(iw/zoom)*0.5':y=0:
d=1:s=1920x1080:fps=${render_fps},
tpad=stop_mode=clone:stop=1,trim=end_frame=${short_beat_frame_count},setpts=PTS-STARTPTS[notification];
[0:v]trim=start=16.4:end=19.4,setpts=(PTS-STARTPTS)*7/6,
crop=2940:1654:0:0,fps=$render_fps,format=yuv420p[agents_source];
[agents_source][agents_mask]alphamerge[agents_cutout];
[agents_wallpaper][agents_cutout]overlay=shortest=1:format=auto,
scale=${working_size}:flags=lanczos,fps=$render_fps,
zoompan=z='1.18+0.04*(1-cos(PI*min(on,120)/120))/2':
x='iw*0.5-(iw/zoom)*0.5':y=0:
d=1:s=1920x1080:fps=${render_fps},
tpad=stop_mode=clone:stop=1,trim=end_frame=${short_beat_frame_count},setpts=PTS-STARTPTS[agents];
[0:v]trim=start=35.3:end=38.6,setpts=(PTS-STARTPTS)*20/11,
crop=2940:1654:0:0,fps=$render_fps,format=yuv420p[expanded_source];
[expanded_source][expanded_mask]alphamerge[expanded_cutout];
[expanded_wallpaper][expanded_cutout]overlay=shortest=1:format=auto,
scale=${working_size}:flags=lanczos,fps=$render_fps,
zoompan=z='1.22+0.08*(1-cos(PI*min(on,120)/120))/2-0.10*(1-cos(PI*max(min(on-120,239),0)/239))/2':
x='iw*0.5-(iw/zoom)*0.5':y=0:
d=1:s=1920x1080:fps=${render_fps},
tpad=stop_mode=clone:stop=1,trim=end_frame=${spotify_beat_frame_count},setpts=PTS-STARTPTS[expanded_spotify];
[0:v]trim=start=43.8:end=44.5,setpts=(PTS-STARTPTS)*5,
crop=2940:1654:0:0,fps=$render_fps,format=yuv420p[compact_source];
[compact_source][compact_mask]alphamerge[compact_cutout];
[compact_wallpaper][compact_cutout]overlay=shortest=1:format=auto,
scale=${working_size}:flags=lanczos,fps=$render_fps,
zoompan=z='1.20+0.08*(1-cos(PI*min(on,120)/120))/2':
x='iw*0.5-(iw/zoom)*0.5':y=0:
d=1:s=1920x1080:fps=${render_fps},
tpad=stop_mode=clone:stop=1,trim=end_frame=${short_beat_frame_count},setpts=PTS-STARTPTS[compact_spotify];
[notification][agents]xfade=transition=fade:duration=0.5:offset=3[agents_story];
[agents_story][expanded_spotify]xfade=transition=fade:duration=0.5:offset=6[expanded_story];
[expanded_story][compact_spotify]xfade=transition=fade:duration=0.5:offset=11.5,
tpad=stop_mode=clone:stop=1,trim=end_frame=${final_frame_count},setpts=PTS-STARTPTS,
fade=t=in:st=0:d=0.15,fade=t=out:st=14.8:d=0.2[base];

[1:v]trim=duration=5.9,setpts=PTS-STARTPTS,format=rgba,
fade=t=in:st=0.15:d=0.2:alpha=1,fade=t=out:st=5.6:d=0.2:alpha=1[hook];
[2:v]trim=duration=5.4,setpts=PTS-STARTPTS,format=rgba,
fade=t=in:st=0:d=0.2:alpha=1,fade=t=out:st=5.1:d=0.2:alpha=1,
setpts=PTS+6/TB[supporting];
[3:v]trim=duration=3.4,setpts=PTS-STARTPTS,format=rgba,
fade=t=in:st=0:d=0.2:alpha=1,fade=t=out:st=3.1:d=0.2:alpha=1,
setpts=PTS+11.5/TB[end];

[base][hook]overlay=x=0:y='32*max(0,1-t/0.32)':eof_action=pass[with_hook];
[with_hook][supporting]overlay=x=0:y='32*max(0,1-(t-6)/0.28)':eof_action=pass[with_supporting];
[with_supporting][end]overlay=x=0:y='32*max(0,1-(t-11.5)/0.28)':eof_action=pass,
format=yuv420p[out]
"

ffmpeg -hide_banner -loglevel error -y \
    -i "$source_recording" \
    -loop 1 -framerate "$render_fps" -i "$captions_dir/hook.png" \
    -loop 1 -framerate "$render_fps" -i "$captions_dir/supporting.png" \
    -loop 1 -framerate "$render_fps" -i "$captions_dir/end.png" \
    -loop 1 -framerate "$render_fps" -i "$wallpaper_image" \
    -loop 1 -framerate "$render_fps" -i "$masks_dir/notification.png" \
    -loop 1 -framerate "$render_fps" -i "$masks_dir/agents.png" \
    -loop 1 -framerate "$render_fps" -i "$masks_dir/spotify.png" \
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
