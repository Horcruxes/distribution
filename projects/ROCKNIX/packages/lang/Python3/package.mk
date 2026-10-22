# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present ROCKNIX (https://github.com/ROCKNIX)

. ${ROOT}/packages/lang/Python3/package.mk

# Meson unwraps subproject downloads with the host python's tarfile, which needs
# _lzma for .tar.xz. Without it a valid archive fails as "Unknown archive format"
# and the dependency is silently dropped (mesa loses libarchive this way).
PKG_DEPENDS_HOST+=" xz:host"
PKG_CONFIGURE_OPTS_HOST="${PKG_CONFIGURE_OPTS_HOST//py_cv_module__lzma=n\/a/py_cv_module__lzma=yes}"
