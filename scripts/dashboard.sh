#!/bin/bash
# Live Dashboard for Conduit CLI (Non-Docker Version)
# Monitors CPU, RAM, connected Iranians, and traffic in real-time

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Find conduit process
find_conduit_pid() {
    ps aux | grep "[.]/dist/conduit start" | grep -v grep | awk '{print $2}' | head -1
}

# Find stats file
find_stats_file() {
    # Check data directory first
    if [ -f "$PROJECT_ROOT/data/stats.json" ]; then
        echo "$PROJECT_ROOT/data/stats.json"
    elif [ -f "$PROJECT_ROOT/stats.json" ]; then
        echo "$PROJECT_ROOT/stats.json"
    else
        echo ""
    fi
}

# Get process stats
get_process_stats() {
    local pid=$1
    if [ -z "$pid" ] || ! ps -p $pid > /dev/null 2>&1; then
        echo "0|0B"
        return
    fi
    
    # Get CPU and memory using ps
    local stats=$(ps -p $pid -o %cpu,rss | tail -1)
    local cpu=$(echo "$stats" | awk '{printf "%.1f%%", $1}')
    local mem_kb=$(echo "$stats" | awk '{print $2}')
    local mem_mb=$(echo "scale=2; $mem_kb / 1024" | bc)
    local mem=$(printf "%.1fM" "$mem_mb")
    
    echo "${cpu}|${mem}"
}

# Get stats from stats file or log parsing
get_conduit_stats() {
    local pid=$1
    local stats_file=$(find_stats_file)
    
    # Try stats file first (most accurate)
    if [ -n "$stats_file" ] && [ -f "$stats_file" ]; then
        # Parse JSON stats file
        if command -v python3 &> /dev/null; then
            local conn=$(python3 -c "import sys, json; data=json.load(open('$stats_file')); print(data.get('connectedClients', 0))" 2>/dev/null || echo "0")
            local up=$(python3 -c "import sys, json; data=json.load(open('$stats_file')); print(data.get('totalBytesUp', 0))" 2>/dev/null || echo "0")
            local down=$(python3 -c "import sys, json; data=json.load(open('$stats_file')); print(data.get('totalBytesDown', 0))" 2>/dev/null || echo "0")
            
            # Format bytes
            local up_formatted=$(format_bytes "$up")
            local down_formatted=$(format_bytes "$down")
            
            echo "${conn}|${up_formatted}|${down_formatted}"
            return
        fi
    fi
    
    # Fallback: Try to parse from log files
    for log_file in "/tmp/conduit.log" "/tmp/conduit_dash.log" "$PROJECT_ROOT/data/conduit.log"; do
        if [ -f "$log_file" ]; then
            local log_line=$(grep "\[STATS\]" "$log_file" 2>/dev/null | tail -1)
            if [ -n "$log_line" ]; then
                # Parse: [STATS] Connecting: X | Connected: Y | Up: ... | Down: ... | Uptime: ...
                local conn=$(echo "$log_line" | sed -n 's/.*Connected:[[:space:]]*\([0-9]*\).*/\1/p')
                local up=$(echo "$log_line" | sed -n 's/.*Up:[[:space:]]*\([^|]*\).*/\1/p' | tr -d ' ')
                local down=$(echo "$log_line" | sed -n 's/.*Down:[[:space:]]*\([^|]*\).*/\1/p' | tr -d ' ')
                
                if [ -n "$conn" ]; then
                    echo "${conn}|${up:-0B}|${down:-0B}"
                    return
                fi
            fi
        fi
    done
    
    # Default: no stats available yet
    echo "0|0B|0B"
}

# Format bytes to human readable
format_bytes() {
    local bytes=$1
    if [ -z "$bytes" ] || [ "$bytes" = "0" ]; then
        echo "0B"
        return
    fi
    
    # Use python if available for accurate conversion
    if command -v python3 &> /dev/null; then
        python3 -c "
bytes = $bytes
for unit in ['B', 'KB', 'MB', 'GB', 'TB']:
    if bytes < 1024.0:
        print(f'{bytes:.1f}{unit}')
        break
    bytes /= 1024.0
" 2>/dev/null || echo "0B"
    else
        # Fallback: simple calculation
        if [ "$bytes" -lt 1024 ]; then
            echo "${bytes}B"
        elif [ "$bytes" -lt 1048576 ]; then
            echo "$(echo "scale=1; $bytes / 1024" | bc)KB"
        elif [ "$bytes" -lt 1073741824 ]; then
            echo "$(echo "scale=1; $bytes / 1048576" | bc)MB"
        else
            echo "$(echo "scale=1; $bytes / 1073741824" | bc)GB"
        fi
    fi
}

