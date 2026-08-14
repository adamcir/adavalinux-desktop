#!/bin/sh
set -eu

WORKSPACE_DIR=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
BUILD_SCRIPT="$WORKSPACE_DIR/xfce/build-xfce.sh"

grep -Fqx 'build_all() {' "$BUILD_SCRIPT"
grep -Fqx '        --build-all) [ "$#" -eq 1 ] || { usage; exit 2; }; build_all ;;' "$BUILD_SCRIPT"
grep -Fqx '        build_component "$component_name" || die "build failed: $component_name"' "$BUILD_SCRIPT"

echo 'PASS: XFCE build-all entry point is present'
