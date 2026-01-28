<div align="center">

# **Conduit** · **Snowflake** · **Xray** CLI

### Help Iranians access the open internet by running volunteer proxy nodes

**Conduit** — Psiphon volunteer proxy  
**Snowflake** — Tor proxy  
**Xray** — VLESS / VMess / REALITY

</div>

---

## 🚀 Installation

### Mac operating system (macOS)

**Option A: Docker** — Run Conduit in a container using Docker Desktop; no building, includes the manager and dashboard.

- **Step A.1** Download and install [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Mac).  
  [![Docker Desktop](https://www.docker.com/favicons/favicon-96x96.png)](https://www.docker.com/products/docker-desktop/)
- **Step A.2** In Terminal, run:
  ```bash
  curl -sL https://raw.githubusercontent.com/farrox/Conduit-Snowflakes-and-X-ray-servers/main/scripts/conduit-manager-mac.sh | bash
  ```

**Option B: Native** — Install the native binary and run with the **Conduit manager** (same terminal dashboard and menu as Docker), no Docker required.

- **Step B.1** Clone this repo:
  ```bash
  git clone https://github.com/farrox/Conduit-Snowflakes-and-X-ray-servers.git
  cd Conduit-Snowflakes-and-X-ray-servers
  ```
- **Step B.2** Build the binary:
  ```bash
  make setup && make build
  ```
- **Step B.3** Run the **native manager** (same menu and dashboard as Docker Option A):
  ```bash
  ./scripts/conduit-manager-native.sh --menu
  ```

  <img src="resources/dashboard.png" alt="Native Manager Dashboard" width="600">

  Or start/restart directly: `./scripts/conduit-manager-native.sh` (no args)

📖 [Mac Installation Guide](docs/markdown/INSTALL_MAC.md)

---

### Linux operating system

**Option A: One-command install**

- **Step A.1** In a terminal, run:
  ```bash
  curl -sL https://raw.githubusercontent.com/farrox/Conduit-Snowflakes-and-X-ray-servers/main/scripts/install-linux.sh | sudo bash
  ```
- **Step A.2** (Optional) With custom settings:
  ```bash
  curl -sL https://raw.githubusercontent.com/farrox/Conduit-Snowflakes-and-X-ray-servers/main/scripts/install-linux.sh | MAX_CLIENTS=500 BANDWIDTH=10 sudo bash
  ```

📖 [Cloud Deployment Guide](docs/markdown/DEPLOY_CLOUD.md) · [Deployment Checklist](docs/reference/DEPLOY_TODO.md)

---

### Windows operating system

**Option A: Docker** — Run Conduit in Docker with the terminal dashboard manager.

- **Step A.1** Download and install [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows).  
  [![Docker Desktop](https://www.docker.com/favicons/favicon-96x96.png)](https://www.docker.com/products/docker-desktop/)
- **Step A.2** Install **WSL2** (Windows Subsystem for Linux — gives you a Linux terminal on Windows). Open **PowerShell as Administrator** and run:
  ```powershell
  wsl --install
  ```
  This installs WSL2 and Ubuntu. Restart your computer when prompted.
- **Step A.3** Open **WSL2** (search "Ubuntu" in Start menu), then run:
  ```bash
  curl -sL https://raw.githubusercontent.com/farrox/Conduit-Snowflakes-and-X-ray-servers/main/scripts/conduit-manager-mac.sh | bash
  ```
  
  **Alternative:** Already have WSL2? Skip Step A.2. Don't want WSL2? Use Option B (native binary) below.

**Option B: Native** — Build the Windows binary from source (requires Go 1.24.x).

- **Step B.1** Clone this repo:
  ```bash
  git clone https://github.com/farrox/Conduit-Snowflakes-and-X-ray-servers.git
  cd Conduit-Snowflakes-and-X-ray-servers
  ```
- **Step B.2** Build for Windows:
  ```bash
  make setup
  make build-windows
  ```
  Binary will be at `dist/conduit-windows-amd64.exe`
- **Step B.3** Run in PowerShell or Command Prompt:
  ```powershell
  .\dist\conduit-windows-amd64.exe start --psiphon-config .\psiphon_config.json -v
  ```

📖 For firewall rules to restrict traffic to Iran: [Iran Conduit Firewall](https://github.com/SamNet-dev/iran-conduit-firewall)

📖 **Documentation:** [HTML docs](docs/index.html) · [Quick Start](docs/quickstart.html) · [Snowflake](docs/snowflake.html) · [Xray](docs/xray.html)

---

## 📋 Before You Start

You need a `psiphon_config.json` file. Create this file in the **repo root** (the main folder where you cloned the repo):

**Example paths:**
- **Mac:** `/Users/yourname/Conduit-Snowflakes-and-X-ray-servers/psiphon_config.json`
- **Linux:** `/home/yourname/Conduit-Snowflakes-and-X-ray-servers/psiphon_config.json`
- **Windows:** `C:\Users\yourname\Conduit-Snowflakes-and-X-ray-servers\psiphon_config.json`

**File contents:**

```json
{
    "PropagationChannelId": "YOUR_CHANNEL_ID_HERE",
    "SponsorId": "YOUR_SPONSOR_ID_HERE",
    "AdditionalParameters": {
        "YOUR_BASE64_ENCRYPTED_BROKER_CONFIG_HERE"
    }
}
```

**What to change:**
- Replace `YOUR_CHANNEL_ID_HERE` with your Psiphon channel ID
- Replace `YOUR_SPONSOR_ID_HERE` with your Psiphon sponsor ID  
- Replace the `AdditionalParameters` content with your encrypted broker configuration

**Where to get these values:**  
📧 **Email Psiphon** at `info@psiphon.ca` with subject "Request for Conduit CLI Configuration"

📖 [Other ways to get config](docs/markdown/GET_CONFIG.md) (extract from iOS app, etc.)

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
