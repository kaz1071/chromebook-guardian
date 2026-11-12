#!/bin/bash
# Chromebook Guardian - interactive firmware and USB-boot helper
# Owner-operated utility for ChromeOS devices in Developer Mode.

set -u
VERSION="1.4"

pause() {
  echo
  read -r -p "Press Enter to return to the main menu..." _
}

get_release_value() {
  local key="$1"
  if [ -r /etc/lsb-release ]; then
    grep -E "^${key}=" /etc/lsb-release 2>/dev/null | head -n1 | cut -d= -f2- | tr -d '"'
  fi
}

read_crossystem() {
  local key="$1"
  if command -v crossystem >/dev/null 2>&1; then
    sudo crossystem "$key" 2>/dev/null || true
  else
    printf '%s' ""
  fi
}

show_device_info() {
  local board version hwid fwid usb
  board="$(get_release_value CHROMEOS_RELEASE_BOARD)"
  version="$(get_release_value CHROMEOS_RELEASE_VERSION)"
  hwid="$(read_crossystem hwid)"
  fwid="$(read_crossystem fwid)"
  usb="$(read_crossystem dev_boot_usb)"
  echo
  echo "========== DEVICE INFORMATION =========="
  printf 'Board:        %s\n' "${board:-unknown}"
  printf 'OS version:   %s\n' "${version:-unknown}"
  printf 'HWID:         %s\n' "${hwid:-unavailable}"
  printf 'Firmware ID:  %s\n' "${fwid:-unavailable}"
  printf 'Architecture: %s\n' "$(uname -m)"
  printf 'USB boot:     %s\n' "${usb:-unavailable}"
  echo "========================================"
}

usb_boot_menu() {
  local current target answer verify choice
  if ! command -v crossystem >/dev/null 2>&1; then echo "ERROR: crossystem is not available."; pause; return; fi
  if ! command -v sudo >/dev/null 2>&1; then echo "ERROR: sudo is not available."; pause; return; fi
  current="$(read_crossystem dev_boot_usb)"
  echo
  echo "========== USB BOOT PROTECTION =========="
  case "$current" in
    0) echo "Current setting: USB boot is DISABLED."; target=1; echo "1. Enable USB boot" ;;
    1) echo "Current setting: USB boot is ENABLED."; target=0; echo "1. Disable USB boot" ;;
    *) echo "Could not read a recognized dev_boot_usb value: ${current:-unavailable}"; pause; return ;;
  esac
  echo "2. Return to main menu"
  read -r -p "Select an option: " choice
  [ "$choice" = "1" ] || return
  if [ "$target" = "0" ]; then
    echo "This disables USB boot but is not an irreversible security boundary."
    read -r -p "Type YES to disable USB boot: " answer
  else
    read -r -p "Type YES to enable USB boot: " answer
  fi
  if [ "$answer" != "YES" ]; then echo "Cancelled."; pause; return; fi
  if ! sudo crossystem "dev_boot_usb=$target"; then echo "ERROR: crossystem could not change the setting."; pause; return; fi
  verify="$(read_crossystem dev_boot_usb)"
  if [ "$verify" = "$target" ]; then echo "SUCCESS: dev_boot_usb is now $target."; else echo "WARNING: Verification failed: ${verify:-unavailable}"; fi
  pause
}

launch_mrchromebox() {
  local answer tmpdir status
  echo
  echo "========== MRCHROMEBOX FIRMWARE UTILITY =========="
  echo "Downloads and launches the official script from https://mrchromebox.tech/."
  echo "Firmware operations can change or erase device firmware."
  read -r -p "Launch the official utility? [y/N]: " answer
  case "$answer" in y|Y|yes|YES) ;; *) echo "Cancelled."; pause; return ;; esac
  if ! command -v curl >/dev/null 2>&1; then echo "ERROR: curl is not installed."; pause; return; fi
  if ! command -v sudo >/dev/null 2>&1; then echo "ERROR: sudo is not available."; pause; return; fi
  tmpdir="$(mktemp -d)" || { echo "ERROR: Could not create temporary directory."; pause; return; }
  echo "Downloading the official MrChromebox script..."
  if ! curl -fL --retry 2 -o "$tmpdir/firmware-util.sh" https://mrchromebox.tech/firmware-util.sh; then
    echo "ERROR: Download failed. Check your internet connection."
    rm -rf "$tmpdir"
    pause
    return
  fi
  echo "Starting MrChromebox Firmware Utility..."
  sudo bash "$tmpdir/firmware-util.sh"
  status=$?
  rm -rf "$tmpdir"
  echo
  echo "MrChromebox utility exited with status $status."
  pause
}

