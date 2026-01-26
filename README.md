# Conduit CLI

Command-line interface for running a Psiphon Conduit node - a volunteer-run proxy that relays traffic for users in censored regions.

## 🚀 Quick Start for Mac Users

**New to this? Start here:** [QUICKSTART_MAC.md](QUICKSTART_MAC.md) - Simple step-by-step guide for non-technical users.

### Quick Options:

**Option 1: Download DMG (Easiest)**
1. Download the DMG from the website/releases
2. Double-click to mount
3. Drag "Conduit" to Applications
4. Double-click "Start Conduit.command"

**Option 2: Clone & Auto-Setup**
```bash
git clone [repo-url]
cd conduit_emergency
./scripts/easy-setup.sh
# Then double-click "Start Conduit.command"
```

See [INSTALL_MAC.md](INSTALL_MAC.md) for detailed instructions.

## Quick Start

```bash
# First time setup (clones required dependencies)
make setup

# Build
make build

# Run
./dist/conduit start --psiphon-config /path/to/psiphon_config.json
```

## Requirements

- **Go 1.24.x** (Go 1.25+ is not supported due to psiphon-tls compatibility)
- Psiphon network configuration file (JSON)

**Installing Go:** See [INSTALL-GO.md](INSTALL-GO.md) for installation instructions.

## Configuration

Conduit requires a Psiphon network configuration file containing connection parameters. See `psiphon_config.example.json` for the expected format.

**No email required!** If you have the iOS Conduit app, extract the config:
```bash
./extract-ios-config.sh  # Extracts from iOS app bundle
```

Or build with embedded config (like the iOS app):
```bash
make build-embedded PSIPHON_CONFIG=./psiphon_config.json
```

See [GET_CONFIG.md](GET_CONFIG.md) for all options. If you don't have the iOS app, contact Psiphon (info@psiphon.ca) to obtain valid configuration values.

### Optimal Settings for Maximum Users

For the easiest way to configure optimal max-clients and bandwidth:

```bash
# Interactive configuration helper
./scripts/configure-optimal.sh

# Or quick start with auto-detection
./scripts/quick-optimal.sh
```

See [CONFIG_OPTIMAL.md](CONFIG_OPTIMAL.md) for detailed guidance.

## Usage

```bash
# Start with default settings
conduit start --psiphon-config ./psiphon_config.json

# Customize limits
conduit start --psiphon-config ./psiphon_config.json --max-clients 500 --bandwidth 10

# Verbose output (info messages)
conduit start --psiphon-config ./psiphon_config.json -v

# Debug output (everything)
conduit start --psiphon-config ./psiphon_config.json -vv
```

### Options

| Flag | Default | Description |
|------|---------|-------------|
| `--psiphon-config, -c` | - | Path to Psiphon network configuration file |
| `--max-clients, -m` | 200 | Maximum concurrent clients (1-1000) |
| `--bandwidth, -b` | 5 | Bandwidth limit per peer in Mbps (1-40) |
| `--data-dir, -d` | `./data` | Directory for keys and state |
| `-v` | - | Verbose output (use `-vv` for debug) |

## Building

```bash
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

## Docker

### Build with embedded config (recommended)

```bash
docker build -t conduit \
  --build-arg PSIPHON_CONFIG=psiphon_config.json \
  -f Dockerfile.embedded .
```

### Run with persistent data

**Important:** The Psiphon broker tracks proxy reputation by key. Always use a persistent volume to preserve your key across container restarts, otherwise you'll start with zero reputation and may not receive client connections.

```bash
# Using a named volume (recommended)
docker run -d --name conduit \
  -v conduit-data:/home/conduit/data \
  --restart unless-stopped \
  conduit

# Or using a host directory
mkdir -p /path/to/data && chown 1000:1000 /path/to/data
docker run -d --name conduit \
  -v /path/to/data:/home/conduit/data \
  --restart unless-stopped \
  conduit
```

### Build without embedded config

If you prefer to mount the config at runtime:

```bash
docker build -t conduit .

docker run -d --name conduit \
  -v conduit-data:/home/conduit/data \
  -v /path/to/psiphon_config.json:/config.json:ro \
  --restart unless-stopped \
  conduit start --psiphon-config /config.json
```

## Data Directory

Keys and state are stored in the data directory (default: `./data`):
- `conduit_key.json` - Node identity keypair (preserve this!)

The broker builds reputation for your proxy based on this key. If you lose it, you'll need to build reputation from scratch.

## License

GNU General Public License v3.0
