#!/bin/bash
# Native (non-Docker) Conduit manager — same menu and options as conduit-manager-mac.sh
# Usage: ./scripts/conduit-manager-native.sh [--menu|--start|--stop|--logs|--dashboard|...]

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONDUIT_BIN="${PROJECT_ROOT}/dist/conduit"
CONDUIT_DATA="${HOME}/.conduit/data"
CONFIG_PATH="${PROJECT_ROOT}/psiphon_config.json"
SETTINGS_FILE="${HOME}/.conduit/settings.conf"
BACKUP_DIR="${HOME}/.conduit-mac/backups"
LOG_FILE="${CONDUIT_DATA}/conduit.log"
STATS_FILE="${CONDUIT_DATA}/stats.json"
SCRIPT_VERSION="1.0"

DEFAULT_MAX_CLIENTS="${CONDUIT_MAX_CLIENTS:-200}"
DEFAULT_BANDWIDTH="${CONDUIT_BANDWIDTH:-5}"

# Load saved settings
if [ -f "$SETTINGS_FILE" ]; then
    # shellcheck source=/dev/null
    source "$SETTINGS_FILE"
fi
MAX_CLIENTS="${MAX_CLIENTS:-$DEFAULT_MAX_CLIENTS}"
BANDWIDTH="${BANDWIDTH:-$DEFAULT_BANDWIDTH}"

# --- COLORS (match Docker manager) ---
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}$*${NC}"; }
log_err()  { echo -e "${RED}$*${NC}"; }

# --- HEADER (exact match to Docker manager) ---
print_header() {
    clear
    echo -e "${CYAN}"
    echo "  ██████╗ ██████╗ ███╗   ██╗██████╗ ██╗   ██╗██╗████████╗"
    echo " ██╔════╝██╔═══██╗████╗  ██║██╔══██╗██║   ██║██║╚══██╔══╝"
    echo " ██║     ██║   ██║██╔██╗ ██║██║  ██║██║   ██║██║   ██║   "
    echo " ██║     ██║   ██║██║╚██╗██║██║  ██║██║   ██║██║   ██║   "
    echo " ╚██████╗╚██████╔╝██║ ╚████║██████╔╝╚██████╔╝██║   ██║   "
    echo "  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝  ╚═════╝ ╚═╝   ╚═╝   "
    echo -e "              ${YELLOW}macOS Professional Edition${CYAN}                  "
    echo -e "${NC}"
}

require_conduit_binary() {
    if [ ! -f "$CONDUIT_BIN" ]; then
        log_err "Conduit binary not found: $CONDUIT_BIN"
        log_err "Run 'make build' or use Docker: ./scripts/conduit-manager-mac.sh"
        exit 1
    fi
}

find_pid() { pgrep -f "conduit start" 2>/dev/null | head -1; }

save_settings() {
    mkdir -p "$(dirname "$SETTINGS_FILE")"
    echo "MAX_CLIENTS=$MAX_CLIENTS" > "$SETTINGS_FILE"
    echo "BANDWIDTH=$BANDWIDTH" >> "$SETTINGS_FILE"
}

# --- START / STOP / RESTART ---
start_conduit_process() {
    mkdir -p "$CONDUIT_DATA"
    local mc="${1:-$MAX_CLIENTS}"
    local bw="${2:-$BANDWIDTH}"
    local config_arg=""
    [ -f "$CONFIG_PATH" ] && config_arg="--psiphon-config $CONFIG_PATH"
    # shellcheck disable=SC2086
    "$CONDUIT_BIN" start $config_arg -v --stats-file -d "$CONDUIT_DATA" --max-clients "$mc" --bandwidth "$bw" >> "$LOG_FILE" 2>&1 &
}

start_noninteractive() {
    local pid
    pid=$(find_pid)
    if [ -n "$pid" ]; then
        log_info "Conduit is running; restarting..."
        kill "$pid" 2>/dev/null || true
        sleep 2
    else
        log_info "Conduit is not running; starting..."
    fi
    start_conduit_process
    sleep 2
    pid=$(find_pid)
    if [ -n "$pid" ]; then
        log_info "Restarted."
    else
        log_info "Started."
    fi
}

