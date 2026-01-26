#!/bin/bash
# Emergency Setup Test Script

echo "🧪 Testing Emergency CLI Setup"
echo ""

cd /Users/ed/Developer/conduit_emergency

# Test 1: Binary exists and is executable
echo "Test 1: Binary exists"
if [ -f "dist/conduit" ]; then
    echo "  ✅ Binary found"
    if [ -x "dist/conduit" ]; then
        echo "  ✅ Binary is executable"
    else
        echo "  ⚠️  Binary not executable (fixing...)"
        chmod +x dist/conduit
    fi
else
    echo "  ⚠️  Binary not found (will need to build)"
fi
echo ""

# Test 2: Config file exists
echo "Test 2: Config file exists"
if [ -f "psiphon_config.json" ]; then
    echo "  ✅ Config file found"
    SIZE=$(wc -c < psiphon_config.json)
    if [ "$SIZE" -gt 1000 ]; then
        echo "  ✅ Config file looks valid (${SIZE} bytes)"
    else
        echo "  ⚠️  Config file seems small (${SIZE} bytes)"
    fi
else
    echo "  ❌ Config file missing!"
fi
echo ""

# Test 3: Go is available
echo "Test 3: Go version"
export PATH="/usr/local/opt/go@1.24/bin:$PATH"
if command -v go &> /dev/null; then
    GO_VERSION=$(go version 2>&1 | head -1)
    echo "  ✅ Go found: $GO_VERSION"
    if echo "$GO_VERSION" | grep -q "go1.24"; then
        echo "  ✅ Correct version (1.24.x)"
    else
        echo "  ⚠️  Wrong version (need 1.24.x)"
    fi
else
    echo "  ⚠️  Go not found in PATH"
fi
echo ""

# Test 4: Binary help works
echo "Test 4: Binary functionality"
if [ -f "dist/conduit" ] && [ -x "dist/conduit" ]; then
    if ./dist/conduit --help &> /dev/null; then
        echo "  ✅ Binary works (help command succeeds)"
    else
        echo "  ⚠️  Binary may be corrupted"
    fi
else
    echo "  ⏭️  Skipped (binary not available)"
fi
echo ""

# Test 5: Documentation exists
echo "Test 5: Documentation"
DOCS=0
for doc in README.md SETUP-GUIDE.md INSTALL-GO.md LLM_DEV_GUIDE.md QUICK_START.md; do
    if [ -f "$doc" ]; then
        DOCS=$((DOCS + 1))
    fi
done
echo "  ✅ Found $DOCS documentation files"
echo ""

# Test 6: Source files
echo "Test 6: Source files"
if [ -f "main.go" ] && [ -f "go.mod" ] && [ -f "Makefile" ]; then
    echo "  ✅ Essential source files present"
else
    echo "  ❌ Missing source files!"
fi
echo ""

echo "✅ Test complete!"
echo ""
echo "Next steps:"
if [ ! -f "dist/conduit" ]; then
    echo "  1. Build: make setup && make build"
fi
echo "  2. Run: ./dist/conduit start --psiphon-config ./psiphon_config.json"
