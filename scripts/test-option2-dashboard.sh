#!/bin/bash
# Test Option 2 (DMG-style) flow: start Conduit + live dashboard using project binary.
# Run from repo: ./scripts/test-option2-dashboard.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONDUIT="${PROJECT_ROOT}/dist/conduit"
CONDUIT_DATA="${HOME}/.conduit/data"
LOG_FILE="${CONDUIT_DATA}/conduit.log"
STATS_FILE="${CONDUIT_DATA}/stats.json"

if [ ! -f "$CONDUIT" ]; then
    echo "Error: Conduit binary not found at $CONDUIT"
    echo "Run: make build"
    exit 1
fi

mkdir -p "$CONDUIT_DATA"

BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Match "conduit start" (from-source binary) or "Conduit start" (DMG binary)
find_pid() { pgrep -f "conduit start" 2>/dev/null | head -1; }
fmt_bytes() {
    local b=$1
    [ -z "$b" ] || [ "$b" = "0" ] && echo "0B" && return
    if [ "$b" -lt 1024 ]; then echo "${b}B"
    elif [ "$b" -lt 1048576 ]; then echo "$(awk "BEGIN{printf \"%.1f\", $b/1024}")KB"
    elif [ "$b" -lt 1073741824 ]; then echo "$(awk "BEGIN{printf \"%.1f\", $b/1048576}")MB"
    else echo "$(awk "BEGIN{printf \"%.1f\", $b/1073741824}")GB"; fi
}
cpu_ram() {
    local pid=$1
    [ -z "$pid" ] && echo "0%|0B" && return
    ps -p "$pid" -o %cpu,rss 2>/dev/null | tail -1 | awk '{printf "%.1f%%|%.1fM", $1, $2/1024}' || echo "0%|0B"
}
traffic_stats() {
    if [ -f "$STATS_FILE" ] && command -v python3 &>/dev/null; then
        python3 -c "
import json
d=json.load(open('$STATS_FILE'))
c=d.get('connectedClients',0)
u=d.get('totalBytesUp',0)
dwn=d.get('totalBytesDown',0)
def f(b):
    if b<1024: return str(b)+'B'
    if b<1048576: return '%.1fKB'%(b/1024)
    if b<1073741824: return '%.1fMB'%(b/1048576)
    return '%.1fGB'%(b/1073741824)
print(c,'|',f(u),'|',f(dwn))
" 2>/dev/null || echo "0|0B|0B"
    else
        local line
        line=$(grep "\[STATS\]" "$LOG_FILE" 2>/dev/null | tail -1)
        if [ -n "$line" ]; then
            local c up down
            c=$(echo "$line" | sed -n 's/.*Connected:[[:space:]]*\([0-9]*\).*/\1/p')
            up=$(echo "$line" | sed -n 's/.*Up:[[:space:]]*\([^|]*\).*/\1/p' | tr -d ' ')
            down=$(echo "$line" | sed -n 's/.*Down:[[:space:]]*\([^|]*\).*/\1/p' | tr -d ' ')
            echo "${c:-0}|${up:-0B}|${down:-0B}"
        else
            echo "0|0B|0B"
        fi
    fi
}

CONFIG_ARG=""
[ -f "$PROJECT_ROOT/psiphon_config.json" ] && CONFIG_ARG="--psiphon-config $PROJECT_ROOT/psiphon_config.json"

echo "Option 2 test: starting Conduit with live dashboard..."
echo "  Binary: $CONDUIT"
echo "  Data:   $CONDUIT_DATA"
echo ""

# Start Conduit in background (use project config if no embedded config)
"$CONDUIT" start $CONFIG_ARG -v --stats-file -d "$CONDUIT_DATA" >> "$LOG_FILE" 2>&1 &
BPID=$!
sleep 2
if ! kill -0 "$BPID" 2>/dev/null; then
    echo "Conduit failed to start. Check: $LOG_FILE"
    exit 1
fi
echo -e "${GREEN}Conduit started.${NC} Opening dashboard (Ctrl+C to stop)..."
sleep 1

cleanup() { kill "$BPID" 2>/dev/null; echo -e "\n${CYAN}Dashboard closed. Conduit stopped.${NC}"; exit 0; }
trap cleanup SIGINT SIGTERM

while true; do
    clear
    echo -e "${CYAN}"
    echo "  ██████╗ ██████╗ ███╗   ██╗██████╗ ██╗   ██╗██╗████████╗"
    echo " ██╔════╝██╔═══██╗████╗  ██║██╔══██╗██║   ██║██║╚══██╔══╝"
    echo " ██║     ██║   ██║██╔██╗ ██║██║  ██║██║   ██║██║   ██║   "
    echo " ██║     ██║   ██║██║╚██╗██║██║  ██║██║   ██║██║   ██║   "
    echo " ╚██████╗╚██████╔╝██║ ╚████║██████╔╝╚██████╔╝██║   ██║   "
    echo "  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝  ╚═════╝ ╚═╝   ╚═╝   "
    echo -e "              ${YELLOW}Live Dashboard (Option 2 test)${CYAN}                  "
    echo -e "${NC}"
    echo -e "${BOLD}LIVE DASHBOARD${NC} (Press ${YELLOW}Ctrl+C${NC} to exit)"
    echo "══════════════════════════════════════════════════════"

    PID=$(find_pid)
    if [ -n "$PID" ]; then
        CR=$(cpu_ram "$PID"); CPU=$(echo "$CR"|cut -d'|' -f1); RAM=$(echo "$CR"|cut -d'|' -f2)
        TR=$(traffic_stats "$PID"); CONN=$(echo "$TR"|cut -d'|' -f1); UP=$(echo "$TR"|cut -d'|' -f2); DOWN=$(echo "$TR"|cut -d'|' -f3)
        UPTIME=$(ps -p "$PID" -o etime= 2>/dev/null | tr -d ' ')
        echo -e " STATUS:      ${GREEN}● ONLINE${NC}"
        echo -e " UPTIME:      ${UPTIME:-—}"
        echo "──────────────────────────────────────────────────────"
        printf " %-15s | %-15s \n" "RESOURCES" "TRAFFIC"
        echo "──────────────────────────────────────────────────────"
        printf " CPU: ${YELLOW}%-9s${NC} | Iranians: ${GREEN}%-9s${NC} \n" "$CPU" "$CONN"
        printf " RAM: ${YELLOW}%-9s${NC} | Up:    ${CYAN}%-9s${NC} \n" "$RAM" "$UP"
        printf "              | Down:  ${CYAN}%-9s${NC} \n" "$DOWN"
    else
        echo -e " STATUS:      ${RED}● OFFLINE${NC}"
        echo "──────────────────────────────────────────────────────"
        echo " Conduit is not running."
    fi
    echo "══════════════════════════════════════════════════════"
    echo -e "${YELLOW}Refreshing every 5 seconds...${NC}"
    sleep 5
done
