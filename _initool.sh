#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script failed at line $LINENO with retcode $?' ERR TERM

_BIN_NAME=initool
_BIN_DEST=/usr/local/bin
_GITHUB_REPO=dbohdan/initool

## Install deps
INSTALLER='sudo pacman -Sy --noconfirm --needed'
for c in curl jq; do
  which $c &>/dev/null || $INSTALLER $c
done

## Get latest version
_LATEST_JSON=$(curl -sS "https://api.github.com/repos/${_GITHUB_REPO}/releases/latest")
_LATEST_VERSION=$(jq -r .tag_name <<< "$_LATEST_JSON")

## Exported function
ini() {
  set -x
  $_BIN_NAME "$@"
  { set +x; } 2>/dev/null
}

## Check current version
if which $_BIN_NAME &>/dev/null && [[ "v$($_BIN_NAME version)" == "${_LATEST_VERSION}" ]]; then
  [[ "${BASH_SOURCE[0]}" == "${0}" ]] && exit 0 || return 0;
fi

## Download and install
_DOWNLOAD_URL=$(jq -r '.assets[] | select(.name | test("linux")).browser_download_url' <<< "$_LATEST_JSON")
_DOWNLOADED=/tmp/$_BIN_NAME.zip

[[ -f "$_DOWNLOADED" ]] || \
  curl -L "$_DOWNLOAD_URL" > "$_DOWNLOADED"
sudo unzip -o "$_DOWNLOADED" -d "$_BIN_DEST"
sudo chmod +x "$_BIN_DEST/$_BIN_NAME"
rm -f "$_DOWNLOADED"
