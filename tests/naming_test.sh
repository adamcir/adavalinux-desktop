#!/usr/bin/env sh
set -eu

if rg -n --glob '!build/**' --glob '!out/**' --glob '!tests/naming_test.sh' '\badava-' .; then exit 1; fi
if rg -n --glob '!build/**' --glob '!out/**' --glob '!tests/naming_test.sh' '/usr/share/adava\b' .; then exit 1; fi
if rg -n --glob '!build/**' --glob '!out/**' --glob '!tests/naming_test.sh' '\bAdava\b' .; then exit 1; fi

printf '%s\n' 'desktop naming test passed'
