# Conduit Web Dashboard

Web-based dashboard for monitoring your Conduit node in real-time.

## Quick Start

### 1. Install Dependencies

```bash
cd dashboard
npm install
```

### 2. Configure

Copy `.env.example` to `.env` and edit if needed:

```bash
cp .env.example .env
```

Default settings:
- Port: 3000
- Password: `changeme` (change this!)
- Data directory: `../data` (where stats.json is located)

### 3. Start Dashboard

```bash
# From dashboard directory
npm start

# Or from project root
./scripts/start-dashboard.sh
```

### 4. Access Dashboard

Open your browser:
- URL: http://localhost:3000
- Password: `changeme` (or whatever you set in `.env`)

## Features

- ✅ Real-time stats (clients, traffic, uptime)
- ✅ Historical charts (24h traffic and clients)
- ✅ Process monitoring (CPU/RAM)
- ✅ SQLite database for history
- ✅ Cumulative stats tracking (survives restarts)

## Requirements

- Node.js 18+ (check with `node --version`)
- Conduit running with `--stats-file` flag
- `data/stats.json` file (created automatically when Conduit runs)

## Usage

### Start Conduit with Stats

```bash
./dist/conduit start \
  --psiphon-config ./psiphon_config.json \
  -v \
  --stats-file
```

### Start Dashboard

```bash
./scripts/start-dashboard.sh
```

Or manually:

```bash
cd dashboard
node server.js
```

## Configuration

Edit `dashboard/.env`:

```env
PORT=3000
DASHBOARD_PASSWORD=your-secure-password
SESSION_SECRET=random-secret-here
CONDUIT_DATA_DIR=../data
```

## Troubleshooting

### "Stats file not found"
- Make sure Conduit is running with `--stats-file` flag
- Check that `data/stats.json` exists
- Wait a few seconds after starting Conduit

### "Cannot read stats"
- Check file permissions
- Verify JSON format: `cat data/stats.json | python3 -m json.tool`

### Dashboard won't start
- Check Node.js: `node --version`
- Install dependencies: `npm install`
- Check port 3000 is available: `lsof -i :3000`

## Development

```bash
# Watch mode (auto-restart on changes)
npm run dev

# Production
npm start
```

## API Endpoints

- `GET /api/stats` - Current stats
- `GET /api/history?hours=24` - Historical data
- `GET /api/offsets` - View cumulative offsets
- `POST /api/offsets/reset` - Reset offsets
- `POST /api/stats/clear` - Clear all stats

All endpoints require authentication (login first).

---

**Note**: This is a single-node dashboard. For fleet management, see the full web dashboard implementation.
