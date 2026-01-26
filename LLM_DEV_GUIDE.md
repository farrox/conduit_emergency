# Conduit CLI - Emergency Rapid Development Guide

**For LLM-Assisted Development**

This is a standalone emergency copy of the Conduit CLI for rapid development. All essential files have been copied here for quick iteration without accessing the main repository.

## 🚨 Emergency Context

This folder contains a **complete, working copy** of the Conduit CLI that can be used for:
- Rapid development and testing
- Emergency fixes
- Non-technical user deployment
- Standalone development without the main repo

## 📁 What's Included

### Essential Files
- **Source Code**: All Go files (`main.go`, `cmd/`, `internal/`)
- **Build System**: `Makefile`, `go.mod`, `go.sum`
- **Documentation**: `README.md`, `SETUP-GUIDE.md`, `INSTALL-GO.md`
- **Config Files**: `psiphon_config.json` (real config), `psiphon_config.example.json`
- **Helper Scripts**: `find-psiphon-config.sh`, `extract-ios-config.sh`
- **Built Binary**: `dist/conduit` (ready to run if Go 1.24.x is available)

### What's NOT Included (Will Be Generated)
- `psiphon-tunnel-core/` - Cloned via `make setup` (required dependency)
- `data/` - Runtime data directory (created on first run)

## ⚡ Quick Start (For Non-Technical Users)

### If Binary Already Exists (Fastest)

```bash
cd /Users/ed/Developer/conduit_emergency

# Run immediately (if binary exists)
./dist/conduit start --psiphon-config ./psiphon_config.json
```

### If You Need to Build

```bash
cd /Users/ed/Developer/conduit_emergency

# Ensure Go 1.24.x is in PATH
export PATH="/usr/local/opt/go@1.24/bin:$PATH"

# Setup dependencies (clones psiphon-tunnel-core)
make setup

# Build
make build

# Run
./dist/conduit start --psiphon-config ./psiphon_config.json
```

## 🔧 For LLM Development Assistants

### Project Structure

```
conduit_emergency/
├── main.go                    # Entry point
├── cmd/                       # CLI commands
│   ├── root.go               # Root command setup
│   └── start.go              # Start command implementation
├── internal/                  # Internal packages
│   ├── conduit/              # Core service logic
│   │   └── service.go
│   ├── config/               # Configuration handling
│   │   ├── config.go
│   │   ├── embedded.go       # Embedded config support
│   │   └── embedded_none.go
│   └── crypto/               # Cryptographic operations
│       └── crypto.go
├── Makefile                   # Build system
├── go.mod                     # Go module definition
├── go.sum                     # Dependency checksums
├── psiphon_config.json        # Real Psiphon config (REQUIRED)
├── dist/conduit               # Built binary (if exists)
└── README.md                  # User documentation
```

### Key Technical Details

1. **Go Version**: **MUST be Go 1.24.x** (Go 1.25+ breaks psiphon-tls)
   - Check: `go version`
   - Install: `brew install go@1.24`
   - PATH: `/usr/local/opt/go@1.24/bin`

2. **Dependencies**: Requires `psiphon-tunnel-core` repository
   - Cloned automatically by `make setup`
   - Branch: `staging-client`
   - Location: `./psiphon-tunnel-core/`

3. **Build Tags**: Uses `PSIPHON_ENABLE_INPROXY` tag
   - Required for inproxy functionality
   - Set in Makefile

4. **Config File**: `psiphon_config.json` is REQUIRED
   - Contains Psiphon network connection parameters
   - Real config is included (copied from installed app)
   - Example config exists but won't work

### Common Development Tasks

#### Modify CLI Commands
- Edit `cmd/start.go` for start command logic
- Edit `cmd/root.go` for root command setup

#### Modify Core Service
- Edit `internal/conduit/service.go` for service logic

#### Modify Configuration Handling
- Edit `internal/config/config.go` for config parsing
- Edit `internal/config/embedded.go` for embedded config

#### Add New Features
1. Add Go files in appropriate `internal/` subdirectory
2. Update `go.mod` if adding external dependencies
3. Run `make build` to test
4. Test with: `./dist/conduit start --psiphon-config ./psiphon_config.json`

### Testing Workflow

