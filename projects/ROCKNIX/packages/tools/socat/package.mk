# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2019-present Shanti Gilbert (https://github.com/shantigilbert)
# Copyright (C) 2023 JELOS (https://github.com/JustEnoughLinuxOS)

PKG_NAME="socat"
<<<<<<< HEAD
PKG_VERSION="1.8.1.3"
PKG_SHA256="25bc6476292b2e614220989c77b0b6fca87bb2525d9747b31a6639b1fb602418"
=======
PKG_VERSION="1.8.1.1"
>>>>>>> eba8ef9d88 (qwen fix cachyos build)
PKG_LICENSE="GPLv2+"
PKG_SITE="http://www.dest-unreach.org/socat/download"
PKG_URL="${PKG_SITE}/${PKG_NAME}-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS_TARGET="toolchain"
PKG_LONGDESC="A multipurpose relay (SOcket CAT)"
PKG_TOOLCHAIN="configure"

PKG_CONFIGURE_OPTS_TARGET+="	--disable-libwrap \
				--disable-readline \
				--enable-termios"

<<<<<<< HEAD

pre_makeinstall_target() {
  # 1.8 installs helper scripts from the source tree, and we build out of tree
  cp -f ${PKG_BUILD}/*.sh ${PKG_BUILD}/.${TARGET_NAME}/ 2>/dev/null || true
=======
post_configure_target() {
  sed -i \
    -e 's|\$(INSTALL) -m 755 socat-chain.sh|\$(INSTALL) -m 755 $(srcdir)/socat-chain.sh|' \
    -e 's|\$(INSTALL) -m 755 socat-mux.sh|\$(INSTALL) -m 755 $(srcdir)/socat-mux.sh|' \
    -e 's|\$(INSTALL) -m 755 socat-broker.sh|\$(INSTALL) -m 755 $(srcdir)/socat-broker.sh|' \
    Makefile
>>>>>>> eba8ef9d88 (qwen fix cachyos build)
}
