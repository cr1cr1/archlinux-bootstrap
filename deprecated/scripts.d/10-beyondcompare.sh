#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script $BASH_SOURCE failed at line $LINENO with retcode $?' ERR TERM

## Install deps
INSTALLER='sudo pacman -Sy --noconfirm --needed'
for c in curl grep tar; do
  which $c &>/dev/null || $INSTALLER $c
done

BCOMPARE_PREFIX=/usr/local
DOWNLOAD_DEST=/tmp/bcompare
[[ -d "$DOWNLOAD_DEST" ]] || mkdir -p "$DOWNLOAD_DEST"

DOWNLOAD_URL=$(curl -sSL https://www.scootersoftware.com/kb/linux_install | grep -oP '[^"]+5.+\.tar\.gz(?=")')
curl -L "https://www.scootersoftware.com$DOWNLOAD_URL" | tar -xz -C "$DOWNLOAD_DEST" --strip-components=1

(cd "$DOWNLOAD_DEST" && sudo ./install.sh --prefix="$BCOMPARE_PREFIX")

#[[ -d "$DOWNLOAD_DEST" ]] && rm -fr "$DOWNLOAD_DEST"
