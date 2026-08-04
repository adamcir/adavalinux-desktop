# Dual LXPanel Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Provide clean, separate top and bottom LXPanel instances for the AdavaLinux LXDE session.

**Architecture:** Keep the existing `panel` profile as the bottom taskbar and add a `top` profile for status controls.  LXPanel automatically loads every file below the LXDE `panels` directory, so no second launch command is required.

**Tech Stack:** POSIX shell, LXPanel 0.10, LXSession, Openbox.

---

### Task 1: Assert the two panel profiles

**Files:**
- Modify: `tests/session_layout_test.sh`
- Modify: `packages/adavalinux-desktop/install.sh`

**Step 1:** Write a test requiring `panel` and `top` configuration files, a bottom taskbar, and a top date/power configuration.

**Step 2:** Run `sh tests/session_layout_test.sh`; it must fail because `top` does not exist.

**Step 3:** Generate the two LXPanel profile files in `install.sh`.

**Step 4:** Re-run the test and require a pass.

### Task 2: Build and inspect the package

**Files:**
- Build: `out/adavalinux-desktop-0.1.0.syspckg`

**Step 1:** Run all focused shell tests.

**Step 2:** Run `make clean && make package`.

**Step 3:** Inspect the archive for `install.sh` and the session launcher, then copy the archive to the package repository.
