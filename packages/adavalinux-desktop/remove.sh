#!/bin/sh
set -eu

root=$1
inittab="$root/etc/inittab"
backup="$root/etc/inittab.d/adavalinux-desktop.tty1"
default_tty1="tty1::respawn:/bin/cttyhack /bin/sh -c 'printf \\\"\\033c\\\" && exec /sbin/getty 115200 tty1'"

test -f "$inittab"
tmp="$inittab.syspckg-remove.$$"
grep -v '^tty1::' "$inittab" > "$tmp" || true
if [ -f "$backup" ]; then
  cat "$backup" >> "$tmp"
else
  printf '%s\n' "$default_tty1" >> "$tmp"
fi
mv "$tmp" "$inittab"
rm -f "$backup"
rmdir "$root/etc/inittab.d" 2>/dev/null || true

if [ "$root" = / ]; then
  killall adavalinux-display-manager Xorg 2>/dev/null || true
  # Ask the real BusyBox init to replace the desktop manager with the restored getty.
  kill -HUP 1 2>/dev/null || true
fi
