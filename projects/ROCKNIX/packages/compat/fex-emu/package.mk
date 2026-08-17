# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2026 ROCKNIX (https://github.com/ROCKNIX)

PKG_NAME="fex-emu"
PKG_VERSION="e869aa644a16e4332cdc15c1ea0b4d13d482385d"
PKG_LICENSE="MIT"
PKG_SITE="https://github.com/FEX-Emu/FEX"
PKG_URL="https://github.com/FEX-Emu/FEX.git"
PKG_DEPENDS_TARGET="toolchain llvm:host fex-emu:host squashfs-tools zlib squashfuse alsa-lib libxcb wayland libglvnd libdrm libX11 libXrandr xorgproto qt6"
PKG_DEPENDS_HOST="toolchain:host llvm:host openssl:host"
PKG_LONGDESC="FEX-Emu is a fast x86/x86-64 emulator for AArch64"
PKG_TOOLCHAIN="manual"

FEX_LLVM_BIN="${TOOLCHAIN}/bin"
FEX_CLANG="${FEX_LLVM_BIN}/clang"
FEX_CLANGXX="${FEX_LLVM_BIN}/clang++"

pre_configure_target() {
  :
}

FEX_CMAKE_BASE=(
  -DCMAKE_BUILD_TYPE=Release
  -DENABLE_LTO=True
  -DBUILD_TESTING=False
  -DBUILD_THUNKS=True
  -DCMAKE_INSTALL_PREFIX=/usr
  -DCMAKE_MAKE_PROGRAM=ninja
  -DCMAKE_C_COMPILER="${FEX_CLANG}"
  -DCMAKE_CXX_COMPILER="${FEX_CLANGXX}"
  
  # Make sure we pick up teh right llvm-ar and llvm-ranlib
  -DCMAKE_AR="${FEX_LLVM_BIN}/llvm-ar"
  -DCMAKE_RANLIB="${FEX_LLVM_BIN}/llvm-ranlib"
  -DCMAKE_C_COMPILER_AR="${FEX_LLVM_BIN}/llvm-ar"
  -DCMAKE_CXX_COMPILER_AR="${FEX_LLVM_BIN}/llvm-ar"
  -DCMAKE_ASM_COMPILER_AR="${FEX_LLVM_BIN}/llvm-ar"
  -DCMAKE_C_COMPILER_RANLIB="${FEX_LLVM_BIN}/llvm-ranlib"
  -DCMAKE_CXX_COMPILER_RANLIB="${FEX_LLVM_BIN}/llvm-ranlib"
  -DCMAKE_ASM_COMPILER_RANLIB="${FEX_LLVM_BIN}/llvm-ranlib"
)

FEX_CMAKE_OPTS=(
  "${FEX_CMAKE_BASE[@]}"
  -DUSE_LINKER=lld
  -DENABLE_ASSERTIONS=False
  -DCMAKE_LINKER="${FEX_LLVM_BIN}/ld.lld"
)

make_host() {
  mkdir -p "${PKG_BUILD}/.${HOST_NAME}"
  cd "${PKG_BUILD}"

  local -a host_opts=(
    -G Ninja
    -S "${PKG_BUILD}"
    -B "${PKG_BUILD}/.${HOST_NAME}"
    "${FEX_CMAKE_BASE[@]}"
    -DUSE_LINKER="${FEX_LLVM_BIN}/ld.lld"
    -DBUILD_FEXCONFIG=False
    -DTHUNKGEN_ONLY=True
    -DCMAKE_ASM_COMPILER="${FEX_CLANG}"
    -DCMAKE_PREFIX_PATH="${TOOLCHAIN}"
    -DCLANG_EXEC_PATH="${FEX_CLANG}"
    -DENABLE_X86_HOST_DEBUG=True
  )
  cmake "${host_opts[@]}"
  cd "${PKG_BUILD}/.${HOST_NAME}"
  ninja thunkgen
}

make_target() {
  local _v
  for _v in CFLAGS CXXFLAGS LDFLAGS; do
    export ${_v}="$(echo ${!_v} | sed 's/-mabi=lp64//g; s/-mtune=[^ ]*//g')"
  done

  mkdir -p "${PKG_BUILD}/.${TARGET_NAME}"
  cd "${PKG_BUILD}/.${TARGET_NAME}"

  case ${TARGET_CPU} in
    cortex-x3|cortex-x4)
      TUNE_CPU="cortex-a710"
      ;;
    *)
      TUNE_CPU="${TARGET_CPU##*.}"
      ;;
  esac

  local -a tgt_opts=(
    -G Ninja
    -S "${PKG_BUILD}"
    -B "${PKG_BUILD}/.${TARGET_NAME}"
    -DCMAKE_SYSTEM_NAME=Linux
    -DCMAKE_SYSTEM_PROCESSOR=aarch64
    -DCMAKE_C_COMPILER_TARGET=aarch64-rocknix-linux-gnu
    -DCMAKE_CXX_COMPILER_TARGET=aarch64-rocknix-linux-gnu
    -DCMAKE_SYSROOT="${SYSROOT_PREFIX}"
    -DCMAKE_FIND_ROOT_PATH="${SYSROOT_PREFIX}"
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY
    -DBUILD_FEXCONFIG=True
    "${FEX_CMAKE_OPTS[@]}"
    -DGENERATOR_EXE="${TOOLCHAIN}/usr/bin/thunkgen"
    -DCMAKE_INSTALL_LIBDIR=lib
    -DQT_HOST_PATH="${TOOLCHAIN}/usr/local/qt6"
    -DTUNE_CPU="${TUNE_CPU}"

    # Force lld for all linkers (override system default bfd)
    -DCMAKE_EXE_LINKER_FLAGS="-fuse-ld=lld -Wl,--as-needed"
    -DCMAKE_MODULE_LINKER_FLAGS="-fuse-ld=lld -Wl,--as-needed"
    -DCMAKE_SHARED_LINKER_FLAGS="-fuse-ld=lld -Wl,--as-needed"
    -DCMAKE_C_LINKER_FLAGS="-fuse-ld=lld"
    -DCMAKE_CXX_LINKER_FLAGS="-fuse-ld=lld"
  )
  cmake "${tgt_opts[@]}"
  ninja
}

makeinstall_target() {
  cd "${PKG_BUILD}/.${TARGET_NAME}"
  DESTDIR="${INSTALL}" ninja install
  mkdir -p "${INSTALL}/usr/config/fex-emu"
  cp -rf "${PKG_DIR}/config/fex-emu/." "${INSTALL}/usr/config/fex-emu"
  cp -rf "${PKG_DIR}/config/gptk" "${INSTALL}/usr/config/fex-emu"
  mkdir -p "${INSTALL}/usr/config/modules"
  cp -rf "${PKG_DIR}/scripts/"* "${INSTALL}/usr/config/modules"

}

makeinstall_host() {
  mkdir -p "${TOOLCHAIN}/usr/bin"
  cp -av "${PKG_BUILD}/.${HOST_NAME}/Bin/thunkgen" "${TOOLCHAIN}/usr/bin"
}
