#!/bin/sh
set -eu

WORKSPACE_DIR=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
BUILD_SCRIPT="$WORKSPACE_DIR/xfce/build-xfce.sh"
LOCKFILE="$WORKSPACE_DIR/xfce/sources/xfce-sources.lock.tsv"
archive_listing=$(mktemp)
trap 'rm -f "$archive_listing"' EXIT HUP INT TERM

grep -Fqx 'JOBS=${JOBS:-2}' "$BUILD_SCRIPT"
"$BUILD_SCRIPT" --build libxfce4util

version=$(awk -F '\t' '$1 == "libxfce4util" { print $2; exit }' "$LOCKFILE")
stage="$WORKSPACE_DIR/syspckg/libs/libxfce4util-$version"
archive="$WORKSPACE_DIR/syspckg/packages/libxfce4util-$version.syspckg"

[ -f "$stage/syspckg-info" ]
[ -f "$stage/syspckg-deps" ]
[ -d "$stage/usr" ]
[ -f "$archive" ]
[ ! -e "$stage/usr/lib/libxfce4util.la" ]
tar -tJf "$archive" > "$archive_listing"
grep -Fqx "libxfce4util-$version/syspckg-info" "$archive_listing"

echo 'PASS: libxfce4util is staged and packaged as a library'
