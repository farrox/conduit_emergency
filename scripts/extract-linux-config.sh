#!/bin/bash
# Extract Psiphon config from Linux GUI app

echo "Searching for Psiphon config in Linux GUI app..."

# Common Linux Psiphon config locations
LOCATIONS=(
    "$HOME/.psiphon/psiphon.config"
    "$HOME/.config/psiphon/psiphon.config"
    "$HOME/.local/share/psiphon/psiphon.config"
    "/opt/psiphon/psiphon.config"
)

for CONFIG in "${LOCATIONS[@]}"; do
    if [ -f "$CONFIG" ]; then
        echo "✅ Found config: $CONFIG"
        echo ""
        echo "Copying to psiphon_config.json..."
        cp "$CONFIG" "$(dirname "$0")/../psiphon_config.json"
        echo "✅ Copied to psiphon_config.json"
        exit 0
    fi
done

echo "❌ Config file not found"
echo ""
echo "Make sure you have the Psiphon Linux GUI app installed and have run it at least once."
echo ""
echo "Checked locations:"
for CONFIG in "${LOCATIONS[@]}"; do
    echo "  - $CONFIG"
done
echo ""
echo "Alternative: Email Psiphon at info@psiphon.ca for a config file."
exit 1
