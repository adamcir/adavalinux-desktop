#!/bin/sh
set -eu

root=$1
test -d "$root"

# Xorg on this rootfs searches the multiarch module directory.  The evdev
# package follows the upstream /usr/lib/xorg layout, so bridge the input
# modules into the path used by the server.
mkdir -p "$root/usr/lib/x86_64-linux-gnu/xorg/modules"
if [ -d "$root/usr/lib/xorg/modules/input" ]; then
  ln -sfn /usr/lib/xorg/modules/input \
    "$root/usr/lib/x86_64-linux-gnu/xorg/modules/input"
fi


# D-Bus needs a machine identity before LXDE starts.  Generate one during
# installation when the target rootfs does not already have one.
if [ ! -s "$root/etc/machine-id" ]; then
  mkdir -p "$root/etc"
  if [ -r /proc/sys/kernel/random/uuid ]; then
    tr -d '-' < /proc/sys/kernel/random/uuid > "$root/etc/machine-id"
    printf '\n' >> "$root/etc/machine-id"
  else
    printf '%032d\n' 0 > "$root/etc/machine-id"
  fi
fi
mkdir -p "$root/var/lib/dbus"
if [ ! -e "$root/var/lib/dbus/machine-id" ]; then
  ln -s /etc/machine-id "$root/var/lib/dbus/machine-id"
fi

# Prepare the standard LXDE configuration locations in the target rootfs.
mkdir -p \
  "$root/etc/xdg/lxsession/LXDE" \
  "$root/etc/xdg/pcmanfm/LXDE" \
  "$root/etc/xdg/openbox/LXDE" \
  "$root/etc/xdg/lxpanel/LXDE/panels" \
  "$root/etc/xdg/menus" \
  "$root/etc/skel/Desktop" \
  "$root/etc/skel/.config/openbox"

# Ensure Openbox has a non-empty, valid configuration.  Some minimal builds
# contain an empty placeholder which makes openbox refuse to start.
openbox_rc="$root/etc/xdg/openbox/LXDE/rc.xml"
if [ ! -s "$openbox_rc" ]; then
  if [ -s "$root/etc/xdg/openbox/rc.xml" ]; then
    cp -f "$root/etc/xdg/openbox/rc.xml" "$openbox_rc"
  else
    cat > "$openbox_rc" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <applications/>
  <keyboard/>
  <mouse/>
  <desktops><number>1</number></desktops>
  <theme><name>Default</name></theme>
</openbox_config>
EOF
  fi
fi

# Provide four workspaces; the pager plugin below switches them from the
# right side of the expandable bottom taskbar.
if grep -q '<number>' "$openbox_rc" 2>/dev/null; then
  sed -i 's#<number>[0-9][0-9]*</number>#<number>4</number>#' "$openbox_rc"
else
  sed -i 's#</desktops>#<number>4</number></desktops>#' "$openbox_rc"
fi

# LXPanel loads every file in this profile's panels directory.  Keep a clean
# bottom application panel separate from the top system-status panel.
# The application-menu backend in this minimal rootfs is incomplete, so core
# applications use direct actions.
cat > "$root/etc/xdg/lxpanel/LXDE/panels/panel" <<'EOF'
Global {
  edge=bottom
  align=left
  margin=0
  widthtype=percent
  width=100
  height=26
  transparent=0
  tintcolor=#000000
  alpha=0
  setdocktype=1
  setpartialstrut=1
  background=0
}
Plugin {
  type = menu
  Config {
    image=/usr/share/adavalinux/panel-icons/menu.png
    item {
      name=Terminal
      image=utilities-terminal
      action=/usr/bin/adaterm
    }
    item {
      name=File Manager
      image=system-file-manager
      action=pcmanfm
    }
    item {
      name=Task Manager
      image=utilities-system-monitor
      action=lxtask
    }
    separator { }
    item {
      name=Appearance
      image=preferences-desktop-theme
      action=lxappearance
    }
    separator { }
    item {
      command=run
    }
    separator { }
    item {
      image=gnome-logout
      command=logout
    }
  }
}
# A launchbar is deliberately absent from the initial layout.  When a user
# pins an application, LXPanel creates that launcher section between this menu
# and the taskbar instead of showing an empty reserved area.
Plugin {
  type = taskbar
  expand=1
  Config {
    tooltips=1
    IconsOnly=0
    AcceptSkipPager=1
    ShowIconified=1
    ShowMapped=1
    ShowAllDesks=0
    ShowSquareBrackets=1
    UseMouseWheel=1
    UseUrgencyHint=1
    FlatButton=0
    MaxTaskWidth=150
    spacing=1
  }
}
Plugin {
  type = pager
}
Plugin {
  type = space
  Config {
    Size=2
  }
}
EOF

