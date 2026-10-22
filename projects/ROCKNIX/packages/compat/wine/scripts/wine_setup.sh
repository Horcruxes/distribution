#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 ROCKNIX (https://github.com/ROCKNIX)
# Adapted from https://github.com/PastorCatto/Rocknix-WINE (wine_setup.sh)

# Creates or reconfigures a Wine game port under the windows system. All ports
# share the single Wine prefix in ${WINE_PREFIX}.

. /etc/profile

PORTS_BASE="/storage/roms/windows"
WINE_PREFIX="/storage/.wine"
GPTOKEYB="/usr/bin/gptokeyb"

msgbox() {
  dialog --title "$1" --msgbox "$2" 10 60
}

yesno() {
  dialog --title "$1" --yesno "$2" 10 60
  return $?
}

# dialog draws its UI on stdout, so it must never run inside a command
# substitution: stdout there is a pipe, and the widget renders into it.
# The value is therefore collected on stderr and assigned by name.
ask() { # ask <var> "prompt" ["default"]
  local tmpfile
  tmpfile=$(mktemp)
  dialog --inputbox "$2" 8 60 "${3:-}" 2>"$tmpfile"
  printf -v "$1" '%s' "$(sed -e 's/^[ \t]*//;s/[ \t]*$//' "$tmpfile")"
  rm -f "$tmpfile"
}

for cmd in wine winetricks box64 "${GPTOKEYB}"; do
  if ! command -v "$cmd" &>/dev/null; then
    msgbox "Error" "Missing dependency: $cmd is not installed. Install it before proceeding."
    exit 1
  fi
done

msgbox "Game Port Setup" "This script will create or modify a game port under ${PORTS_BASE}."
if ! yesno "Proceed?" "Folders and files will be created under ${PORTS_BASE}, using the shared Wine prefix at ${WINE_PREFIX}. Continue?"; then
  clear
  exit 1
fi

MODE=$(dialog --stdout --radiolist "Select mode:" 10 60 2 \
  "new" "Create a new game port" on \
  "modify" "Modify an existing game port" off)

