#!/bin/sh
# Builds tests/<name>.bas with real QB64pe and saves its output as
# tests/<name>.expected, so the interpreter is checked against QB64 itself.
#
# usage: tests/make_expected.sh name [name...]
# QB64PE defaults to ~/git/QB64pe.
cd "$(dirname "$0")" || exit 1
here=$(pwd)
qb=${QB64PE:-$HOME/git/QB64pe}
tmp=$(mktemp -d)
for n in "$@"; do
    { echo '$CONSOLE:ONLY'; cat "$n.bas"; echo; echo 'SYSTEM'; } > "$tmp/$n.bas"
    (cd "$qb" && ./qb64pe -x "$tmp/$n.bas" -o "$tmp/$n" > /dev/null 2>&1) || { echo "QB64pe could not compile $n"; continue; }
    if [ -f "$n.in" ]; then input="$n.in"; else input=/dev/null; fi
    timeout 20 "$tmp/$n" < "$input" > "$here/$n.expected" || echo "warning: $n timed out or failed"
    echo "wrote $n.expected"
done
rm -rf "$tmp"
