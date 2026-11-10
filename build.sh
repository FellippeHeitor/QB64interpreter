#!/bin/sh
# Builds ./basiccmdline from src/basiccmdline.bas.
# QB64PE defaults to ~/git/QB64pe.
cd "$(dirname "$0")" || exit 1
here=$(pwd)
qb=${QB64PE:-$HOME/git/QB64pe}
cd "$qb" && ./qb64pe -x "$here/src/basiccmdline.bas" -o "$here/basiccmdline"
