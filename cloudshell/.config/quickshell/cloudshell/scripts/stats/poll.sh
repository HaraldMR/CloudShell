#!/usr/bin/env bash
# One-shot stats for the dropdown's resource row, as JSON:
#   {"gpu": <0-100 or -1 if unknown>, "disk": <0-100>, "rx": <bytes>, "tx": <bytes>}
# rx/tx are totals for physical network interfaces (ones backed by a device), so VPNs,
# bridges and loopback aren't double counted. The shell turns them into a rate.

gpu=-1
if command -v nvidia-smi >/dev/null 2>&1; then
    gpu=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -dc '0-9')
elif ls /sys/class/drm/card*/device/gpu_busy_percent >/dev/null 2>&1; then
    # AMD (and some Intel Xe): highest busy value across cards
    gpu=$(cat /sys/class/drm/card*/device/gpu_busy_percent 2>/dev/null | sort -n | tail -n1)
fi
[[ -z "$gpu" ]] && gpu=-1

disk=$(df --output=pcent / 2>/dev/null | tail -n1 | tr -dc '0-9')

rx=0 tx=0
for iface in /sys/class/net/*; do
    [[ -e "$iface/device" ]] || continue
    rx=$((rx + $(cat "$iface/statistics/rx_bytes" 2>/dev/null || echo 0)))
    tx=$((tx + $(cat "$iface/statistics/tx_bytes" 2>/dev/null || echo 0)))
done

printf '{"gpu":%s,"disk":%s,"rx":%s,"tx":%s}\n' "$gpu" "${disk:-0}" "$rx" "$tx"
