#!/bin/bash
set -u
set -o pipefail
# ╔═══════════════════════════════════════════════════════════════╗
# ║             🚀 PSIPHON CONDUIT (macOS)                    ║
# ╚═══════════════════════════════════════════════════════════════╝
#
# Based on: https://github.com/polamgh/conduit-manager-mac
# Original Author: polamgh
# Integrated into conduit_emergency project with permission
#
# Direct Link (Run from GitHub):
# curl -sL https://raw.githubusercontent.com/farrox/conduit_emergency/main/scripts/conduit-manager-mac.sh | bash
#
# Or download and run:
# curl -sL https://raw.githubusercontent.com/farrox/conduit_emergency/main/scripts/conduit-manager-mac.sh -o conduit-manager-mac.sh
# chmod +x conduit-manager-mac.sh
# ./conduit-manager-mac.sh
#
# With no args: ensures Docker is running, then starts or restarts Conduit.
# Use --menu for the interactive menu.
#

# --- CONFIGURATION ---
CONTAINER_NAME="conduit-mac"
# Updated to release d8522a8 (Critical Update)
IMAGE="ghcr.io/ssmirr/conduit/conduit:d8522a8"
VOLUME_NAME="conduit-data"
SCRIPT_VERSION="1.0"
# Backup dir for node identity key (user-local, no root)
BACKUP_DIR="${HOME}/.conduit-mac/backups"

# State dir for optional tooling (GeoIP DB, caches, etc.)
STATE_DIR="${HOME}/.conduit-mac"

# Optional: Peer IP and GeoIP tooling (runs OUTSIDE the Conduit container)
INSPECTOR_IMAGE="${CONDUIT_INSPECTOR_IMAGE:-nicolaka/netshoot:latest}"
GEOIP_INSPECTOR_IMAGE="${CONDUIT_GEOIP_INSPECTOR_IMAGE:-conduit-geoip-inspector:latest}"
GEOIP_DB_DIR="${CONDUIT_GEOIP_DB_DIR:-${STATE_DIR}/geoip}"
GEOIP_DB_PATH="${CONDUIT_GEOIP_DB_PATH:-${GEOIP_DB_DIR}/dbip-country-lite.mmdb}"

# Defaults (override via flags or env)
DEFAULT_MAX_CLIENTS="${CONDUIT_MAX_CLIENTS:-200}"
DEFAULT_BANDWIDTH="${CONDUIT_BANDWIDTH:-5}"

# --- COLORS ---
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- LOG HELPERS ---
log_info() { echo -e "${BLUE}$*${NC}"; }
log_err()  { echo -e "${RED}$*${NC}"; }

ensure_container_running() {
  if ! docker ps 2>/dev/null | grep -q "$CONTAINER_NAME"; then
    log_err "Conduit is not running. Start it first."
    return 1
  fi
  return 0
}

ensure_inspector_image() {
  if ! docker image inspect "$INSPECTOR_IMAGE" >/dev/null 2>&1; then
    log_info "Pulling inspector image: $INSPECTOR_IMAGE"
    docker pull "$INSPECTOR_IMAGE" >/dev/null 2>&1 || true
  fi
}

ensure_geoip_inspector_image() {
  # Build once locally so we don't apk-add every run.
  if docker image inspect "$GEOIP_INSPECTOR_IMAGE" >/dev/null 2>&1; then
    return 0
  fi

  log_info "Building GeoIP inspector image: $GEOIP_INSPECTOR_IMAGE"
  docker build -t "$GEOIP_INSPECTOR_IMAGE" - >/dev/null <<'EOF'
FROM nicolaka/netshoot:latest
RUN apk add --no-cache python3 py3-geoip2 ca-certificates
WORKDIR /work
EOF
}

ensure_geoip_db() {
  mkdir -p "$GEOIP_DB_DIR"
  if [ -f "$GEOIP_DB_PATH" ]; then
    return 0
  fi

  local ym
  ym="$(date +%Y-%m)"

  local url="https://download.db-ip.com/free/dbip-country-lite-${ym}.mmdb.gz"
  local gz="${GEOIP_DB_PATH}.gz"

  log_info "Downloading offline GeoIP DB (DB-IP Country Lite): ${ym}"
  log_info "Source: ${url}"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$gz"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$gz" "$url"
  else
    log_err "Neither curl nor wget found; cannot download GeoIP DB."
    return 1
  fi

  gunzip -f "$gz"
  log_info "GeoIP DB ready at: $GEOIP_DB_PATH (Attribution: DB-IP.com CC BY 4.0)"
}

