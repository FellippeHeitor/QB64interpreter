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
    if [ -f "$n.in" ]; then input="$here/$n.in"; else input=/dev/null; fi
    (cd "$tmp" && timeout 20 "./$n" < "$input" > "$tmp/$n.out") || echo "warning: $n timed out or failed"
    # QB64 waits for a key after END; the interpreter doesn't
    perl -0pe 's/\n?Press enter to continue\z//' "$tmp/$n.out" > "$here/$n.expected"
    echo "wrote $n.expected"
done
rm -rf "$tmp"
