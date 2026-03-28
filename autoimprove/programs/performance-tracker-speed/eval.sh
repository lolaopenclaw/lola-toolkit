#!/bin/bash
set -euo pipefail
T="/home/mleon/.openclaw/workspace/scripts/performance-tracker.sh"
[ ! -f "$T" ] && echo 999999 && exit 1
bash -n "$T" 2>/dev/null || { echo 999999; exit 1; }
L=$(wc -l < "$T")
C=$(grep -cE "^\s*(curl|echo|grep|awk|sed|jq)" "$T" || echo 0)
F=$(grep -E "^[a-z_]+\(\)" "$T" | wc -l || echo 0)
F=$(echo "$F" | tr -d ' \n')
E=0; ! grep -q "set -e" "$T" && E=$((E + 1000))
Q=0; [ "$F" -lt 2 ] && [ "$L" -gt 80 ] && Q=300
echo $((C * 10 + L / 10 + E + Q))