get_peer_ips() {
  ensure_container_running || return 1
  ensure_inspector_image

  docker run --rm --network "container:${CONTAINER_NAME}" "$INSPECTOR_IMAGE" sh -lc \
    "ss -Htan state established 2>/dev/null || netstat -tn 2>/dev/null || true" \
    | sed 's/\[//g; s/\]//g' \
    | awk '
      {
        peer=$NF
        if (peer ~ /:/) print peer
        else if ($5 ~ /:/) print $5
      }
    ' \
    | awk -F':' '{print $1}' \
    | grep -E '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' \
    | sort -u
}

show_connections() {
  ensure_container_running || return 1
  ensure_inspector_image

  cat <<'EOF'
NOTE:
  - This prints the IPs of *direct peers* connected to your node.
  - Depending on routing, these IPs may be relays/NATs, not end users.
EOF
  echo ""

  get_peer_ips | sort | uniq -c | sort -nr | head -50 || true
}

get_top_countries() {
  # Output: "<count>\t<country>"
  ensure_container_running || return 1
  ensure_geoip_inspector_image >/dev/null 2>&1 || return 1
  ensure_geoip_db >/dev/null 2>&1 || return 1

  # Single container execution: list connections + GeoIP mapping in one process.
  docker run --rm \
    --network "container:${CONTAINER_NAME}" \
    -v "${GEOIP_DB_PATH}:/db.mmdb:ro" \
    "$GEOIP_INSPECTOR_IMAGE" \
    python3 -c '
import re
import subprocess
from collections import Counter
import geoip2.database

def get_lines():
    try:
        out = subprocess.check_output(["ss","-Htan","state","established"], text=True, stderr=subprocess.DEVNULL)
        return out.splitlines()
    except Exception:
        try:
            out = subprocess.check_output(["netstat","-tn"], text=True, stderr=subprocess.DEVNULL)
            return out.splitlines()
        except Exception:
            return []

ip_re = re.compile(r"\b(?:\d{1,3}\.){3}\d{1,3}\b")
ips = set()
for line in get_lines():
    for ip in ip_re.findall(line):
        ips.add(ip)

if not ips:
    raise SystemExit(0)

counts = Counter()
with geoip2.database.Reader("/db.mmdb") as reader:
    for ip in ips:
        try:
            resp = reader.country(ip)
            name = resp.country.name or resp.country.iso_code or "Unknown"
            counts[name] += 1
        except Exception:
            counts["Unknown"] += 1

for name, c in counts.most_common(5):
    print(f"{c}\t{name}")
' 2>/dev/null || true
}

show_countries() {
  ensure_container_running || return 1
  ensure_geoip_inspector_image
  ensure_geoip_db

  cat <<'EOF'
NOTE:
  - Country mapping is OFFLINE using DB-IP Country Lite (MMDB).
  - This maps peer IPs (direct connections). These may be relays/NATs, not end users.
EOF
  echo ""

  # Reuse top-countries engine but show more (top 25)
  get_peer_ips \
    | docker run --rm -i -v "${GEOIP_DB_PATH}:/db.mmdb:ro" "$GEOIP_INSPECTOR_IMAGE" \
      python3 -c '
import sys
from collections import Counter
import geoip2.database
import geoip2.errors

ips = [line.strip() for line in sys.stdin if line.strip()]
counts = Counter()
unknown = 0
with geoip2.database.Reader("/db.mmdb") as reader:
    for ip in ips:
        try:
            resp = reader.country(ip)
            name = resp.country.name or resp.country.iso_code or "Unknown"
            counts[name] += 1
        except Exception:
            unknown += 1

for name, c in counts.most_common(25):
    print(f"{c:4d}  {name}")
if unknown:
    print(f"{unknown:4d}  Unknown")
' 2>/dev/null || true

  echo ""
  log_info "Attribution: DB-IP.com (CC BY 4.0)"
}

