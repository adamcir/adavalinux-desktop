#!/bin/sh
set -eu

install_hook=packages/adavalinux-desktop/install.sh
remove_hook=packages/adavalinux-desktop/remove.sh

grep -Fq 'tty1::respawn:/usr/bin/adavalinux-display-manager' "$install_hook"
grep -Fq "printf '%s\\n' /usr/lib /usr/lib/x86_64-linux-gnu > \"\$root/etc/ld.so.conf\"" "$install_hook"
grep -Fqx "ensure_system_user 'messagebus' 102 102 'D-Bus system message bus' '/run/dbus'" "$install_hook"
grep -Fqx "ensure_system_user 'systemd-oom' 995 995 'systemd Userspace OOM Killer' '/'" "$install_hook"
grep -Fqx "ensure_system_user 'systemd-resolve' 996 996 'systemd Resolver' '/'" "$install_hook"
grep -Fqx '  kill -HUP 1 2>/dev/null || true' "$install_hook"
grep -Fqx '  kill -HUP 1 2>/dev/null || true' "$remove_hook"
! grep -Fq '/sbin/init q' "$install_hook"
! grep -Fq '/sbin/init q' "$remove_hook"
grep -Fq 'adavalinux-desktop.tty1' "$install_hook"
grep -Fq 'tty1::respawn:/bin/cttyhack /bin/sh -c' "$remove_hook"
grep -Fq 'adavalinux-desktop.tty1' "$remove_hook"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
root="$workdir/root"
mkdir -p "$root/etc" "$root/usr/lib/xorg/modules/input"
cat > "$root/etc/inittab" <<'EOF'
::sysinit:/etc/init.d/rcS
tty1::respawn:/bin/cttyhack /bin/sh -c 'printf "\033c" && exec /sbin/getty 115200 tty1'
tty2::respawn:/bin/cttyhack /bin/sh -c 'printf "\033c" && exec /sbin/getty 115200 tty2'
tty7::respawn:/bin/cttyhack /bin/sh -c 'printf "\033c" && exec /sbin/getty 115200 tty7'
ttyS0::respawn:/bin/cttyhack /bin/sh -c 'printf "\033c" && exec /sbin/getty 115200 ttyS0'
EOF
: > "$root/etc/passwd"
: > "$root/etc/group"
tty1_initial=$(grep '^tty1::' "$root/etc/inittab")

sh "$install_hook" "$root"
grep -Fqx 'tty1::respawn:/usr/bin/adavalinux-display-manager' "$root/etc/inittab"
grep -Fq 'tty2::respawn:' "$root/etc/inittab"
grep -Fq 'tty7::respawn:' "$root/etc/inittab"
grep -Fq 'ttyS0::respawn:' "$root/etc/inittab"

sh "$remove_hook" "$root"
grep -Fqx "$tty1_initial" "$root/etc/inittab"
grep -Fq 'tty2::respawn:' "$root/etc/inittab"
grep -Fq 'tty7::respawn:' "$root/etc/inittab"
grep -Fq 'ttyS0::respawn:' "$root/etc/inittab"

printf '%s\n' 'LightDM inittab transition test passed'
