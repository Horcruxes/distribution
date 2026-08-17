# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="umu-launcher"
PKG_VERSION="cf3d1b107147480c447ffbfb3f789dc74335074c" # 1.4.4
PKG_LICENSE="GPLv3"
PKG_SITE="https://github.com/Open-Wine-Components/umu-launcher"
PKG_URL="${PKG_SITE}.git"
PKG_GIT_CLONE_BRANCH="1.4.4"
PKG_DEPENDS_TARGET="toolchain cargo:host cargo rust Python3"
PKG_LONGDESC="Run Windows games via Proton outside of Steam"
PKG_TOOLCHAIN="manual"

make_target() {
  unset CMAKE
  export PYO3_CROSS_PYTHON_VERSION="${PKG_PYTHON_VERSION#python}"
  export PYO3_CROSS_LIB_DIR="${SYSROOT_PREFIX}/usr/lib/${PKG_PYTHON_VERSION}"

  cargo build \
    --target ${TARGET_NAME} \
    --release
}

makeinstall_target() {
  # Remove root user check
  sed -i '/if os.geteuid() == 0:/,/sys.exit(1)/d' ${PKG_BUILD}/umu/__main__.py

  # Install Python package
  local PY_SITE="${INSTALL}/usr/lib/${PKG_PYTHON_VERSION}/site-packages"
  mkdir -p ${PY_SITE}
  cp -rf ${PKG_BUILD}/umu ${PY_SITE}/
  find ${PY_SITE}/umu -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

  # Install vendored dependencies from git submodules
  cp -rf ${PKG_BUILD}/subprojects/urllib3/src/urllib3 ${PY_SITE}/
  echo '__version__ = "2.5.0"' > ${PY_SITE}/urllib3/_version.py
  cp -rf ${PKG_BUILD}/subprojects/python-xlib/Xlib ${PY_SITE}/

  # Install cross-compiled Rust extension
  local RUST_SO=$(find ${PKG_BUILD}/.${TARGET_NAME}/target/${TARGET_NAME}/release \
    -maxdepth 1 -name "*.so" 2>/dev/null | head -1)
  if [ -n "${RUST_SO}" ]; then
    cp -f ${RUST_SO} ${PY_SITE}/umu/
  fi

  # Install umu-run wrapper
  mkdir -p ${INSTALL}/usr/bin
  cp -f ${PKG_DIR}/umu-run ${INSTALL}/usr/bin/
  sed -i "s|@PYVER@|${PKG_PYTHON_VERSION}|" ${INSTALL}/usr/bin/umu-run
  chmod +x ${INSTALL}/usr/bin/umu-run
}
