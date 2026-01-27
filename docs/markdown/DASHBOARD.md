# Live Dashboard

One dashboard works for **Docker** and **native** Conduit: real-time monitoring in the same style as Option 1 (Docker) and Option 2 (DMG).

![Live Dashboard Screenshot](../resources/dashboard.png)

*Connected users, CPU/RAM, and traffic in real time. Auto-detects Docker (conduit-mac container) or native process.*

## Quick Start

### View dashboard (Conduit already running)

Works for **Docker** or **native**. Run in the same or another terminal:

```bash
./scripts/dashboard.sh
```

### Start Conduit + dashboard (from source)

**Option A — two terminals (recommended):**
```bash
./scripts/start-with-dashboard.sh
```
Starts Conduit with stats and opens the dashboard in a new terminal.

**Option B — one terminal (Option 2–style):**
```bash
./scripts/test-option2-dashboard.sh
```
Starts Conduit and runs the dashboard in the same window. Ctrl+C stops both.

### Manual start, then dashboard

1. Start Conduit with stats (e.g. `./dist/conduit start -v --stats-file -d ~/.conduit/data` or use Docker menu).
2. Run `./scripts/dashboard.sh` in another terminal.

## Dashboard Features

The dashboard displays:

- **Status**: Online/Offline (and “Docker” when using the container)
- **Uptime**: How long Conduit has been running
- **CPU**: CPU usage
- **RAM**: Memory usage
- **Users**: Connected users
- **Up** / **Down**: Upload and download traffic

The dashboard auto-refreshes every 5 seconds.

## Enabling Stats

For the dashboard to show accurate statistics, start Conduit with the `--stats-file` flag:

```bash
./dist/conduit start \
  --psiphon-config ./psiphon_config.json \
  -v \
  --stats-file
```

This creates a `stats.json` file in the data directory that the dashboard reads.

## Using Optimal Configuration

The optimal configuration script now automatically enables stats:

```bash
./scripts/configure-optimal.sh
```

This creates a launcher that includes `--stats-file`, so the dashboard will work automatically.

## One Dashboard for Docker and Native

`./scripts/dashboard.sh` auto-detects how Conduit is running:

| Running as | How dashboard gets data |
|------------|-------------------------|
| **Docker** (conduit-mac container) | `docker stats` + container logs |
| **Native** (conduit process) | Process stats + `~/.conduit/data/stats.json` or log parsing |

Same layout and refresh (5 seconds) in both cases.

## Troubleshooting

### "Stats file not found"
- Make sure you started Conduit with `--stats-file` flag
- Wait a few seconds after starting - stats file is created when first stats are recorded
- Check: `ls -la data/stats.json`

### "Conduit is not running"
- Start Conduit first (Docker: `./scripts/conduit-manager-mac.sh`; native: `./scripts/test-option2-dashboard.sh` or `./scripts/start-with-dashboard.sh`)

### Stats showing 0
- Stats are only updated when there's activity
- Wait for Iranians to connect
- Check that Conduit is connected: Look for "[OK] Connected to Psiphon network" in logs

## Keyboard Shortcuts

- **Ctrl+C**: Exit dashboard
- Dashboard will continue refreshing until you press Ctrl+C

## Example Output

```
  ██████╗ ██████╗ ███╗   ██╗██████╗ ██╗   ██╗██╗████████╗
 ██╔════╝██╔═══██╗████╗  ██║██╔══██╗██║   ██║██║╚══██╔══╝
 ██║     ██║   ██║██╔██╗ ██║██║  ██║██║   ██║██║   ██║   
 ██║     ██║   ██║██║╚██╗██║██║  ██║██║   ██║██║   ██║   
 ╚██████╗╚██████╔╝██║ ╚████║██████╔╝╚██████╔╝██║   ██║   
  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝  ╚═════╝ ╚═╝   ╚═╝   
              Live Dashboard                  

LIVE DASHBOARD (Press Ctrl+C to exit)
══════════════════════════════════════════════════════
 STATUS:      ● ONLINE
 UPTIME:      5:23
──────────────────────────────────────────────────────
 RESOURCES    | TRAFFIC
──────────────────────────────────────────────────────
 CPU: 2.5%    | Users:  15
 RAM: 12.3M    | Up:   1.2MB
              | Down: 3.4MB
══════════════════════════════════════════════════════
Refreshing every 5 seconds...
```

---

**Enjoy monitoring your Conduit node in real-time!** 🎉
