#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script failed at line $LINENO with retcode $?' ERR TERM

_BIN_NAME=paru
_BIN_DEST=/usr/local/bin
_GITHUB_REPO=Morganamilo/paru

## Install deps
INSTALLER='sudo pacman -Sy --noconfirm --needed'
for c in curl jq tar; do
  which $c &>/dev/null || $INSTALLER $c
done

## Get latest version
_LATEST_JSON=$(curl -sS "https://api.github.com/repos/${_GITHUB_REPO}/releases/latest")
_LATEST_VERSION=$(jq -r .tag_name <<< "$_LATEST_JSON")

## Check current version
if which $_BIN_NAME &>/dev/null && [[ $($_BIN_NAME --version | cut -d' ' -f2) == "${_LATEST_VERSION}" ]]; then
  [[ "${BASH_SOURCE[0]}" == "${0}" ]] && exit 0 || return 0;
fi

## Download and install
_DOWNLOAD_URL=$(jq -r '.assets[] | select(.name | test("'"$(uname -m)"'")).browser_download_url' <<< "$_LATEST_JSON" | head -1)
curl -L "$_DOWNLOAD_URL" | \
  sudo tar -xf - --zstd -C "${_BIN_DEST}" paru

## Post install
paru -Su --noconfirm
