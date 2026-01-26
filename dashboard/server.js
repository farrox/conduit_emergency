import 'dotenv/config';
import express from 'express';
import session from 'express-session';
import { existsSync, readFileSync, writeFileSync } from 'fs';
import { dirname, join } from 'path';
import initSqlJs from 'sql.js';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __dirname = dirname(fileURLToPath(import.meta.url));
const app = express();
const PORT = process.env.PORT || 3000;
const PASSWORD = process.env.DASHBOARD_PASSWORD || 'changeme';
const CONDUIT_DATA_DIR = process.env.CONDUIT_DATA_DIR || join(__dirname, '..', 'data');
const STATS_FILE = join(CONDUIT_DATA_DIR, 'stats.json');
const DB_PATH = join(__dirname, 'data', 'stats.db');

// Initialize SQLite database
let db;
async function initDb() {
  const SQL = await initSqlJs();
  if (existsSync(DB_PATH)) {
    db = new SQL.Database(readFileSync(DB_PATH));
  } else {
    db = new SQL.Database();
  }
  // Stats table stores cumulative values
  db.run(`
    CREATE TABLE IF NOT EXISTS stats (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      timestamp INTEGER NOT NULL,
      status TEXT,
      clients INTEGER DEFAULT 0,
      upload_bytes INTEGER DEFAULT 0,
      download_bytes INTEGER DEFAULT 0,
      uptime TEXT
    )
  `);
  // Offsets track cumulative totals across restarts
  db.run(`
    CREATE TABLE IF NOT EXISTS offsets (
      upload_offset INTEGER DEFAULT 0,
      download_offset INTEGER DEFAULT 0,
      last_upload INTEGER DEFAULT 0,
      last_download INTEGER DEFAULT 0
    )
  `);
  db.run(`CREATE INDEX IF NOT EXISTS idx_stats_timestamp ON stats(timestamp)`);
  saveDb();
}

function saveDb() {
  if (db) {
    const dbDir = dirname(DB_PATH);
    if (!existsSync(dbDir)) {
      execSync(`mkdir -p "${dbDir}"`, { encoding: 'utf8' });
    }
    writeFileSync(DB_PATH, Buffer.from(db.export()));
  }
}

// Get offset record
function getOffset() {
  const stmt = db.prepare(`SELECT upload_offset, download_offset, last_upload, last_download FROM offsets LIMIT 1`);
  let offset = { upload_offset: 0, download_offset: 0, last_upload: 0, last_download: 0 };
  if (stmt.step()) offset = stmt.getAsObject();
  stmt.free();
  return offset;
}

// Parse bytes from string
function parseBytes(str) {
  if (!str || str === 'N/A' || typeof str === 'number') return str || 0;
  const match = String(str).match(/^([\d.]+)\s*([KMGTPE]?B?)$/i);
  if (!match) return 0;
  const units = { B: 1, KB: 1024, MB: 1024**2, GB: 1024**3, TB: 1024**4 };
  return Math.round(parseFloat(match[1]) * (units[(match[2] || 'B').toUpperCase()] || 1));
}

// Format bytes for display
function formatBytes(bytes) {
  if (bytes === 0) return '0 B';
  const i = Math.floor(Math.log(bytes) / Math.log(1024));
  return (bytes / Math.pow(1024, i)).toFixed(1) + ' ' + ['B', 'KB', 'MB', 'GB', 'TB'][i];
}

// Get Conduit process info
function getConduitProcess() {
  try {
    // Try to find conduit process
    const output = execSync('ps aux | grep "[.]/dist/conduit start" | grep -v grep | head -1', { encoding: 'utf8' });
    if (output.trim()) {
      const parts = output.trim().split(/\s+/);
      return {
        pid: parts[1],
        cpu: parseFloat(parts[2]) || 0,
        mem: parseFloat(parts[3]) || 0,
        running: true
      };
    }
  } catch (e) {
    // Process not found
  }
  return { pid: null, cpu: 0, mem: 0, running: false };
}

