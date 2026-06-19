# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2017 Escalade
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="at-spi2-core"
PKG_VERSION="2.57.0"
PKG_SHA256="942070eff19155b7d6ce5557f1a020015287b840048536e9ef9a28c4e9ce428c"
PKG_LICENSE="OSS"
PKG_SITE="http://www.gnome.org/"
PKG_URL="https://download.gnome.org/sources/at-spi2-core/${PKG_VERSION:0:4}/at-spi2-core-${PKG_VERSION}.tar.xz"
PKG_DEPENDS_TARGET="toolchain atk dbus glib libXtst libXext libXi"
PKG_LONGDESC="Protocol definitions and daemon for D-Bus at-spi."

PKG_MESON_OPTS_TARGET="-Ddocs=false \
                       -Dintrospection=no \
                       -Ddbus_daemon=/usr/bin/dbus-daemon"

pre_configure_target() {
  TARGET_LDFLAGS="${TARGET_LDFLAGS} -lXi -lXext"
}
