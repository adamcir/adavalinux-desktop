#!/bin/sh
set -eu

WORKSPACE_DIR=$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)
BUILD_SCRIPT="$WORKSPACE_DIR/xfce/build-xfce.sh"

grep -Fqx '        meson)' "$BUILD_SCRIPT"
grep -Fqx "            if grep -Eq \"['\\\"]docs['\\\"]\" \"\$build_dir/meson_options.txt\" 2>/dev/null; then" "$BUILD_SCRIPT"
grep -Fqx "                meson_doc_option='-Ddocs=disabled'" "$BUILD_SCRIPT"
grep -Fqx "            elif grep -Eq \"['\\\"]doc['\\\"]\" \"\$build_dir/meson_options.txt\" 2>/dev/null; then" "$BUILD_SCRIPT"
grep -Fqx "                meson_doc_option='-Ddoc=false'" "$BUILD_SCRIPT"
grep -Fqx '            meson setup "$meson_build_dir" "$build_dir" --prefix=/usr --sysconfdir=/etc --buildtype=release $meson_doc_option' "$BUILD_SCRIPT"
grep -Fqx '            meson compile -C "$meson_build_dir" -j "$JOBS"' "$BUILD_SCRIPT"
grep -Fqx '            meson install -C "$meson_build_dir" --destdir "$stage_dir"' "$BUILD_SCRIPT"
grep -Fqx '            shift 2' "$BUILD_SCRIPT"

echo 'PASS: XFCE Meson build support is present'
