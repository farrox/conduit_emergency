# Docker Version Test Results

## ✅ Test Status: All Tests Passed

Date: January 25, 2026

## Test Summary

The Docker-based Conduit manager has been tested and verified working:

### Test Results

1. ✅ **Docker is installed and running**
   - Version: Docker 29.1.3
   - Docker Desktop: Running
   - Docker daemon: Accessible

2. ✅ **Docker manager script exists**
   - Location: `./scripts/conduit-manager-mac.sh`
   - Executable permissions: ✓
   - Based on: [conduit-manager-mac](https://github.com/polamgh/conduit-manager-mac) by polamgh

3. ✅ **Docker image accessible**
   - Image: `ghcr.io/ssmirr/conduit/conduit:d8522a8`
   - Pulls successfully on first run
   - Contains embedded config (no external config file needed)

4. ✅ **Container creation works**
   - Container starts successfully
   - Connects to Psiphon network
   - Inproxy service initializes
   - Config migration completes

5. ✅ **Container management**
   - Start/Stop works
   - Volume persistence configured
   - Network host mode enabled
   - Auto-restart configured

## Test Command

Run the automated Docker test suite:

```bash
./scripts/test-docker.sh
```

## Using the Docker Manager

### Interactive Menu

Run the Docker manager:

```bash
./scripts/conduit-manager-mac.sh
```

**Menu Options:**
1. **Start / Restart** - Smart install/start/restart
2. **Stop Service** - Safely stops the container
3. **Live Dashboard** - Real-time monitoring (CPU, RAM, users, traffic)
4. **View Raw Logs** - Stream Docker logs
5. **Reconfigure** - Reinstall with new settings
0. **Exit**

### First Time Setup

When you run the manager for the first time:
1. Select option **1** (Start / Restart)
2. Enter **Max Clients** (default: 200)
3. Enter **Bandwidth** in Mbps (default: 5, or -1 for unlimited)
4. Container will be created and started automatically

### Configuration

The Docker image has **embedded config**, so you don't need a `psiphon_config.json` file!

**Default Settings:**
- Max Clients: 200
- Bandwidth: 5 Mbps

**Recommended Settings:**
- Apple Silicon Macs: 400-800 clients, 10-20 Mbps
- Intel Macs: 200-400 clients, 5-10 Mbps

## Advantages of Docker Version

✅ **No build required** - Uses pre-built image  
✅ **Beautiful UI** - Interactive menu with live dashboard  
✅ **Easy updates** - Just pull new image  
✅ **Isolated** - Runs in container, doesn't affect system  
✅ **Auto-restart** - Container restarts on system reboot  
✅ **Persistent data** - Volume preserves keys across restarts  

## Container Details

- **Container Name:** `conduit-mac`
- **Volume:** `conduit-data` (persistent)
- **Network:** Host mode (for best performance)
- **Restart Policy:** `unless-stopped`

## Monitoring

### View Live Dashboard
Select option **3** from the menu to see:
- CPU usage
- RAM usage
- Connected users
- Traffic (Up/Down)
- Auto-refreshes every 10 seconds

### View Logs
Select option **4** from the menu to stream logs in real-time.

### Check Status via Docker
```bash
# Check if running
docker ps | grep conduit-mac

# View logs
docker logs -f conduit-mac

# View stats
docker stats conduit-mac
```

## Comparison: Docker vs Native

| Feature | Docker Version | Native Version |
|---------|---------------|----------------|
| Setup | ✅ Easiest (just run script) | ⚙️ Need to build |
| UI | ✅ Beautiful interactive menu | ❌ Command-line only |
| Updates | ✅ Pull new image | ⚙️ Rebuild required |
| Config | ✅ Embedded (no file needed) | ⚙️ Need config file |
| Monitoring | ✅ Live dashboard | ⚙️ Verbose logs |
| Isolation | ✅ Container | ❌ Native process |

**Recommendation:** Use Docker version for easiest setup and best UX.

## Troubleshooting

### "Docker is NOT running"
- Start Docker Desktop
- Wait for it to fully start (whale icon in menu bar)
- Try again

### Container won't start
- Check logs: `docker logs conduit-mac`
- Remove and recreate: Select option 5 (Reconfigure)

### Can't connect to network
- The image has embedded config, so it should work automatically
- Check Docker network: `docker network ls`
- Verify host network mode is working

## Next Steps

1. Run the manager: `./scripts/conduit-manager-mac.sh`
2. Select option 1 to start
3. Configure optimal settings for your bandwidth
4. Use option 3 to monitor the live dashboard

---

**All Docker tests passed successfully!** 🎉
