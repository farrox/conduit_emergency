# Adding Snowflake Capabilities — Where to Start on GitHub/GitLab

If you want to add **Snowflake** (censorship circumvention via WebRTC proxies) alongside or into your setup, here’s where to look.

---

## Quickest CLI: run Tor Snowflake alongside Conduit

**If you have Docker** — one command, no config. Uses Tor’s default broker. Runs in the background and survives reboot:

```bash
docker run -d --restart unless-stopped --name snowflake-proxy thetorproject/snowflake-proxy
```

Run Conduit as usual in another terminal or in Docker; Snowflake and Conduit are separate processes/containers.

**If you don’t have Docker** — clone, build, run (requires [Go 1.21+](https://go.dev/doc/install)):

```bash
git clone --depth 1 https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/snowflake.git /tmp/snowflake \
  && cd /tmp/snowflake/proxy && go build -o snowflake-proxy . && ./snowflake-proxy
```

To run in background: add `&` at the end, or use `nohup ./snowflake-proxy &`. To stop: `docker stop snowflake-proxy` (Docker) or kill the proxy process.

### Verify and troubleshoot

- **Docker:** “failed to connect to the docker API” or “no such file or directory” → start **Docker Desktop** (Mac/Windows), then rerun the `docker run` command. If you don’t use Docker, use the from-source one-liner above.
- **Check it’s running:** `docker ps | grep snowflake-proxy`
- **View logs:** `docker logs -f snowflake-proxy` (Ctrl+C leaves the container running)
- **“NAT type: restricted” in logs:** Normal on a home Mac or consumer connection. The proxy still works and helps Tor users; Tor recommends full-cone/unrestricted NAT for maximum capacity. For more concurrent users, run the same Docker command on a VPS (e.g. same server as Conduit) where NAT is usually unrestricted.
- **Stop:** `docker stop snowflake-proxy`. To remove the container: `docker rm snowflake-proxy` (after stopping).

### How to see how effective your Snowflake is

- **Watch the logs:** `docker logs -f snowflake-proxy`. When your proxy helps Tor users, it prints lines like:
  - `In the last 1h0m0s, there were N completed connections. Traffic Relayed ↓ X KB, ↑ Y KB.`
  - “completed connections” = successful sessions you helped; “Traffic Relayed” = download ↑ and upload ↓ in that window (often every ~1 hour when there’s activity).
- **At first you may only see** “Proxy starting” and “NAT type: restricted”. The “Traffic Relayed” / “completed connections” lines appear once the broker has assigned you to clients and they’ve used the tunnel. On a home connection with restricted NAT it can take time; on a VPS it’s often sooner.
- **Optional: sum traffic and connections from logs.** Community scripts parse `docker logs snowflake-proxy` for “Traffic Relayed” and report total GB and connection count, e.g. [snowstats.sh](https://gist.github.com/Atrate/be4a7d308549c7a9fe281d2cdf578d21) or [snowflake-stats](https://github.com/HeIIow2/snowflake-stats). Log format can change; if numbers look wrong, double‑check against raw log lines.
- **Network-wide stats only:** [Tor Metrics – bridge users by transport](https://metrics.torproject.org/userstats-bridge-transport.html?transport=snowflake) shows Snowflake usage across the whole network, not per‑proxy. Use it to see how big Snowflake is overall, not “how much is my proxy doing.”

---

## 1. Official Tor Snowflake (run a Snowflake proxy)

**Best for:** Helping Tor users by running a Snowflake proxy (e.g. on the same host as Conduit).

- **Code:**  
  **https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/snowflake**
- **Docs:**  
  https://community.torproject.org/relay/setup/snowflake/standalone/

**Clone and build the proxy:**

```bash
git clone https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/snowflake.git
cd snowflake/proxy
go build
./proxy  # or see Tor’s docs for broker URL and flags
```

**Start here:** Clone the repo above, read the [standalone setup](https://community.torproject.org/relay/setup/snowflake/standalone/) (Docker / source / Debian / FreeBSD), then run the `proxy` from the `proxy/` directory. That’s the minimal “add Snowflake” path: run this proxy next to Conduit.

---

## 2. Snowflake “generalized” (Snowflake-style tunnels, not Tor-only)

**Best for:** Reusing Snowflake’s idea (WebRTC proxies) for **any** TCP/UDP service (VPN, SOCKS, your own backend), not only Tor.

- **Code:**  
  **https://github.com/WofWca/snowflake-generalized**
- **Relationship:** Built on a fork of Tor’s Snowflake; adds “connect to arbitrary host” and extra hardening.

**Layout:**

- `client/` — client that gets a tunnel to your server
- `server/` — server that accepts Snowflake connections and forwards to your service
- `common/`, `docs/`, `examples/` — shared code and usage

**Start here:**  
Clone [WofWca/snowflake-generalized](https://github.com/WofWca/snowflake-generalized), then follow the “Try it” and “Usage” sections in its README. You’ll see how the client, broker, proxy, and server fit together. Use this repo when your goal is “Snowflake-like transport for my own service” rather than “only Tor.”

---

## 3. Tor Snowflake on GitHub (mirror / discovery)

Tor’s canonical repo is on **GitLab** (link in section 1). For discovery and links:

- **https://github.com/search?q=snowflake+tor+proxy**  
  Use this to find mirrors, wrappers, or Docker images that point back to Tor’s Snowflake or to snowflake-generalized.

---

## 4. How this fits with Conduit

| You want to… | Start with |
|--------------|------------|
| Run a **Snowflake proxy** on the same box as Conduit (help Tor users) | **Section 1** — Tor’s GitLab repo + [standalone setup](https://community.torproject.org/relay/setup/snowflake/standalone/) |
| Build a **Snowflake-style tunnel** to your own service (e.g. VPN/SOCKS), not Tor | **Section 2** — [WofWca/snowflake-generalized](https://github.com/WofWca/snowflake-generalized) |
| Understand **design and protocols** | Tor Snowflake repo (section 1) + [Snowflake paper](https://www.bamsoftware.com/papers/snowflake/) |
| **Docker** Snowflake proxy | Tor’s [Docker setup](https://community.torproject.org/relay/setup/snowflake/standalone/docker/) |

Conduit = Psiphon inproxy (one ecosystem). Snowflake = Tor pluggable transport (another). “Adding Snowflake capabilities” usually means either:

1. **Run both:** Conduit + Snowflake proxy on the same machine (two separate processes), or  
2. **Use Snowflake tech for your own service:** use snowflake-generalized’s client/server and, if you need it, run Tor’s or a customized proxy.

---

## 5. One-line “where to start”

- **“I want to run a Snowflake proxy”**  
  → **https://gitlab.torproject.org/tpo/anti-censorship/pluggable-transports/snowflake** and [standalone setup](https://community.torproject.org/relay/setup/snowflake/standalone/).

- **“I want Snowflake-style tunnels to my own service”**  
  → **https://github.com/WofWca/snowflake-generalized**

Both are in Go and can live on the same server as Conduit; start from the repo that matches your goal above.
