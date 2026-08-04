#!/usr/bin/env sh
set -eu

archive=../syspckg/packages/util-linux-2.41.syspckg
contents=$(mktemp)
trap 'rm -f "$contents"' EXIT
tar -tJf "$archive" > "$contents"
grep -Eq '/(lib|usr/lib)/libmount\.so\.1(\.|$)' "$contents"

readelf --version-info ../syspckg/libs/openssl-3.4.0/usr/lib/libcrypto.so.3 \
  | grep -Fq 'Name: OPENSSL_3.4.0'

printf '%s\n' 'systemd-udevd runtime closure test passed'
