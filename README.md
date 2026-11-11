# Chromebook Guardian

An owner-operated interactive firmware and USB-boot helper for personally owned ChromeOS devices running in Developer Mode. Initial target hardware: Lenovo 100e Gen 2 and Lenovo 100e Gen 2 AST.

## Current release

Version 1.2 provides a terminal menu with:
- **Device Information:** reports the ChromeOS board, HWID, firmware ID, architecture, and current `dev_boot_usb` value.
- **USB Boot Protection:** offers to enable or disable USB boot after an explicit `YES` confirmation, then verifies the result.
- **MrChromebox Firmware Utility:** asks for confirmation, downloads the official script from `https://mrchromebox.tech/firmware-util.sh`, and launches it with sudo.
- **Administrator Password Guide:** explains how to use the firmware's own password settings where available.
- **Safety & Limitations:** explains what the utility does and does not do.

## UEFI Boot Menu Protection

See [UEFI Boot Menu Protection Guide](UEFI_BOOT_MENU_PROTECTION.md) for the manual Setup Administrator Password procedure in MrChromebox UEFI Full ROM. The owner reports verifying that it protects the ESC boot menu and USB boot selection on a Lenovo 100e Gen 2 AST.

Chromebook Guardian does not set, read, verify, store, or transmit firmware passwords. Password operations must be performed through the firmware's own setup interface.

## Safety and limitations

- This is not a firmware password, verified-boot policy, or tamper-proof lock. A user with physical access and Developer Mode/recovery access may be able to change device configuration.
- Disabling USB boot is not guaranteed to be irreversible and may be reversible through recovery or firmware procedures.
- Guardian does not write raw firmware or NVRAM storage.
- It does not install remote desktop software, background services, persistence, or covert monitoring.
- It does not transmit device information or email credentials. Never commit Gmail App Passwords, SMTP credentials, tokens, or other secrets to this public repository.
- Remote monitoring, if added later, should be transparent to device users, authenticated, encrypted, and revocable. Never expose an unauthenticated remote desktop server to the public internet.
- Firmware settings and command availability can vary by board and firmware. Test on each device and keep a recovery path.

## Run

Review the script before running it. Download it first rather than piping an unreviewed remote script directly into a shell:

```bash
curl -fsSLo guardian.sh https://raw.githubusercontent.com/kaz1071/chromebook-guardian/main/guardian.sh
less guardian.sh
chmod +x guardian.sh
./guardian.sh
```

Run from a ChromeOS Developer Mode VT-2 shell as `chronos`. The script uses `sudo` for firmware reads and writes and asks for explicit confirmation before changing USB boot configuration or launching the MrChromebox utility.

## License

MIT. See [LICENSE](LICENSE).
