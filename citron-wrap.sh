#!/bin/bash
emuName="citron"

# ============================================================
# Citron wrapper (Steam Deck) - auto swap qt-config.ini by mode
#
# Requires these files (you create once):
#   ~/.config/citron/qt-config.desktop.ini
#   ~/.config/citron/qt-config.gamemode.ini
# ============================================================

# --- Persistent log ---
LOG="$HOME/.local/state/citron-wrap.log"
mkdir -p "$(dirname "$LOG")"

# --- Log rotate (keep log from growing forever) ---
rotate_log() {
  local log="$1"
  local max_bytes=$((512 * 1024))   # 512 KB
  local keep_lines=3500

  [[ -f "$log" ]] || return 0

  local size
  size=$(stat -c%s "$log" 2>/dev/null || echo 0)

  if [[ "$size" -gt "$max_bytes" ]]; then
    local tmp="${log}.tmp"
    if tail -n "$keep_lines" "$log" > "$tmp" 2>/dev/null; then
      mv "$tmp" "$log"
    else
      rm -f "$tmp" 2>/dev/null || true
    fi
  fi
}
rotate_log "$LOG"

{
  echo "============================================================"
  echo "[$(date -Is)] START"
  echo "XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-<unset>}"
  echo "XDG_SESSION_DESKTOP=${XDG_SESSION_DESKTOP:-<unset>}"
  echo "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-<unset>}"
} >> "$LOG" 2>&1

# --- Force consistent config root across Desktop/Game Mode ---
export XDG_CONFIG_HOME="$HOME/.config"

# --- Determine Game Mode (gamescope) ---
is_gamemode() {
  [[ "${XDG_CURRENT_DESKTOP:-}" == *gamescope* ]] && return 0
  [[ "${XDG_SESSION_DESKTOP:-}" == *gamescope* ]] && return 0
  pgrep -x gamescope >/dev/null 2>&1 && return 0
  return 1
}

# ------------------------------------------------------------
# Swap qt-config.ini (GUID mappings live here)
# ------------------------------------------------------------
CFG_DIR="$HOME/.config/citron"
ACTIVE_QT="$CFG_DIR/qt-config.ini"
DESKTOP_QT="$CFG_DIR/qt-config.desktop.ini"
GAMEMODE_QT="$CFG_DIR/qt-config.gamemode.ini"

MODE="desktop"
SRC="$DESKTOP_QT"
if is_gamemode; then
  MODE="gamemode"
  SRC="$GAMEMODE_QT"
fi

echo "Detected mode: $MODE" >> "$LOG" 2>&1
echo "Config source: $SRC" >> "$LOG" 2>&1

if [[ -f "$SRC" ]]; then
  if [[ ! -f "$ACTIVE_QT" ]] || ! cmp -s "$SRC" "$ACTIVE_QT"; then
    cp -a "$SRC" "$ACTIVE_QT" >> "$LOG" 2>&1
    echo "Applied qt-config swap" >> "$LOG" 2>&1
  else
    echo "qt-config already matches $SRC (no change)" >> "$LOG" 2>&1
  fi
else
  echo "WARN: Missing $SRC (not modifying qt-config.ini)" >> "$LOG" 2>&1
fi

# Quick sanity: log the first GUID seen (if any)
firstGuid=$(grep -oE 'guid:[0-9a-fA-F]{32}' "$ACTIVE_QT" 2>/dev/null | head -n 1 || true)
echo "First GUID: ${firstGuid:-<none found>}" >> "$LOG" 2>&1

# ------------------------------------------------------------
# Prevent Steam overlay preload mismatch spam/crashes (optional)
# ------------------------------------------------------------
export STEAM_DISABLE_GAMEOVERLAY=1
if [[ -n "${LD_PRELOAD:-}" ]]; then
  LD_PRELOAD="$(echo "$LD_PRELOAD" | tr ':' '\n' | grep -v -i 'gameoverlayrenderer\.so' | paste -sd ':' -)"
  export LD_PRELOAD
fi

# ------------------------------------------------------------
# EmuDeck init (keep if present)
# ------------------------------------------------------------
if [[ -f "$HOME/.config/EmuDeck/backend/functions/all.sh" ]]; then
  # shellcheck disable=SC1090
  . "$HOME/.config/EmuDeck/backend/functions/all.sh"
  emulatorInit "$emuName"
else
  echo "WARN: EmuDeck functions not found." >> "$LOG" 2>&1
fi

# ------------------------------------------------------------
# Locate & launch Citron
# ------------------------------------------------------------
appimage=""

# Prefer EmuDeck-managed emulators folder
if [[ -n "${emusFolder:-}" ]]; then
  appimage=$(find "$emusFolder" -maxdepth 2 -type f -iname "${emuName}*.AppImage" -print -quit 2>/dev/null)
fi

# Fallback: your ~/Applications
if [[ -z "$appimage" ]]; then
  appimage=$(find "$HOME/Applications" -maxdepth 1 -type f \( -iname "Citron*.AppImage" -o -iname "citron*.AppImage" \) -print -quit 2>/dev/null)
fi

if [[ -z "$appimage" ]]; then
  echo "ERROR: Citron AppImage not found." >> "$LOG" 2>&1
  exit 127
fi

chmod +x "$appimage" >> "$LOG" 2>&1 || true

echo "Launching: $appimage $*" >> "$LOG" 2>&1

"$appimage" "$@" >> "$LOG" 2>&1
exitCode=$?

echo "Citron exit code: $exitCode" >> "$LOG" 2>&1

# EmuDeck housekeeping (guarded)
if command -v cloud_sync_uploadForced >/dev/null 2>&1; then
  cloud_sync_uploadForced >> "$LOG" 2>&1
fi
if [[ -n "${savesPath:-}" ]]; then
  rm -rf "$savesPath/.gaming" >> "$LOG" 2>&1
fi

echo "[$(date -Is)] END" >> "$LOG" 2>&1
exit $exitCode
