# Conduit CLI

<div align="center">

**Help Iranians access the open internet by running a volunteer proxy node**

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

</div>

---

## 📊 Live Dashboard

Monitor your Conduit node in real-time with the built-in dashboard:

![Live Dashboard](resources/dashboard.png)

*The dashboard shows connected Iranians, CPU/RAM usage, and traffic statistics in real-time.*

**Quick Start with Dashboard:**
```bash
./scripts/start-with-dashboard.sh
```

See the [Dashboard Guide](docs/markdown/DASHBOARD.md) for full documentation.

---

## 🚀 Quick Start

Get Conduit running in minutes! Choose the method that works best for you:

### Option 1: Docker Manager (Easiest - Recommended for Mac)

**Perfect for:** Mac users who want the simplest setup with a beautiful UI

**Run directly from GitHub:**
```bash
curl -sL https://raw.githubusercontent.com/farrox/conduit_emergency/main/scripts/conduit-manager-mac.sh | bash
```

**Or download and run:**
```bash
./scripts/conduit-manager-mac.sh
```

✅ No building required  
✅ Beautiful live dashboard  
✅ Automatic updates  
✅ Smart start/stop/restart  
✅ Can be run directly from GitHub URL

See [Docker Manager Guide](docs/markdown/CONDUIT_MANAGER_MAC.md) for details.

### Option 2: Download DMG (Native Binary for Mac)

**Perfect for:** Mac users who want a native app without Docker

1. Download the `Conduit.dmg` file
2. Double-click to mount it
3. Drag "Conduit" to Applications
4. Double-click "Start Conduit.command"

See [Installation Guide](docs/markdown/INSTALL_MAC.md) for detailed instructions.

### Option 3: Build from Source

**Perfect for:** Developers or users who want full control

**macOS:**
```bash
# Clone repository
git clone https://github.com/farrox/conduit_emergency.git
cd conduit_emergency

# Run automated setup (installs everything)
./scripts/easy-setup.sh

# Then double-click "Start Conduit.command"
```

**Linux/VPS (One-Command Install):**
```bash
# One command installs everything
curl -sL https://raw.githubusercontent.com/farrox/conduit_emergency/main/scripts/install-linux.sh | sudo bash

# Or with custom settings
curl -sL https://raw.githubusercontent.com/farrox/conduit_emergency/main/scripts/install-linux.sh | MAX_CLIENTS=500 BANDWIDTH=10 sudo bash
```

✅ Automated setup (installs everything)  
✅ Creates launcher script (macOS) or systemd service (Linux)  
✅ Full customization

See [Quick Start Guide](docs/markdown/QUICKSTART_MAC.md) for macOS step-by-step instructions.

---

## 📋 What You Need

### 1. Get Your Config File

Conduit needs a `psiphon_config.json` file to connect to the Psiphon network.

**Easiest Method - Extract from iOS App:**
```bash
./scripts/extract-ios-config.sh
```

**Alternative - Email Psiphon:**
- Email: `info@psiphon.ca`
- Subject: "Request for Conduit CLI Configuration"

See [Get Config Guide](docs/markdown/GET_CONFIG.md) for all options.

### 2. Start Conduit

**With Dashboard (Recommended):**
```bash
./scripts/start-with-dashboard.sh
```

**Manual Start:**
```bash
./dist/conduit start \
  --psiphon-config ./psiphon_config.json \
  -v \
  --stats-file
```

**View Dashboard:**
```bash
# In another terminal
./scripts/dashboard.sh
```

---

## ⚙️ Configuration

### Optimal Settings for Maximum Iranians

Automatically calculate the best settings for your internet speed:

```bash
# Interactive configuration helper
./scripts/configure-optimal.sh

# Or quick start with auto-detection
./scripts/quick-optimal.sh
```

This will:
- ✅ Test your internet bandwidth
- ✅ Calculate optimal `max-clients` and `bandwidth`
- ✅ Create a launcher with optimal settings

