#!/bin/sh
#
# Tailscale updater for OpenWRT
# Updates Tailscale to the latest stable version
#

set -e

echo "=== Tailscale Updater for OpenWRT ==="
echo ""

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    aarch64)
        TS_ARCH="arm64"
        ;;
    armv7l|armv6l)
        TS_ARCH="arm"
        ;;
    x86_64)
        TS_ARCH="amd64"
        ;;
    i686|i386)
        TS_ARCH="386"
        ;;
    *)
        echo "Unknown architecture: $ARCH"
        echo "Please specify architecture manually"
        exit 1
        ;;
esac

echo "Detected architecture: $ARCH (Tailscale: $TS_ARCH)"
echo ""

# Get current version
CURRENT_VERSION=$(tailscale version 2>/dev/null | head -1 || echo "not installed")
echo "Current Tailscale version: $CURRENT_VERSION"
echo ""

# Fetch latest version from Tailscale
echo "Checking for latest version..."
LATEST_VERSION=$(curl -s https://pkgs.tailscale.com/stable/ | grep -oP 'tailscale_\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)

if [ -z "$LATEST_VERSION" ]; then
    echo "Failed to fetch latest version. Check your internet connection."
    exit 1
fi

echo "Latest Tailscale version: $LATEST_VERSION"
echo ""

# Check if already up to date
if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
    echo "Already running the latest version!"
    exit 0
fi

# Confirm update
echo "Do you want to update from $CURRENT_VERSION to $LATEST_VERSION? (y/n)"
read -r CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Update cancelled."
    exit 0
fi

echo ""
echo "Starting update..."
echo ""

# Stop Tailscale
echo "Stopping Tailscale service..."
/etc/init.d/tailscale stop

# Download and extract
DOWNLOAD_URL="https://pkgs.tailscale.com/stable/tailscale_${LATEST_VERSION}_${TS_ARCH}.tgz"
echo "Downloading from: $DOWNLOAD_URL"

cd /tmp
rm -f tailscale_*.tgz
rm -rf tailscale_*_${TS_ARCH}

wget -q --show-progress "$DOWNLOAD_URL" || {
    echo "Download failed!"
    /etc/init.d/tailscale start
    exit 1
}

echo "Extracting..."
tar xzf "tailscale_${LATEST_VERSION}_${TS_ARCH}.tgz"

cd "tailscale_${LATEST_VERSION}_${TS_ARCH}"

# Backup old binaries
echo "Backing up old binaries..."
cp /usr/sbin/tailscale /usr/sbin/tailscale.bak 2>/dev/null || true
cp /usr/sbin/tailscaled /usr/sbin/tailscaled.bak 2>/dev/null || true

# Install new binaries
echo "Installing new binaries..."
cp tailscale tailscaled /usr/sbin/
chmod +x /usr/sbin/tailscale /usr/sbin/tailscaled

# Cleanup
cd /tmp
rm -f "tailscale_${LATEST_VERSION}_${TS_ARCH}.tgz"
rm -rf "tailscale_${LATEST_VERSION}_${TS_ARCH}"

# Start Tailscale
echo "Starting Tailscale service..."
/etc/init.d/tailscale start
sleep 2

# Verify
NEW_VERSION=$(tailscale version 2>/dev/null | head -1)
echo ""
echo "=== Update Complete ==="
echo "New version: $NEW_VERSION"
echo ""

if [ "$NEW_VERSION" = "$LATEST_VERSION" ]; then
    echo "✓ Successfully updated to $LATEST_VERSION"
    echo ""
    echo "Backup binaries saved as:"
    echo "  /usr/sbin/tailscale.bak"
    echo "  /usr/sbin/tailscaled.bak"
else
    echo "⚠ Warning: Version mismatch detected"
    echo "Expected: $LATEST_VERSION"
    echo "Got: $NEW_VERSION"
fi
