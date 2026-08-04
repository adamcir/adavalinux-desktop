#!/bin/sh
set -eu

session=adavalinux-lxde-start
xorg=xorg.conf
makefile=Makefile
refresh=adavalinux-xrefresh.c

# Cairo must use the normal XRender path.  The debug override made GTK2 paint
# only after a later mouse-driven expose event.
if grep -Fq 'CAIRO_DEBUG=' "$session"; then
  printf '%s\n' 'session must not override CAIRO_DEBUG' >&2
  exit 1
fi

grep -Fq 'Driver "modesetting"' "$xorg"
grep -Fq 'Option "AccelMethod" "none"' "$xorg"
grep -Fq 'Option "AIGLX" "off"' "$xorg"
grep -Fq 'Xorg "$display" vt1 -nolisten tcp -extension GLX -logfile' "$session"
grep -Fq 'adavalinux-xrefresh' "$session"
grep -Fq '$(BUILD_DIR)/usr/bin/adavalinux-xrefresh' "$makefile"
grep -Fq 'type = pager' ../adavalinux-desktop/packages/adavalinux-desktop/install.sh
grep -Fq '<number>4</number>' ../adavalinux-desktop/packages/adavalinux-desktop/install.sh
test -s "$refresh"
grep -Fq 'InputOnly' "$refresh"
grep -Fq '$(BUILD_DIR)/etc/X11/xorg.conf' "$makefile"
grep -Fq 'cp $(BUILD_DIR)/etc/X11/xorg.conf' "$makefile"

printf '%s\n' 'XRender session test passed'
