#!/usr/bin/env sh
set -eu

test -f adavalinux-logon.c
test -f pam.d/adavalinux-logon
grep -Fq 'pam_start("adavalinux-logon"' adavalinux-logon.c
grep -Fq 'adavalinux-logon: cannot open X display' adavalinux-logon.c
grep -Fq 'adavalinux-logon.c pam_compat.h' Makefile
grep -Fq 'etc/pam.d/adavalinux-logon' Makefile

printf '%s\n' 'desktop logon naming test passed'