smart_start() {
    print_header
    local pid
    pid=$(find_pid)
    if [ -z "$pid" ]; then
        echo -e "${BLUE}▶ FIRST TIME SETUP${NC}"
        echo "-----------------------------------"
        install_new
        return
    fi
    echo -e "${YELLOW}Status: Running${NC}"
    echo -e "${BLUE}Action: Restarting Service...${NC}"
    kill "$pid" 2>/dev/null || true
    sleep 2
    start_conduit_process
    sleep 2
    echo -e "${GREEN}✔ Service Restarted Successfully.${NC}"
    sleep 2
}

install_new() {
    local mc="${MAX_CLIENTS:-$DEFAULT_MAX_CLIENTS}"
    local bw="${BANDWIDTH:-$DEFAULT_BANDWIDTH}"
    if [ "${AUTO_YES:-0}" != "1" ] && [ -t 0 ]; then
        echo ""
        read -p "Maximum Clients [Default: ${mc}]: " _mc || true
        mc="${_mc:-$mc}"
        read -p "Bandwidth Limit (Mbps) [Default: ${bw}, Enter -1 for Unlimited]: " _bw || true
        bw="${_bw:-$bw}"
    fi
    MAX_CLIENTS=$mc
    BANDWIDTH=$bw
    save_settings
    echo ""
    echo -e "${YELLOW}Starting Conduit...${NC}"
    find_pid | xargs kill 2>/dev/null || true
    sleep 2
    start_conduit_process "$mc" "$bw"
    sleep 2
    if find_pid >/dev/null; then
        echo -e "${GREEN}✔ Installation Complete & Started!${NC}"
        echo ""
        [ "${AUTO_YES:-0}" = "1" ] || { read -n 1 -s -r -p "Press any key to return..." || true; }
        return 0
    else
        log_err "Failed to start. Check: $LOG_FILE"
        [ "${AUTO_YES:-0}" = "1" ] || { read -n 1 -s -r -p "Press any key to continue..." || true; }
        return 1
    fi
}

stop_service() {
    echo -e "${YELLOW}Stopping Conduit...${NC}"
    find_pid | xargs kill 2>/dev/null || true
    sleep 1
    echo -e "${GREEN}✔ Service stopped.${NC}"
    sleep 1
}

