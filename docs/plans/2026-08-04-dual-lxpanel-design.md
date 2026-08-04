# Dual LXPanel Design

## Goal

Replace the current single mixed LXPanel layout with two independent LXPanel
instances in the LXDE session.

## Layout

- The bottom panel contains the application menu, pinned launchers, and the
  task list in that order.  The task list is separated from the launchers by
  LXPanel's expandable taskbar.
- The top panel displays the AdavaLinux label and system status.  Its right
  edge contains network status, date/time, and a power menu with logout,
  restart, and shutdown actions.

## Startup

LXPanel loads every panel configuration in the normal LXDE profile directory.
The package therefore writes both `panel` and `top` there; no second process
or unsupported `--panel` argument is used.  This keeps the implementation on
LXPanel rather than the obsolete custom Xlib panel.

## Compatibility

The menu remains made of explicit application actions because the minimal
rootfs does not yet provide a complete freedesktop menu backend.  The power
actions use the available BusyBox system commands.  The current LXPanel build
does not contain a network-status plugin, so the top-panel Network item is a
visible placeholder until that dependency is packaged.
