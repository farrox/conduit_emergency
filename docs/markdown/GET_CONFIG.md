# Getting Your Psiphon Config - No Email Required!

## Why the GUI Works Without Email

The **GUI apps** (iOS, Windows, Linux) have the `psiphon_config.json` **embedded or stored locally** when they're built/installed. That's why you can run them without emailing Psiphon - the config is already included!

## How to Get Config for CLI (Easy Ways)

### Option 1: Extract from Psiphon GUI Apps (Easiest - No Email!)

If you have any Psiphon GUI app installed, you can extract the config:

**Mac (from iOS app):**
```bash
./scripts/extract-ios-config.sh
```
Finds config from:
- iOS Simulator apps (`~/Library/Developer/CoreSimulator/Devices`)
- Xcode DerivedData
- iOS app bundles

**Windows (from Windows GUI app):**
```powershell
.\scripts\extract-windows-config.ps1
```
Finds config from:
- `%LOCALAPPDATA%\Psiphon3\psiphon.config`
- `%APPDATA%\Psiphon3\psiphon.config`

**Linux (from Linux GUI app):**
```bash
./scripts/extract-linux-config.sh
```
Finds config from:
- `~/.psiphon/psiphon.config`
- `~/.config/psiphon/psiphon.config`
- `~/.local/share/psiphon/psiphon.config`

### Option 2: Use Embedded Config in Build

Build the CLI with the config embedded (just like the iOS app):

```bash
# First, get the config (Option 1 above, or from Psiphon)
# Then build with embedded config
make build-embedded PSIPHON_CONFIG=./psiphon_config.json
```

Now the binary includes the config - no file needed at runtime!

### Option 3: Email Psiphon (Only if Options 1 & 2 Don't Work)

If you don't have any Psiphon GUI app installed and need a fresh config:
- Email: **info@psiphon.ca**
- Subject: Request for Conduit CLI Configuration

## Quick Start (Recommended)

1. **Extract from any GUI app** (if you have it):
   ```bash
   # Mac
   ./scripts/extract-ios-config.sh
   
   # Windows
   .\scripts\extract-windows-config.ps1
   
   # Linux
   ./scripts/extract-linux-config.sh
   ```

2. **Or build with embedded config**:
   ```bash
   # Get config first (extract or email)
   make build-embedded PSIPHON_CONFIG=./psiphon_config.json
   ```

3. **Run without needing the file**:
   ```bash
   ./dist/conduit start  # Config is embedded!
   ```

## Why This Works

The GUI app developers embed the config at **build time** or store it locally after first run, so users never need to manage it. You can do the same for the CLI by:

1. Extracting the config from any GUI app (if available)
2. Building with `make build-embedded`
3. Distributing the binary with config already included

This makes the CLI as easy to use as the GUI!

## Creating a DMG with Embedded Config

For distribution, create a DMG with embedded config:

```bash
# Get config first (from any platform's GUI app)
./scripts/extract-ios-config.sh         # Mac
./scripts/extract-windows-config.ps1    # Windows  
./scripts/extract-linux-config.sh       # Linux

# Create DMG with embedded config
./scripts/create-dmg.sh ./psiphon_config.json
```

The DMG will include a binary that works without any config file - just like the GUI apps!
