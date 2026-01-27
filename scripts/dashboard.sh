#!/bin/bash
# Live Dashboard for Conduit — native binary or Docker (Option 2 / Docker manager style)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONTAINER_NAME="conduit-mac"
CONDUIT_DATA="${HOME}/.conduit/data"
STATS_FILE_NATIVE="$PROJECT_ROOT/data/stats.json"

# Colors
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Detect: Docker container or native process
is_docker_running() {
    docker ps 2>/dev/null | grep -q "$CONTAINER_NAME"
}

find_conduit_pid() {
    pgrep -f "conduit start" 2>/dev/null | head -1
}

find_stats_file() {
    if [ -f "$CONDUIT_DATA/stats.json" ]; then
        echo "$CONDUIT_DATA/stats.json"
    elif [ -f "$PROJECT_ROOT/data/stats.json" ]; then
        echo "$PROJECT_ROOT/data/stats.json"
    elif [ -f "$PROJECT_ROOT/stats.json" ]; then
        echo "$PROJECT_ROOT/stats.json"
    else
        echo ""
    fi
}

get_process_stats() {
    local pid=$1
    if [ -z "$pid" ] || ! ps -p "$pid" >/dev/null 2>&1; then
        echo "0%|0B"
        return
    fi
    ps -p "$pid" -o %cpu,rss 2>/dev/null | tail -1 | awk '{printf "%.1f%%|%.1fM", $1, $2/1024}' || echo "0%|0B"
}

format_bytes() {
    local bytes=$1
    if [ -z "$bytes" ] || [ "$bytes" = "0" ]; then
        echo "0B"
        return
    fi
    if command -v python3 &>/dev/null; then
        python3 -c "
b=$bytes
for u in ['B','KB','MB','GB','TB']:
    if b<1024: print(f'{b:.1f}{u}'); break
    b/=1024
" 2>/dev/null || echo "0B"
    else
        if [ "$bytes" -lt 1024 ]; then echo "${bytes}B"
        elif [ "$bytes" -lt 1048576 ]; then echo "$(awk "BEGIN{printf \"%.1f\", $bytes/1024}")KB"
        elif [ "$bytes" -lt 1073741824 ]; then echo "$(awk "BEGIN{printf \"%.1f\", $bytes/1048576}")MB"
        else echo "$(awk "BEGIN{printf \"%.1f\", $bytes/1073741824}")GB"; fi
    fi
}

get_native_stats() {
    local stats_file
    stats_file=$(find_stats_file)
    if [ -n "$stats_file" ] && [ -f "$stats_file" ] && command -v python3 &>/dev/null; then
        python3 -c "
import json
d=json.load(open('$stats_file'))
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
        for log_file in "/tmp/conduit.log" "/tmp/conduit_dash.log" "$PROJECT_ROOT/data/conduit.log" "$CONDUIT_DATA/conduit.log"; do
            [ -f "$log_file" ] || continue
            line=$(grep "\[STATS\]" "$log_file" 2>/dev/null | tail -1)
            if [ -n "$line" ]; then
                local c up down
                c=$(echo "$line" | sed -n 's/.*Connected:[[:space:]]*\([0-9]*\).*/\1/p')
                up=$(echo "$line" | sed -n 's/.*Up:[[:space:]]*\([^|]*\).*/\1/p' | tr -d ' ')
                down=$(echo "$line" | sed -n 's/.*Down:[[:space:]]*\([^|]*\).*/\1/p' | tr -d ' ')
                echo "${c:-0}|${up:-0B}|${down:-0B}"
                return
            fi
        done
        echo "0|0B|0B"
    fi
}

print_header() {
    clear
    echo -e "${CYAN}"
    echo "  ██████╗ ██████╗ ███╗   ██╗██████╗ ██╗   ██╗██╗████████╗"
    echo " ██╔════╝██╔═══██╗████╗  ██║██╔══██╗██║   ██║██║╚══██╔══╝"
    echo " ██║     ██║   ██║██╔██╗ ██║██║  ██║██║   ██║██║   ██║   "
    echo " ██║     ██║   ██║██║╚██╗██║██║  ██║██║   ██║██║   ██║   "
    echo " ╚██████╗╚██████╔╝██║ ╚████║██████╔╝╚██████╔╝██║   ██║   "
    echo "  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝  ╚═════╝ ╚═╝   ╚═╝   "
    echo -e "              ${YELLOW}Live Dashboard${CYAN}                  "
    echo -e "${NC}"
}

