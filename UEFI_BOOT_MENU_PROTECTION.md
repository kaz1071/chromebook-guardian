# UEFI Boot Menu Protection Guide

Chromebook Guardian can guide an owner through the UEFI firmware's built-in Setup Administrator Password option. It does **not** set, read, store, or transmit the password.

## Compatibility

The owner of this project reports testing this behavior on a Lenovo 100e Gen 2 AST running MrChromebox UEFI Full ROM:

1. Power on or restart the Chromebook.
2. Press `ESC` repeatedly at the boot splash to open the UEFI Main Menu.
3. Select **Device Manager**.
4. Select **System Setup**.
5. Select **Security Configuration**.
6. Select **Setup Administrator Password** (or, if shown by that firmware build, **User Password Management**).
7. Set a strong password and confirm it.

On the tested AST setup, the owner reports that pressing `ESC` afterward requires the password and prevents access to the boot menu, including USB boot selection.

**This is an owner-reported result for that specific setup, not a guarantee for every Chromebook, MrChromebox build, or UEFI configuration.** Menu labels and behavior can vary.

## Before enabling it

- Make sure you have a reliable, private way to retain the password. Do not put it in this repository, a script, email, issue, or shared notes.
- Confirm you understand the firmware's documented password-clear and recovery process for your exact device before setting it.
- Keep a recovery plan and any required recovery media available.
- Do not assume this password prevents every possible firmware modification, hardware-level attack, or recovery procedure.
- Test the behavior on a device you own and are authorized to administer.

## Verify

After setting the password, restart and press `ESC`. Confirm that the firmware requests the password before allowing access to the Main Menu. On the exact device and firmware tested, also verify that USB boot selection is inaccessible without the password.

If the behavior differs, stop and consult the documentation for that exact MrChromebox firmware build. Do not repeatedly guess passwords.

## Chromebook Guardian scope

This guide is informational. Chromebook Guardian does not automate firmware password changes because password interfaces and firmware variables are implementation-specific, and an error could lock the owner out. The password never leaves the firmware setup interface.
