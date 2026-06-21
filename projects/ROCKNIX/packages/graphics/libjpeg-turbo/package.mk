# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2009-2016 Stephan Raue (stephan@openelec.tv)
# Copyright (C) 2018-present Team LibreELEC (https://libreelec.tv)
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="libjpeg-turbo"
PKG_VERSION="3.1.1"
PKG_SHA256="aadc97ea91f6ef078b0ae3a62bba69e008d9a7db19b34e4ac973b19b71b4217c"
PKG_LICENSE="GPL"
PKG_SITE="https://libjpeg-turbo.org/"
PKG_URL="https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/${PKG_VERSION}/${PKG_NAME}-${PKG_VERSION}.tar.gz"
PKG_DEPENDS_HOST="toolchain:host"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="A high-speed version of libjpeg for x86 and x86-64 processors which uses SIMD."
PKG_BUILD_FLAGS="+pic +pic:host"

PKG_CMAKE_OPTS_HOST="-DENABLE_STATIC=ON \
                     -DENABLE_SHARED=OFF \
                     -DWITH_JPEG8=ON \
                     -DWITH_SIMD=OFF"

PKG_CMAKE_OPTS_TARGET="-DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
                       -DENABLE_STATIC=ON \
                       -DENABLE_SHARED=ON \
                       -DWITH_JPEG8=ON"

if target_has_feature "(neon|sse)"; then
  PKG_CMAKE_OPTS_TARGET+=" -DWITH_SIMD=ON"
else
  PKG_CMAKE_OPTS_TARGET+=" -DWITH_SIMD=OFF"
fi

if [[ ${TARGET_ARCH} =~ i*86|x86_64 ]]; then
  PKG_DEPENDS_HOST+=" nasm:host"
  PKG_DEPENDS_TARGET+=" nasm:host"
fi

post_makeinstall_target() {
  rm -rf ${INSTALL}/usr/bin
}
