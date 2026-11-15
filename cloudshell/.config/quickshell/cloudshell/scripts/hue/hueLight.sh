#!/usr/bin/env bash
# Control a Philips Hue room through the bridge's local API.
#   hueLight.sh get          print {"name","reachable","on","brightness"} as JSON
#   hueLight.sh on|off
#   hueLight.sh set <0-100>  brightness in percent, 0 turns the room off
# Bridge address, API key and room id are read from $HUE_ENV_FILE (default ~/.config/hue/bridge.env):
#   HUE_BRIDGE=<ip>  HUE_KEY=<api key>  HUE_GROUP=<room id>
set -euo pipefail

source "${HUE_ENV_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/hue/bridge.env}"
api="https://$HUE_BRIDGE/api/$HUE_KEY"

req() { curl -sfk --max-time 3 "$@"; }

# Lights are set one by one because the bridge rate-limits room commands to ~1/s
put_lights() {
    local ids
    ids=$(req "$api/groups/$HUE_GROUP" | jq -r '.lights[]')
    for id in $ids; do
        req -X PUT -d "$1" "$api/lights/$id/state" >/dev/null &
    done
    wait
}

case "${1:-get}" in
get)
    group=$(req "$api/groups/$HUE_GROUP")
    lights=$(req "$api/lights")
    jq -cn --argjson g "$group" --argjson l "$lights" '
        [$g.lights[] | $l[.].state | select(.reachable)] as $r
        | {
            name: $g.name,
            reachable: ($r | length > 0),
            on: ($r | any(.on)),
            brightness: (if ($r | length) > 0 then ($r | map(.bri) | add / length / 254 * 100 | round) else 0 end)
        }'
    ;;
on) put_lights '{"on":true}' ;;
off) put_lights '{"on":false}' ;;
set)
    pct="${2:-}"
    [[ "$pct" =~ ^[0-9]+$ ]] && ((pct <= 100)) || { echo "Usage: hueLight.sh set <0-100>" >&2; exit 1; }
    if ((pct == 0)); then
        put_lights '{"on":false}'
    else
        bri=$(((pct * 254 + 50) / 100))
        ((bri < 1)) && bri=1
        put_lights "{\"on\":true,\"bri\":$bri}"
    fi
    ;;
*)
    echo "Usage: hueLight.sh get | on | off | set <0-100>" >&2
    exit 1
    ;;
esac
