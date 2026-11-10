#!/bin/sh
# Runs every tests/*.bas through the interpreter in headless mode and compares
# its output with tests/<name>.expected. A tests/<name>.in file, if present,
# is fed to the program as keyboard input.
#
# usage: tests/run.sh [path/to/basiccmdline]
cd "$(dirname "$0")" || exit 1
here=$(pwd)
bin=${1:-../basiccmdline}
case $bin in /*) ;; *) bin="$here/$bin" ;; esac
[ -x "$bin" ] || { echo "interpreter not found: $bin"; exit 1; }

pass=0; fail=0
for f in *.bas; do
    n=${f%.bas}
    [ -f "$n.expected" ] || continue
    if [ -f "$n.in" ]; then input="$n.in"; else input=/dev/null; fi
    got=$("$bin" -run "$here/$f" < "$input" 2>&1)
    if [ "$got" = "$(cat "$n.expected")" ]; then
        pass=$((pass + 1))
    else
        fail=$((fail + 1))
        echo "FAIL: $n"
        printf '%s\n' "$got" | diff "$n.expected" - | head -20
    fi
done
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
