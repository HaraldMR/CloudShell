#!/usr/bin/env bash
# Screen recording via gpu-screen-recorder.
#   record.sh [--fullscreen | --region "X,Y WxH"] [--sound]   start, or stop if already recording
#   record.sh --stop
#   record.sh --replay-start [--sound] | --replay-stop | --replay-save
#   record.sh --status        prints "recording", "replay", "both" or "idle"
set -uo pipefail

run_dir="${XDG_RUNTIME_DIR:-/tmp}/cloudshell"
rec_pid="$run_dir/record.pid"
replay_pid="$run_dir/replay.pid"
mkdir -p "$run_dir"

config="${XDG_CONFIG_HOME:-$HOME/.config}/cloudshell/config.json"
save_dir=$(jq -r '.screenRecord.savePath // empty' "$config" 2>/dev/null)
[[ -z "$save_dir" ]] && save_dir="$(xdg-user-dir VIDEOS 2>/dev/null || echo "$HOME/Videos")"
replay_seconds=$(jq -r '.gameBar.replaySeconds // 60' "$config" 2>/dev/null)
mkdir -p "$save_dir"

alive() { [[ -f "$1" ]] && kill -0 "$(cat "$1")" 2>/dev/null; }
notify() { notify-send -a "Recorder" "$@" & disown; }
focused_monitor() { hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | .name'; }

region="" sound=0 fullscreen=0 mode="record"
while (($#)); do
    case "$1" in
    --region) region="${2:-}"; shift ;;
    --sound) sound=1 ;;
    --fullscreen) fullscreen=1 ;;
    --stop) mode="stop" ;;
    --replay-start) mode="replay-start" ;;
    --replay-stop) mode="replay-stop" ;;
    --replay-save) mode="replay-save" ;;
    --status) mode="status" ;;
    esac
    shift
done

case "$mode" in
status)
    r=0 p=0
    alive "$rec_pid" && r=1
    alive "$replay_pid" && p=1
    if ((r && p)); then echo both; elif ((r)); then echo recording; elif ((p)); then echo replay; else echo idle; fi
    exit 0
    ;;
stop)
    alive "$rec_pid" && kill -INT "$(cat "$rec_pid")" && notify "Recording saved" "$save_dir"
    exit 0
    ;;
replay-stop)
    alive "$replay_pid" && kill -INT "$(cat "$replay_pid")" && notify "Replay buffer stopped"
    rm -f "$replay_pid"
    exit 0
    ;;
replay-save)
    if alive "$replay_pid"; then
        kill -USR1 "$(cat "$replay_pid")" && notify "Replay saved" "Last ${replay_seconds}s → $save_dir"
    else
        notify "Replay buffer is not running"
    fi
    exit 0
    ;;
esac

audio=()
((sound)) && audio=(-a default_output)

if [[ "$mode" == "replay-start" ]]; then
    alive "$replay_pid" && exit 0
    gpu-screen-recorder -w "$(focused_monitor)" -f 60 -c mp4 -r "$replay_seconds" "${audio[@]}" -o "$save_dir" &
    echo $! >"$replay_pid"
    notify "Replay buffer started" "Save the last ${replay_seconds}s from the game bar"
    exit 0
fi

# Toggle: stop a running recording
if alive "$rec_pid"; then
    kill -INT "$(cat "$rec_pid")"
    rm -f "$rec_pid"
    notify "Recording saved" "$save_dir"
    exit 0
fi

out="$save_dir/recording_$(date '+%Y-%m-%d_%H.%M.%S').mp4"
if ((fullscreen)) || [[ -z "$region" ]]; then
    target=(-w "$(focused_monitor)")
else
    # "X,Y WxH" (slurp format) -> "WxH+X+Y"
    read -r xy wh <<<"$region"
    target=(-w region -region "${wh}+${xy%,*}+${xy#*,}")
fi

gpu-screen-recorder "${target[@]}" -f 60 "${audio[@]}" -o "$out" &
echo $! >"$rec_pid"
notify "Recording started" "$(basename "$out")"
wait $!
rm -f "$rec_pid"
