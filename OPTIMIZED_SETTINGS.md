# Optimized CLI Settings

## Current Configuration

- **Max Clients**: 1000 (maximum allowed)
- **Bandwidth**: 15.5 Mbps (half of your tested internet capacity: 31.0 Mbps)

## Bandwidth Test Results

Tested on: 2026-01-25 using Ookla Speedtest (official)
- **Download Speed**: 31.0 Mbps
- **Upload Speed**: 10.45 Mbps
- **Ping**: 8 ms
- **Half Capacity**: 15.5 Mbps → **Set to 15.5 Mbps**

## Service Status

The CLI is currently running with these optimized settings.

### View Logs
```bash
tail -f /tmp/conduit_optimized.log
```

### Stop Service
```bash
pkill -f 'conduit start'
```

### Restart with Optimized Settings
```bash
cd /Users/ed/Developer/conduit_emergency
./start_optimized.sh
```

This script will automatically:
1. Run Ookla Speedtest to measure your bandwidth
2. Calculate half capacity
3. Start CLI with max clients (1000) and optimized bandwidth

Or manually:
```bash
cd /Users/ed/Developer/conduit_emergency
./dist/conduit start \
  --psiphon-config ./psiphon_config.json \
  --max-clients 1000 \
  --bandwidth 15.5 \
  -v
```

## Re-testing Bandwidth

The `start_optimized.sh` script automatically tests bandwidth each time you run it using the official Ookla Speedtest.

To manually test:
```bash
speedtest --accept-license --format=json --progress=no
```

---

**Note**: The bandwidth setting (15.5 Mbps) is half of your tested capacity to ensure stable performance while leaving bandwidth for your own use.
