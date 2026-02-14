# OpenWRT scripts

Utility scripts for OpenWRT routers.

## Scripts

### update-tailscale.sh

Updates Tailscale to the latest stable version on OpenWRT.

**Usage:**
SSH into your router, then run:

```bash
wget https://raw.githubusercontent.com/connor-leech/openwrt-scripts/refs/heads/main/update-tailscale.sh
chmod +x update-tailscale.sh
./update-tailscale.sh
```

**What it does:**
- Auto-detects your router architecture
- Downloads latest Tailscale version
- Backs up existing binaries
- Installs and verifies the update

**Why:** OpenWRT package repos often lag behind Tailscale releases, including security updates.

## Requirements

- OpenWRT router
- Internet connection
- Root/SSH access
