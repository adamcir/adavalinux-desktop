# LightDM Login Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Start LightDM on tty1 after installing `adavalinux-desktop`, provide an XFCE session at login, and restore the ordinary tty1 getty when the desktop package is removed.

**Architecture:** LightDM and its greeter are ordinary syspckg packages; `adavalinux-desktop` declares them as dependencies and supplies the XFCE XSession descriptor plus LightDM configuration. The desktop package install hook changes only the tty1 inittab entry to a supervised display-manager launcher. Its remove hook restores the original getty entry so a non-desktop system boots normally.

**Tech Stack:** BusyBox init/inittab, LightDM, GTK greeter, PAM, XFCE, syspckg archives and install/remove hooks.

---

### Task 1: Package and validate LightDM runtime

**Files:**

- Create: `../syspckg/lightdm-<version>/`
- Create: `../syspckg/lightdm-gtk-greeter-<version>/`
- Test: `../syspckg/lightdm-<version>/tests/runtime_test.sh`

**Step 1: Write the failing test**

Assert that the LightDM archive includes `/usr/sbin/lightdm`, a default configuration selecting the GTK greeter, required PAM files, and all dynamically linked runtime libraries. Assert that the greeter archive contains the executable and desktop resources.

**Step 2: Run test to verify it fails**

Run the test against the absent package directories. Expected: missing archive/runtime files.

**Step 3: Write minimal implementation**

Build or import compatible x86_64 LightDM and GTK greeter files, declare every runtime package dependency, and package their PAM/config files. Do not place archives in the live ISO package cache.

**Step 4: Run test to verify it passes**

Inspect the archives with `tar -tJf`, `readelf`, and a disposable target root.

**Step 5: Commit**

Do not commit: the user explicitly requested no commits while testing.

### Task 2: Add LightDM integration to the desktop package

**Files:**

- Modify: `packages/adavalinux-desktop/syspckg-deps`
- Modify: `Makefile`
- Create: `lightdm/lightdm.conf`
- Create: `lightdm/adavalinux-xfce.desktop`
- Test: `tests/lightdm_package_test.sh`

**Step 1: Write the failing test**

Verify desktop dependencies require LightDM and greeter; verify the archive ships `/etc/lightdm/lightdm.conf` and `/usr/share/xsessions/adavalinux-xfce.desktop`; verify the session runs `/usr/bin/startxfce4`.

**Step 2: Run test to verify it fails**

Run the test before integration. Expected: missing dependencies and files.

**Step 3: Write minimal implementation**

Package a LightDM configuration with `[Seat:*]`, `greeter-session=lightdm-gtk-greeter`, `user-session=adavalinux-xfce`; package the XFCE session descriptor; declare LightDM packages.

**Step 4: Run test to verify it passes**

Build `adavalinux-desktop` and inspect its archive.

**Step 5: Commit**

Do not commit: testing-only workflow.

### Task 3: Switch tty1 safely on install and restore it on removal

**Files:**

- Modify: `packages/adavalinux-desktop/install.sh`
- Create: `packages/adavalinux-desktop/remove.sh`
- Modify: `../AdavaLinux/tools/syspckg/main.c`
- Test: `../AdavaLinux/tools/syspckg/tests/package_remove_hook_test.sh`
- Test: `tests/lightdm_inittab_test.sh`

**Step 1: Write the failing tests**

Use a temporary root with a standard inittab. Test that desktop installation replaces only tty1 with `respawn:/usr/sbin/lightdm`, preserves tty2–tty7 and ttyS0, and that removing the desktop restores the standard tty1 getty. Add a syspckg test proving a package `remove.sh` executes before its files are deleted.

**Step 2: Run tests to verify they fail**

Expected: no remove hook and no managed tty1 transition.

**Step 3: Write minimal implementation**

Add lifecycle support for a `remove.sh` package hook. In the desktop install hook, retain an idempotent backup of the original tty1 line and replace it with LightDM. In the removal hook, stop LightDM if present and restore exactly that saved getty line; do not alter any other inittab entry.

**Step 4: Run tests to verify they pass**

Run the syspckg lifecycle test and desktop inittab test; rebuild and inspect the archive.

**Step 5: Commit**

Do not commit: testing-only workflow.

### Task 4: End-to-end image verification

**Files:**

- Test: `../AdavaLinux/tests/lightdm_installed_system_test.sh`

**Step 1: Write the failing test**

Require the installed root to contain the LightDM tty1 entry, display-manager executable, greeter configuration, and XFCE session file; require a simulated desktop removal to restore the getty entry.

**Step 2: Run test to verify it fails**

Expected: absent LightDM integration.

**Step 3: Write minimal implementation**

Build packages, repack `adavalinux-desktop`, replace only its archive in `../syspckg/packages`, rebuild the installer/ISO artifacts.

**Step 4: Run test to verify it passes**

Run all new tests, existing installer tests, package archive checks, and boot QEMU to confirm tty1 presents LightDM while Ctrl+Alt+F2 remains usable.

**Step 5: Commit**

Do not commit: testing-only workflow.
