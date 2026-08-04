#!/usr/bin/env sh
set -eu

grep -Fqx '    Option "AutoAddDevices" "on"' xorg.conf
if grep -Fq 'AutoAddDevices" "off' xorg.conf; then exit 1; fi

printf '%s\n' 'Xorg explicit input configuration test passed'
