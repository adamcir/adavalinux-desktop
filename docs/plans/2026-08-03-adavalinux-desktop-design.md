# AdavaLinux Desktop Design

## Goal

Provide an AdavaLinux-branded graphical login and desktop using Openbox as the
window manager and a small, replaceable set of standard X applications.

## Components

- **Xorg and Openbox** provide the display server and window management.
- **AdavaLinux logon** remains a separate X11 window.  It supplies keyboard
  focus, mouse-selectable user and password fields, a login button, and power
  actions.  PAM continues to authenticate the selected account.
- **LXPanel** provides configurable top and bottom panels.  The login desktop
  uses a top panel for clock, network state, and power controls.  A logged-in
  desktop uses a bottom panel with application menu and task list.
- **PCManFM** owns desktop icons and opens filesystems.  Its desktop view will
  expose the root filesystem, the current user's home directory, and mounted
  volumes.

## Lifecycle

The display manager waits for a usable X connection before it starts Openbox,
the login panel, and the logon window.  It must not treat an existing X socket as
proof that Xorg is usable, and it must exit with diagnostics when Xorg dies.

After PAM authentication, the logon window exits.  The user session stops the
login-only panel, starts Openbox, PCManFM desktop handling, and the customized
bottom LXPanel.  Openbox then manages user windows until the user logs out.

## Branding and configuration

AdavaLinux-owned Openbox, LXPanel, and PCManFM configuration files are
installed under `/usr/share/adavalinux/`.  The session copies or references
them from the user's configuration directory so upgrades do not overwrite
user changes.  Themes, panel icons, desktop launcher files, and wallpaper
remain replaceable package assets.

## Error handling and tests

The display manager tests a real X connection and reports failed Xorg startup
instead of restarting the logon window in a tight loop.  Logon interaction tests
cover focus, mouse selection, form submission, and failure status.  Session
tests verify required commands, the separate login and user panel layouts,
and packaged configuration assets.  Packaging tests verify all added runtime
dependencies and installed files.