# --- DASHBOARD (match Docker manager layout: 10s refresh, same labels) ---
view_dashboard() {
    trap "break" SIGINT
    while true; do
        print_header
        echo -e "${BOLD}LIVE DASHBOARD${NC} (Press ${YELLOW}Ctrl+C${NC} to Exit)"
        echo "══════════════════════════════════════════════════════"
        local pid
        pid=$(find_pid)
        if [ -n "$pid" ]; then
            local cpu_ram
            cpu_ram=$(ps -p "$pid" -o %cpu,rss 2>/dev/null | tail -1 | awk '{printf "%.1f%%|%.1fM", $1, $2/1024}' || echo "0%|0B")
            local CPU RAM CONN UP DOWN UPTIME
            CPU=$(echo "$cpu_ram" | cut -d'|' -f1)
            RAM=$(echo "$cpu_ram" | cut -d'|' -f2)
            if [ -f "$STATS_FILE" ] && command -v python3 &>/dev/null; then
                local tr
                tr=$(python3 -c "
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
" 2>/dev/null || echo "0|0B|0B")
                CONN=$(echo "$tr" | cut -d'|' -f1)
                UP=$(echo "$tr" | cut -d'|' -f2)
                DOWN=$(echo "$tr" | cut -d'|' -f3)
            else
                local line
                line=$(grep "\[STATS\]" "$LOG_FILE" 2>/dev/null | tail -1)
                CONN=$(echo "$line" | sed -n 's/.*Connected:[[:space:]]*\([0-9]*\).*/\1/p')
                UP=$(echo "$line" | sed -n 's/.*Up:[[:space:]]*\([^|]*\).*/\1/p' | tr -d ' ')
                DOWN=$(echo "$line" | sed -n 's/.*Down:[[:space:]]*\([^|]*\).*/\1/p' | tr -d ' ')
                CONN=${CONN:-0}
                UP=${UP:-0B}
                DOWN=${DOWN:-0B}
            fi
            UPTIME=$(ps -p "$pid" -o etime= 2>/dev/null | tr -d ' ')
            echo -e " STATUS:      ${GREEN}● ONLINE${NC}"
            echo -e " UPTIME:      ${UPTIME:-—}"
            echo "──────────────────────────────────────────────────────"
            printf " %-15s | %-15s \n" "RESOURCES" "TRAFFIC"
            echo "──────────────────────────────────────────────────────"
            printf " CPU: ${YELLOW}%-9s${NC} | Users: ${GREEN}%-9s${NC} \n" "$CPU" "$CONN"
            printf " RAM: ${YELLOW}%-9s${NC} | Up:    ${CYAN}%-9s${NC} \n" "$RAM" "$UP"
            printf "              | Down:  ${CYAN}%-9s${NC} \n" "$DOWN"
            echo "══════════════════════════════════════════════════════"
            echo -e "${YELLOW}Refreshing every 10 seconds...${NC}"
        else
            echo -e " STATUS:      ${RED}● OFFLINE${NC}"
            echo "──────────────────────────────────────────────────────"
            echo -e " Service is not running."
            echo " Press 1 to Start."
            echo "══════════════════════════════════════════════════════"
        fi
        sleep 10
    done
    trap - SIGINT
}

view_logs() {
    clear
    echo -e "${CYAN}Streaming Logs (Press Ctrl+C to Exit)...${NC}"
    echo "------------------------------------------------"
    if [ -f "$LOG_FILE" ]; then
        tail -f "$LOG_FILE"
    else
        echo "No log file yet. Start Conduit first."
        [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
    fi
}

view_live_stats() {
    if ! find_pid >/dev/null; then
        print_header
        log_err "Conduit is not running. Start it first (option 1 or 6)."
        [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
        return 1
    fi
    echo -e "${CYAN}Streaming [STATS] lines... Press Ctrl+C to return${NC}"
    echo -e "${YELLOW}(filtered for statistics only)${NC}"
    echo ""
    trap 'echo -e "\n${CYAN}Returning to menu...${NC}"; return' SIGINT
    if [ -f "$LOG_FILE" ]; then
        tail -f "$LOG_FILE" 2>/dev/null | grep "\[STATS\]"
    else
        echo "No log file."
    fi
    trap - SIGINT
}

show_version() {
    echo -e "${CYAN}Conduit Manager (macOS Native) v${SCRIPT_VERSION}${NC}"
    echo "Binary: $CONDUIT_BIN"
    if find_pid >/dev/null; then
        echo "Status: Running"
    fi
}

health_check() {
    echo -e "${CYAN}═══ CONDUIT HEALTH CHECK ═══${NC}"
    echo ""
    local all_ok=true
    echo -n "Conduit binary: "
    if [ -f "$CONDUIT_BIN" ]; then echo -e "${GREEN}OK${NC}"; else echo -e "${RED}FAILED${NC}"; all_ok=false; fi
    echo -n "Process running: "
    if find_pid >/dev/null; then echo -e "${GREEN}OK${NC}"; else echo -e "${YELLOW}Stopped${NC}"; fi
    echo -n "Data directory: "
    if [ -d "$CONDUIT_DATA" ]; then echo -e "${GREEN}OK${NC}"; else echo -e "${RED}FAILED${NC}"; all_ok=false; fi
    echo -n "Node key: "
    if [ -f "${CONDUIT_DATA}/conduit_key.json" ]; then echo -e "${GREEN}OK${NC}"; else echo -e "${YELLOW}PENDING (created on first run)${NC}"; fi
    echo ""
    if [ "$all_ok" = true ]; then echo -e "${GREEN}✓ Health check OK${NC}"; else echo -e "${YELLOW}Some checks failed or pending.${NC}"; fi
}

backup_key() {
    echo -e "${CYAN}═══ BACKUP NODE KEY ═══${NC}"
    echo ""
    mkdir -p "$BACKUP_DIR"
    if [ ! -f "${CONDUIT_DATA}/conduit_key.json" ]; then
        log_err "No node key found. Start Conduit at least once first."
        [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
        return 1
    fi
    local ts dest
    ts=$(date '+%Y%m%d_%H%M%S')
    dest="$BACKUP_DIR/conduit_key_${ts}.json"
    cp "${CONDUIT_DATA}/conduit_key.json" "$dest"
    echo -e "${GREEN}✓ Backup saved${NC}"
    echo "  $dest"
    [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
}

restore_key() {
    echo -e "${CYAN}═══ RESTORE NODE KEY ═══${NC}"
    echo ""
    mkdir -p "$BACKUP_DIR"
    local backups=()
    while IFS= read -r f; do [ -n "$f" ] && backups+=("$f"); done < <(ls -t "$BACKUP_DIR"/conduit_key_*.json 2>/dev/null || true)
    if [ ${#backups[@]} -eq 0 ]; then
        echo -e "${YELLOW}No backups in $BACKUP_DIR${NC}"
        [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
        return 0
    fi
    echo "Available backups:"
    local i=1
    for f in "${backups[@]}"; do
        echo "  $i. $(basename "$f")"
        i=$((i + 1))
    done
    echo "  0. Cancel"
    echo ""
    read -p " Restore number [0]: " sel || true
    sel=${sel:-0}
    if [ "$sel" = "0" ] || ! [[ "${sel:-}" =~ ^[0-9]+$ ]] || [ "$sel" -lt 1 ] || [ "$sel" -gt ${#backups[@]} ]; then
        echo "Cancelled."
        return 0
    fi
    local src="${backups[$((sel - 1))]}"
    echo ""
    echo "Restoring $(basename "$src")..."
    find_pid | xargs kill 2>/dev/null || true
    sleep 2
    mkdir -p "$CONDUIT_DATA"
    cp "$src" "${CONDUIT_DATA}/conduit_key.json"
    start_conduit_process
    sleep 2
    echo -e "${GREEN}✓ Restored.${NC}"
    [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
}

update_conduit() {
    echo -e "${CYAN}═══ UPDATE CONDUIT ═══${NC}"
    echo ""
    echo "Restarting with current binary..."
    find_pid | xargs kill 2>/dev/null || true
    sleep 2
    start_conduit_process
    sleep 2
    if find_pid >/dev/null; then
        echo -e "${GREEN}✓ Restarted.${NC}"
    else
        log_err "Failed to start."
        return 1
    fi
    [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
}

uninstall_native() {
    echo ""
    echo -e "${RED}═══ UNINSTALL CONDUIT (Native) ═══${NC}"
    echo ""
    echo "This will stop Conduit and remove data in $CONDUIT_DATA."
    echo -e "${RED}This cannot be undone.${NC}"
    echo ""
    read -p "Type 'yes' to confirm: " confirm || true
    if [ "$confirm" != "yes" ]; then
        echo "Cancelled."
        return 0
    fi
    find_pid | xargs kill 2>/dev/null || true
    rm -rf "$CONDUIT_DATA"
    echo -e "${GREEN}✓ Uninstall complete.${NC}"
    echo "Backups (if any) kept in: $BACKUP_DIR"
    echo ""
}

start_only() {
    if find_pid >/dev/null; then
        echo -e "${GREEN}✓ Conduit is already running.${NC}"
    else
        start_conduit_process
        sleep 2
        if find_pid >/dev/null; then
            echo -e "${GREEN}✓ Conduit started.${NC}"
        else
            log_err "Failed to start. Check: $LOG_FILE"
            return 1
        fi
    fi
    [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
}

restart_only() {
    if ! find_pid >/dev/null; then
        log_err "Conduit is not running. Use option 1 or 6 to start."
        [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
        return 1
    fi
    find_pid | xargs kill 2>/dev/null || true
    sleep 2
    start_conduit_process
    sleep 2
    echo -e "${GREEN}✓ Conduit restarted.${NC}"
    [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
}

peer_info_stub() {
    show_live_peers_native
}

# GeoIP database paths (common locations)
GEOIP_DB_DIR="${HOME}/.conduit-mac/geoip"
GEOIP_DB_PATH="${GEOIP_DB_DIR}/dbip-country-lite.mmdb"

ensure_geoip_db_native() {
    if [ -f "$GEOIP_DB_PATH" ]; then
        return 0
    fi
    
    mkdir -p "$GEOIP_DB_DIR"
    local ym
    ym="$(date +%Y-%m)"
    local url="https://download.db-ip.com/free/dbip-country-lite-${ym}.mmdb.gz"
    local gz="${GEOIP_DB_PATH}.gz"
    
    log_info "Downloading GeoIP database..."
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$gz" 2>/dev/null || return 1
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$gz" "$url" 2>/dev/null || return 1
    else
        log_err "curl or wget required for GeoIP download"
        return 1
    fi
    
    gunzip -f "$gz" 2>/dev/null || return 1
    log_info "GeoIP database ready (DB-IP.com CC BY 4.0)"
    return 0
}

get_native_peer_ips() {
    local pid
    pid=$(find_pid)
    [ -z "$pid" ] && return 1
    
    # Use lsof to find established TCP connections for the Conduit process
    lsof -nP -iTCP -sTCP:ESTABLISHED -a -p "$pid" 2>/dev/null | \
        awk 'NR>1 && $9 ~ /->/ {
            split($9, a, "->")
            split(a[2], b, ":")
            print b[1]
        }' | grep -v "^127\." | grep -v "^::1" | sort -u
}

show_live_peers_native() {
    local pid
    pid=$(find_pid)
    if [ -z "$pid" ]; then
        print_header
        log_err "Conduit is not running. Start it first."
        [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
        return 1
    fi
    
    # Check if Python3 and geoip2 are available
    if ! command -v python3 &>/dev/null; then
        print_header
        log_err "Python3 is required for GeoIP lookups."
        echo ""
        echo "Install with: brew install python3"
        echo "Then install geoip2: pip3 install geoip2"
        [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
        return 1
    fi
    
    if ! python3 -c "import geoip2.database" 2>/dev/null; then
        print_header
        log_err "Python geoip2 library is required."
        echo ""
        echo "Install with: pip3 install geoip2"
        [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
        return 1
    fi
    
    ensure_geoip_db_native || {
        log_err "Failed to download GeoIP database."
        [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
        return 1
    fi
    
    trap "echo ''; return 0" SIGINT
    
    while true; do
        print_header
        echo -e "${BOLD}LIVE PEER TRAFFIC BY COUNTRY${NC} (Press ${YELLOW}Ctrl+C${NC} to Exit)"
        echo "══════════════════════════════════════════════════════════════════════"
        echo ""
        
        local peer_data
        peer_data=$(get_native_peer_ips | python3 -c "
import sys
from collections import Counter
import geoip2.database
import geoip2.errors

ips = [line.strip() for line in sys.stdin if line.strip()]
counts = Counter()
ip_counts = {}

try:
    with geoip2.database.Reader('$GEOIP_DB_PATH') as reader:
        for ip in ips:
            try:
                resp = reader.country(ip)
                country = resp.country.name or resp.country.iso_code or 'Unknown'
                counts[country] += 1
                if country not in ip_counts:
                    ip_counts[country] = 1
                else:
                    ip_counts[country] += 1
            except Exception:
                counts['Unknown'] += 1

    # Sort by connection count (descending)
    sorted_countries = sorted(counts.items(), key=lambda x: x[1], reverse=True)

    # Print header
    print(f\"{'Country':<30} {'Connections':>12} {'IPs':>8}\")
    print('-' * 52)

    # Print data
    for country, count in sorted_countries[:20]:  # Top 20
        ip_count = ip_counts.get(country, 0)
        print(f\"{country:<30} {count:>12} {ip_count:>8}\")

    total = sum(counts.values())
    total_countries = len(counts)
    if total > 0:
        print('-' * 52)
        print(f\"{'TOTAL':<30} {total:>12} {len(set(ips)):>8}\")
        print(f\"\nConnections from {total_countries} countries\")
except Exception as e:
    print(f\"Error: {e}\")
" 2>/dev/null || echo "No data available")
        
        if [ -n "$peer_data" ] && [ "$peer_data" != "No data available" ]; then
            echo "$peer_data"
        else
            echo "No active connections detected."
            echo ""
            echo "NOTE: This shows TCP connections established by the Conduit process."
            echo "      Connections may take a few minutes to appear after startup."
        fi
        
        echo ""
        echo "══════════════════════════════════════════════════════════════════════"
        echo -e "${YELLOW}Refreshing every 10 seconds...${NC}"
        sleep 10
    done
    
    trap - SIGINT
}

usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "  No arguments    Start or restart Conduit (non-interactive)."
    echo "  --menu          Show interactive menu."
    echo "  --start         Start/restart Conduit (same as no args)."
    echo "  --stop          Stop Conduit."
    echo "  --logs          Stream logs."
    echo "  --dashboard     Open live dashboard."
    echo "  --reconfigure   Apply new max-clients/bandwidth and restart."
    echo "  --yes, -y       Non-interactive (no prompts)."
    echo "  --max-clients N Set max clients (default: ${DEFAULT_MAX_CLIENTS})."
    echo "  --bandwidth N   Set bandwidth Mbps, -1=unlimited (default: ${DEFAULT_BANDWIDTH})."
    echo "  --help, -h      Show this help."
}

# --- MENU (exact same options and labels as Docker manager) ---
menu_loop() {
    while true; do
        print_header
        echo -e "${BOLD}MAIN MENU${NC}"
        echo -e "${CYAN}─────────────────────────────────────────────────────────────────${NC}"
        echo "  1. ▶ Start / Restart (Smart)"
        echo "  2. 📊 Live stats (stream [STATS])"
        echo "  3. 📋 View logs"
        echo "  4. ⚙ Reconfigure (max-clients, bandwidth)"
        echo "  5. 🔄 Update Conduit (pull latest image)"
        echo "  6. ▶ Start Conduit"
        echo "  7. ⏹ Stop Conduit"
        echo "  8. 🔁 Restart Conduit"
        echo "  9. 🌍 Live peers by country (GeoIP)"
        echo ""
        echo "  h. 🩺 Health check    b. 💾 Backup node key    r. 📥 Restore node key"
        echo "  u. 🗑 Uninstall        v. ℹ Version"
        echo "  0. 🚪 Exit"
        echo -e "${CYAN}─────────────────────────────────────────────────────────────────${NC}"
        echo ""
        read -p " Select option: " option || true

        case "${option:-}" in
            1) smart_start ;;
            2) view_live_stats; [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; } ;;
            3) view_logs ;;
            4) print_header; echo -e "${BLUE}▶ RECONFIGURATION${NC}"; install_new ;;
            5) update_conduit ;;
            6) start_only ;;
            7) stop_service; [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; } ;;
            8) restart_only ;;
            9) peer_info_stub ;;
            h|H) health_check; [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; } ;;
            b|B) backup_key ;;
            r|R) restore_key ;;
            u|U) uninstall_native; [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; } ;;
            v|V) show_version; [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; } ;;
            0) echo -e "${CYAN}Goodbye!${NC}"; exit 0 ;;
            "") ;;
            *) echo -e "${RED}Invalid option.${NC} Use 0-9, h, b, r, u, or v."; sleep 1 ;;
        esac
    done
}

# --- ARG PARSING (same as Docker manager) ---
MODE="start"
AUTO_YES="${AUTO_YES:-0}"

while [ $# -gt 0 ]; do
    case "$1" in
        --help|-h) usage; exit 0 ;;
        --menu)    MODE="menu"; shift ;;
        --start)   MODE="start"; shift ;;
        --stop)    MODE="stop"; shift ;;
        --logs)    MODE="logs"; shift ;;
        --dashboard)   MODE="dashboard"; shift ;;
        --reconfigure) MODE="reconfigure"; shift ;;
        --yes|-y)  AUTO_YES=1; shift ;;
        --max-clients) shift; MAX_CLIENTS="${1:-$DEFAULT_MAX_CLIENTS}"; shift || true ;;
        --bandwidth)   shift; BANDWIDTH="${1:-$DEFAULT_BANDWIDTH}"; shift || true ;;
        *) log_err "Unknown argument: $1"; usage; exit 2 ;;
    esac
done

require_conduit_binary

case "$MODE" in
    menu)        menu_loop ;;
    stop)        stop_service ;;
    logs)        view_logs ;;
    dashboard)   view_dashboard ;;
    reconfigure) AUTO_YES=1; install_new ;;
    start|*)     AUTO_YES=1; start_noninteractive ;;
esac
