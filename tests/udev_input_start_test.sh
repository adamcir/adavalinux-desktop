#!/usr/bin/env sh
set -eu

grep -Fq '/usr/lib/systemd/systemd-udevd --daemon' adavalinux-display-manager
grep -Fq 'mkdir -p /run /run/udev' adavalinux-display-manager
grep -Fq '/usr/bin/udevadm trigger --subsystem-match=input &' adavalinux-display-manager
grep -Fq '/usr/bin/udevadm settle --timeout=5 >/dev/null 2>&1 &' adavalinux-display-manager
run_line=$(grep -n 'mkdir -p /run /run/udev' adavalinux-display-manager | cut -d: -f1)
udevd_line=$(grep -n '/usr/lib/systemd/systemd-udevd --daemon' adavalinux-display-manager | cut -d: -f1)
xorg_line=$(grep -n 'Xorg "$display" vt1 -nolisten tcp &' adavalinux-display-manager | cut -d: -f1)
test "$run_line" -lt "$udevd_line"
test "$udevd_line" -lt "$xorg_line"

printf '%s\n' 'desktop udev input start test passed'
