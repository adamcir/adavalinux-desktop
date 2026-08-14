#!/bin/sh
set -eu

WORKSPACE_DIR=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
BUILD_SCRIPT="$WORKSPACE_DIR/xfce/build-xfce.sh"
LOCKFILE="$WORKSPACE_DIR/xfce/sources/xfce-sources.lock.tsv"

"$BUILD_SCRIPT" --build xfconf

version=$(awk -F '\t' '$1 == "xfconf" { print $2; exit }' "$LOCKFILE")
stage="$WORKSPACE_DIR/syspckg/libs/xfconf-$version"
archive="$WORKSPACE_DIR/syspckg/packages/xfconf-$version.syspckg"

[ -f "$stage/syspckg-info" ]
[ -f "$stage/usr/lib/pkgconfig/libxfconf-0.pc" ]
[ -f "$archive" ]

echo 'PASS: xfconf builds against staged libxfce4util'
