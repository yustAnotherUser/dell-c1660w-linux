# Dell C1660w WiFi printer on Linux (Arch / CachyOS)

The Dell C1660w is a rebadged **Xerox Phaser 6000B**, and Dell never shipped a
Linux driver for it. The fix that has worked for years is Xerox's Linux driver
for the Phaser 6000/6010 — a 2011, 32-bit CUPS driver.

The problem: **Xerox removed those downloads** (as of 2026 the support URLs
redirect-loop or 404), so the AUR package
[`xerox-phaser-6000-6010`](https://aur.archlinux.org/packages/xerox-phaser-6000-6010)
no longer builds. This repo archives the **authentic driver zip** (sha256-pinned
below) and sets everything up with one script.

## What's in here

| File | Purpose |
|---|---|
| `driver/xerox-phaser-6000-6010-1.01_20110222.zip` | original Xerox driver archive (i686 RPM + PPDs) |
| `PKGBUILD` | pacman package build with corrected 64-bit dependencies |
| `install.sh` | one-shot installer: verify → build → install → queue → test page |

Driver integrity:

```
sha256:  3cb437d2a83fe18718ee73f0293cef17b7129f16e7302c94752e93b4e9152ff2
matches: checksum published in the AUR PKGBUILD of xerox-phaser-6000-6010
original URL:  https://www.support.xerox.com/download/116070   (dead)
recovered from: https://web.archive.org/web/20201022124108id_/https://www.support.xerox.com/download/116070
```

## Requirements

- Arch-based x86_64 system (tested on CachyOS) with the `multilib` repo enabled
- `paru` or `yay` (the script uses it to install `cups` and the 32-bit libs the
  driver needs alongside the package)
- `unzip` and `base-devel` (for makepkg)
- The printer joined to your WiFi

## Install

```bash
git clone https://github.com/yustAnotherUser/dell-c1660w-linux.git
cd dell-c1660w-linux
./install.sh                 # auto-detects the printer (LAN scan on port 9100)
./install.sh 192.168.1.50    # ... or pass the printer's IP explicitly
```

The script creates a CUPS queue named `Dell_C1660w` (`socket://<ip>:9100`,
`Xerox_Phaser_6000B` PPD), sets it as your default printer and prints a test
page.

## Notes / troubleshooting

- **Give the printer a fixed IP** in your router, otherwise the queue breaks
  when DHCP hands out a different address. If it already changed, re-point the
  queue: `sudo lpadmin -p Dell_C1660w -v socket://NEW.IP:9100`
- This printer does **not** announce itself via mDNS/Bonjour, so it never shows
  up in `avahi-browse` or GNOME's printer discovery — that's normal, not a fault.
- The filters are 32-bit binaries; the package therefore depends on
  `lib32-libcups`, `lib32-gcc-libs` and `lib32-glibc` (installed automatically).
  (The AUR package also lists `lib32-libstdc++5`, which is no longer in the
  repos — and is not actually needed by any of the filters.)
- Remove everything again with:
  `paru -Rns xerox-phaser-6000-6010 && sudo lpadmin -x Dell_C1660w`

## Credits & license

- Driver: © Xerox, distributed under its own EULA (`XeroxEULA`, installed with
  the package). Archived here because the vendor no longer offers it.
- Package recipe adapted from the AUR package
  [`xerox-phaser-6000-6010`](https://aur.archlinux.org/packages/xerox-phaser-6000-6010)
  by Fabio 'Lolix' Loli, Archydan and Guglielmo De Concini.
- The scripts and docs in this repo: MIT (see `LICENSE`).
