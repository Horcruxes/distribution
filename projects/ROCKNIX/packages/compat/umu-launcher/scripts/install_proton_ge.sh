#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

set -e
set -o pipefail

source /etc/profile

STEAM_BASE="${STEAM_BASE:-/storage/.local/share/Steam}"
COMPAT_DIR="${COMPAT_DIR:-${STEAM_BASE}/compatibilitytools.d}"
PROTON_GE_RELEASE_API="${PROTON_GE_RELEASE_API:-https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest}"

log_info() { echo -e "[\033[1;34mINFO\033[0m] $1"; }
log_success() { echo -e "[\033[1;32mSUCCESS\033[0m] $1"; }
die() { echo -e "[\033[1;31mERROR\033[0m] $1" >&2; exit 1; }

# umu-run resolves GE-Proton from Steam's compatibilitytools.d so one copy
# serves both launchers; the dir is created here when Steam is not installed.
steam_absent=""
[ -e "${STEAM_BASE}" ] || steam_absent="yes"
mkdir -p "${COMPAT_DIR}"

log_info "Fetching latest Proton-GE release from GitHub..."

release_json=$(curl -fsSL "${PROTON_GE_RELEASE_API}") || die "Failed to fetch Proton-GE latest release info."

version_tag=$(echo "${release_json}" | grep -oP '"tag_name":\s*"\K[^"]+' | head -n 1) || true
[ -n "${version_tag}" ] || die "Failed to parse Proton-GE version tag."

download_url=$(echo "${release_json}" | grep -oP '"browser_download_url":\s*"\K[^"]*aarch64[^"]*' | grep -v '\.sha512sum' | head -n 1) || true
[ -n "${download_url}" ] || die "Could not find an aarch64 asset in the Proton-GE release."

tar_name=$(basename "${download_url}")
dir_name=$(echo "${tar_name}" | sed 's/\.[^.]*$//' | sed 's/\.[^.]*$//')
[ -n "${dir_name}" ] || die "Failed to derive the Proton-GE directory name from ${tar_name}."

# Runs only once a good ${dir_name} is on disk, so a failed download keeps the old release.
prune_old_proton_ge() {
  for old_dir in "${COMPAT_DIR}"/GE-Proton*-aarch64; do
    [ -d "${old_dir}" ] || continue
    if [ "${old_dir}" = "${COMPAT_DIR}/${dir_name}" ]; then
      continue
    fi
    log_info "Removing old Proton-GE: $(basename "${old_dir}")"
    rm -rf "${old_dir}"
  done
}

if [ -d "${COMPAT_DIR}/${dir_name}" ]; then
  log_success "Proton-GE ${version_tag} is already installed."
  prune_old_proton_ge
  exit 0
fi

log_info "Downloading Proton-GE ${version_tag}..."
tar_path="${COMPAT_DIR}/${tar_name}"
stage_dir="${COMPAT_DIR}/.proton-ge-stage"
trap 'rm -f "${tar_path}"; rm -rf "${stage_dir}"' EXIT
wget -c -t 5 -O "${tar_path}" "${download_url}" || die "Failed to download Proton-GE ${version_tag}."

# Stage outside the tool search path so a half-extracted tool is never visible.
rm -rf "${stage_dir}"
mkdir -p "${stage_dir}"
tar -xf "${tar_path}" -C "${stage_dir}" || die "Failed to extract Proton-GE ${version_tag}."
[ -d "${stage_dir}/${dir_name}" ] || die "Proton-GE archive did not contain ${dir_name}."
mv "${stage_dir}/${dir_name}" "${COMPAT_DIR}/${dir_name}"
rm -rf "${stage_dir}"
rm -f "${tar_path}"

prune_old_proton_ge
log_success "Proton-GE ${version_tag} installed to ${COMPAT_DIR}/${dir_name}."
log_info "umu-run picks it up on the next game launch."
if [ -n "${steam_absent}" ]; then
  log_info "Steam is not installed yet - Install Steam replaces this path and re-adds Proton-GE."
fi
