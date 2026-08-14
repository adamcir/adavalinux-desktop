#!/bin/sh
set -eu

launcher=adavalinux-xfce-start
session=adavalinux-session
makefile=Makefile
installer=packages/adavalinux-desktop/install.sh
deps=$(cat packages/adavalinux-desktop/syspckg-deps)

test -x "$launcher"
grep -Fq 'export DISPLAY="$display"' "$launcher"
grep -Fq 'export XDG_CURRENT_DESKTOP=XFCE' "$launcher"
grep -Fq 'export XDG_SESSION_DESKTOP=XFCE' "$launcher"
grep -Fq 'export DESKTOP_SESSION=xfce' "$launcher"
grep -Fq 'runtime_dir=${XDG_RUNTIME_DIR:-/tmp/adavalinux-runtime-$USER}' "$launcher"
grep -Fq 'if [ ! -x /usr/bin/xfce4-session ]; then' "$launcher"
grep -Fq 'exec /usr/bin/xfce4-session' "$launcher"
! grep -Fq 'mkdir -p /dev/pts' "$launcher"
! grep -Fq 'mkdir -p /run /run/udev' "$launcher"
! grep -Fq 'Xorg "$display"' "$launcher"
grep -Fq '$(BUILD_DIR)/usr/bin/adavalinux-xfce-start' "$makefile"
grep -Fq 'adavalinux-xfce-start' "$makefile"
grep -Fq 'exec /usr/bin/adavalinux-xfce-start' "$session"
grep -Fq 'mount -t devpts -o gid=5,mode=620,ptmxmode=666 devpts /dev/pts' adavalinux-display-manager
grep -Fq 'chmod 666 /dev/ptmx' adavalinux-display-manager
grep -Fq 'chmod 666 /dev/null' adavalinux-display-manager
grep -Fq 'chmod 755 /run' adavalinux-display-manager
grep -Fq 'exec /usr/bin/startxfce4' "$installer"
printf '%s\n' "$deps" | grep -Fqx 'DEP=xfce4-session'
printf '%s\n' "$deps" | grep -Fqx 'DEP=xfce4-panel'
printf '%s\n' "$deps" | grep -Fqx 'DEP=xfdesktop'
if rg -n -i 'startlxde|lxde|lxpanel|lxsession|lxappearance|lxinput|lxrandr|lxtask|lxmenu|pcmanfm|libfm|menu-cache' \
  --glob '!**/xfce_launcher_test.sh' .; then
  printf '%s\n' 'desktop source must not retain LXDE components' >&2
  exit 1
fi

printf '%s\n' 'XFCE launcher test passed'
