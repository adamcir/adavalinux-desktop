#!/bin/sh
set -eu

root=$1
test -d "$root"

# Xorg uses the multiarch module directory in this minimal rootfs.  Bridge the
# separately packaged evdev input module into the path used by the server.
mkdir -p "$root/usr/lib/x86_64-linux-gnu/xorg/modules"
if [ -d "$root/usr/lib/xorg/modules/input" ]; then
  ln -sfn /usr/lib/xorg/modules/input \
    "$root/usr/lib/x86_64-linux-gnu/xorg/modules/input"
fi

# D-Bus and xfconf require a valid 32-hex-character machine identity.
if [ ! -s "$root/etc/machine-id" ] || \
   [ "$(wc -c < "$root/etc/machine-id")" -ne 33 ] || \
   ! grep -Eq '^[0-9a-f]{32}$' "$root/etc/machine-id"; then
  mkdir -p "$root/etc"
  if [ -r /proc/sys/kernel/random/uuid ]; then
    tr -d '-' < /proc/sys/kernel/random/uuid > "$root/etc/machine-id"
  else
    printf '%032d\n' 0 > "$root/etc/machine-id"
  fi
fi
mkdir -p "$root/var/lib/dbus" "$root/root/Desktop" "$root/etc/skel/Desktop"
ln -sfn /etc/machine-id "$root/var/lib/dbus/machine-id"

# The desktop owns the system display manager, therefore it also guarantees
# the D-Bus service accounts required by the system bus policy.
ensure_system_user() {
  name=$1
  uid=$2
  gid=$3
  comment=$4
  home=$5
  grep -q "^$name:" "$root/etc/group" 2>/dev/null || \
    printf '%s\n' "$name:x:$gid:" >> "$root/etc/group"
  grep -q "^$name:" "$root/etc/passwd" 2>/dev/null || \
    printf '%s\n' "$name:x:$uid:$gid:$comment:$home:/usr/sbin/nologin" >> "$root/etc/passwd"
}
ensure_system_user 'messagebus' 102 102 'D-Bus system message bus' '/run/dbus'
ensure_system_user 'systemd-oom' 995 995 'systemd Userspace OOM Killer' '/'
ensure_system_user 'systemd-resolve' 996 996 'systemd Resolver' '/'

# Register both native and multiarch package library directories.  This fixes
# the whole D-Bus dependency closure, not only whichever SONAME failed first.
mkdir -p "$root/etc"
printf '%s\n' /usr/lib /usr/lib/x86_64-linux-gnu > "$root/etc/ld.so.conf"
if [ -x /sbin/ldconfig ]; then
  /sbin/ldconfig -r "$root" 2>/dev/null || true
fi

# D-Bus clients use /run/dbus. Repair the obsolete path in an older D-Bus
# archive as well, so installing desktop fixes existing installations.
if [ -f "$root/usr/share/dbus-1/system.conf" ]; then
  sed -i 's|/usr/var/run/dbus|/run/dbus|g' \
    "$root/usr/share/dbus-1/system.conf"
fi

# New accounts start the XFCE session exclusively.
printf '%s\n' 'exec /usr/bin/startxfce4' > "$root/etc/skel/.xsession"
chmod 0755 "$root/etc/skel/.xsession"

# LightDM replaces only tty1.  Keep the original entry so package removal
# restores a desktop-free system without touching the rescue consoles.
inittab="$root/etc/inittab"
backup="$root/etc/inittab.d/adavalinux-desktop.tty1"
if [ -f "$inittab" ]; then
  mkdir -p "$(dirname "$backup")"
  if [ ! -f "$backup" ]; then
    grep '^tty1::' "$inittab" > "$backup" || true
  fi
  tmp="$inittab.syspckg-install.$$"
  awk '
    /^tty1::/ { print "tty1::respawn:/usr/bin/adavalinux-display-manager"; replaced = 1; next }
    { print }
    END { if (!replaced) print "tty1::respawn:/usr/bin/adavalinux-display-manager" }
  ' "$inittab" > "$tmp"
  mv "$tmp" "$inittab"
fi

if [ "$root" = / ]; then
  if [ -x /usr/bin/dbus-daemon ] && \
     ! /usr/bin/dbus-send --system --type=method_call --dest=org.freedesktop.DBus / org.freedesktop.DBus.ListNames >/dev/null 2>&1; then
    mkdir -p /run/dbus
    chown messagebus:messagebus /run/dbus 2>/dev/null || true
    rm -f /run/dbus/system_bus_socket /run/dbus/pid
    /usr/bin/dbus-daemon --config-file=/usr/share/dbus-1/system.conf \
      >/dev/null 2>&1 || true
  fi
  # BusyBox init reloads inittab when its actual PID 1 receives SIGHUP.
  # Running /sbin/init from this hook would merely start a child process.
  kill -HUP 1 2>/dev/null || true
fi
