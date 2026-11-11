# Chromebook Guardian

An owner-operated diagnostic and USB-boot configuration helper for personally owned ChromeOS devices running in Developer Mode. Initial target hardware: Lenovo 100e Gen 2 and Lenovo 100e Gen 2 AST.

## Current release

This is an interactive, local utility. It:
- Reports the ChromeOS board, HWID, firmware ID, architecture, and current `dev_boot_usb` value.
- Offers to set `dev_boot_usb=0` only after explicit confirmation.
- Reads the setting back and reports whether the change succeeded.
- Provides the matching command to restore the previous value.

## UEFI Boot Menu Protection

See [UEFI Boot Menu Protection Guide](UEFI_BOOT_MENU_PROTECTION.md) for the manual Setup Administrator Password procedure in MrChromebox UEFI Full ROM. The owner reports verifying that it protects the ESC boot menu and USB boot selection on a Lenovo 100e Gen 2 AST. This is device/firmware-specific; Chromebook Guardian does not set, read, store, or transmit firmware passwords.

## Safety and limitations

- This is not a firmware password, verified-boot policy, or tamper-proof lock. A user with physical access and Developer Mode/recovery access may be able to change device configuration.
- It does not install remote desktop software, noVNC, background services, persistence, or covert monitoring.
- It does not transmit device information or email credentials. Never commit Gmail App Passwords, SMTP credentials, tokens, or other secrets to this public repository.
- Remote monitoring, if added later, should be transparent to device users, authenticated, encrypted, and revocable. Never expose an unauthenticated noVNC server to the public internet.
- Firmware settings and command availability can vary by board and firmware. Test on each device and keep a recovery path.

## Run

Review the script before running it. Download it first rather than piping an unreviewed remote script directly into a shell:

```bash
curl -fsSLo guardian.sh https://raw.githubusercontent.com/kaz1071/chromebook-guardian/main/guardian.sh
less guardian.sh
chmod +x guardian.sh
./guardian.sh
```

Run from a ChromeOS Developer Mode VT-2 shell as `chronos`. The script uses `sudo` for firmware reads/writes and asks before changing the setting.

## License

MIT. See [LICENSE](LICENSE).
