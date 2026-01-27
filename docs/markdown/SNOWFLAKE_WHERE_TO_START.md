# Adding Snowflake Capabilities — Where to Start on GitHub/GitLab

If you want to add **Snowflake** (censorship circumvention via WebRTC proxies) alongside or into your setup, here’s where to look.

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
