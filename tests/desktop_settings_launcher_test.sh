#!/bin/sh
set -eu

entry=applications/adavalinux-desktop-settings.desktop
makefile=Makefile

test -f "$entry"
grep -Fqx 'Name=Desktop Settings' "$entry"
grep -Fqx 'Exec=xfdesktop-settings' "$entry"
grep -Fqx 'Categories=Settings;DesktopSettings;X-XFCE-SettingsDialog;' "$entry"
grep -Fq 'adavalinux-desktop-settings.desktop' "$makefile"

printf '%s\n' 'desktop settings launcher test passed'
