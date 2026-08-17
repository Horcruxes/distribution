# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2024-present ROCKNIX (https://github.com/ROCKNIX)

. ${ROOT}/packages/devel/readline/package.mk

# the termcap functions live in the wide termlib (libtinfow) here, so link it
# into libreadline.so explicitly (readline otherwise leaves termcap symbols
# unresolved, expecting consumers to link curses themselves)
PKG_CONFIGURE_OPTS_TARGET="bash_cv_wcwidth_broken=no \
                           bash_cv_termcap_lib=libncursesw \
                           --enable-shared \
                           --disable-static \
                           --with-curses \
                           --with-shared-termcap-library=-ltinfow"