// Get stats from stats.json
function getConduitStats() {
  const result = {
    name: 'local',
    host: 'localhost',
    status: 'offline',
    clients: 0,
    upload: '0 B',
    download: '0 B',
    uptime: 'N/A',
    error: null,
    maxClients: null,
    bandwidth: null
  };

  // Check if process is running
  const process = getConduitProcess();
  if (!process.running) {
    result.status = 'stopped';
    return result;
  }

  result.status = 'running';

  // Try to read stats.json
  if (existsSync(STATS_FILE)) {
    try {
      const statsData = JSON.parse(readFileSync(STATS_FILE, 'utf8'));
      result.clients = statsData.connectedClients || 0;
      
      const uploadBytes = statsData.totalBytesUp || 0;
      const downloadBytes = statsData.totalBytesDown || 0;
      
      // Get offset for cumulative tracking
      const offset = getOffset();
      
      // Detect reset (service restart)
      const MIN_FOR_RESET = 1024 * 1024; // 1MB
      let newUpOffset = offset.upload_offset;
      let newDownOffset = offset.download_offset;
      
      if (uploadBytes < offset.last_upload * 0.5 && offset.last_upload > MIN_FOR_RESET) {
        newUpOffset += offset.last_upload;
      }
      if (downloadBytes < offset.last_download * 0.5 && offset.last_download > MIN_FOR_RESET) {
        newDownOffset += offset.last_download;
      }
      
      // Calculate cumulative
      const cumulativeUp = newUpOffset + uploadBytes;
      const cumulativeDown = newDownOffset + downloadBytes;
      
      result.upload = formatBytes(cumulativeUp);
      result.download = formatBytes(cumulativeDown);
      
      // Update offsets
      db.run(`INSERT OR REPLACE INTO offsets (upload_offset, download_offset, last_upload, last_download) VALUES (?, ?, ?, ?)`,
        [newUpOffset, newDownOffset, uploadBytes, downloadBytes]);
      
      // Calculate uptime from startTime if available
      if (statsData.startTime) {
        const start = new Date(statsData.startTime);
        const now = new Date();
        const diff = Math.floor((now - start) / 1000);
        const hours = Math.floor(diff / 3600);
        const minutes = Math.floor((diff % 3600) / 60);
        const seconds = diff % 60;
        if (hours > 0) {
          result.uptime = `${hours}h ${minutes}m`;
        } else if (minutes > 0) {
          result.uptime = `${minutes}m ${seconds}s`;
        } else {
          result.uptime = `${seconds}s`;
        }
      }
      
      // Try to get config from process args
      try {
        const psOutput = execSync(`ps aux | grep "[.]/dist/conduit start" | grep -v grep`, { encoding: 'utf8' });
        const mMatch = psOutput.match(/-m\s+(\d+)/);
        const bMatch = psOutput.match(/-b\s+(-?\d+)/);
        if (mMatch) result.maxClients = parseInt(mMatch[1], 10);
        if (bMatch) result.bandwidth = parseInt(bMatch[1], 10);
      } catch (e) {
        // Ignore
      }
      
      saveDb();
    } catch (e) {
      result.error = `Failed to read stats: ${e.message}`;
    }
  } else {
    result.status = 'waiting';
    result.error = 'Stats file not created yet (waiting for first activity)';
  }

  return result;
}

// Save stats to database
function saveStats(stats) {
  const timestamp = Date.now();
  
  // Get current stats from stats.json (not from display format)
  let uploadBytes = 0;
  let downloadBytes = 0;
  
  if (existsSync(STATS_FILE)) {
    try {
      const statsData = JSON.parse(readFileSync(STATS_FILE, 'utf8'));
      uploadBytes = statsData.totalBytesUp || 0;
      downloadBytes = statsData.totalBytesDown || 0;
    } catch (e) {
      // Fallback to parsing display format
      uploadBytes = parseBytes(stats.upload);
      downloadBytes = parseBytes(stats.download);
    }
  } else {
    uploadBytes = parseBytes(stats.upload);
    downloadBytes = parseBytes(stats.download);
  }
  
  const offset = getOffset();
  
  // Detect reset (service restart)
  const MIN_FOR_RESET = 1024 * 1024; // 1MB
  let newUpOffset = offset.upload_offset;
  let newDownOffset = offset.download_offset;
  
  if (uploadBytes < offset.last_upload * 0.5 && offset.last_upload > MIN_FOR_RESET) {
    newUpOffset += offset.last_upload;
  }
  if (downloadBytes < offset.last_download * 0.5 && offset.last_download > MIN_FOR_RESET) {
    newDownOffset += offset.last_download;
  }
  
  // Calculate cumulative
  const cumulativeUp = newUpOffset + uploadBytes;
  const cumulativeDown = newDownOffset + downloadBytes;
  
  db.run(`INSERT INTO stats (timestamp, status, clients, upload_bytes, download_bytes, uptime) VALUES (?, ?, ?, ?, ?, ?)`,
    [timestamp, stats.status, stats.clients, cumulativeUp, cumulativeDown, stats.uptime]);
  
  // Update offsets
  db.run(`INSERT OR REPLACE INTO offsets (upload_offset, download_offset, last_upload, last_download) VALUES (?, ?, ?, ?)`,
    [newUpOffset, newDownOffset, uploadBytes, downloadBytes]);
  
  saveDb();
}

