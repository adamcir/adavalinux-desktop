#!/bin/sh
set -eu

installer=packages/adavalinux-desktop/install.sh

test -f "$installer"
grep -Fq 'panels/panel' "$installer"
grep -Fq 'panels/top' "$installer"
grep -Fq 'edge=bottom' "$installer"
grep -Fq 'edge=top' "$installer"
if grep -Fq 'type = launchbar' "$installer"; then
  printf '%s\n' 'default panel must not create a pinned-applications section' >&2
  exit 1
fi
grep -Fq 'type = taskbar' "$installer"
grep -Fq 'type = dclock' "$installer"
grep -Fq 'name=Network' "$installer"
grep -Fq '/usr/share/adavalinux/panel-icons/eth.png' "$installer"
grep -Fq '/usr/share/adavalinux/panel-icons/power.png' "$installer"
grep -Fq '/usr/share/adavalinux/panel-icons/menu.png' "$installer"
test -f assets/panel-icons/eth.png
test -f assets/panel-icons/internet-no.png
test -f assets/panel-icons/power.png
test -f assets/panel-icons/menu.png
test -f assets/panel-icons/wifi-high.png
test -f assets/panel-icons/wifi-medium.png
test -f assets/panel-icons/wifi-low.png
test -f assets/panel-icons/wifi-no.png
grep -Fq 'assets/panel-icons' Makefile
grep -Fq 'action=/sbin/poweroff' "$installer"
grep -Fq 'action=/sbin/reboot' "$installer"
grep -Fq 'command=logout' "$installer"

printf '%s\n' 'dual LXPanel layout test passed'
