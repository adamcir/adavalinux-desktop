# AdavaLinux Desktop Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Deliver an AdavaLinux-branded Openbox desktop with a mouse-usable logon window, login panel, user desktop icons, and an application panel.

**Architecture:** Xorg starts once and is probed with a real X11 client before the display manager starts Openbox.  The logon window is an AdavaLinux X11 dialog that exits after PAM authentication.  Openbox handles windows while PCManFM supplies desktop icons and LXPanel supplies separately configured login and user panels.

**Tech Stack:** POSIX shell, C11, Xlib, PAM, Xorg, Openbox, PCManFM, LXPanel, syspckg packages.

---

### Task 1: Make Xorg readiness and failure handling reliable

**Files:**
- Modify: `adavalinux-display-manager:4-16`
- Modify: `Makefile:13-16, 42-54`
- Modify: `packages/adavalinux-desktop/syspckg-deps`
- Test: `tests/display_vt_test.sh`

**Step 1: Write the failing test**

Extend `tests/display_vt_test.sh` to require an X11 client probe after the
socket check, require that Xorg death writes an error and exits, and reject the
unconditional `|| true` logon restart loop.

**Step 2: Run test to verify it fails**

Run: `sh tests/display_vt_test.sh`

Expected: failure because the manager only checks `/tmp/.X11-unix/X0`.

**Step 3: Write minimal implementation**

Package `xdpyinfo` and its runtime libraries.  Start Xorg with a dedicated log
file, wait for `DISPLAY=:0 xdpyinfo` to succeed while checking the Xorg PID,
and print the Xorg log then exit if it dies.  Treat a logon exit as an
intentional handoff only after successful authentication; otherwise report the
exit code and restart with a bounded delay.

**Step 4: Run test to verify it passes**

Run: `sh tests/display_vt_test.sh`

Expected: `desktop display VT test passed`.

**Step 5: Commit**

```bash
git add adavalinux-display-manager Makefile packages/adavalinux-desktop/syspckg-deps tests/display_vt_test.sh
git commit -m "fix: wait for usable X display"
```

### Task 2: Add a testable mouse and keyboard logon form

**Files:**
- Modify: `adavalinux-logon.c:91-165`
- Test: `tests/logon_source_test.sh`

**Step 1: Write the failing test**

Create a source-level regression test requiring `ButtonPressMask`, a
`ButtonPress` handler, focus assignment to username on mapping, clickable
username/password fields, and Login/Power/Restart buttons.  Require that the
successful-login path returns from `main` rather than retaining the logon window
window.

**Step 2: Run test to verify it fails**

Run: `sh tests/logon_source_test.sh`

Expected: failure because the logon window currently selects only expose and key
events and loops after a session ends.

**Step 3: Write minimal implementation**

Define explicit rectangles for inputs and buttons.  Render filled input and
button controls, set input focus using `XSetInputFocus`, handle clicks by
selecting fields or invoking the same submit function as Return, and send
power actions through a narrowly defined system command.  On a successful PAM
login, destroy/close the X display and return zero so the manager can launch
the user session.

**Step 4: Run test to verify it passes**

Run: `sh tests/logon_source_test.sh && make build/usr/bin/adavalinux-logon`

Expected: source test passes and the logon window compiles with `-Werror`.

**Step 5: Commit**

```bash
git add adavalinux-logon.c tests/logon_source_test.sh
git commit -m "feat: add mouse controls to logon"
```

### Task 3: Package the Openbox, PCManFM, and LXPanel runtime

**Files:**
- Modify: `packages/adavalinux-desktop/syspckg-deps`
- Modify: `Makefile:13-66`
- Create: `openbox/rc.xml`
- Create: `lxpanel/login-panel.conf`
- Create: `lxpanel/user-panel.conf`
- Create: `pcmanfm/desktop.conf`
- Create: `desktop/root.desktop`
- Create: `desktop/home.desktop`
- Test: `tests/desktop_runtime_package_test.sh`

**Step 1: Write the failing test**