cat > "$root/etc/xdg/lxpanel/LXDE/panels/top" <<'EOF'
Global {
  edge=top
  align=left
  margin=0
  widthtype=percent
  width=100
  height=26
  transparent=0
  tintcolor=#000000
  alpha=0
  setdocktype=1
  setpartialstrut=1
  background=0
}
Plugin {
  type = space
  expand=1
  Config {
    Size=2
  }
}
# A matching second flexible space keeps the clock at the visual center while
# network and power controls occupy the right edge.
Plugin {
  type = dclock
  Config {
    ClockFmt=%a %d.%m. %R
    TooltipFmt=%A %d %B %Y
  }
}
Plugin {
  type = space
  expand=1
  Config {
    Size=2
  }
}
# The current LXPanel package has no network-status plugin.  Keep the network
# control visible here; a later network plugin can replace this menu without
# changing panel geometry.
Plugin {
  type = menu
  Config {
    image=/usr/share/adavalinux/panel-icons/eth.png
    item {
      name=Network
      action=/bin/true
    }
  }
}
Plugin {
  type = menu
  Config {
    image=/usr/share/adavalinux/panel-icons/power.png
    item {
      name=Log out
      command=logout
    }
    item {
      name=Restart
      action=/sbin/reboot
    }
    item {
      name=Shut down
      action=/sbin/poweroff
    }
  }
}
EOF

# Copy the system panel profile into root/skel user profiles.  lxpanel gives
# precedence to ~/.config and an empty profile there results in a black desktop
# even when the system profile is valid.
for home in "$root/root" "$root/etc/skel"; do
  mkdir -p "$home/.config/lxpanel/LXDE/panels"
  cp -f "$root/etc/xdg/lxpanel/LXDE/panels/panel" \
    "$home/.config/lxpanel/LXDE/panels/panel"
  cp -f "$root/etc/xdg/lxpanel/LXDE/panels/top" \
    "$home/.config/lxpanel/LXDE/panels/top"
done

# GTK2 applications otherwise inherit an empty theme/font setup in a minimal
# rootfs, resulting in blank labels and missing stock icons.
gtkrc='gtk-font-name = "DejaVu Sans 10"\ngtk-icon-theme-name = "nuoveXT2"\ngtk-button-images = 1\ngtk-menu-images = 1\n'
printf '%b' "$gtkrc" > "$root/etc/skel/.gtkrc-2.0"
mkdir -p "$root/root"
printf '%b' "$gtkrc" > "$root/root/.gtkrc-2.0"

# Some imported packages install menu data below /usr/etc.  Bridge it to the
# conventional /etc/xdg location used by lxpanel/menu-cache.
if [ -f "$root/usr/etc/xdg/menus/lxde-applications.menu" ] &&
   [ ! -e "$root/etc/xdg/menus/lxde-applications.menu" ]; then
  ln -s /usr/etc/xdg/menus/lxde-applications.menu \
    "$root/etc/xdg/menus/lxde-applications.menu"
fi
if [ -f "$root/root/.config/openbox/lxde-rc.xml" ] &&
   [ ! -s "$root/root/.config/openbox/lxde-rc.xml" ]; then
  rm -f "$root/root/.config/openbox/lxde-rc.xml"
fi

cat > "$root/etc/xdg/lxsession/LXDE/desktop.conf" <<'EOF'
[Session]
window_manager=openbox-lxde
polkit/command=/usr/bin/lxpolkit
EOF

cat > "$root/etc/xdg/pcmanfm/LXDE/pcmanfm.conf" <<'EOF'
[desktop]
wallpaper_mode=stretch
show_wm_menu=0
sort=mtime;ascending;name;ascending
EOF

# Make newly created users start with the LXDE session selected.
if ! grep -q '^exec /usr/bin/startlxde$' "$root/etc/skel/.xsession" 2>/dev/null; then
  printf '%s\n' 'exec /usr/bin/startlxde' > "$root/etc/skel/.xsession"
  chmod 0755 "$root/etc/skel/.xsession"
fi
