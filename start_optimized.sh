#!/bin/bash
# Start Conduit CLI with optimized settings (max clients, half bandwidth)

cd /Users/ed/Developer/conduit_emergency

echo "🌐 Testing bandwidth with Ookla Speedtest..."
echo ""

# Run official Ookla Speedtest
speedtest --accept-license --format=json --progress=no > /tmp/speedtest_result.json 2>&1

# Parse results
BANDWIDTH_HALF=$(cat /tmp/speedtest_result.json | python3 -c "
import sys, json
content = sys.stdin.read()
lines = content.split('\n')
json_line = None
for line in lines:
    if line.strip().startswith('{'):
        json_line = line
        break
if json_line:
    data = json.loads(json_line)
    dl = round(data.get('download', {}).get('bandwidth', 0) / 1000000, 2)
    half = round(dl / 2, 1)
    print(f'{half}')
else:
    print('20')
" 2>/dev/null)

if [ -z "$BANDWIDTH_HALF" ] || [ "$BANDWIDTH_HALF" = "0" ]; then
    BANDWIDTH_HALF=20
    echo "⚠️  Using default: ${BANDWIDTH_HALF} Mbps"
else
    echo "✅ Download speed: $(cat /tmp/speedtest_result.json | python3 -c "import sys, json; content=sys.stdin.read(); lines=content.split('\n'); json_line=[l for l in lines if l.strip().startswith('{')][0]; data=json.loads(json_line); print(round(data.get('download', {}).get('bandwidth', 0) / 1000000, 2))" 2>/dev/null) Mbps"
    echo "📊 Half capacity: ${BANDWIDTH_HALF} Mbps"
fi

MAX_CLIENTS=1000

echo ""
echo "🚀 Starting Conduit CLI with:"
echo "  Max clients: ${MAX_CLIENTS} (maximum)"
echo "  Bandwidth: ${BANDWIDTH_HALF} Mbps"
echo ""
echo "Press Ctrl+C to stop"
echo ""

./dist/conduit start \
  --psiphon-config ./psiphon_config.json \
  --max-clients ${MAX_CLIENTS} \
  --bandwidth ${BANDWIDTH_HALF} \
  -v
