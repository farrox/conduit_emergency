#!/bin/bash
# Linux Installation Script for Conduit CLI
# One-command install for Linux VPS and servers
# Usage: curl -sL https://raw.githubusercontent.com/farrox/conduit_emergency/main/scripts/install-linux.sh | sudo bash
# Or with custom settings: curl ... | MAX_CLIENTS=500 BANDWIDTH=10 sudo bash

set -e

# Configuration
INSTALL_DIR="/usr/local/bin"
DATA_DIR="/var/lib/conduit"
SERVICE_FILE="/etc/systemd/system/conduit.service"
PROJECT_DIR="/opt/conduit"

# Configuration (override with: curl ... | MAX_CLIENTS=500 BANDWIDTH=10 bash)
MAX_CLIENTS=${MAX_CLIENTS:-200}
BANDWIDTH=${BANDWIDTH:-5}

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "╔═══════════════════════════════════════════════╗"
echo "║     Conduit CLI - Linux Installation         ║"
echo "╚═══════════════════════════════════════════════╝"
echo -e "${NC}"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root (sudo)${NC}"
    exit 1
fi

# Check if Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo -e "${RED}This script is for Linux only${NC}"
    echo "For macOS, use: ./scripts/easy-setup.sh"
    exit 1
fi

#
# Step 1: Install Dependencies
#
echo -e "${YELLOW}[1/6] Installing dependencies...${NC}"

# Detect package manager
if command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt"
    apt-get update -qq >/dev/null 2>&1
    apt-get install -y -qq curl wget git build-essential >/dev/null 2>&1 || true
elif command -v yum &> /dev/null; then
    PKG_MANAGER="yum"
    yum install -y -q curl wget git gcc make >/dev/null 2>&1 || true
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
    dnf install -y -q curl wget git gcc make >/dev/null 2>&1 || true
else
    echo -e "${RED}Unsupported package manager. Please install: curl, wget, git, build-essential${NC}"
    exit 1
fi

echo " Dependencies installed"

# Function to install Go
install_go() {
    GO_VERSION="1.24.0"
    GO_ARCH=$(uname -m)
    if [ "$GO_ARCH" = "x86_64" ]; then
        GO_ARCH="amd64"
    elif [ "$GO_ARCH" = "aarch64" ]; then
        GO_ARCH="arm64"
    fi
    
    GO_TAR="go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    GO_URL="https://go.dev/dl/${GO_TAR}"
    
    cd /tmp
    if curl -fsSL "$GO_URL" -o "$GO_TAR" && [ -s "$GO_TAR" ]; then
        echo " Downloaded Go ${GO_VERSION}"
    else
        echo -e "${RED}Failed to download Go${NC}"
        exit 1
    fi
    
    rm -rf /usr/local/go
    tar -C /usr/local -xzf "$GO_TAR" >/dev/null 2>&1
    rm -f "$GO_TAR"
    
    # Add to PATH
    if ! grep -q "/usr/local/go/bin" /etc/profile; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
    fi
    export PATH=$PATH:/usr/local/go/bin
    
    # Verify
    if ! /usr/local/go/bin/go version >/dev/null 2>&1; then
        echo -e "${RED}Go installation verification failed${NC}"
        exit 1
    fi
    
    echo " Go ${GO_VERSION} installed successfully"
}

#
# Step 2: Install Go 1.24.x
#
echo -e "${YELLOW}[2/6] Installing Go 1.24.x...${NC}"

if command -v go &> /dev/null; then
    GO_VERSION=$(go version | grep -oE 'go[0-9]+\.[0-9]+' | sed 's/go//')
    GO_MAJOR=$(echo $GO_VERSION | cut -d. -f1)
    GO_MINOR=$(echo $GO_VERSION | cut -d. -f2)
    
    if [ "$GO_MAJOR" -eq 1 ] && [ "$GO_MINOR" -eq 24 ]; then
        echo " Go $GO_VERSION already installed"
    elif [ "$GO_MAJOR" -gt 1 ] || ([ "$GO_MAJOR" -eq 1 ] && [ "$GO_MINOR" -ge 25 ]); then
        echo " Go $GO_VERSION detected, but Go 1.24.x is required"
        echo " Installing Go 1.24.0..."
        install_go
    else
        echo " Go $GO_VERSION detected, but Go 1.24.x is required"
        echo " Installing Go 1.24.0..."
        install_go
    fi
else
    echo " Installing Go 1.24.0..."
    install_go
fi

# Ensure Go is in PATH
export PATH=$PATH:/usr/local/go/bin
if ! command -v go &> /dev/null; then
    echo -e "${RED}Go not found in PATH${NC}"
    exit 1
fi

GO_VER=$(go version | grep -oE 'go[0-9]+\.[0-9]+')
echo " Version: $GO_VER"

#
# Step 3: Clone and Build
#
echo -e "${YELLOW}[3/6] Cloning repository and building...${NC}"

# Clone or update repository
if [ -d "$PROJECT_DIR/.git" ]; then
    echo " Repository exists, updating..."
    cd "$PROJECT_DIR"
    git pull -q >/dev/null 2>&1 || true
else
    echo " Cloning repository..."
    rm -rf "$PROJECT_DIR"
    git clone --depth 1 -q https://github.com/farrox/conduit_emergency.git "$PROJECT_DIR" >/dev/null 2>&1
    cd "$PROJECT_DIR"
fi