See [Optimal Configuration Guide](docs/markdown/CONFIG_OPTIMAL.md) for detailed guidance.

### Command Options

| Flag | Default | Description |
|------|---------|-------------|
| `--psiphon-config, -c` | - | Path to Psiphon network configuration file |
| `--max-clients, -m` | 200 | Maximum concurrent clients (1-1000) |
| `--bandwidth, -b` | 5 | Bandwidth limit per peer in Mbps (1-40) |
| `--data-dir, -d` | `./data` | Directory for keys and state |
| `--stats-file` | - | Enable stats file for dashboard |
| `-v` | - | Verbose output (use `-vv` for debug) |

### Example Commands

```bash
# Start with default settings
./dist/conduit start --psiphon-config ./psiphon_config.json

# High-capacity node
./dist/conduit start \
  --psiphon-config ./psiphon_config.json \
  --max-clients 1000 \
  --bandwidth 40

# With dashboard enabled
./dist/conduit start \
  --psiphon-config ./psiphon_config.json \
  --max-clients 500 \
  --bandwidth 10 \
  -v \
  --stats-file
```

---

## 🐳 Docker

### Quick Start (Recommended)

```bash
# Build with embedded config
docker build -t conduit \
  --build-arg PSIPHON_CONFIG=psiphon_config.json \
  -f Dockerfile.embedded .

# Run with persistent volume
docker run -d --name conduit \
  -v conduit-data:/home/conduit/data \
  --restart unless-stopped \
  conduit
```

**Important:** Always use a persistent volume to preserve your node's identity key and reputation.

### Docker Manager (Mac)

Use the interactive Docker Manager for the easiest experience:

```bash
./scripts/conduit-manager-mac.sh
```

See [Docker Manager Guide](docs/markdown/CONDUIT_MANAGER_MAC.md) for details.

---

## ☁️ Cloud Deployment

Deploy Conduit to cloud providers like DigitalOcean, Linode, Hetzner, AWS, Google Cloud, or Azure:

- **[Cloud Deployment Guide](docs/markdown/DEPLOY_CLOUD.md)** - Complete guide for all major cloud providers
- **[Deployment TODO Checklist](DEPLOY_TODO.md)** - Quick reference checklist

### Quick Start (Linux VPS)

**Option 1: One-Command Install (Recommended)**
```bash
# Installs everything: Go, builds from source, creates systemd service
curl -sL https://raw.githubusercontent.com/farrox/conduit_emergency/main/scripts/install-linux.sh | sudo bash

# With custom settings
curl -sL https://raw.githubusercontent.com/farrox/conduit_emergency/main/scripts/install-linux.sh | MAX_CLIENTS=500 BANDWIDTH=10 sudo bash
```

**Option 2: Docker**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh

# Clone and build
git clone https://github.com/farrox/conduit_emergency.git
cd conduit_emergency
docker build -t conduit --build-arg PSIPHON_CONFIG=psiphon_config.json -f Dockerfile.embedded .

# Run with persistent volume
docker run -d --name conduit \
  -v conduit-data:/home/conduit/data \
  --restart unless-stopped \
  conduit
```

See the [full deployment guide](docs/markdown/DEPLOY_CLOUD.md) for systemd services, firewall configuration, monitoring, and provider-specific notes.

---

## 🔨 Building from Source

### Requirements

- **Go 1.24.x** (Go 1.25+ is not supported due to psiphon-tls compatibility)
- Psiphon network configuration file (JSON)

**Installing Go:** See [Go Installation Guide](docs/markdown/INSTALL-GO.md).

### Build Commands

```bash
# First time setup (clones required dependencies)
make setup

# Build for current platform
make build

# Build with embedded config (single-binary distribution)
make build-embedded PSIPHON_CONFIG=./psiphon_config.json

# Build for all platforms
make build-all

