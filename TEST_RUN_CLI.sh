#!/bin/bash
# Test running CLI from emergency directory

cd /Users/ed/Developer/conduit_emergency

echo "🧪 Testing CLI Run from Emergency Directory"
echo ""

# Test 1: Binary exists and is executable
echo "Test 1: Binary check"
if [ -x "./dist/conduit" ]; then
    echo "  ✅ Binary is executable"
    ./dist/conduit --version
else
    echo "  ❌ Binary not found or not executable"
    exit 1
fi
echo ""

# Test 2: Config file exists
echo "Test 2: Config file check"
if [ -f "./psiphon_config.json" ]; then
    echo "  ✅ Config file exists"
    if python3 -m json.tool ./psiphon_config.json > /dev/null 2>&1; then
        echo "  ✅ Config file is valid JSON"
    else
        echo "  ⚠️  Config file may not be valid JSON"
    fi
else
    echo "  ❌ Config file missing!"
    exit 1
fi
echo ""

# Test 3: Try to start service (briefly)
echo "Test 3: Service initialization"
echo "  Starting service for 2 seconds..."
(./dist/conduit start --psiphon-config ./psiphon_config.json -v > /tmp/conduit_emergency_test.log 2>&1 &)
CLI_PID=$!
sleep 2
kill $CLI_PID 2>/dev/null
wait $CLI_PID 2>/dev/null

if [ -f /tmp/conduit_emergency_test.log ]; then
    LINES=$(wc -l < /tmp/conduit_emergency_test.log)
    if [ "$LINES" -gt 0 ]; then
        echo "  ✅ Service started and produced output ($LINES lines)"
        echo "  First few lines:"
        head -5 /tmp/conduit_emergency_test.log | sed 's/^/    /'
    else
        echo "  ⚠️  Service started but no output"
    fi
else
    echo "  ⚠️  Could not capture service output"
fi
echo ""

# Test 4: Check data directory
echo "Test 4: Data directory"
if [ -d "./data" ]; then
    echo "  ✅ Data directory exists"
    ls -la ./data/ 2>/dev/null | head -5 | sed 's/^/    /'
else
    echo "  ℹ️  Data directory not created (normal if service didn't fully initialize)"
fi
echo ""

echo "✅ CLI run test complete!"
echo ""
echo "To run the service:"
echo "  cd /Users/ed/Developer/conduit_emergency"
echo "  ./dist/conduit start --psiphon-config ./psiphon_config.json"
