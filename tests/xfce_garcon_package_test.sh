#!/bin/sh
set -eu

WORKSPACE_DIR=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
BUILD_SCRIPT="$WORKSPACE_DIR/xfce/build-xfce.sh"
LOCKFILE="$WORKSPACE_DIR/xfce/sources/xfce-sources.lock.tsv"

"$BUILD_SCRIPT" --build garcon

version=$(awk -F '\t' '$1 == "garcon" { print $2; exit }' "$LOCKFILE")
[ -f "$WORKSPACE_DIR/syspckg/libs/garcon-$version/syspckg-info" ]
[ -f "$WORKSPACE_DIR/syspckg/packages/garcon-$version.syspckg" ]

echo 'PASS: garcon links against staged XFCE libraries'
