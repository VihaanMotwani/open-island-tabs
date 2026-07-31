#!/bin/zsh

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "The Claude launch demo runs only on macOS." >&2
    exit 1
fi

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

swift build -c debug --product OpenIslandApp

build_root="$(swift build -c debug --show-bin-path)"
app_binary="$build_root/OpenIslandApp"
sparkle_framework="$build_root/Sparkle.framework"
demo_root="$(mktemp -d "$repo_root/.build/claude-demo.XXXXXX")"
bundle_dir="$demo_root/Open Island Claude Demo.app"
bundle_binary="$bundle_dir/Contents/MacOS/OpenIslandApp"
demo_pid=""

cleanup() {
    if [[ -n "$demo_pid" ]] && kill -0 "$demo_pid" 2>/dev/null; then
        kill -TERM "$demo_pid" 2>/dev/null || true
    fi
    rm -rf "$demo_root"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

mkdir -p "$bundle_dir/Contents/MacOS" "$bundle_dir/Contents/Frameworks"
command cp "$app_binary" "$bundle_binary"
command cp "$repo_root/scripts/claude-demo-Info.plist" "$bundle_dir/Contents/Info.plist"
command cp -R "$sparkle_framework" "$bundle_dir/Contents/Frameworks/"
chmod +x "$bundle_binary"
install_name_tool -add_rpath @loader_path/../Frameworks "$bundle_binary" 2>/dev/null || true
codesign --force --deep --sign - "$bundle_dir" >/dev/null

echo "Launching the local Claude demo. No live hooks or session history will be used."
echo "The demo stays open until you press Control-C or quit Open Island."
open -n "$bundle_dir" \
    --env OPEN_ISLAND_HARNESS_SCENARIO=claudeDemo \
    --env OPEN_ISLAND_HARNESS_PRESENT_OVERLAY=1 \
    --env OPEN_ISLAND_HARNESS_START_BRIDGE=0 \
    --env OPEN_ISLAND_HARNESS_BOOT_ANIMATION=0

for _ in {1..50}; do
    demo_pid="$(pgrep -f -x "$bundle_binary" || true)"
    if [[ -n "$demo_pid" ]]; then
        break
    fi
    sleep 0.1
done

if [[ -z "$demo_pid" ]]; then
    echo "Claude demo failed to launch." >&2
    exit 1
fi

while kill -0 "$demo_pid" 2>/dev/null; do
    sleep 0.5
done
