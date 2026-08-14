#!/bin/sh
set -eu

WORKSPACE_DIR=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
BUILD_SCRIPT="$WORKSPACE_DIR/xfce/build-xfce.sh"
MANIFEST="$WORKSPACE_DIR/xfce/xfce-components.tsv"

grep -Fqx "    while IFS=\"\$(printf '\\t')\" read -r name package_class component_path series dependencies; do" "$BUILD_SCRIPT"
grep -Fqx "libxfce4util	library	xfce/libxfce4util	4.20	glib-2.82.2" "$MANIFEST"
grep -Fqx "libxfce4ui	library	xfce/libxfce4ui	4.20	libxfce4util,xfconf" "$MANIFEST"
grep -Fqx "libxfce4windowing	library	xfce/libxfce4windowing	4.20	libxfce4util" "$MANIFEST"
grep -Fqx "garcon	library	xfce/garcon	4.20	libxfce4util,xfconf,libxfce4ui" "$MANIFEST"
"$BUILD_SCRIPT" --check-manifest
echo 'PASS: XFCE manifest accepts the stable 4.20 series'