```bash
# 1. Make changes to source code

# 2. Build
export PATH="/usr/local/opt/go@1.24/bin:$PATH"
make build

# 3. Test help
./dist/conduit --help

# 4. Test start (dry run - will fail without network, but tests binary)
./dist/conduit start --psiphon-config ./psiphon_config.json -v

# 5. Check for errors
```

### Build Commands

```bash
# Setup dependencies (first time or after clean)
make setup

# Build for current platform
make build

# Build with embedded config (single binary)
make build-embedded PSIPHON_CONFIG=./psiphon_config.json

# Clean build artifacts
make clean

# Clean everything including dependencies
make clean-all
```

### Runtime Options

```bash
# Basic start
./dist/conduit start --psiphon-config ./psiphon_config.json

# With custom limits
./dist/conduit start \
  --psiphon-config ./psiphon_config.json \
  --max-clients 500 \
  --bandwidth 10

# Verbose logging
./dist/conduit start --psiphon-config ./psiphon_config.json -v

# Debug logging
./dist/conduit start --psiphon-config ./psiphon_config.json -vv

# Custom data directory
./dist/conduit start \
  --psiphon-config ./psiphon_config.json \
  --data-dir /path/to/data
```

## 🐛 Troubleshooting

### "Go 1.24.x not found"
```bash
export PATH="/usr/local/opt/go@1.24/bin:$PATH"
go version  # Verify
```

### "psiphon-tunnel-core not found"
```bash
make setup  # Clones the dependency
```

### "Error: Go 1.25+ detected"
You need Go 1.24.x specifically. Install:
```bash
brew install go@1.24
export PATH="/usr/local/opt/go@1.24/bin:$PATH"
```

### Build Fails
```bash
make clean
make setup
make build
```

### Binary Not Found
```bash
# Build it
export PATH="/usr/local/opt/go@1.24/bin:$PATH"
make setup
make build
```

## 📝 Important Notes for LLMs

1. **This is a standalone copy** - Changes here don't affect the main repo
2. **Config file is real** - `psiphon_config.json` contains actual credentials
3. **Binary may be outdated** - Rebuild with `make build` after code changes
4. **Dependencies must be cloned** - Run `make setup` if `psiphon-tunnel-core/` is missing
5. **Go version is critical** - Must be 1.24.x, not 1.25+
6. **Data directory is runtime** - `./data/` is created on first run, contains keys

## 🎯 Common Development Patterns

### Adding a New CLI Flag
1. Edit `cmd/start.go` - Add flag definition
2. Edit `internal/conduit/service.go` - Use flag value
3. Build: `make build`
4. Test: `./dist/conduit start --psiphon-config ./psiphon_config.json --new-flag value`

### Modifying Service Behavior
1. Edit `internal/conduit/service.go`
2. Build: `make build`
3. Test: `./dist/conduit start --psiphon-config ./psiphon_config.json -v`

### Debugging
- Use `-vv` flag for maximum verbosity
- Check logs for connection issues
- Verify config file is valid JSON
- Ensure network connectivity

## 🔗 Related Files

- **README.md** - User-facing documentation
- **SETUP-GUIDE.md** - Step-by-step setup instructions
- **INSTALL-GO.md** - Go installation guide
- **Makefile** - Build system documentation

## ✅ Verification Checklist

Before deploying or sharing:
- [ ] Binary exists: `ls -lh dist/conduit`
- [ ] Binary works: `./dist/conduit --help`
- [ ] Config exists: `ls -lh psiphon_config.json`
- [ ] Go version correct: `go version` shows 1.24.x
- [ ] Dependencies cloned: `ls -d psiphon-tunnel-core/`
- [ ] Build succeeds: `make build`

---

**Last Updated**: 2026-01-25  
**Source**: Copied from `/Users/ed/Developer/conduit/cli`  
**Purpose**: Emergency rapid development and non-technical deployment  
**Status**: ✅ Fully tested - CLI runs successfully from this directory

### Verification

The CLI has been tested and confirmed working:
- Binary executes: `./dist/conduit --version` ✅
- Service starts: `./dist/conduit start --psiphon-config ./psiphon_config.json` ✅
- Network connection: Successfully connects to Psiphon network ✅
- Data directory: Creates `./data/` with keys ✅

Run `./TEST_RUN_CLI.sh` to verify everything works.