if [ "$MODE" = "modify" ]; then
  EXISTING_OPTIONS=()
  for dir in "${PORTS_BASE}"/*/; do
    [ -d "$dir" ] || continue
    foldername=$(basename "$dir")
    EXISTING_OPTIONS+=("$foldername" "$foldername" "off")
  done

  if [ ${#EXISTING_OPTIONS[@]} -eq 0 ]; then
    msgbox "No Existing Ports" "No game ports were found in ${PORTS_BASE}. Switching to new port mode."
    MODE="new"
  else
    SELECTED=$(dialog --stdout --radiolist "Select a game port to modify:" 15 60 5 "${EXISTING_OPTIONS[@]}")
    if [ -z "$SELECTED" ]; then
      msgbox "Cancelled" "No selection made. Exiting."
      exit 1
    fi
    GAME_FOLDER="$SELECTED"
    GAME_TITLE="$SELECTED"
  fi
fi

if [ "$MODE" = "new" ]; then
  ask GAME_TITLE "Enter the game title (e.g. ExampleGame):"
  if [ -z "$GAME_TITLE" ]; then
    clear
    echo "No game title provided. Exiting."
    exit 1
  fi
  # Folder-friendly name: lowercase, no spaces.
  GAME_FOLDER=$(echo "$GAME_TITLE" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
fi

DEFAULT_EXE="${GAME_TITLE}.exe"
ask EXE_NAME "Enter the game executable filename (with extension, e.g. game.exe):" "$DEFAULT_EXE"
[ -z "$EXE_NAME" ] && EXE_NAME="$DEFAULT_EXE"

if yesno "Executable Location" "Is your game executable located in a subfolder relative to the 'data' folder?\n\n(If 'No', the executable filename will be used directly.)"; then
  ask SUBFOLDER "Enter the relative subfolder path (e.g. bin64):"
else
  SUBFOLDER=""
fi
EXE_PATH="${SUBFOLDER:+${SUBFOLDER}/}${EXE_NAME}"

CHOICE=$(dialog --stdout --radiolist "Select graphics compatibility package:" 15 90 7 \
  "dxvk" "Install latest DXVK (Newer regressions have shown ~-5FPS)" off \
  "dxvk2041" "Install DXVK 2041 (fixes regression in later builds)" on \
  "vkd3d" "Install vkd3d (DirectX 12 to Vulkan)" off \
  "none" "Install neither" off)
[ -z "$CHOICE" ] && CHOICE="none"

HUD_CHOICE=$(dialog --stdout --radiolist "DXVK HUD:" 10 60 2 \
  "1" "Enable DXVK HUD" off \
  "0" "Disable DXVK HUD" on)
[ -z "$HUD_CHOICE" ] && HUD_CHOICE=0

if yesno "DXVK Async Mode" "Do you want to enable DXVK/VKD3D async mode? (This may reduce shader stutter)"; then
  DXVK_ASYNC=1
else
  DXVK_ASYNC=0
fi

if yesno "ESYNC" "Do you want to enable ESYNC (Wine's eventfd-based synchronization)?"; then
  STAGING_SHARED_MEMORY=1
else
  STAGING_SHARED_MEMORY=0
fi

if yesno "FSYNC" "Do you want to enable FSYNC (Wine's file descriptor based synchronization)?"; then
  STAGING_WRITECOPY=1
else
  STAGING_WRITECOPY=0
fi

UNITY_OPT=0
if yesno "Unity/Other Game Optimizations" "Would you like to apply additional optimal settings for Unity games (or similar titles)?\n\nThis will write extra BOX64 environment variable settings to the launcher script."; then
  UNITY_OPT=1
  msgbox "Additional Settings" "Extra BOX64 settings will be written to your launcher script."
fi

SOUND_OPTION=$(dialog --stdout --radiolist "Pulse Audio Option" 10 90 3 \
  "nopulse" "Do not use Pulse Audio" on \
  "pulse60" "Use winetricks sound=pulse with 60 ms latency" off \
  "pulse90" "Use winetricks sound=pulse with 90 ms latency" off)
[ -z "$SOUND_OPTION" ] && SOUND_OPTION="nopulse"

DEP_OPTIONS=""
if yesno "VC++/DirectX Dependencies" "Do you want to install common VC++ runtimes and DirectX9 (d3dx9_43)?\n\nThese include VC++ 2008, 2010, 2012, 2013, and 2015-2022."; then
  DEP_OPTIONS=$(dialog --stdout --checklist "Select VC++/DirectX dependencies to install:" 15 60 8 \
    "vcrun2008" "Visual C++ 2008" off \
    "vcrun2010" "Visual C++ 2010" off \
    "vcrun2012" "Visual C++ 2012" off \
    "vcrun2013" "Visual C++ 2013" off \
    "vcrun2022" "Visual C++ 2015-2022" off \
    "d3dx9_43" "DirectX9 (d3dx9_43)" off)
fi

ADDITIONAL_WT=""
if yesno "Additional Winetricks" "Do you want to install additional winetricks packages (fetched from the official list)?"; then
  WT_URL="https://raw.githubusercontent.com/Winetricks/winetricks/master/files/verbs/all.txt"
  WT_TEMP=$(mktemp)
  curl -sL "$WT_URL" -o "$WT_TEMP"
  if [ ! -s "$WT_TEMP" ]; then
    msgbox "Error" "Failed to fetch winetricks list."
  else
    WT_PARSED=$(mktemp)
    # Drop section headers and blank lines.
    grep -v '^=====' "$WT_TEMP" | grep -v '^[[:space:]]*$' >"$WT_PARSED"
    ADD_OPTIONS=()
    while IFS= read -r line; do
      pkg=$(echo "$line" | awk '{print $1}')
      desc=$(echo "$line" | cut -d' ' -f2-)
      ADD_OPTIONS+=("$pkg" "$desc" "off")
    done <"$WT_PARSED"
    ADD_SELECTION=$(dialog --stdout --checklist "Select additional winetricks packages:" 30 85 10 "${ADD_OPTIONS[@]}")
    ADDITIONAL_WT=$(echo "$ADD_SELECTION" | tr -d '"')
    rm -f "$WT_PARSED" "$WT_TEMP"
  fi
fi

GAME_DIR="${PORTS_BASE}/${GAME_FOLDER}"
GPTK_FILE="${GAME_DIR}/${GAME_FOLDER}.gptk"
LAUNCH_SCRIPT="${PORTS_BASE}/${GAME_FOLDER}.sh"

msgbox "Creating Directories" "Creating ${GAME_DIR} (with subfolders data and config)."
mkdir -p "${GAME_DIR}/data" "${GAME_DIR}/config" "${WINE_PREFIX}"

if yesno "Keyboard Mapping" "Do you want to manually assign keyboard button mappings?\n\n(If you choose 'No', default empty mappings will be created.)"; then
  BUTTONS=("back" "start" "a" "b" "x" "y" "l1" "l2" "r1" "r2" "up" "down" "left" "right" "left_analog_up" "left_analog_down" "left_analog_left" "left_analog_right" "right_analog_up" "right_analog_down" "right_analog_left" "right_analog_right")
  GPTK_CONTENT=""
  for btn in "${BUTTONS[@]}"; do
    ask KEY_ASSIGN "Press keyboard button for the ${btn} button:"
    GPTK_CONTENT+="${btn} = \"${KEY_ASSIGN}\"\n"
  done
else
  GPTK_CONTENT="back = \"\"\nstart = \"\"\na = \"\"\nb = \"\"\nx = \"\"\ny = \"\"\nl1 = \"\"\nl2 = \"\"\nr1 = \"\"\nr2 = \"\"\nup = \"\"\ndown = \"\"\nleft = \"\"\nright = \"\"\nleft_analog_up = \"\"\nleft_analog_down = \"\"\nleft_analog_left = \"\"\nleft_analog_right = \"\"\nright_analog_up = \"\"\nright_analog_down = \"\"\nright_analog_left = \"\"\nright_analog_right = \"\""
fi

printf '%b' "$GPTK_CONTENT" >"${GPTK_FILE}"

if [ "$MODE" = "new" ]; then
  if [ ! -d "${WINE_PREFIX}/drive_c" ]; then
    msgbox "Initializing Wine Prefix" "Creating 64-bit Wine prefix at ${WINE_PREFIX}.\n\n(Note: A Wine Mono GUI prompt may appear on the main display.)"
    WINEPREFIX="${WINE_PREFIX}" wine wineboot --init
    if [ ! -d "${WINE_PREFIX}/drive_c" ]; then
      msgbox "Error" "Failed to initialize the Wine prefix. Setup aborted."
      exit 1
    fi
  fi
else
  msgbox "Modifying Wine Prefix" "Reusing the shared Wine prefix at ${WINE_PREFIX}.\n\n(Note: A Wine Mono GUI prompt may appear if components are missing.)"
fi

# wine-gecko/mono are left to Wine itself to install on first launch.

if [ "$CHOICE" != "none" ]; then
  WINEPREFIX="${WINE_PREFIX}" winetricks -q "$CHOICE"
  if [ "$CHOICE" = "dxvk" ] || [ "$CHOICE" = "dxvk2041" ]; then
    if [ ! -f "${WINE_PREFIX}/drive_c/windows/system32/dxgi.dll" ]; then
      msgbox "Error" "DXVK installation failed or dxgi.dll is missing. Game may not work properly."
    fi
  fi
fi

for pkg in $DEP_OPTIONS $ADDITIONAL_WT; do
  WINEPREFIX="${WINE_PREFIX}" winetricks -q "$pkg"
done

cat >"${LAUNCH_SCRIPT}" << 'EOF'
#!/bin/bash

# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 ROCKNIX (https://github.com/ROCKNIX)

. /etc/profile

# PortMaster control.txt provides get_controls and sdl_controllerconfig.
if [ -d "/storage/roms/ports/PortMaster" ]; then
  controlfolder="/storage/roms/ports/PortMaster"
else
  controlfolder="/storage/.config/PortMaster"
fi
[ -f "${controlfolder}/control.txt" ] && source "${controlfolder}/control.txt"

GAMEDIR="__PORTS_BASE__/__GAME_FOLDER__"
WINEPREFIX="__WINE_PREFIX__"

if [ ! -d "$GAMEDIR" ]; then
  echo "Error: Game directory missing ($GAMEDIR). Please check your installation."
  exit 1
fi

cd "$GAMEDIR"
> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1
chmod +x -R "$GAMEDIR"/*

export WINEPREFIX
export WINEDEBUG=-all
if type get_controls &>/dev/null; then
  get_controls
  [ -n "${sdl_controllerconfig}" ] && export SDL_GAMECONTROLLERCONFIG="${sdl_controllerconfig}"
fi

# Graphics and optimization options.
export DXVK_HUD=__DXVK_HUD__
export DXVK_ASYNC=__DXVK_ASYNC__
export STAGING_SHARED_MEMORY=__STAGING_SHARED_MEMORY__
export STAGING_WRITECOPY=__STAGING_WRITECOPY__
__BOX64_EXTRA_SETTINGS__

# Sound setup
__SOUND_SETUP__

if ! command -v box64 &>/dev/null || ! command -v wine &>/dev/null; then
  echo "Error: box64 or wine is missing. Install them before running the game."
  exit 1
fi
if ! command -v __GPTOKEYB__ &>/dev/null; then
  echo "Error: GPTOKEYB is missing. Install it before running the game."
  exit 1
fi

# Launch the game:
# First, launch GPToKeyB for controller mapping.
__GPTOKEYB__ "__EXE_NAME__" -c "./__GAME_FOLDER__.gptk" &
GPTK_PID=$!
# Then launch the game executable from the data folder using box64/wine.
box64 wine "$GAMEDIR/data/__EXE_PATH__"
kill "${GPTK_PID}" 2>/dev/null
EOF

sed -i "s|__PORTS_BASE__|${PORTS_BASE}|g" "${LAUNCH_SCRIPT}"
sed -i "s|__WINE_PREFIX__|${WINE_PREFIX}|g" "${LAUNCH_SCRIPT}"
sed -i "s|__GAME_FOLDER__|${GAME_FOLDER}|g" "${LAUNCH_SCRIPT}"
sed -i "s|__EXE_PATH__|${EXE_PATH}|g" "${LAUNCH_SCRIPT}"
sed -i "s|__GPTOKEYB__|${GPTOKEYB}|g" "${LAUNCH_SCRIPT}"
sed -i "s|__EXE_NAME__|${EXE_NAME}|g" "${LAUNCH_SCRIPT}"
sed -i "s|__DXVK_HUD__|${HUD_CHOICE}|g" "${LAUNCH_SCRIPT}"
sed -i "s|__DXVK_ASYNC__|${DXVK_ASYNC}|g" "${LAUNCH_SCRIPT}"
sed -i "s|__STAGING_SHARED_MEMORY__|${STAGING_SHARED_MEMORY}|g" "${LAUNCH_SCRIPT}"
sed -i "s|__STAGING_WRITECOPY__|${STAGING_WRITECOPY}|g" "${LAUNCH_SCRIPT}"
sed -i "s|__BOX64_EXTRA_SETTINGS__||g" "${LAUNCH_SCRIPT}"

if [ "$UNITY_OPT" -eq 1 ]; then
  sed -i "/# Launch the game:/i \
export BOX64_DYNAREC_SAFEFLAGS=1\n\
export BOX64_DYNAREC_FASTNAN=1\n\
export BOX64_DYNAREC_FASTROUND=1\n\
export BOX64_DYNAREC_X87DOUBLE=0\n\
export BOX64_DYNAREC_BIGBLOCK=3\n\
export BOX64_DYNAREC_STRONGMEM=0\n\
export BOX64_DYNAREC_FORWARD=512\n\
export BOX64_DYNAREC_CALLRET=1\n\
export BOX64_DYNAREC_WAIT=1\n\
export BOX64_AVX=0\n\
export BOX64_MAXCPU=8\n\
export BOX64_UNITYPLAYER=1" "${LAUNCH_SCRIPT}"
fi

SOUND_CMD=""
if [ "$SOUND_OPTION" = "pulse60" ]; then
  SOUND_CMD+="winetricks -q sound=pulse\n"
  SOUND_CMD+="export PULSE_LATENCY_MSEC=60\n"
elif [ "$SOUND_OPTION" = "pulse90" ]; then
  SOUND_CMD+="winetricks -q sound=pulse\n"
  SOUND_CMD+="export PULSE_LATENCY_MSEC=90\n"
fi

if [ -n "$SOUND_CMD" ]; then
  sed -i "s|__SOUND_SETUP__|${SOUND_CMD}|g" "${LAUNCH_SCRIPT}"
else
  sed -i "s|__SOUND_SETUP__||g" "${LAUNCH_SCRIPT}"
fi

chmod +x "${LAUNCH_SCRIPT}"

msgbox "Setup Complete" "Setup complete.
Files created/modified:
- Launch Script: ${LAUNCH_SCRIPT}
- Game Folder: ${GAME_DIR} (with subfolders data and config)
- GPTK File: ${GPTK_FILE}

Please copy your game data into the 'data' folder before launching."
clear
echo "Setup complete. Run: ${LAUNCH_SCRIPT} after you copy your game over to the data folder"
