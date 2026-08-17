# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2021-present Team LibreELEC (https://libreelec.tv)

<<<<<<< HEAD
# PKG_DIR resolves here, so this shadow keeps copies of core's scripts/ and config/
. ${ROOT}/packages/wayland/util/foot/package.mk
=======
PKG_NAME="foot"
PKG_VERSION="1.27.0"
PKG_SHA256="f5917cad2d7b723b99873e53d78fd10ea202923d189aed5086591fc53b70b7e3"
PKG_LICENSE="MIT"
PKG_SITE="https://codeberg.org/dnkl/foot/"
PKG_URL="https://codeberg.org/dnkl/foot/archive/${PKG_VERSION}.tar.gz"
PKG_DEPENDS_TARGET="toolchain ncurses wayland wayland-protocols pixman fontconfig libxkbcommon fcft"
PKG_LONGDESC="A fast, lightweight and minimalistic Wayland terminal emulator"
>>>>>>> eba8ef9d88 (qwen fix cachyos build)

# codeberg regenerated this tag's archive, so core's checksum no longer matches upstream
PKG_SHA256="f5917cad2d7b723b99873e53d78fd10ea202923d189aed5086591fc53b70b7e3"
