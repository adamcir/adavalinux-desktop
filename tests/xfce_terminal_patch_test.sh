#!/bin/sh
set -eu

WORKSPACE_DIR=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
PATCH_FILE="$WORKSPACE_DIR/xfce/patches/xfce4-terminal-1.2.0-gtk-layer-shell-guard.patch"
BUILD_SCRIPT="$WORKSPACE_DIR/xfce/build-xfce.sh"

[ -f "$PATCH_FILE" ]
grep -Fqx '+#ifdef HAVE_GTK_LAYER_SHELL' "$PATCH_FILE"
grep -Fqx '        xfce4-terminal-1.2.0) patch -d "$build_dir" -p1 < "$WORKSPACE_DIR/xfce/patches/xfce4-terminal-1.2.0-gtk-layer-shell-guard.patch" ;;' "$BUILD_SCRIPT"

echo 'PASS: XFCE Terminal source patch is applied during the build'
