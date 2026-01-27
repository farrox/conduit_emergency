# Adding Xray Alongside Conduit — Where to Start

**Xray** (XTLS/Xray-core) is a proxy platform for censorship circumvention. It supports VLESS, VMess, Trojan, REALITY, and more. You run an **Xray server**; users connect with **Xray clients** (e.g. v2rayN, Hiddify, Sing-box). It is a different stack from Psiphon (Conduit) and Tor (Snowflake).

---

## How this fits with Conduit

| Service   | Role              | Typical use                    |
|-----------|-------------------|---------------------------------|
| Conduit   | Psiphon inproxy   | Iranians via Psiphon network   |
| Snowflake | Tor proxy         | Tor users                      |
| Xray      | Your own proxy    | Users with Xray/v2ray clients  |

You can run **Xray on the same machine** as Conduit and Snowflake. Use different ports in Xray’s `config.json` (e.g. 443, 8443, 10086) so it does not conflict with Conduit.

---

## Where to start

- **Code:** [https://github.com/XTLS/Xray-core](https://github.com/XTLS/Xray-core)
- **Docs:** [https://xtls.github.io](https://xtls.github.io)
- **Install:** [https://xtls.github.io/en/document/install.html](https://xtls.github.io/en/document/install.html)

---

## Quickest ways to run an Xray server

Xray always needs a **config file** (inbounds, outbounds, users). There is no one-command zero-config option like Snowflake.

### 1. Binary + config

1. **Get a binary:** [Releases](https://github.com/XTLS/Xray-core/releases) or `brew install xray` (macOS).
2. **Use a minimal server example:** e.g. [VLESS-TCP-XTLS-Vision](https://github.com/XTLS/Xray-examples/tree/main/VLESS-TCP-XTLS-Vision) or [Xray-examples](https://github.com/XTLS/Xray-examples).
3. **Run:** `xray run -c /path/to/config.json`

### 2. Docker

- **Image:** `ghcr.io/xtls/xray-core` (see [Xray-core README](https://github.com/XTLS/Xray-core)).
- You must create a `config.json` and mount it into the container (see official docs or Docker examples in the repo).

### 3. One-click / install script

- **Official install script:** [XTLS/Xray-install](https://github.com/XTLS/Xray-install) (Linux).
- **One-click setups** (config + install):  
  [Xray-REALITY](https://github.com/zxcvos/Xray-script), [xray-reality](https://github.com/sajjaddg/xray-reality), [v2ray-agent](https://github.com/mack-a/v2ray-agent), [Xray_onekey](https://github.com/wulabing/Xray_onekey).

These generate a server config and often set up systemd or Docker.

---

## One-line “where to start”

- **“I want to run an Xray server alongside Conduit”**  
  → [https://github.com/XTLS/Xray-core](https://github.com/XTLS/Xray-core) and [https://xtls.github.io](https://xtls.github.io). Install a binary or use Xray-install / a one-click script, create or generate a server `config.json`, then run Xray on its own ports.

- **“I want ready-made server examples”**  
  → [XTLS/Xray-examples](https://github.com/XTLS/Xray-examples) — copy a server example, adjust ports/users, and run with `xray run -c config.json`.

---

## Comparison with Snowflake

| | Snowflake (Tor) | Xray |
|---|-----------------|------|
| **Config** | One Docker command, no config | Requires `config.json` (inbounds, users, etc.) |
| **Who uses it** | Tor Browser / Orbot users | Any client with VLESS/VMess/etc. (v2rayN, Hiddify, etc.) |
| **Run alongside Conduit** | Yes, separate container/process | Yes, separate process, different ports |

Both can run on the same server as Conduit without conflict.

---

## Test Xray locally

A minimal test config is included so you can verify Xray starts without setting up a full server.

### macOS (binary)

```bash
# Install Xray
brew install xray

# Run using the project’s test config (VMess on port 10086)
cd /path/to/conduit_emergency
xray run -c scripts/xray-test-config.json
```

You should see something like: `[Info] transport/internet/tcp: listening TCP on 0.0.0.0:10086` and `Xray ... started`. Stop with Ctrl+C. The config in `scripts/xray-test-config.json` is for local testing only (VMess, no TLS); replace it with a proper server config for real use.

### Docker

With Docker running, use the same config:

```bash
cd /path/to/conduit_emergency
docker run -d --name xray-test \
  -v "$(pwd)/scripts/xray-test-config.json:/etc/xray/config.json:ro" \
  -p 10086:10086 \
  --restart no \
  ghcr.io/xtls/xray-core:latest
docker logs xray-test   # verify “listening TCP on ...” and “started”
docker stop xray-test
```
