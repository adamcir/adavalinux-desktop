#!/bin/sh
set -eu

WORKSPACE_DIR=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
XFCE_DIR="$WORKSPACE_DIR/xfce"
MANIFEST="$XFCE_DIR/xfce-components.tsv"
BUILD_SCRIPT="$XFCE_DIR/build-xfce.sh"

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

[ -f "$MANIFEST" ] || fail "missing XFCE component manifest: $MANIFEST"
[ -x "$BUILD_SCRIPT" ] || fail "missing executable XFCE build script: $BUILD_SCRIPT"

grep -Fqx 'SOURCE_DIR="$WORKSPACE_DIR/xfce/sources"' "$BUILD_SCRIPT" ||
    fail "XFCE sources must be stored in ./xfce/sources"
grep -Fqx 'DESKTOP_STAGE_DIR="$WORKSPACE_DIR/syspckg"' "$BUILD_SCRIPT" ||
    fail "desktop packages must stage in ./syspckg"
grep -Fqx 'LIBRARY_STAGE_DIR="$WORKSPACE_DIR/syspckg/libs"' "$BUILD_SCRIPT" ||
    fail "library packages must stage in ./syspckg/libs"
grep -Fqx 'ARCHIVE_DIR="$WORKSPACE_DIR/syspckg/packages"' "$BUILD_SCRIPT" ||
    fail "all archives must be stored in ./syspckg/packages"

echo 'PASS: XFCE package layout contract'
