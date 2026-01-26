# Quick Start for Mac Users

**Get Conduit running in 5 minutes - no technical knowledge needed!**

## Step 1: Download or Clone

### Option A: Download DMG (Easiest)
1. Download the `Conduit.dmg` file
2. Double-click the DMG to open it
3. Drag "Conduit" to your Applications folder
4. Skip to Step 3

### Option B: Clone from GitHub
1. Open Terminal (press `Cmd + Space`, type "Terminal", press Enter)
2. Copy and paste this command:
   ```bash
   git clone https://github.com/farrox/conduit_emergency.git
   cd conduit_emergency
   ```
3. Press Enter

## Step 2: Get Your Config File (No Email Needed!)

The config file connects you to the Psiphon network. Here's the easiest way:

### If You Have the iOS Conduit App:
1. In Terminal, type this and press Enter:
   ```bash
   ./extract-ios-config.sh
   ```
2. If it says "✅ Copied!", you're done! Skip to Step 3.

### If You Don't Have the iOS App:
1. You'll need to get the config file from Psiphon
2. Email: **info@psiphon.ca**
3. Subject: "Request for Conduit CLI Configuration"
4. Save the file they send you as `psiphon_config.json` in the project folder

## Step 3: Run the Setup Script

In Terminal, type this and press Enter:

```bash
./scripts/easy-setup.sh
```

**What this does:**
- Installs everything you need (if not already installed)
- Builds the Conduit program
- Creates a launcher you can double-click

**Just wait for it to finish** - it will tell you when it's done.

## Step 4: Start Conduit

You have two easy options:

### Option A: Double-Click (Easiest)
1. Look in the project folder for `Start Conduit.command`
2. Double-click it
3. A Terminal window will open and Conduit will start running

### Option B: Terminal Command
1. In Terminal, type:
   ```bash
   ./dist/conduit start --psiphon-config ./psiphon_config.json
   ```
2. Press Enter

## Step 5: Configure Optimal Settings (Optional but Recommended)

To get the most users with your internet speed:

1. In Terminal, type:
   ```bash
   ./scripts/configure-optimal.sh
   ```
2. Follow the prompts - it will:
   - Test your internet speed
   - Calculate the best settings
   - Create a launcher with optimal settings

3. Then use the new launcher: `Start Conduit (Optimal).command`

## That's It!

Conduit is now running and helping users in censored regions access the internet.

### To Stop Conduit:
- Press `Ctrl + C` in the Terminal window, or
- Close the Terminal window

### To Start Again Later:
- Just double-click `Start Conduit.command` (or `Start Conduit (Optimal).command` if you configured it)

## Troubleshooting

### "Permission denied"
In Terminal, type:
```bash
chmod +x scripts/*.sh
chmod +x extract-ios-config.sh
```

### "Command not found: make"
Install Xcode Command Line Tools:
1. In Terminal, type: `xcode-select --install`
2. Click "Install" when prompted
3. Wait for it to finish, then try again

### "Config file not found"
Make sure you completed Step 2. Run:
```bash
./scripts/check-config.sh
```
This will help you find or get the config file.

### "Binary not found"
Run the setup script again:
```bash
./scripts/easy-setup.sh
```

## Need More Help?

- See [GET_CONFIG.md](GET_CONFIG.md) for detailed config instructions
- See [CONFIG_OPTIMAL.md](CONFIG_OPTIMAL.md) for optimal settings guide
- See [README.md](README.md) for full documentation
