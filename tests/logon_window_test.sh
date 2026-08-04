#!/usr/bin/env sh
set -eu

grep -Fq '$(BUILD_DIR)/usr/bin/adavalinux-logon' Makefile
grep -Fq 'DISPLAY="$display" openbox &' adavalinux-display-manager
grep -Fq 'DISPLAY="$display" /usr/bin/adavalinux-logon' adavalinux-display-manager
grep -Fq '#include <X11/cursorfont.h>' adavalinux-logon.c
grep -Fq 'XStoreName(display, window, "AdavaLinux Logon")' adavalinux-logon.c
grep -Fq 'XCreateFontCursor(display, XC_left_ptr)' adavalinux-logon.c
grep -Fq 'XDefineCursor(display, window, cursor)' adavalinux-logon.c
grep -Fq 'ButtonPressMask' adavalinux-logon.c
grep -Fq 'event.xbutton.y' adavalinux-logon.c

printf '%s\n' 'desktop logon window test passed'