# Individual platform builds
make build-linux       # Linux amd64
make build-linux-arm   # Linux arm64
make build-darwin      # macOS Intel
make build-darwin-arm  # macOS Apple Silicon
make build-windows     # Windows amd64
```

Binaries are output to `dist/`.

---

## 🔒 Security & Firewall

By default, Conduit accepts connections from anywhere. If you want to restrict traffic to specific regions (e.g., only Iran), see [Security & Firewall Guide](docs/markdown/SECURITY_FIREWALL.md).

**Windows users:** Check out the [Iran Conduit Firewall](https://github.com/SamNet-dev/iran-conduit-firewall) project for an automated solution with explicit blocking rules and full IPv6 support.

---

## 📁 Data Directory

Keys and state are stored in the data directory (default: `./data`):
- `conduit_key.json` - Node identity keypair (**preserve this!**)
- `stats.json` - Statistics file (if `--stats-file` is enabled)

**Important:** The Psiphon broker tracks proxy reputation by key. If you lose `conduit_key.json`, you'll need to build reputation from scratch.

**Backup your data directory regularly!**

---

## 📚 Documentation

### Getting Started
- **[Quick Start for Mac](docs/markdown/QUICKSTART_MAC.md)** - Simple step-by-step guide for non-technical users
- **[Installation Guide](docs/markdown/INSTALL_MAC.md)** - Detailed installation options
- **[Get Config Guide](docs/markdown/GET_CONFIG.md)** - How to get your `psiphon_config.json`

### Configuration
- **[Optimal Configuration](docs/markdown/CONFIG_OPTIMAL.md)** - Calculate best settings for maximum Iranians
- **[Dashboard Guide](docs/markdown/DASHBOARD.md)** - Live monitoring dashboard
- **[Security & Firewall](docs/markdown/SECURITY_FIREWALL.md)** - Restrict traffic to specific regions

### Deployment
- **[Cloud Deployment](docs/markdown/DEPLOY_CLOUD.md)** - Deploy to DigitalOcean, Linode, Hetzner, AWS, etc.
- **[Deployment TODO](DEPLOY_TODO.md)** - Quick reference checklist

### Run alongside Conduit
- **[Snowflake Guide](docs/markdown/SNOWFLAKE_WHERE_TO_START.md)** - Run Tor Snowflake proxy alongside Conduit
- **[Xray Guide](docs/markdown/XRAY_WHERE_TO_START.md)** - Run Xray (VLESS/VMess/REALITY) server alongside Conduit

### HTML Documentation
- **[HTML Docs](docs/index.html)** - Beautiful web-based documentation

---

## 🤝 Community & Acknowledgements

This project incorporates and references several excellent community contributions:

- **[Conduit Manager for macOS](https://github.com/polamgh/conduit-manager-mac)** - Docker-based management tool with beautiful UI (by [polamgh](https://github.com/polamgh))
- **[Conduit Manager (Linux)](https://github.com/SamNet-dev/conduit-manager)** - One-click Linux management tool with live peer mapping (by [SamNet-dev](https://github.com/SamNet-dev))
- **[Conduit Relay](https://github.com/paradixe/conduit-relay)** - Web dashboard with fleet management (by [paradixe](https://github.com/paradixe))
- **[Iran Conduit Firewall](https://github.com/SamNet-dev/iran-conduit-firewall)** - Windows firewall solution for traffic restriction (by [SamNet-dev](https://github.com/SamNet-dev))

See [ACKNOWLEDGEMENTS.md](ACKNOWLEDGEMENTS.md) for full credits and links.

---

## 📝 License

GNU General Public License v3.0

---

## 🆘 Need Help?

1. Check the [Quick Start Guide](docs/markdown/QUICKSTART_MAC.md) for step-by-step instructions
2. See the [HTML Documentation](docs/index.html) for visual guides
3. Review the [troubleshooting section](docs/markdown/QUICKSTART_MAC.md#troubleshooting) in the Quick Start guide
4. Open an issue on GitHub if you need further assistance

---

<div align="center">

**Thank you for helping Iranians access the open internet!** 🌐

Made with ❤️ for internet freedom

</div>