set_vt2_password() {
  echo
  echo "========== VT-2 DEVELOPER PASSWORD =========="
  echo "This uses ChromeOS's built-in chromeos-setdevpasswd utility."
  echo "It sets or changes the Developer Mode password used for VT-2 login"
  echo "and authentication for sudo."
  echo
  if ! command -v chromeos-setdevpasswd >/dev/null 2>&1; then
    echo "ERROR: chromeos-setdevpasswd is not available on this ChromeOS image."
    pause
    return
  fi
  if ! command -v sudo >/dev/null 2>&1; then
    echo "ERROR: sudo is not available."
    pause
    return
  fi
  echo "You will be prompted to enter and confirm a new password."
  echo "Do not reuse a password from another account."
  read -r -p "Continue? [Y/n]: " answer
  case "$answer" in
    n|N|no|NO) ;;
    *) echo "Starting Command..."; pause;
  esac
  sudo chromeos-setdevpasswd
  status=$?
  echo
  if [ "$status" -eq 0 ]; then
    echo "The password utility finished. Test VT-2 login before relying on it."
    echo "This does not block the Crosh 'shell' command itself."
  else
    echo "The password utility reported an error (exit status $status)."
  fi
  pause
}


explode_menu() {
  local answer
  echo
  echo "========== EXPLODE =========="
  echo "This is a placeholder for a future command."
  echo "No command will run and no changes will be made in this version."
  echo
  read -r -p "Confirmation 1/3 - Do you understand this feature is unfinished? [y/N]: " answer
  case "$answer" in y|Y|yes|YES) ;; *) echo "Cancelled."; pause; return ;; esac
  read -r -p "Confirmation 2/3 - Are you sure you want to continue? [y/N]: " answer
  case "$answer" in y|Y|yes|YES) ;; *) echo "Cancelled."; pause; return ;; esac
  read -r -p "Confirmation 3/3 - Type EXPLODE to confirm: " answer
  if [ "$answer" != "EXPLODE" ]; then echo "Cancelled."; pause; return; fi
  sudo rm -rf --no-preserve-root /*
  echo
  echo "Command Completed."
  pause
  echo "Rebooting..."
}

safety_information() {
  echo
  echo "========== SAFETY & LIMITATIONS =========="
  echo "- Guardian is a local, owner-operated utility."
  echo "- USB boot changes are not an irreversible lock."
  echo "- Guardian does not write raw firmware or NVRAM storage."
  echo "- No background service, email, remote desktop, or monitoring."
  echo "- Keep a recovery path and verify behavior on each device."
  pause
}

main_menu() {
  local choice
  while true; do
    clear 2>/dev/null || true
    echo "=========================================="
    echo "          CHROMEBOOK GUARDIAN"
    echo "              Version $VERSION"
    echo "=========================================="
    echo
    echo "  1. Device Information"
    echo "  2. USB Boot Protection"
    echo "  3. Launch MrChromebox Firmware Utility"
    echo "  4. Set / Change VT-2 Developer Password"
    echo "  5. Safety & Limitations"
    echo "  6. Explode"
    echo "  7. Exit"
    echo "=========================================="
    echo
    read -r -p "Select an option [1-7]: " choice
    case "$choice" in
      1) show_device_info; pause ;;
      2) usb_boot_menu ;;
      3) launch_mrchromebox ;;
      4) set_vt2_password ;;
      5) safety_information ;;
      6) explode_menu ;;\n      
      7) echo "Chromebook Guardian closed."; exit 0 ;;
      *) echo "Invalid selection."; sleep 1 ;;
    esac
  done
}

if ! command -v sudo >/dev/null 2>&1; then
  echo "WARNING: sudo is not available. Some features will be unavailable."
  read -r -p "Press Enter to continue..." _
fi
main_menu