view_dashboard() {
    trap "echo ''; echo -e '${CYAN}Dashboard closed.${NC}'; exit 0" SIGINT

    while true; do
        print_header
        echo -e "${BOLD}LIVE DASHBOARD${NC} (Press ${YELLOW}Ctrl+C${NC} to exit)"
        echo "══════════════════════════════════════════════════════"

        if is_docker_running; then
            # Docker path (same as conduit-manager-mac)
            DOCKER_STATS=$(docker stats --no-stream --format "{{.CPUPerc}}|{{.MemUsage}}" "$CONTAINER_NAME" 2>/dev/null)
            CPU=$(echo "$DOCKER_STATS" | cut -d'|' -f1)
            RAM=$(echo "$DOCKER_STATS" | cut -d'|' -f2)
            LOG_LINE=$(docker logs --tail 50 "$CONTAINER_NAME" 2>&1 | grep "\[STATS\]" | tail -n 1)
            if [[ -n "${LOG_LINE:-}" ]]; then
                CONN=$(echo "$LOG_LINE" | sed -n 's/.*Connected:[[:space:]]*\([0-9]*\).*/\1/p')
                UP=$(echo "$LOG_LINE" | sed -n 's/.*Up:[[:space:]]*\([^|]*\).*/\1/p' | tr -d ' ')
                DOWN=$(echo "$LOG_LINE" | sed -n 's/.*Down:[[:space:]]*\([^|]*\).*/\1/p' | tr -d ' ')
            else
                CONN="0"
                UP="0B"
                DOWN="0B"
            fi
            UPTIME=$(docker ps -f name="$CONTAINER_NAME" --format '{{.Status}}' 2>/dev/null)
            echo -e " STATUS:      ${GREEN}● ONLINE${NC} (Docker)"
            echo -e " UPTIME:      ${UPTIME:-—}"
            echo "──────────────────────────────────────────────────────"
            printf " %-15s | %-15s \n" "RESOURCES" "TRAFFIC"
            echo "──────────────────────────────────────────────────────"
            printf " CPU: ${YELLOW}%-9s${NC} | Users: ${GREEN}%-9s${NC} \n" "${CPU:-0%}" "${CONN:-0}"
            printf " RAM: ${YELLOW}%-9s${NC} | Up:    ${CYAN}%-9s${NC} \n" "${RAM:-0B}" "${UP:-0B}"
            printf "              | Down:  ${CYAN}%-9s${NC} \n" "${DOWN:-0B}"
        else
            # Native binary path
            CONDUIT_PID=$(find_conduit_pid)
            if [ -n "$CONDUIT_PID" ]; then
                PROCESS_STATS=$(get_process_stats "$CONDUIT_PID")
                CPU=$(echo "$PROCESS_STATS" | cut -d'|' -f1)
                RAM=$(echo "$PROCESS_STATS" | cut -d'|' -f2)
                CONDUIT_STATS=$(get_native_stats)
                CONN=$(echo "$CONDUIT_STATS" | cut -d'|' -f1)
                UP=$(echo "$CONDUIT_STATS" | cut -d'|' -f2)
                DOWN=$(echo "$CONDUIT_STATS" | cut -d'|' -f3)
                CONN=${CONN:-0}
                UP=${UP:-0B}
                DOWN=${DOWN:-0B}
                UPTIME=$(ps -p "$CONDUIT_PID" -o etime= 2>/dev/null | tr -d ' ')
                echo -e " STATUS:      ${GREEN}● ONLINE${NC}"
                echo -e " UPTIME:      ${UPTIME:-—}"
                echo "──────────────────────────────────────────────────────"
                printf " %-15s | %-15s \n" "RESOURCES" "TRAFFIC"
                echo "──────────────────────────────────────────────────────"
                printf " CPU: ${YELLOW}%-9s${NC} | Users: ${GREEN}%-9s${NC} \n" "$CPU" "$CONN"
                printf " RAM: ${YELLOW}%-9s${NC} | Up:    ${CYAN}%-9s${NC} \n" "$RAM" "$UP"
                printf "              | Down:  ${CYAN}%-9s${NC} \n" "$DOWN"
            else
                echo -e " STATUS:      ${RED}● OFFLINE${NC}"
                echo "──────────────────────────────────────────────────────"
                echo " Conduit is not running."
                echo ""
                echo " Start with dashboard:  ./scripts/test-option2-dashboard.sh"
                echo " Or Docker menu:        ./scripts/conduit-manager-mac.sh --menu"
                echo " Or native:             ./dist/conduit start -v --stats-file -d $CONDUIT_DATA"
            fi
        fi

        echo "══════════════════════════════════════════════════════"
        echo -e "${YELLOW}Refreshing every 5 seconds...${NC}"
        sleep 5
    done
}

view_dashboard
