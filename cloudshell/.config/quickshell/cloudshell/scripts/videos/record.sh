#!/usr/bin/env bash
# Screen recording via gpu-screen-recorder.
#   record.sh [--fullscreen | --region "X,Y WxH"] [--sound]   start, or stop if a recording is running
#   record.sh --stop
#   record.sh --replay-start [--sound] | --replay-stop | --replay-save
#   record.sh --status        prints "recording", "replay", "both" or "idle"
# Running recordings are found from the processes themselves (no pid files that can go stale).
set -uo pipefail

config="${XDG_CONFIG_HOME:-$HOME/.config}/cloudshell/config.json"
save_dir=$(jq -r '.screenRecord.savePath // empty' "$config" 2>/dev/null)
[[ -z "$save_dir" ]] && save_dir="$(xdg-user-dir VIDEOS 2>/dev/null || echo "$HOME/Videos")"
replay_seconds=$(jq -r '.gameBar.replaySeconds // 60' "$config" 2>/dev/null)
mkdir -p "$save_dir"

notify() { notify-send -a "Recorder" "$@" >/dev/null 2>&1 & }
focused_monitor() { hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | .name'; }

# PIDs of running gpu-screen-recorder processes; $1 = "record" or "replay" (replay = has -r)
recorder_pids() {
    local pid args
    for pid in $(pgrep -f gpu-screen-recorder); do
        [[ "$(readlink "/proc/$pid/exe" 2>/dev/null)" == */gpu-screen-recorder ]] || continue
        args=" $(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null) "
        if [[ "$args" == *" -r "* ]]; then
            [[ "$1" == replay ]] && echo "$pid"
        else
            [[ "$1" == record ]] && echo "$pid"
        fi
    done
}
recording() { [[ -n "$(recorder_pids record)" ]]; }
replaying() { [[ -n "$(recorder_pids replay)" ]]; }

stop_recording() {
    local pids
    pids=$(recorder_pids record)
    [[ -z "$pids" ]] && return 1
    kill -INT $pids
    notify "Recording saved" "$save_dir"
}

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

audio=()
((sound)) && audio=(-a default_output)

case "$mode" in
status)
    r=0 p=0
    recording && r=1
    replaying && p=1
    if ((r && p)); then echo both; elif ((r)); then echo recording; elif ((p)); then echo replay; else echo idle; fi
    ;;
stop)
    stop_recording || true
    ;;
replay-stop)
    pids=$(recorder_pids replay)
    [[ -n "$pids" ]] && kill -INT $pids && notify "Replay buffer stopped"
    ;;
replay-save)
    pids=$(recorder_pids replay)
    if [[ -n "$pids" ]]; then
        kill -USR1 $pids && notify "Replay saved" "Last ${replay_seconds}s → $save_dir"
    else
        notify "Replay buffer is not running"
    fi
    ;;
replay-start)
    replaying && exit 0
    setsid gpu-screen-recorder -w "$(focused_monitor)" -f 60 -c mp4 -r "$replay_seconds" "${audio[@]}" -o "$save_dir" >/dev/null 2>&1 </dev/null &
    notify "Replay buffer started" "Save the last ${replay_seconds}s from the game bar"
    ;;
record)
    # Toggle: a second press stops the running recording
    stop_recording && exit 0

    out="$save_dir/recording_$(date '+%Y-%m-%d_%H.%M.%S').mp4"
    if ((fullscreen)) || [[ -z "$region" ]]; then
        target=(-w "$(focused_monitor)")
    else
        # "X,Y WxH" (slurp format) -> "WxH+X+Y"
        read -r xy wh <<<"$region"
        target=(-w region -region "${wh}+${xy%,*}+${xy#*,}")
    fi
    setsid gpu-screen-recorder "${target[@]}" -f 60 "${audio[@]}" -o "$out" >/dev/null 2>&1 </dev/null &
    notify "Recording started" "$(basename "$out")"
    ;;
esac
exit 0