# --- DOCKER: REQUIRE CLI + AUTO-START DESKTOP ---
require_docker_cli() {
  if ! command -v docker >/dev/null 2>&1; then
    log_err "Docker CLI not found."
    log_err "Install Docker Desktop for macOS, then re-run."
    exit 1
  fi
}

ensure_docker_desktop_running() {
  require_docker_cli

  if docker info >/dev/null 2>&1; then
    return 0
  fi

  if [ -d "/Applications/Docker.app" ]; then
    log_info "Starting Docker Desktop..."
    open -a Docker >/dev/null 2>&1 || true
  else
    log_err "Docker Desktop not found at /Applications/Docker.app"
    log_err "Install & start Docker Desktop, then re-run."
    exit 1
  fi

  log_info "Waiting for Docker daemon..."
  for _i in $(seq 1 90); do
    if docker info >/dev/null 2>&1; then
      log_info "Docker is ready."
      return 0
    fi
    sleep 2
  done

  log_err "Timed out waiting for Docker to start."
  exit 1
}

# --- UTILS ---
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

print_header_noclear() {
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

# --- NON-INTERACTIVE START (default when running with no args) ---
start_noninteractive() {
  if ! docker ps -a 2>/dev/null | grep -q "$CONTAINER_NAME"; then
    log_info "First-time setup: installing Conduit container..."
    install_new
    return $?
  fi

  if docker ps 2>/dev/null | grep -q "$CONTAINER_NAME"; then
    log_info "Conduit is running; restarting..."
    docker restart "$CONTAINER_NAME" >/dev/null
    log_info "Restarted."
  else
    log_info "Conduit is stopped; starting..."
    docker start "$CONTAINER_NAME" >/dev/null
    log_info "Started."
  fi
}

# --- SMART START (menu version, with header) ---
smart_start() {
    print_header

    if ! docker ps -a 2>/dev/null | grep -q "$CONTAINER_NAME"; then
        echo -e "${BLUE}▶ FIRST TIME SETUP${NC}"
        echo "-----------------------------------"
        install_new
        return
    fi

    if docker ps 2>/dev/null | grep -q "$CONTAINER_NAME"; then
        echo -e "${YELLOW}Status: Running${NC}"
        echo -e "${BLUE}Action: Restarting Service...${NC}"
        docker restart "$CONTAINER_NAME" >/dev/null
        echo -e "${GREEN}✔ Service Restarted Successfully.${NC}"
        sleep 2
    else
        echo -e "${RED}Status: Stopped${NC}"
        echo -e "${BLUE}Action: Starting Service...${NC}"
        docker start "$CONTAINER_NAME" >/dev/null
        echo -e "${GREEN}✔ Service Started Successfully.${NC}"
        sleep 2
    fi
}

# --- INSTALLATION (First Time or Reconfigure) ---
install_new() {
    local MAX_CLIENTS="${MAX_CLIENTS:-$DEFAULT_MAX_CLIENTS}"
    local BANDWIDTH="${BANDWIDTH:-$DEFAULT_BANDWIDTH}"

    if [ "${AUTO_YES:-0}" != "1" ] && [ -t 0 ]; then
        echo ""
        read -p "Maximum Clients [Default: ${MAX_CLIENTS}]: " _mc || true
        MAX_CLIENTS="${_mc:-$MAX_CLIENTS}"
        read -p "Bandwidth Limit (Mbps) [Default: ${BANDWIDTH}, Enter -1 for Unlimited]: " _bw || true
        BANDWIDTH="${_bw:-$BANDWIDTH}"
    fi

    echo ""
    echo -e "${YELLOW}Deploying container (ver: d8522a8)...${NC}"

    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

    if ! docker pull "$IMAGE" >/dev/null 2>&1; then
        log_err "Image pull failed."
        [ "${AUTO_YES:-0}" = "1" ] || { read -n 1 -s -r -p "Press any key to continue..." || true; }
        return 1
    fi

    if docker run -d \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        -v "$VOLUME_NAME:/home/conduit/data" \
        --network host \
        "$IMAGE" \
        start --max-clients "$MAX_CLIENTS" --bandwidth "$BANDWIDTH" -v >/dev/null 2>&1; then
        echo -e "${GREEN}✔ Installation Complete & Started!${NC}"
        echo ""
        [ "${AUTO_YES:-0}" = "1" ] || { read -n 1 -s -r -p "Press any key to return..." || true; }
        return 0
    else
        log_err "Installation failed."
        [ "${AUTO_YES:-0}" = "1" ] || { read -n 1 -s -r -p "Press any key to continue..." || true; }
        return 1
    fi
}

stop_service() {
    echo -e "${YELLOW}Stopping Conduit...${NC}"
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1
    echo -e "${GREEN}✔ Service stopped.${NC}"
    sleep 1
}

view_dashboard() {
    local stop_dashboard=0
    trap 'stop_dashboard=1' SIGINT SIGTERM

    local EL="\033[K"
    tput smcup 2>/dev/null || true
    echo -ne "\033[?25l" # Hide cursor
    clear

    # Best-effort GeoIP init (doesn't break dashboard)
    local GEOIP_READY=0
    if ( ensure_geoip_inspector_image && ensure_geoip_db ) >/dev/null 2>&1; then
      GEOIP_READY=1
    fi
    local LAST_GEOIP_TS=0
    local GEOIP_CACHE_FILE="${TMPDIR:-/tmp}/conduit_geoip_top5_${CONTAINER_NAME}.txt"
    local GEOIP_JOB_PID=0

    while [ "$stop_dashboard" -eq 0 ]; do
        if ! tput cup 0 0 2>/dev/null; then
          printf "\033[H"
        fi

        print_header_noclear
        echo -e "${BOLD}LIVE DASHBOARD${NC} (Press ${YELLOW}Ctrl+C${NC} to Exit)${EL}"
        echo -e "══════════════════════════════════════════════════════${EL}"

        if docker ps 2>/dev/null | grep -q "$CONTAINER_NAME"; then
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

            UPTIME=$(docker ps -f name="$CONTAINER_NAME" --format '{{.Status}}')

            echo -e " STATUS: ${GREEN}● ONLINE${NC}${EL}"
            echo -e " UPTIME: ${UPTIME}${EL}"
            echo -e "──────────────────────────────────────────────────────${EL}"
            printf " %-15s | %-15s %b\n" "RESOURCES" "TRAFFIC" "$EL"
            echo -e "──────────────────────────────────────────────────────${EL}"
            printf " CPU: ${YELLOW}%-9s${NC} | Users: ${GREEN}%-9s${NC} %b\n" "${CPU:-0%}" "${CONN:-0}" "$EL"
            printf " RAM: ${YELLOW}%-18s${NC} | Up: ${CYAN}%-12s${NC} %b\n" "${RAM:-0MiB}" "${UP:-0B}" "$EL"
            printf " %-22s | Down: ${CYAN}%-12s${NC} %b\n" "" "${DOWN:-0B}" "$EL"

            echo -e "──────────────────────────────────────────────────────${EL}"
            echo -e " ${BOLD}TOP COUNTRIES${NC} (peer IP count)${EL}"

            if [ "$GEOIP_READY" -eq 1 ] && [ "${CONN:-0}" != "0" ]; then
              NOW_TS="$(date +%s)"
              # Refresh at most once per 60 seconds, async to keep UI responsive.
              if [ $((NOW_TS - LAST_GEOIP_TS)) -ge 60 ]; then
                if [ "$GEOIP_JOB_PID" -eq 0 ] || ! kill -0 "$GEOIP_JOB_PID" 2>/dev/null; then
                  (
                    get_top_countries > "${GEOIP_CACHE_FILE}.tmp" 2>/dev/null || true
                    mv -f "${GEOIP_CACHE_FILE}.tmp" "$GEOIP_CACHE_FILE" 2>/dev/null || true
                  ) &
                  GEOIP_JOB_PID=$!
                  LAST_GEOIP_TS="$NOW_TS"
                fi
              fi

              if [ -s "$GEOIP_CACHE_FILE" ]; then
                local i=0
                while IFS=$'\t' read -r c name; do
                  [ -n "${c:-}" ] || continue
                  printf " %-28s %4s%b\n" "${name:-Unknown}" "$c" "$EL"
                  i=$((i + 1))
                done < "$GEOIP_CACHE_FILE"
                while [ "$i" -lt 5 ]; do
                  printf " %-28s %4s%b\n" "-" "-" "$EL"
                  i=$((i + 1))
                done
              else
                printf " %-28s %4s%b\n" "(updating...)" "" "$EL"
                printf " %-28s %4s%b\n" "-" "-" "$EL"
                printf " %-28s %4s%b\n" "-" "-" "$EL"
                printf " %-28s %4s%b\n" "-" "-" "$EL"
                printf " %-28s %4s%b\n" "-" "-" "$EL"
              fi
            else
              printf " %-28s %4s%b\n" "(GeoIP pending or no users)" "" "$EL"
              printf " %-28s %4s%b\n" "-" "-" "$EL"
              printf " %-28s %4s%b\n" "-" "-" "$EL"
              printf " %-28s %4s%b\n" "-" "-" "$EL"
              printf " %-28s %4s%b\n" "-" "-" "$EL"
            fi

            echo -e "══════════════════════════════════════════════════════${EL}"
            echo -e "${YELLOW}Refreshing every 10 seconds...${NC}${EL}"
        else
            echo -e " STATUS: ${RED}● OFFLINE${NC}${EL}"
            echo -e "──────────────────────────────────────────────────────${EL}"
            echo -e " Service is not running.${EL}"
            echo -e " Press 1 to Start.${EL}"
            echo -e "══════════════════════════════════════════════════════${EL}"
        fi

        tput ed 2>/dev/null || printf "\033[J"

        for _ in $(seq 1 10); do
          [ "$stop_dashboard" -eq 1 ] && break
          sleep 1
        done
    done

    if [ "$GEOIP_JOB_PID" -ne 0 ]; then
      kill "$GEOIP_JOB_PID" 2>/dev/null || true
    fi
    echo -ne "\033[?25h"
    tput rmcup 2>/dev/null || true
    trap - SIGINT SIGTERM
}

view_logs() {
    clear
    echo -e "${CYAN}Streaming Logs (Press Ctrl+C to Exit)...${NC}"
    echo "------------------------------------------------"
    docker logs -f --tail 100 "$CONTAINER_NAME"
}

# Stream only [STATS] lines (like Linux conduit-manager "Live stats")
view_live_stats() {
    if ! docker ps 2>/dev/null | grep -q "$CONTAINER_NAME"; then
        print_header
        log_err "Conduit is not running. Start it first (option 1 or 6)."
        [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
        return 1
    fi
    echo -e "${CYAN}Streaming [STATS] lines... Press Ctrl+C to return${NC}"
    echo -e "${YELLOW}(filtered for statistics only)${NC}"
    echo ""
    trap 'echo -e "\n${CYAN}Returning to menu...${NC}"; return' SIGINT
    docker logs -f --tail 20 "$CONTAINER_NAME" 2>&1 | grep "\[STATS\]"
    trap - SIGINT
}

show_version() {
    echo -e "${CYAN}Conduit Manager (macOS) v${SCRIPT_VERSION}${NC}"
    echo "Image: $IMAGE"
    if docker ps 2>/dev/null | grep -q "$CONTAINER_NAME"; then
        local digest
        digest=$(docker inspect --format='{{index .RepoDigests 0}}' "$IMAGE" 2>/dev/null | grep -o 'sha256:[a-f0-9]*' || true)
        [ -n "${digest:-}" ] && echo "Running: ${digest}"
    fi
}

health_check() {
    echo -e "${CYAN}═══ CONDUIT HEALTH CHECK ═══${NC}"
    echo ""
    local all_ok=true

    echo -n "Docker daemon: "
    if docker info >/dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAILED${NC}"
        all_ok=false
    fi

    echo -n "Container exists: "
    if docker ps -a 2>/dev/null | grep -q "$CONTAINER_NAME"; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAILED${NC}"
        all_ok=false
    fi

    echo -n "Container running: "
    if docker ps 2>/dev/null | grep -q "$CONTAINER_NAME"; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${YELLOW}Stopped${NC}"
    fi

    echo -n "Restart count: "
    local restarts
    restarts=$(docker inspect --format='{{.RestartCount}}' "$CONTAINER_NAME" 2>/dev/null || echo "")
    if [ -n "${restarts:-}" ]; then
        if [ "${restarts:-0}" -lt 5 ]; then
            echo -e "${GREEN}${restarts}${NC}"
        else
            echo -e "${YELLOW}${restarts}${NC}"
        fi
    else
        echo -e "${YELLOW}N/A${NC}"
    fi

    echo -n "Data volume: "
    if docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAILED${NC}"
        all_ok=false
    fi

    echo -n "Node key: "
    local mp
    mp=$(docker volume inspect "$VOLUME_NAME" --format '{{ .Mountpoint }}' 2>/dev/null || true)
    if [ -n "${mp:-}" ] && [ -f "${mp}/conduit_key.json" ]; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${YELLOW}PENDING (created on first run)${NC}"
    fi

    echo ""
    if [ "$all_ok" = true ]; then
        echo -e "${GREEN}✓ Health check OK${NC}"
    else
        echo -e "${YELLOW}Some checks failed or pending.${NC}"
    fi
}

backup_key() {
    echo -e "${CYAN}═══ BACKUP NODE KEY ═══${NC}"
    echo ""
    mkdir -p "$BACKUP_DIR"
    local ts
    ts=$(date '+%Y%m%d_%H%M%S')
    local dest="$BACKUP_DIR/conduit_key_${ts}.json"
    if docker run --rm -v "$VOLUME_NAME:/data:ro" -v "$BACKUP_DIR:/backup" alpine cp /data/conduit_key.json "/backup/conduit_key_${ts}.json" 2>/dev/null; then
        echo -e "${GREEN}✓ Backup saved${NC}"
        echo "  $dest"
        [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
    else
        log_err "No node key found. Start Conduit at least once first."
        [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
        return 1
    fi
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
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    if docker run --rm -v "$VOLUME_NAME:/data" -v "$BACKUP_DIR:/backup:ro" alpine cp "/backup/$(basename "$src")" /data/conduit_key.json 2>/dev/null; then
        echo -e "${GREEN}✓ Restored.${NC}"
        docker start "$CONTAINER_NAME" 2>/dev/null || true
    else
        log_err "Restore failed."
    fi
    [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
}

update_conduit() {
    echo -e "${CYAN}═══ UPDATE CONDUIT ═══${NC}"
    echo ""
    echo "Pulling latest image..."
    if ! docker pull "$IMAGE" >/dev/null 2>&1; then
        log_err "Pull failed. Check network."
        [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
        return 1
    fi
    local mc="${MAX_CLIENTS:-$DEFAULT_MAX_CLIENTS}"
    local bw="${BANDWIDTH:-$DEFAULT_BANDWIDTH}"
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
    if docker run -d --name "$CONTAINER_NAME" --restart unless-stopped \
        -v "$VOLUME_NAME:/home/conduit/data" --network host "$IMAGE" \
        start --max-clients "$mc" --bandwidth "$bw" -v >/dev/null 2>&1; then
        echo -e "${GREEN}✓ Updated and restarted.${NC}"
    else
        log_err "Failed to start container."
        return 1
    fi
    [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
}

uninstall_mac() {
    echo ""
    echo -e "${RED}═══ UNINSTALL CONDUIT (macOS) ═══${NC}"
    echo ""
    echo "This will remove: container, image, data volume."
    echo -e "${RED}This cannot be undone.${NC}"
    echo ""
    read -p "Type 'yes' to confirm: " confirm || true
    if [ "$confirm" != "yes" ]; then
        echo "Cancelled."
        return 0
    fi
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
    docker rmi "$IMAGE" 2>/dev/null || true
    docker volume rm "$VOLUME_NAME" 2>/dev/null || true
    echo -e "${GREEN}✓ Uninstall complete.${NC}"
    echo "Backups (if any) kept in: $BACKUP_DIR"
    echo ""
}

start_only() {
    if ! docker ps -a 2>/dev/null | grep -q "$CONTAINER_NAME"; then
        log_info "First-time setup..."
        install_new
        return
    fi
    if docker ps 2>/dev/null | grep -q "$CONTAINER_NAME"; then
        echo -e "${GREEN}✓ Conduit is already running.${NC}"
    else
        docker start "$CONTAINER_NAME" >/dev/null
        echo -e "${GREEN}✓ Conduit started.${NC}"
    fi
    [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
}

restart_only() {
    if ! docker ps -a 2>/dev/null | grep -q "$CONTAINER_NAME"; then
        log_err "No container found. Use option 1 or 6 to install/start."
        [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
        return 1
    fi
    docker restart "$CONTAINER_NAME" >/dev/null
    echo -e "${GREEN}✓ Conduit restarted.${NC}"
    [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
}

# Peers-by-country needs tcpdump + geoiplookup; Linux conduit-manager has full support
peer_info_stub() {
    echo -e "${CYAN}Live peers by country${NC}"
    echo ""
    echo "Peer-by-country (GeoIP) is supported in the Linux conduit-manager:"
    echo "  https://github.com/SamNet-dev/conduit-manager"
    echo ""
    echo "On macOS you can watch traffic with:"
    echo "  docker logs -f $CONTAINER_NAME 2>&1 | grep STATS"
    echo ""
    [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; }
}

usage() {
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "  No arguments    Start or restart Conduit (non-interactive)."
    echo "  --menu          Show interactive menu."
    echo "  --start         Start/restart Conduit (same as no args)."
    echo "  --stop          Stop Conduit."
    echo "  --logs          Stream container logs."
    echo "  --connections   Show current peer IPs (ephemeral)."
    echo "  --countries     Show current peer countries (offline GeoIP)."
    echo "  --dashboard     Open live dashboard."
    echo "  --reconfigure   Reinstall with new max-clients/bandwidth."
    echo "  --yes, -y       Non-interactive (no prompts)."
    echo "  --max-clients N Set max clients (default: ${DEFAULT_MAX_CLIENTS})."
    echo "  --bandwidth N   Set bandwidth Mbps, -1=unlimited (default: ${DEFAULT_BANDWIDTH})."
    echo "  --help, -h      Show this help."
}

# --- INTERACTIVE MENU (used when run with --menu) ---
# Layout aligned with https://github.com/SamNet-dev/conduit-manager where applicable
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
    echo "  9. 🌍 Peers by country (see Linux manager)"
    echo "  c. 🌐 Show peer IPs (connections)"
    echo "  g. 🗺  Show peer countries (GeoIP)"
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
      c|C) print_header; show_connections; [ -t 0 ] && { echo ""; read -n 1 -s -r -p "Press any key to return..." || true; } ;;
      g|G) print_header; show_countries; [ -t 0 ] && { echo ""; read -n 1 -s -r -p "Press any key to return..." || true; } ;;
      h|H) health_check; [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; } ;;
      b|B) backup_key ;;
      r|R) restore_key ;;
      u|U) uninstall_mac; [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; } ;;
      v|V) show_version; [ -t 0 ] && { read -n 1 -s -r -p "Press any key to return..." || true; } ;;
      0) echo -e "${CYAN}Goodbye!${NC}"; exit 0 ;;
      "") ;;
      *) echo -e "${RED}Invalid option.${NC} Use 0-9, h, b, r, u, or v."; sleep 1 ;;
    esac
  done
}

