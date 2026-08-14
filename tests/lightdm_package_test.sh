#!/bin/sh
set -eu

deps=packages/adavalinux-desktop/syspckg-deps
makefile=Makefile

grep -Fqx 'DEP=gtk3-runtime-3.24.48' "$deps"
grep -Fqx 'DEP=pam-1.7.2' "$deps"
! grep -Fq 'DEP=lightdm-' "$deps"
grep -Fqx 'DEP=systemd-256.7' "$deps"
grep -Fqx 'DEP=libcap-2.77' "$deps"
grep -Fqx 'DEP=expat-2.7.4' "$deps"
grep -Fqx 'DEP=libselinux-3.7' "$deps"
grep -Fqx 'DEP=pcre2-10.47' "$deps"
grep -Fq 'adavalinux-display-manager' "$makefile"
grep -Fq 'adavalinux-logon' "$makefile"
grep -Fq 'pam.d/adavalinux-logon' "$makefile"
grep -Fq 'remove.sh' "$makefile"
! grep -Fq 'lightdm/lightdm.conf' "$makefile"
! grep -Fq 'adavalinux-lightdm' "$makefile"

printf '%s\n' 'LightDM desktop package test passed'
