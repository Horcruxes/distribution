#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026-present ROCKNIX (https://github.com/ROCKNIX)

source /etc/profile

/usr/bin/install_proton_ge.sh
status=$?

echo ""
if [ ${status} -eq 0 ]; then
  echo "Proton-GE is ready for umu-launched games."
else
  echo "Proton-GE installation failed."
fi
sleep 10

exit ${status}
