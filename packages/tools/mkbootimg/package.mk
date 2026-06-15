# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

PKG_NAME="mkbootimg"
PKG_VERSION="d2bb0af5ba6d3198a3e99529c97eda1be0b5a093"
PKG_LICENSE="GPL"
PKG_SITE="https://android.googlesource.com/platform/system/tools/mkbootimg"
PKG_URL="${PKG_SITE}.git"
PKG_TOOLCHAIN="manual"
PKG_DEPENDS_HOST="toolchain Python3:host"
PKG_LONGDESC="mkbootimg: Creates kernel boot images for Android"

makeinstall_host() {
  mkdir -p ${TOOLCHAIN}/mkbootimg
  cp -r gki/ mkbootimg.py $TOOLCHAIN/mkbootimg/
}
