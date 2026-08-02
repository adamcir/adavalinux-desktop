#!/usr/bin/env sh
set -eu

grep -Fq '$(BUILD_DIR)/usr/share/X11/xkb/rules/evdev' Makefile
grep -Fq 'cp -aL /usr/share/X11/xkb $(BUILD_DIR)/usr/share/X11/' Makefile
grep -Fq '$(BUILD_DIR)/usr/bin/xkbcomp' Makefile
grep -Fq 'libxkbfile.so.1' Makefile

printf '%s\n' 'desktop XKB package test passed'
