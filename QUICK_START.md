# Conduit CLI - Quick Start for Non-Technical Users

**⚠️ For Mac users, see [QUICKSTART_MAC.md](QUICKSTART_MAC.md) for the simplest step-by-step guide!**

**Emergency Deployment Guide**

## 🚀 Fastest Way to Run (If Binary Exists)

```bash
cd /Users/ed/Developer/conduit_emergency
./dist/conduit start --psiphon-config ./psiphon_config.json
```

That's it! The service will start and begin relaying traffic.

## 📋 Step-by-Step (If You Need to Build)

### Step 1: Open Terminal
Open Terminal app on your Mac.

### Step 2: Navigate to Folder
```bash
cd /Users/ed/Developer/conduit_emergency
```

### Step 3: Check if Binary Exists
```bash
ls -lh dist/conduit
```

If you see the file, skip to Step 6.

### Step 4: Install Go (If Needed)
```bash
# Check if Go is installed
go version

# If not installed, install it:
brew install go@1.24

# Add to PATH
export PATH="/usr/local/opt/go@1.24/bin:$PATH"
```

### Step 5: Build
```bash
# Setup dependencies
make setup

# Build
make build
```

### Step 6: Run
```bash
./dist/conduit start --psiphon-config ./psiphon_config.json
```

## 🎛️ Options

### Verbose Output (See What's Happening)
```bash
./dist/conduit start --psiphon-config ./psiphon_config.json -v
```

### Set Maximum Clients
```bash
./dist/conduit start \
  --psiphon-config ./psiphon_config.json \
  --max-clients 500
```

### Set Bandwidth Limit
```bash
./dist/conduit start \
  --psiphon-config ./psiphon_config.json \
  --bandwidth 10
```

## ⚠️ Troubleshooting

### "Permission denied"
```bash
chmod +x dist/conduit
```

### "No such file or directory"
Make sure you're in the right folder:
```bash
cd /Users/ed/Developer/conduit_emergency
pwd  # Should show: /Users/ed/Developer/conduit_emergency
```

### "Command not found: make"
Install Xcode Command Line Tools:
```bash
xcode-select --install
```

### "Go not found"
Install Go:
```bash
brew install go@1.24
export PATH="/usr/local/opt/go@1.24/bin:$PATH"
```

## 📞 Need Help?

See `LLM_DEV_GUIDE.md` for detailed technical information.
