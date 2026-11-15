#!/usr/bin/env bash
# Route a line-in source to an output through a PulseAudio/PipeWire loopback.
#   line-in.sh on <sourceMatch> <sinkMatch>
#   line-in.sh off
#   line-in.sh status     exits 0 when the loopback is loaded
# sourceMatch / sinkMatch are substrings of the names in `pactl list short sources/sinks`.
set -uo pipefail

loaded() { pactl list short modules | grep -q "module-loopback"; }

case "${1:-status}" in
on)
    loaded && exit 0
    source=$(pactl list short sources | awk '{print $2}' | grep -v '\.monitor$' | grep -i -- "${2:-Line}" | head -n1)
    sink=$(pactl list short sinks | awk '{print $2}' | grep -i -- "${3:-}" | head -n1)
    [[ -z "$source" ]] && { echo "No source matching '${2:-}'" >&2; exit 1; }
    args=(source="$source")
    [[ -n "$sink" ]] && args+=(sink="$sink")
    pactl load-module module-loopback "${args[@]}" >/dev/null
    ;;
off)
    pactl list short modules | awk '/module-loopback/ {print $1}' | xargs -r -n1 pactl unload-module
    ;;
status)
    loaded
    ;;
*)
    echo "Usage: line-in.sh on <sourceMatch> <sinkMatch> | off | status" >&2
    exit 1
    ;;
esac
