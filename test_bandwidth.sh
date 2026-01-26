#!/bin/bash
# Simple bandwidth test

echo "🌐 Testing your internet bandwidth..."
echo "This will take about 10-15 seconds..."
echo ""

# Try multiple test servers
TEST_SERVERS=(
    "http://ipv4.download.thinkbroadband.com/10MB.zip"
    "http://212.183.159.230/10MB.zip"
    "https://proof.ovh.net/files/10Mb.dat"
)

BEST_SPEED=0

for SERVER in "${TEST_SERVERS[@]}"; do
    echo "Testing with: $(echo $SERVER | cut -d'/' -f3)"
    START=$(date +%s.%N)
    BYTES=$(curl -s --max-time 15 -o /dev/null -w '%{size_download}' "$SERVER" 2>&1)
    END=$(date +%s.%N)
    
    if [ -n "$BYTES" ] && [ "$BYTES" -gt 1000000 ] 2>/dev/null; then
        DURATION=$(python3 -c "print($END - $START)" 2>/dev/null || echo "1")
        MBPS=$(python3 -c "print(round($BYTES * 8 / $DURATION / 1000000, 2))" 2>/dev/null)
        if [ -n "$MBPS" ]; then
            echo "  Result: ${MBPS} Mbps"
            if (( $(echo "$MBPS > $BEST_SPEED" | bc -l 2>/dev/null || echo "0") )); then
                BEST_SPEED=$MBPS
            fi
        fi
    fi
done

if (( $(echo "$BEST_SPEED > 0" | bc -l 2>/dev/null || echo "0") )); then
    HALF=$(python3 -c "print(round($BEST_SPEED / 2, 1))" 2>/dev/null)
    echo ""
    echo "✅ Best result: ${BEST_SPEED} Mbps"
    echo "📊 Half capacity: ${HALF} Mbps"
    echo "$HALF"
else
    echo ""
    echo "⚠️  Could not measure bandwidth accurately"
    echo "Using conservative default: 20 Mbps"
    echo "20"
fi
