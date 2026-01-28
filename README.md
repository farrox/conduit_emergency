<div align="center">

# **Conduit** · **Snowflake** · **Xray** CLI

### Help Iranians access the open internet by running volunteer proxy nodes

**Conduit** — Psiphon volunteer proxy  
**Snowflake** — Tor proxy  
**Xray** — VLESS / VMess / REALITY

</div>

---

## 🚀 Installation

### macOS

**Docker**  
[![Docker Desktop](https://www.docker.com/favicons/favicon-96x96.png)](https://www.docker.com/products/docker-desktop/)  
[**Download Docker Desktop**](https://www.docker.com/products/docker-desktop/) (Mac, Windows, Linux)

```bash
curl -sL https://raw.githubusercontent.com/farrox/conduit_emergency/main/scripts/conduit-manager-mac.sh | bash
```
No building · Dashboard · Backup/restore · Auto-updates

**Native**
1. Download `Conduit.dmg`
2. Double-click to mount, drag "Conduit" to Applications
3. Double-click **"Start Conduit.command"**

📖 [Mac Installation Guide](docs/markdown/INSTALL_MAC.md)

---

### Linux

**One-Command Install (Recommended)**
```bash
curl -sL https://raw.githubusercontent.com/farrox/conduit_emergency/main/scripts/install-linux.sh | sudo bash
```

**With Custom Settings**
```bash
curl -sL https://raw.githubusercontent.com/farrox/conduit_emergency/main/scripts/install-linux.sh | MAX_CLIENTS=500 BANDWIDTH=10 sudo bash
```

✅ Installs everything · Creates systemd service · Auto-starts on boot

📖 [Cloud Deployment Guide](docs/markdown/DEPLOY_CLOUD.md) · [Deployment Checklist](docs/reference/DEPLOY_TODO.md)

---

### Windows

**Coming Soon** - Windows support is in development.

For now, Windows users can:
- Use WSL2 (Windows Subsystem for Linux) and follow the Linux instructions
- Use Docker Desktop and follow the Docker instructions

📖 [Windows Guide](docs/markdown/INSTALL-GO.md) (WSL2 setup)

📖 **Documentation:** [HTML docs](docs/index.html) · [Quick Start](docs/quickstart.html) · [Snowflake](docs/snowflake.html) · [Xray](docs/xray.html)

---

## 📋 What You Need

1. **Get Config File** - You need a `psiphon_config.json` file
   - **Easiest:** `./scripts/extract-ios-config.sh` (extract from iOS app)
   - **Alternative:** Email `info@psiphon.ca` with subject "Request for Conduit CLI Configuration"
   
   📖 [Get Config Guide](docs/markdown/GET_CONFIG.md)

2. **Start Conduit** - Run one of the installation options above

---

## 📊 Dashboard

View live stats (CPU, RAM, connected users, traffic):

```bash
./scripts/dashboard.sh
```

📖 [Dashboard Guide](docs/markdown/DASHBOARD.md)

---

## ⚙️ Configuration

**Auto-configure optimal settings:**
```bash
./scripts/configure-optimal.sh
```

📖 [Configuration Guide](docs/markdown/CONFIG_OPTIMAL.md) · [All Documentation](docs/markdown/)

---

## 🐳 Docker

**Quick Start:**
```bash
docker build -t conduit --build-arg PSIPHON_CONFIG=psiphon_config.json -f Dockerfile.embedded .
docker run -d --name conduit -v conduit-data:/home/conduit/data --restart unless-stopped conduit
```

**Mac Docker Manager:**
```bash
./scripts/conduit-manager-mac.sh --menu
```

📖 [Docker Manager Guide](docs/markdown/CONDUIT_MANAGER_MAC.md)

---

## ☁️ Cloud Deployment

Deploy to DigitalOcean, Linode, Hetzner, AWS, Google Cloud, or Azure:

📖 [Cloud Deployment Guide](docs/markdown/DEPLOY_CLOUD.md) · [Deployment Checklist](docs/reference/DEPLOY_TODO.md)

---

## 🔒 Security

By default, Conduit accepts connections from anywhere. To restrict traffic to specific regions:

📖 [Security & Firewall Guide](docs/markdown/SECURITY_FIREWALL.md)

---

## 📚 More Documentation

### Getting Started
- [Quick Start for Mac](docs/markdown/QUICKSTART_MAC.md)
- [Installation Guide](docs/markdown/INSTALL_MAC.md)
- [Get Config Guide](docs/markdown/GET_CONFIG.md)

### Configuration
- [Optimal Configuration](docs/markdown/CONFIG_OPTIMAL.md)
- [Dashboard Guide](docs/markdown/DASHBOARD.md)
- [Security & Firewall](docs/markdown/SECURITY_FIREWALL.md)

### Run Alongside Conduit
- [Snowflake Guide](docs/markdown/SNOWFLAKE_WHERE_TO_START.md) - Tor Snowflake proxy
- [Xray Guide](docs/markdown/XRAY_WHERE_TO_START.md) - VLESS/VMess/REALITY server

### Deployment
- [Cloud Deployment](docs/markdown/DEPLOY_CLOUD.md)
- [Deployment Checklist](docs/reference/DEPLOY_TODO.md)

### HTML Documentation
- [HTML Docs](docs/index.html) - Beautiful web-based documentation

---

## 🤝 Community & Acknowledgements

This project incorporates excellent community contributions:
- [Conduit Manager for macOS](https://github.com/polamgh/conduit-manager-mac) - Docker-based management tool
- [Conduit Manager (Linux)](https://github.com/SamNet-dev/conduit-manager) - One-click Linux management
- [Conduit Relay](https://github.com/paradixe/conduit-relay) - Web dashboard with fleet management
- [Iran Conduit Firewall](https://github.com/SamNet-dev/iran-conduit-firewall) - Windows firewall solution

📖 [Full Acknowledgements](ACKNOWLEDGEMENTS.md)

---

## 📝 License

GNU General Public License v3.0

---

## 🆘 Need Help?

1. Check the [HTML Documentation](docs/index.html) for visual guides
2. See the [Quick Start Guide](docs/markdown/QUICKSTART_MAC.md) for step-by-step instructions
3. Review the [troubleshooting section](docs/markdown/QUICKSTART_MAC.md#troubleshooting)
4. Open an issue on GitHub

---

<div align="center">

**Thank you for helping Iranians access the open internet!** 🌐

Made with ❤️ for internet freedom

</div>
