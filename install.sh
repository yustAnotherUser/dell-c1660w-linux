#!/bin/bash
# install.sh - set up a Dell C1660w WiFi printer on Arch Linux / CachyOS using
# the Xerox Phaser 6000B driver (the C1660w is a rebadged Phaser 6000B).
#
# Usage:  ./install.sh [printer-ip]
#         The IP is optional; without it the script scans your LAN for devices
#         listening on raw-print port 9100.
#
# What it does:
#   1. verifies the driver archive against a pinned sha256
#   2. builds the pacman package (makepkg)
#   3. installs it with paru/yay (pulls in cups + 32-bit libs; asks for sudo)
#   4. enables CUPS, creates the print queue, prints a test page
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZIP="$REPO_DIR/driver/xerox-phaser-6000-6010-1.01_20110222.zip"
ZIP_SHA256="3cb437d2a83fe18718ee73f0293cef17b7129f16e7302c94752e93b4e9152ff2"
QUEUE="Dell_C1660w"

msg() { printf '\n==> %s\n' "$1"; }

command -v makepkg >/dev/null || { echo "ERROR: makepkg not found (install pacman)." >&2; exit 1; }
command -v unzip   >/dev/null || { echo "ERROR: unzip not found - run: sudo pacman -S unzip" >&2; exit 1; }
command -v ip      >/dev/null || { echo "ERROR: ip not found (install iproute2)." >&2; exit 1; }

msg "Verifying driver archive integrity ..."
echo "$ZIP_SHA256  $ZIP" | sha256sum -c - || {
    echo "ERROR: checksum mismatch - this is not the authentic Xerox driver." >&2
    exit 1
}

if [[ $# -ge 1 ]]; then
    PRINTER_IP="$1"
else
    msg "No IP given - scanning your subnet for raw-print (port 9100) devices ..."
    SRC_IP=$(ip -4 route get 1.1.1.1 | grep -oP 'src \K[0-9.]+')
    SUBNET=$(printf '%s' "$SRC_IP" | cut -d. -f1-3)
    CANDIDATES=$(printf '%s\n' $(seq 1 254) \
        | SUBNET="$SUBNET" xargs -P 64 -I{} sh -c \
          'timeout 0.4 bash -c "echo >/dev/tcp/$SUBNET.{}/9100" 2>/dev/null && echo "$SUBNET.{}"' \
        | sort -t. -k4 -n || true)
    COUNT=$(printf '%s' "$CANDIDATES" | grep -c . || true)
    case "$COUNT" in
        0) echo "ERROR: no device found on port 9100. Is the printer powered on and" >&2
           echo "connected to the WiFi? You can also pass the IP explicitly:" >&2
           echo "  $0 <printer-ip>" >&2
           exit 1 ;;
        1) PRINTER_IP="$CANDIDATES" ;;
        *) echo "Several devices listen on port 9100:" >&2
           printf '  %s\n' $CANDIDATES >&2
           echo "Find the printer's IP in your router (Fritz!Box: Heimnetz -> Netzwerk)" >&2
           echo "or print its network config page, then rerun:" >&2
           echo "  $0 <printer-ip>" >&2
           exit 1 ;;
    esac
fi
msg "Using printer at $PRINTER_IP"

msg "Building pacman package ..."
BUILD_DIR=$(mktemp -d)
cp "$REPO_DIR/PKGBUILD" "$ZIP" "$BUILD_DIR/"
( cd "$BUILD_DIR" && makepkg -df )
PKG=$(ls -t "$BUILD_DIR"/*.pkg.tar.zst | head -n1)

AURHELPER=${AURHELPER:-$(command -v paru || command -v yay || true)}
if [[ -z "$AURHELPER" ]]; then
    echo "ERROR: paru or yay is needed to install the package together with its" >&2
    echo "dependencies (cups, lib32-*). Install one of them and rerun." >&2
    exit 1
fi
msg "Installing $PKG ($AURHELPER asks for your sudo password) ..."
"$AURHELPER" -U --needed "$PKG"

msg "Enabling CUPS ..."
sudo systemctl enable --now cups.service

msg "Creating print queue '$QUEUE' (socket://$PRINTER_IP:9100) ..."
TMP_PPD=$(mktemp /tmp/Xerox_Phaser_6000B.XXXXXX.ppd)
zcat /usr/share/cups/model/Xerox/Xerox_Phaser_6000B.ppd.gz > "$TMP_PPD"
sudo lpadmin -p "$QUEUE" -E -v "socket://$PRINTER_IP:9100" -P "$TMP_PPD"
rm -f "$TMP_PPD"
lpoptions -d "$QUEUE" >/dev/null && echo "    '$QUEUE' is now your default printer."

msg "Sending CUPS test page ..."
lp -d "$QUEUE" /usr/share/cups/data/testprint

cat <<EOF

Done - the test page should come out of the printer now.

If the printer's IP ever changes (DHCP), re-point the queue:
  sudo lpadmin -p $QUEUE -v socket://NEW.IP:9100
Better: give the printer a fixed IP in your router (Fritz!Box: Heimnetz ->
Netzwerk -> printer -> "Diesem Netzwerkgerät immer die gleiche
IPv4-Adresse zuweisen").
EOF