Add a package-source test requiring Openbox, PCManFM, LXPanel, and their
libraries in dependencies; all five configuration/launcher assets as Makefile
targets; and matching installed asset paths below
`/usr/share/adavalinux/desktop/`.

**Step 2: Run test to verify it fails**

Run: `sh tests/desktop_runtime_package_test.sh`

Expected: failure because these dependencies and assets do not exist.

**Step 3: Write minimal implementation**

Add dependencies using the repository's exact available package names and
versions.  Install immutable defaults beneath
`/usr/share/adavalinux/desktop/{openbox,lxpanel,pcmanfm,launchers}`.  Configure
LXPanel's login layout with clock, network applet and system actions; configure
the user layout with menu, taskbar, workspace switching and notification area.
Add PCManFM desktop launchers for `/` and `$HOME`; enable automatic mounted
volume display where PCManFM supports it.

**Step 4: Run test to verify it passes**

Run: `sh tests/desktop_runtime_package_test.sh && make clean && make all && make package`

Expected: asset test passes and both syspckg archives are produced.

**Step 5: Commit**

```bash
git add Makefile packages/adavalinux-desktop/syspckg-deps openbox lxpanel pcmanfm desktop tests/desktop_runtime_package_test.sh
git commit -m "feat: package Openbox desktop runtime"
```

### Task 4: Split login and user session launchers

**Files:**
- Modify: `adavalinux-display-manager:4-16`
- Modify: `adavalinux-session:1-26`
- Create: `adavalinux-login-session`
- Test: `tests/session_layout_test.sh`

**Step 1: Write the failing test**

Create a test requiring the login session to launch Openbox plus the login
LXPanel before the logon window, and the user session to launch Openbox, PCManFM
desktop mode, and only the user LXPanel.  Assert that each process has cleanup
handling and no hard-coded user home directory.

**Step 2: Run test to verify it fails**

Run: `sh tests/session_layout_test.sh`

Expected: failure because both existing custom panels start only from the user
session and the logon window has no Openbox environment.

**Step 3: Write minimal implementation**

Add `adavalinux-login-session` to start Openbox and the top LXPanel, then exec
the logon window.  Have the display manager run it after X readiness.  Update
`adavalinux-session` to create user-owned configuration copies only if absent,
launch PCManFM desktop mode, and start the bottom panel before execing Openbox.
Ensure the logon window's successful exit transfers control to the authenticated
user session without leaving login-only processes alive.

**Step 4: Run test to verify it passes**

Run: `sh tests/session_layout_test.sh && make clean && make all`

Expected: session-layout test passes and all packaged scripts are executable.

**Step 5: Commit**

```bash
git add adavalinux-display-manager adavalinux-login-session adavalinux-session Makefile tests/session_layout_test.sh
git commit -m "feat: launch branded login and user desktops"
```

### Task 5: Validate packaging and QEMU login flow

**Files:**
- Modify if needed: `README.md`
- Test: `tests/naming_test.sh`, `tests/xkb_package_test.sh`, all new tests

**Step 1: Write the failing test**

If the manual verification procedure is absent, add a README checklist that
requires booting the newly built package, clicking each logon control,
logging in, opening the application menu, opening root/home desktop icons, and
checking a mounted volume icon.

**Step 2: Run test to verify it fails**

Run: `rg -n 'QEMU|logon|PCManFM|LXPanel' README.md`

Expected: no matching manual verification section.

**Step 3: Write minimal implementation**

Document exact build/package installation and visual acceptance steps.  Do not
claim support for network or power actions unless the target image's services
are installed and the actions work there.

**Step 4: Run test to verify it passes**

Run: `sh tests/display_vt_test.sh && sh tests/logon_source_test.sh && sh tests/desktop_runtime_package_test.sh && sh tests/session_layout_test.sh && sh tests/naming_test.sh && sh tests/xkb_package_test.sh && make clean && make package`

Expected: every test reports success and `out/adavalinux-desktop-0.1.0.syspckg`
and `out/adavalinux-theme-default-0.1.0.syspckg` are recreated.

**Step 5: Commit**

```bash
git add README.md tests
git commit -m "docs: document desktop acceptance checks"
```
