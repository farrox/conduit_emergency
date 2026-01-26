#!/bin/bash
# Test script for Conduit CLI (non-Docker version)
# Tests that the binary works correctly

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "=========================================="
echo "Conduit CLI Test Suite"
echo "=========================================="
echo ""

# Test 1: Check binary exists
echo "Test 1: Checking binary..."
if [ ! -f "./dist/conduit" ]; then
    echo "❌ Binary not found at ./dist/conduit"
    echo "   Run: make build"
    exit 1
fi
echo "✅ Binary found"

# Test 2: Check help command
echo ""
echo "Test 2: Testing help command..."
if ./dist/conduit --help > /dev/null 2>&1; then
    echo "✅ Help command works"
else
    echo "❌ Help command failed"
    exit 1
fi

# Test 3: Check start help
echo ""
echo "Test 3: Testing start help..."
if ./dist/conduit start --help > /dev/null 2>&1; then
    echo "✅ Start help command works"
else
    echo "❌ Start help command failed"
    exit 1
fi

# Test 4: Check config file
echo ""
echo "Test 4: Checking config file..."
if [ ! -f "./psiphon_config.json" ]; then
    echo "⚠️  Config file not found"
    echo "   Run: ./scripts/extract-ios-config.sh"
    echo "   Or get from: info@psiphon.ca"
    exit 1
fi
echo "✅ Config file found"

# Test 5: Test actual start (brief)
echo ""
echo "Test 5: Testing actual start (10 seconds)..."
echo "   Starting Conduit with test settings..."
echo ""

# Backup data if exists, use clean data for test
if [ -d "data" ] && [ -d "data/ca.psiphon.PsiphonTunnel.tunnel-core" ]; then
    echo "   Using existing data directory"
else
    echo "   Creating fresh data directory for test"
    mkdir -p data
fi

# Start in background
./dist/conduit start \
    --psiphon-config ./psiphon_config.json \
    --max-clients 50 \
    --bandwidth 5 \
    -v > /tmp/conduit_test.log 2>&1 &

CONDUIT_PID=$!
echo "   Conduit started (PID: $CONDUIT_PID)"

# Wait and check if it's still running
sleep 10

if ps -p $CONDUIT_PID > /dev/null 2>&1; then
    echo "✅ Conduit is running successfully"
    
    # Check logs for success indicators
    if grep -q "inproxy proxy: running" /tmp/conduit_test.log 2>/dev/null; then
        echo "✅ Inproxy service started"
    fi
    
    if grep -q "Connected to Psiphon network" /tmp/conduit_test.log 2>/dev/null || \
       grep -q "updated server" /tmp/conduit_test.log 2>/dev/null; then
        echo "✅ Connected to Psiphon network"
    fi
    
    # Stop it
    echo "   Stopping Conduit..."
    kill $CONDUIT_PID 2>/dev/null || true
    wait $CONDUIT_PID 2>/dev/null || true
    sleep 1
    
    if ! ps -p $CONDUIT_PID > /dev/null 2>&1; then
        echo "✅ Conduit stopped cleanly"
    else
        echo "⚠️  Conduit may not have stopped cleanly"
    fi
else
    echo "❌ Conduit failed to start or crashed"
    echo ""
    echo "Last 20 lines of log:"
    tail -20 /tmp/conduit_test.log
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ All Tests Passed!"
echo "=========================================="
echo ""
echo "Conduit CLI is working correctly."
echo ""
echo "To run Conduit:"
echo "  ./dist/conduit start --psiphon-config ./psiphon_config.json -v"
echo ""
echo "Or use the optimal configuration:"
echo "  ./scripts/configure-optimal.sh"
echo ""
