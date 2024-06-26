#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script failed at line $LINENO with retcode $?' ERR TERM

GO_VERSION=${GO_VERSION:-go1.22.4}
GO_HOME="${GO_HOME:-/usr/local/go}"

## Install deps
INSTALLER='sudo pacman -Sy --noconfirm --needed'
for c in curl tar; do
  which $c &>/dev/null || $INSTALLER $c
done

## Check current version
[[ $("$GO_HOME/bin/go" version | awk '{print $3}') != "$GO_VERSION" ]] || exit 0

## Download and install
[[ -d "$GO_HOME" ]] && sudo rm -rf "$GO_HOME"
curl -L "https://go.dev/dl/${GO_VERSION}.linux-amd64.tar.gz" -O - | sudo tar -C "${GO_HOME%/*}" -xzf -
