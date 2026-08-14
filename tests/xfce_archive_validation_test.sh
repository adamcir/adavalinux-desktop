#!/bin/sh
set -eu

WORKSPACE_DIR=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
BUILD_SCRIPT="$WORKSPACE_DIR/xfce/build-xfce.sh"

grep -Fqx '    [ -d "$stage_dir/usr" ] || die "empty package staging tree: $package_name"' "$BUILD_SCRIPT"
grep -Fqx '    [ -n "$(find "$stage_dir/usr" \( -type f -o -type l \) -print -quit)" ] || die "empty package payload: $package_name"' "$BUILD_SCRIPT"
grep -Fqx '        libxfce4windowing-*) configure_features="--enable-x11 --disable-wayland" ;;' "$BUILD_SCRIPT"

echo 'PASS: XFCE archives require a staged payload'
