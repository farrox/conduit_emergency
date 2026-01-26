# Conduit CLI - Emergency Deployment Package

**Standalone, ready-to-use CLI for rapid development and deployment**

## 📦 What This Is

This is a **complete, standalone copy** of the Conduit CLI that has been extracted from the main repository for emergency use. Everything needed to run, build, and develop is included.

## ✅ What's Ready

- ✅ **Built binary** (`dist/conduit`) - Ready to run immediately
- ✅ **Real config file** (`psiphon_config.json`) - Actual Psiphon network configuration
- ✅ **All source code** - Complete Go source for modifications
- ✅ **Build system** - Makefile and Go modules ready
- ✅ **Documentation** - Comprehensive guides for users and developers

## 🚀 Quick Start

### For Non-Technical Users

See **[QUICK_START.md](QUICK_START.md)** for simple step-by-step instructions.

### For Developers / LLMs

See **[LLM_DEV_GUIDE.md](LLM_DEV_GUIDE.md)** for comprehensive development information.

## 📁 File Structure

```
conduit_emergency/
├── dist/
│   └── conduit              # Built binary (ready to run)
├── cmd/                     # CLI commands
├── internal/                 # Core service logic
├── main.go                  # Entry point
├── go.mod, go.sum          # Go dependencies
├── Makefile                 # Build system
├── psiphon_config.json      # Real Psiphon config (REQUIRED)
├── psiphon_config.example.json  # Example template
├── README.md                # Original user docs
├── SETUP-GUIDE.md           # Setup instructions
├── INSTALL-GO.md            # Go installation guide
├── LLM_DEV_GUIDE.md         # LLM development guide ⭐
├── QUICK_START.md           # Quick start for users
├── TEST_EMERGENCY_SETUP.sh  # Test script
└── Helper scripts...
```

## ⚡ Fastest Way to Run

```bash
cd /Users/ed/Developer/conduit_emergency
./dist/conduit start --psiphon-config ./psiphon_config.json
```

## 🔧 If You Need to Build

```bash
cd /Users/ed/Developer/conduit_emergency

# Ensure Go 1.24.x is in PATH
export PATH="/usr/local/opt/go@1.24/bin:$PATH"

# Setup (clones dependencies)
make setup

# Build
make build

# Run
./dist/conduit start --psiphon-config ./psiphon_config.json
```

## 📚 Documentation

- **[QUICK_START.md](QUICK_START.md)** - Simple guide for non-technical users
- **[LLM_DEV_GUIDE.md](LLM_DEV_GUIDE.md)** - Comprehensive guide for LLM-assisted development
- **[README.md](README.md)** - Original CLI documentation
- **[SETUP-GUIDE.md](SETUP-GUIDE.md)** - Detailed setup walkthrough
- **[INSTALL-GO.md](INSTALL-GO.md)** - Go installation instructions

## ✅ Verification

Run the test script to verify everything works:

```bash
./TEST_EMERGENCY_SETUP.sh
```

## 🎯 Use Cases

1. **Emergency Deployment** - Quick deployment without accessing main repo
2. **Rapid Development** - Fast iteration and testing
3. **Non-Technical Users** - Standalone package with clear instructions
4. **LLM Development** - Complete context for AI-assisted coding
5. **Testing** - Isolated environment for testing changes

## ⚠️ Important Notes

1. **This is a standalone copy** - Changes here don't affect the main repository
2. **Config is real** - `psiphon_config.json` contains actual credentials
3. **Go version matters** - Must be Go 1.24.x (not 1.25+)
4. **Dependencies** - `psiphon-tunnel-core/` will be cloned by `make setup` if needed
5. **Data directory** - `./data/` is created on first run (contains keys)

## 🔗 Requirements

- **Go 1.24.x** (required for building, not needed if binary exists)
- **Make** (usually pre-installed on macOS)
- **Git** (for cloning dependencies via `make setup`)

## 📞 Quick Reference

```bash
# Test setup
./TEST_EMERGENCY_SETUP.sh

# Run (if binary exists)
./dist/conduit start --psiphon-config ./psiphon_config.json

# Build (if needed)
export PATH="/usr/local/opt/go@1.24/bin:$PATH"
make setup && make build

# Help
./dist/conduit --help
./dist/conduit start --help
```

---

**Created**: 2026-01-25  
**Source**: `/Users/ed/Developer/conduit/cli`  
**Status**: ✅ Fully tested and verified working

### ✅ Tested and Verified

The CLI has been **fully tested** from this emergency directory:
- ✅ Binary executes correctly
- ✅ Config file loads successfully  
- ✅ Service starts and initializes
- ✅ Connects to Psiphon network
- ✅ Creates data directory with keys
- ✅ Fetches server lists successfully

**Test script**: Run `./TEST_RUN_CLI.sh` to verify everything works.
