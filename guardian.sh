#!/bin/bash
# Chromebook Guardian - interactive firmware and USB-boot helper
# Owner-operated utility for ChromeOS devices in Developer Mode.
# No network calls, email, remote access, persistence, or background monitoring.

set -u
VERSION="1.1"

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
  if ! command -v crossystem >/dev/null 2>&1; then
    echo "ERROR: crossystem is not available in this shell."
    pause
    return
  fi
  if ! command -v sudo >/dev/null 2>&1; then
    echo "ERROR: sudo is not available."
    pause
    return
  fi

  current="$(read_crossystem dev_boot_usb)"
  echo
  echo "========== USB BOOT PROTECTION =========="
  case "$current" in
    0)
      echo "Current setting: USB boot is DISABLED (dev_boot_usb=0)."
      target=1
      echo "1. Enable USB boot"
      ;;
    1)
      echo "Current setting: USB boot is ENABLED (dev_boot_usb=1)."
      target=0
      echo "1. Disable USB boot"
      ;;
    *)
      echo "Could not read a recognized dev_boot_usb value."
      echo "Reported value: ${current:-unavailable}"
      echo "No changes can be made."
      pause
      return
      ;;
  esac
  echo "2. Return to main menu"
  read -r -p "Select an option: " choice
  if [ "$choice" != "1" ]; then return; fi

  if [ "$target" = "0" ]; then
    echo
    echo "This disables the firmware's USB boot setting."
    echo "It is not a guaranteed security boundary and may be reversible"
    echo "through recovery or firmware procedures."
    read -r -p "Type YES to disable USB boot: " answer
  else
    echo
    echo "This enables booting from USB devices."
    read -r -p "Type YES to enable USB boot: " answer
  fi

  if [ "$answer" != "YES" ]; then
    echo "Cancelled. No changes were made."
    pause
    return
  fi

  if ! sudo crossystem "dev_boot_usb=$target"; then
    echo "ERROR: crossystem could not change the setting."
    pause
    return
  fi

  verify="$(read_crossystem dev_boot_usb)"
  if [ "$verify" = "$target" ]; then
    echo "SUCCESS: dev_boot_usb is now $target."
  else
    echo "WARNING: Verification failed. Current value: ${verify:-unavailable}"
  fi
  pause
}

uefi_setup_instructions() {
  cd; curl -LOf mrchromebox.tech/firmware-util.sh && sudo bash firmware-util.sh
  pause
}

password_guide() {
  echo
  echo "========== UEFI PASSWORD GUIDE =========="
  echo "On firmware versions where the option is available:"
  echo "1. Restart and repeatedly press ESC at the firmware splash screen."
  echo "2. Open Device Manager > System Setup."
  echo "3. Open Security Configuration."
  echo "4. Look for Setup Administrator Password or User Password Management."
  echo "5. Follow the firmware's prompts to set, change, or remove a password."
  echo
  echo "IMPORTANT:"
  echo "- This guide does not set, read, verify, or remove the password."
  echo "- Do not use a shared or publicly known default password."
  echo "- Keep your password somewhere secure; losing it may prevent setup access."
  echo "- Available options vary by firmware build and device."
  pause
}

safety_information() {
  echo
  echo "========== SAFETY & LIMITATIONS =========="
  echo "- Guardian is a local, owner-operated utility."
  echo "- USB boot changes are not an irreversible lock."
  echo "- Firmware password management must be performed in firmware setup."
  echo "- Guardian does not write raw firmware or NVRAM storage."
  echo "- No network, email, remote desktop, background service, or monitoring."
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
    echo "  3. UEFI Firmware Setup"
    echo "  4. Administrator Password Guide"
    echo "  5. Safety & Limitations"
    echo "  6. Exit"
    echo "=========================================="
    echo
    read -r -p "Select an option [1-6]: " choice
    case "$choice" in
      1) show_device_info; pause ;;
      2) usb_boot_menu ;;
      3) uefi_setup_instructions ;;
      4) password_guide ;;
      5) safety_information ;;
      6) echo "Chromebook Guardian closed."; exit 0 ;;
      *) echo "Invalid selection."; sleep 1 ;;
    esac
  done
}

if ! command -v sudo >/dev/null 2>&1; then
  echo "WARNING: sudo is not available. Firmware information may be limited."
  echo "USB boot configuration will be unavailable."
  read -r -p "Press Enter to continue..." _
fi

main_menu