# Setup dependencies
echo " Setting up dependencies..."
make setup >/dev/null 2>&1 || {
    echo -e "${RED}Failed to setup dependencies${NC}"
    exit 1
}

# Build
echo " Building Conduit..."
if make build >/dev/null 2>&1; then
    echo " Build successful"
else
    echo -e "${RED}Build failed${NC}"
    exit 1
fi

# Verify binary
if [ ! -f "$PROJECT_DIR/dist/conduit" ]; then
    echo -e "${RED}Binary not found after build${NC}"
    exit 1
fi

if ! "$PROJECT_DIR/dist/conduit" --version >/dev/null 2>&1; then
    echo -e "${RED}Binary verification failed${NC}"
    exit 1
fi

BINARY_VERSION=$("$PROJECT_DIR/dist/conduit" --version 2>/dev/null || echo "unknown")
echo " Binary version: $BINARY_VERSION"

# Create symlink
ln -sf "$PROJECT_DIR/dist/conduit" "$INSTALL_DIR/conduit"
chmod +x "$INSTALL_DIR/conduit"

#
# Step 4: Create User and Directories
#
echo -e "${YELLOW}[4/6] Setting up user and directories...${NC}"

# Create conduit user
if ! getent passwd conduit >/dev/null 2>&1; then
    useradd -r -s /usr/sbin/nologin -d "$DATA_DIR" -M conduit
    echo " Created user: conduit"
else
    echo " User 'conduit' already exists"
fi

# Create data directory
mkdir -p "$DATA_DIR"
chown conduit:conduit "$DATA_DIR"
echo " Data directory: $DATA_DIR"

# Check for config file
CONFIG_FILE="$PROJECT_DIR/psiphon_config.json"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e " ${YELLOW}⚠️  Config file not found${NC}"
    echo " You'll need to add psiphon_config.json to $PROJECT_DIR"
    echo " Or contact Psiphon (info@psiphon.ca) to obtain one"
    CONFIG_ARG=""
else
    # Validate it's not the example
    if grep -q "FFFFFFFFFFFFFFFF" "$CONFIG_FILE" 2>/dev/null; then
        echo -e " ${YELLOW}⚠️  Example config found (will not work)${NC}"
        CONFIG_ARG=""
    else
        echo " Config file found: $CONFIG_FILE"
        CONFIG_ARG="--psiphon-config $CONFIG_FILE"
    fi
fi

#
# Step 5: Create Systemd Service
#
echo -e "${YELLOW}[5/6] Creating systemd service...${NC}"

cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Conduit Psiphon Inproxy Node
After=network.target

[Service]
Type=simple
User=conduit
Group=conduit
WorkingDirectory=$PROJECT_DIR
ExecStart=$INSTALL_DIR/conduit start $CONFIG_ARG --max-clients $MAX_CLIENTS --bandwidth $BANDWIDTH --data-dir $DATA_DIR -v
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload >/dev/null 2>&1
systemctl enable conduit >/dev/null 2>&1
echo " Service created and enabled"

#
# Step 6: Start Service
#
echo -e "${YELLOW}[6/6] Starting Conduit service...${NC}"

if [ -z "$CONFIG_ARG" ]; then
    echo -e " ${YELLOW}⚠️  Service created but not started (no config file)${NC}"
    echo " Add psiphon_config.json to $PROJECT_DIR and run:"
    echo "   sudo systemctl start conduit"
else
    systemctl restart conduit >/dev/null 2>&1 || true
    sleep 2
    
    if systemctl is-active --quiet conduit; then
        echo -e " ${GREEN}Service started successfully${NC}"
    else
        echo -e " ${YELLOW}Service may have issues. Check logs:${NC}"
        echo "   sudo journalctl -u conduit -n 50"
    fi
fi

#
# Final Output
#
echo ""
echo -e "${GREEN}${BOLD}"
echo "════════════════════════════════════════════════════════════"
echo " Installation Complete!"
echo "════════════════════════════════════════════════════════════"
echo -e "${NC}"
echo -e " ${CYAN}Binary:${NC} $INSTALL_DIR/conduit"
echo -e " ${CYAN}Data:${NC} $DATA_DIR"
echo -e " ${CYAN}Config:${NC} $PROJECT_DIR/psiphon_config.json"
echo -e " ${CYAN}Service:${NC} conduit"
echo ""
echo -e " ${BOLD}Configuration:${NC}"
echo -e "   Max Clients: ${YELLOW}$MAX_CLIENTS${NC}"
echo -e "   Bandwidth: ${YELLOW}$BANDWIDTH Mbps${NC}"
echo ""
echo -e " ${BOLD}Useful Commands:${NC}"
echo -e "   ${CYAN}Status:${NC}   sudo systemctl status conduit"
echo -e "   ${CYAN}Logs:${NC}      sudo journalctl -u conduit -f"
echo -e "   ${CYAN}Start:${NC}     sudo systemctl start conduit"
echo -e "   ${CYAN}Stop:${NC}      sudo systemctl stop conduit"
echo -e "   ${CYAN}Restart:${NC}   sudo systemctl restart conduit"
echo ""
if [ -z "$CONFIG_ARG" ]; then
    echo -e " ${YELLOW}⚠️  Next Step:${NC}"
    echo "   1. Add psiphon_config.json to $PROJECT_DIR"
    echo "   2. Run: sudo systemctl start conduit"
    echo ""
fi
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
