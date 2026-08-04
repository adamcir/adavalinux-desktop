#!/usr/bin/env sh
set -eu

grep -Fq 'Xorg "$display" vt1 -nolisten tcp &' adavalinux-display-manager
grep -Fq 'DISPLAY="$display" /usr/bin/adavalinux-x-ready' adavalinux-display-manager
grep -Fq 'Xorg failed to start' adavalinux-display-manager
if grep -Fq '/tmp/.X11-unix/X0' adavalinux-display-manager; then exit 1; fi
grep -Fq '$(BUILD_DIR)/usr/bin/adavalinux-x-ready' Makefile

printf '%s\n' 'desktop display VT test passed'
