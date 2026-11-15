#!/usr/bin/env bash
# One-time import of settings from the end-4 ii config into cloudshell.
# Merges into ~/.config/cloudshell/config.json (existing cloudshell values are overwritten
# only for the keys imported here). Safe to re-run.
set -euo pipefail
ii="${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/config.json"
cs_dir="${XDG_CONFIG_HOME:-$HOME/.config}/cloudshell"
cs="$cs_dir/config.json"

[[ -f "$ii" ]] || { echo "No ii config at $ii, nothing to import"; exit 0; }
mkdir -p "$cs_dir"
[[ -f "$cs" ]] || echo '{}' >"$cs"

imported=$(jq '
  def pick(p): (try getpath(p) catch null);
  {
    bar: {
      borderless: .bar.borderless,
      cornerStyle: .bar.cornerStyle,
      showBackground: .bar.showBackground,
      verbose: .bar.verbose,
      screenList: .bar.screenList,
      workspaces: .bar.workspaces,
      indicators: .bar.indicators
    },
    overview: .overview,
    battery: .battery,
    calendar: .calendar,
    time: (.time | del(.pomodoro)),
    tray: .tray,
    media: .media,
    launcher: .launcher,
    screenRecord: .screenRecord,
    screenSnip: .screenSnip,
    osd: .osd,
    audio: .audio,
    apps: (.apps | del(.update, .changePassword, .manageUser)),
    lock: { launchOnStartup: .lock.launchOnStartup },
    notifications: { timeout: .notifications.timeout, filters: .notifications.filters },
    dropdown: {
      columns: 4,
      toggles: [ (.sidebar.quickToggles.android.toggles // [])[]
        | select(.type as $t | ["network","bluetooth","audio","mic","notifications","idleInhibitor","powerProfile","monitorLineIn","switch2Mode","hueLight"] | index($t))
        | .size = (if .type == "hueLight" or .type == "network" or .type == "bluetooth" then 2 else .size end) ],
      sections: {
        volume: (.sidebar.quickSliders.showVolume // true),
        mic: (.sidebar.quickSliders.showMic // false),
        brightness: true
      }
    }
  } | del(..|nulls)' "$ii")

tmp=$(mktemp)
jq -s '.[0] * .[1]' "$cs" <(echo "$imported") >"$tmp" && mv "$tmp" "$cs"
echo "Imported ii settings into $cs"