// Cache
let statsCache = { data: null, timestamp: 0 };
const CACHE_TTL = 5000; // 5 seconds

async function fetchAllStats() {
  const now = Date.now();
  if (statsCache.data && (now - statsCache.timestamp) < CACHE_TTL) {
    return statsCache.data;
  }

  const stats = getConduitStats();
  saveStats(stats);
  
  // Add cumulative values for display
  const offset = getOffset();
  const uploadBytes = parseBytes(stats.upload);
  const downloadBytes = parseBytes(stats.download);
  stats.upload = formatBytes(offset.upload_offset + uploadBytes);
  stats.download = formatBytes(offset.download_offset + downloadBytes);
  
  statsCache = { data: [stats], timestamp: now };
  return [stats];
}

// Express setup
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(session({
  secret: process.env.SESSION_SECRET || 'conduit-dashboard-secret-change-this',
  resave: false,
  saveUninitialized: false,
  cookie: { maxAge: 86400000 }
}));

const requireAuth = (req, res, next) => {
  if (req.session.authenticated) return next();
  if (req.path.startsWith('/api/')) return res.status(401).json({ error: 'Unauthorized' });
  res.redirect('/login');
};

// Routes
app.get('/login', (_, res) => res.sendFile(join(__dirname, 'public', 'login.html')));
app.post('/login', (req, res) => {
  if (req.body.password === PASSWORD) {
    req.session.authenticated = true;
    res.redirect('/');
  } else {
    res.redirect('/login?error=1');
  }
});
app.get('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/login');
});

app.get('/api/stats', requireAuth, async (_, res) => {
  try {
    res.json(await fetchAllStats());
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.get('/api/history', requireAuth, (req, res) => {
  try {
    const hours = parseInt(req.query.hours) || 24;
    const since = Date.now() - (hours * 3600000);
    const stmt = db.prepare(`SELECT timestamp, status, clients, upload_bytes, download_bytes, uptime FROM stats WHERE timestamp > ? ORDER BY timestamp ASC`);
    stmt.bind([since]);
    const rows = [];
    while (stmt.step()) {
      const row = stmt.getAsObject();
      // Add server field for compatibility with multi-server UI
      row.server = 'local';
      rows.push(row);
    }
    stmt.free();
    res.json(rows);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// Add missing API endpoints for UI compatibility
app.get('/api/geo', requireAuth, (req, res) => {
  // Geo stats not available for single-node local setup
  res.json([]);
});

app.get('/api/bandwidth', requireAuth, (req, res) => {
  // Bandwidth limits not implemented for single-node
  res.json({});
});

app.get('/api/status', requireAuth, (req, res) => {
  res.json({
    firstRun: false,
    serverCount: 1,
    joinCommand: null,
    hasJoinToken: false
  });
});

app.get('/api/servers', requireAuth, (req, res) => {
  res.json([{ name: 'local', host: 'localhost' }]);
});

app.post('/api/control/:action', requireAuth, (req, res) => {
  res.json({ action: req.params.action, results: [] });
});

app.post('/api/control/:server/:action', requireAuth, (req, res) => {
  res.json({ server: req.params.server, action: req.params.action, success: false, error: 'Control not implemented for local node' });
});

// Debug endpoint to view/reset offsets
app.get('/api/offsets', requireAuth, (_, res) => {
  try {
    const stmt = db.prepare(`SELECT * FROM offsets LIMIT 1`);
    let row = null;
    if (stmt.step()) row = stmt.getAsObject();
    stmt.free();
    res.json(row || {});
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/offsets/reset', requireAuth, (_, res) => {
  try {
    db.run(`DELETE FROM offsets`);
    saveDb();
    res.json({ success: true, message: 'Offsets reset' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post('/api/stats/clear', requireAuth, (_, res) => {
  try {
    db.run(`DELETE FROM stats`);
    db.run(`DELETE FROM offsets`);
    saveDb();
    res.json({ success: true, message: 'Stats and offsets cleared' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.use(requireAuth, express.static(join(__dirname, 'public')));
app.get('/', requireAuth, (_, res) => res.sendFile(join(__dirname, 'public', 'index.html')));

// Start
initDb().then(() => {
  app.listen(PORT, () => {
    console.log(`Dashboard running on http://localhost:${PORT}`);
    console.log(`Password: ${PASSWORD}`);
    console.log(`Stats file: ${STATS_FILE}`);
    console.log(`\nOpen http://localhost:${PORT} in your browser`);
  });
}).catch(e => {
  console.error('Failed to initialize:', e);
  process.exit(1);
});
