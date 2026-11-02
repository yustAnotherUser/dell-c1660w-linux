# Driver for Xerox Phaser 6000/6010 color printers (works with the Dell C1660w,
# which is a rebadged Phaser 6000B).
# Adapted from the AUR package xerox-phaser-6000-6010 (contributors: Fabio
# 'Lolix' Loli, Archydan, Guglielmo De Concini). The driver zip under driver/
# was recovered from the Wayback Machine and sha256-verified against the AUR
# PKGBUILD checksums - see README.md.
pkgname=xerox-phaser-6000-6010
pkgver=1.01_20110222
pkgrel=1
pkgdesc="CUPS driver for Xerox Phaser 6000/6010 color printers (also works with Dell C1660w)"
url="https://github.com/yustAnotherUser/dell-c1660w-linux"
license=('custom:"XeroxEULA"')
arch=(x86_64)
depends=(cups lib32-libcups lib32-gcc-libs lib32-glibc)
# The zip normally lives under driver/ - install.sh stages a copy next to this
# PKGBUILD before building. To build manually: cp driver/*.zip . && makepkg -df
source=("xerox-phaser-6000-6010-1.01_20110222.zip"
        "XeroxEULA::https://raw.githubusercontent.com/FabioLolix/AUR-artifacts/master/XeroxEULA")
sha256sums=('3cb437d2a83fe18718ee73f0293cef17b7129f16e7302c94752e93b4e9152ff2'
            '0b4c700a15719e07766c44451c767f1470ab97bf466cc61b18b96aec5891fc7e')

package() {
  bsdtar -xf "${srcdir}/rpm_${pkgver}/Xerox-Phaser_6000_6010-1.0-1.i686.rpm" -C "${pkgdir}"
  install -D -m644 "${srcdir}/XeroxEULA" "${pkgdir}/usr/share/licenses/${pkgname}/XeroxEULA"
}
