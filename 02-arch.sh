#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script failed at line $LINENO with retcode $?' ERR TERM

if [[ $EUID -eq 0 ]]; then
  echo "This script must not be run as root" 1>&2
  exit 1
fi

## Deps
INSTALLER='sudo pacman -Sy --noconfirm --needed'
which fd &>/dev/null || $INSTALLER fd
which tput &>/dev/null || $INSTALLER ncurses
which seq &>/dev/null || $INSTALLER coreutils

## Execute scripts
for sc in $(fd '\.sh$' "${BASH_SOURCE%/*}/scripts.d"); do
  SEP=$(printf -- '-%.0s' $(seq 1 "$(tput cols)"))
  printf -- "$SEP\nRunning: %s\n$SEP\n" "$sc"
  bash "$sc"
done
