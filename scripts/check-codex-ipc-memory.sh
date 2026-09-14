#!/bin/zsh
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
probe_dir="$(mktemp -d /tmp/oi-memory.XXXXXX)"
trap 'rm -rf "$probe_dir"' EXIT

# A separate process makes the memory ceiling independent of parallel tests.
swiftc -swift-version 6 -module-cache-path "$probe_dir/module-cache" \
    "$repo_root/Sources/OpenIslandCore/CodexDesktopIPCClient.swift" \
    "$repo_root/Sources/OpenIslandCore/CodexDesktopRequestStream.swift" \
    "$repo_root/scripts/fixtures/CodexIPCMemoryProbe.swift" \
    -o "$probe_dir/probe"
"$probe_dir/probe" "$probe_dir/ipc.sock"
