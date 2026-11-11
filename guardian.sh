#!/bin/bash
# Chromebook Guardian - interactive local USB-boot configuration helper
# Targets: Lenovo 100e Gen 2 / Gen 2 AST (and other ChromeOS boards with crossystem)
# No network calls, email, remote access, persistence, or background monitoring.

set -u

echo "======================================"
echo "       CHROMEBOOK GUARDIAN 1.0"
echo "======================================"
echo
echo "This tool only inspects firmware settings and, with your confirmation,"
echo "can set dev_boot_usb=0. It does not create a firmware password."
echo

if ! command -v crossystem >/dev/null 2>&1; then
  echo "ERROR: crossystem is not available in this shell."
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "ERROR: sudo is not available."
  exit 1
fi

if [ ! -r /etc/lsb-release ]; then
  echo "WARNING: ChromeOS release information is unavailable."
fi

BOARD="$(grep -E '^CHROMEOS_RELEASE_BOARD=' /etc/lsb-release 2>/dev/null | cut -d= -f2- | tr -d '"')"
VERSION="$(grep -E '^CHROMEOS_RELEASE_VERSION=' /etc/lsb-release 2>/dev/null | cut -d= -f2- | tr -d '"')"
HWID="$(sudo crossystem hwid 2>/dev/null || true)"
FWID="$(sudo crossystem fwid 2>/dev/null || true)"
CURRENT="$(sudo crossystem dev_boot_usb 2>/dev/null || true)"

echo "Device information"
echo "------------------"
echo "Board:        ${BOARD:-unknown}"
echo "OS version:   ${VERSION:-unknown}"
echo "HWID:         ${HWID:-unavailable}"
echo "Firmware ID:  ${FWID:-unavailable}"
echo "Architecture: $(uname -m)"
echo "USB boot:     ${CURRENT:-unavailable}"
echo

if [ -z "$CURRENT" ]; then
  echo "ERROR: Could not read dev_boot_usb. No changes were made."
  exit 1
fi

if [ "$CURRENT" = "0" ]; then
  echo "USB boot is already disabled (dev_boot_usb=0)."
  exit 0
fi

if [ "$CURRENT" != "1" ]; then
  echo "WARNING: Unexpected dev_boot_usb value '$CURRENT'."
  echo "No changes were made because the value is not recognized."
  exit 1
fi

echo "The current value is 1 (USB boot enabled)."
echo "This change is not a guaranteed security boundary and may be"
echo "reversible through device recovery or firmware procedures."
echo
read -r -p "Set dev_boot_usb=0 on this Chromebook? Type YES to confirm: " answer

if [ "$answer" != "YES" ]; then
  echo "Cancelled. No changes were made."
  exit 0
fi

if ! sudo crossystem dev_boot_usb=0; then
  echo "ERROR: crossystem could not set the value."
  exit 1
fi

VERIFY="$(sudo crossystem dev_boot_usb 2>/dev/null || true)"
if [ "$VERIFY" = "0" ]; then
  echo
  echo "SUCCESS: dev_boot_usb is now 0."
  echo "Verify it later with: sudo crossystem dev_boot_usb"
  echo
  echo "To restore the previous value (1), run:"
  echo "  sudo crossystem dev_boot_usb=1"
else
  echo "WARNING: Verification failed. Current value: ${VERIFY:-unavailable}"
  echo "Inspect the device firmware and ChromeOS documentation before retrying."
  exit 1
fi
