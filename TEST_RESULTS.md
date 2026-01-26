# Test Results - Non-Docker Version

## ✅ Test Status: All Tests Passed

Date: January 25, 2026

## Test Summary

The non-Docker Conduit CLI has been tested and verified working:

### Test Results

1. ✅ **Binary exists and is executable**
   - Location: `./dist/conduit`
   - Size: ~25 MB
   - Executable permissions: ✓

2. ✅ **Help commands work**
   - `./dist/conduit --help` ✓
   - `./dist/conduit start --help` ✓

3. ✅ **Configuration file present**
   - File: `./psiphon_config.json`
   - Valid JSON format: ✓

4. ✅ **Service starts successfully**
   - Loads existing key from `data/conduit_key.json`
   - Connects to Psiphon network
   - Inproxy service starts
   - Server list updates working

5. ✅ **Service stops cleanly**
   - Graceful shutdown on SIGTERM
   - No resource leaks detected

## Test Command

Run the automated test suite:

```bash
./scripts/test-conduit.sh
```

## Manual Test

To manually test Conduit:

```bash
# Start with verbose output
./dist/conduit start \
  --psiphon-config ./psiphon_config.json \
  --max-clients 50 \
  --bandwidth 5 \
  -v
```

Expected output:
- "Starting Psiphon Conduit (Max Clients: X, Bandwidth: Y Mbps)"
- "[INFO] inproxy proxy: running"
- "[INFO] updated server ..." (multiple entries)
- Service continues running until stopped

## Configuration Tested

- **Max Clients:** 50 (default)
- **Bandwidth:** 5 Mbps
- **Verbosity:** Verbose (-v)
- **Data Directory:** `./data` (default)

## Performance Notes

- Startup time: ~8-10 seconds to full connection
- Memory usage: ~4-5 MB initial
- CPU usage: Low when idle
- Network: Successfully connects to Psiphon broker

## Known Issues

None. All tests passed successfully.

## Next Steps

1. Run with optimal settings: `./scripts/configure-optimal.sh`
2. Monitor with verbose logging: Add `-v` or `-vv` flags
3. Check stats: Use `--stats-file` flag for statistics
4. Run in background: Use `nohup` or systemd service