# --- ARG PARSING / ENTRYPOINT ---
MODE="start"
AUTO_YES="${AUTO_YES:-0}"
MAX_CLIENTS="${MAX_CLIENTS:-$DEFAULT_MAX_CLIENTS}"
BANDWIDTH="${BANDWIDTH:-$DEFAULT_BANDWIDTH}"

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --menu)    MODE="menu"; shift ;;
    --start)   MODE="start"; shift ;;
    --stop)    MODE="stop"; shift ;;
    --logs)    MODE="logs"; shift ;;
    --connections) MODE="connections"; shift ;;
    --countries)   MODE="countries"; shift ;;
    --dashboard)   MODE="dashboard"; shift ;;
    --reconfigure) MODE="reconfigure"; shift ;;
    --yes|-y)  AUTO_YES=1; shift ;;
    --max-clients) shift; MAX_CLIENTS="${1:-$DEFAULT_MAX_CLIENTS}"; shift || true ;;
    --bandwidth)   shift; BANDWIDTH="${1:-$DEFAULT_BANDWIDTH}"; shift || true ;;
    *) log_err "Unknown argument: $1"; usage; exit 2 ;;
  esac
done

ensure_docker_desktop_running

case "$MODE" in
  menu)        menu_loop ;;
  stop)        stop_service ;;
  logs)        view_logs ;;
  connections) show_connections ;;
  countries)   show_countries ;;
  dashboard)   view_dashboard ;;
  reconfigure) AUTO_YES=1; install_new ;;
  start|*)     AUTO_YES=1; start_noninteractive ;;
esac