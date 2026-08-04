#!/usr/bin/env sh
set -eu

grep -Fqx 'DEP=xf86-input-evdev-2.11.0' packages/adavalinux-desktop/syspckg-deps

printf '%s\n' 'desktop input driver dependency test passed'
