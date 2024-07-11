#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script failed at line $LINENO with retcode $?' ERR TERM

_BIN_NAME=$(which nerdctl)
_BASE_PATH=

## Install deps
INSTALLER='sudo pacman -Sy --noconfirm --needed'
for c in buildkit nerdctl cni-plugins rootlesskit slirp4netns; do
  which $c &>/dev/null || $INSTALLER $c
done

[[ -r "/usr/local/bin/docker" ]] || sudo ln -s "$_BIN_NAME" /usr/local/bin/docker

## Setup rootless containerd
sudo systemctl daemon-reload
for srv in containerd buildkit; do
  sudo systemctl disable $srv
  sudo systemctl stop $srv || true
done

which newuidmap &>/dev/null || $INSTALLER uidmap

CMDS=(
  "containerd-rootless-setuptool.sh install"
  "containerd-rootless-setuptool.sh install-buildkit"
)

if [[ $EUID -eq 0 ]]; then
  echo "This is a rootless installation. As a regular user run:"
  printf "  > %s\n" "${CMDS[@]}"
  exit 0
fi

printf "%s\n" "${CMDS[@]}" | xargs -I {} bash -c "{}"