# Get uptime
get_uptime() {
    local pid=$1
    if [ -z "$pid" ] || ! ps -p $pid > /dev/null 2>&1; then
        echo "N/A"
        return
    fi
    
    # Get process start time and calculate uptime
    local start_time=$(ps -p $pid -o lstart= 2>/dev/null | awk '{print $2, $3, $4}')
    if [ -n "$start_time" ]; then
        # Calculate uptime (simplified - shows running status)
        local elapsed=$(ps -p $pid -o etime= 2>/dev/null | tr -d ' ')
        echo "$elapsed"
    else
        echo "Running"
    fi
}

# Print header
print_header() {
    clear
    echo -e "${CYAN}"
    echo "  ██████╗ ██████╗ ███╗   ██╗██████╗ ██╗   ██╗██╗████████╗"
    echo " ██╔════╝██╔═══██╗████╗  ██║██╔══██╗██║   ██║██║╚══██╔══╝"
    echo " ██║     ██║   ██║██╔██╗ ██║██║  ██║██║   ██║██║   ██║   "
    echo " ██║     ██║   ██║██║╚██╗██║██║  ██║██║   ██║██║   ██║   "
    echo " ╚██████╗╚██████╔╝██║ ╚████║██████╔╝╚██████╔╝██║   ██║   "
    echo "  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝  ╚═════╝ ╚═╝   ╚═╝   "
    echo -e "              ${YELLOW}CLI Live Dashboard${CYAN}                  "
    echo -e "${NC}"
}

# Main dashboard loop
view_dashboard() {
    trap "echo ''; echo -e '${CYAN}Dashboard closed.${NC}'; exit 0" SIGINT
    
    while true; do
        print_header
        echo -e "${BOLD}LIVE DASHBOARD${NC} (Press ${YELLOW}Ctrl+C${NC} to Exit)"
        echo "══════════════════════════════════════════════════════"
        
        CONDUIT_PID=$(find_conduit_pid)
        
        if [ -n "$CONDUIT_PID" ]; then
            # Get process stats
            PROCESS_STATS=$(get_process_stats "$CONDUIT_PID")
            CPU=$(echo "$PROCESS_STATS" | cut -d'|' -f1)
            RAM=$(echo "$PROCESS_STATS" | cut -d'|' -f2)
            
            # Get conduit stats
            CONDUIT_STATS=$(get_conduit_stats "$CONDUIT_PID")
            CONN=$(echo "$CONDUIT_STATS" | cut -d'|' -f1)
            UP=$(echo "$CONDUIT_STATS" | cut -d'|' -f2)
            DOWN=$(echo "$CONDUIT_STATS" | cut -d'|' -f3)
            
            # Default values if empty
            CONN=${CONN:-0}
            UP=${UP:-0B}
            DOWN=${DOWN:-0B}
            
            # Get uptime
            UPTIME=$(get_uptime "$CONDUIT_PID")
            
            echo -e " STATUS:      ${GREEN}● ONLINE${NC}"
            echo -e " PID:         $CONDUIT_PID"
            echo -e " UPTIME:      $UPTIME"
            echo "──────────────────────────────────────────────────────"
            printf " %-15s | %-15s \n" "RESOURCES" "TRAFFIC"
            echo "──────────────────────────────────────────────────────"
            printf " CPU: ${YELLOW}%-9s${NC} | Iranians: ${GREEN}%-9s${NC} \n" "$CPU" "$CONN"
            printf " RAM: ${YELLOW}%-9s${NC} | Up:    ${CYAN}%-9s${NC} \n" "$RAM" "$UP"
            printf "              | Down:  ${CYAN}%-9s${NC} \n" "$DOWN"
            echo "══════════════════════════════════════════════════════"
            
            # Show stats file location if available
            STATS_FILE=$(find_stats_file)
            if [ -n "$STATS_FILE" ]; then
                echo -e "${BLUE}📊 Stats: $STATS_FILE${NC}"
            else
                echo -e "${YELLOW}💡 Tip: Start with --stats-file for accurate stats${NC}"
            fi
            
            echo -e "${YELLOW}Refreshing every 5 seconds...${NC}"
        else
            echo -e " STATUS:      ${RED}● OFFLINE${NC}"
            echo "──────────────────────────────────────────────────────"
            echo -e " Conduit is not running."
            echo ""
            echo " To start Conduit:"
            echo "   ./dist/conduit start --psiphon-config ./psiphon_config.json -v --stats-file"
            echo ""
            echo " Or use the optimal configuration:"
            echo "   ./scripts/configure-optimal.sh"
            echo "══════════════════════════════════════════════════════"
        fi
        
        sleep 5
    done
}

# Main execution
view_dashboard
