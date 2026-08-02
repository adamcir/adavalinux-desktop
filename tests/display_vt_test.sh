#!/usr/bin/env sh
set -eu

grep -Fq 'Xorg "$display" vt1 -nolisten tcp &' adavalinux-display-manager
grep -Fq '[ -S /tmp/.X11-unix/X0 ]' adavalinux-display-manager
if grep -Fq 'xdpyinfo' adavalinux-display-manager; then exit 1; fi

printf '%s\n' 'desktop display VT test passed'
