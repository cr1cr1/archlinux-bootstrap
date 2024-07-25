#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script $BASH_SOURCE failed at line $LINENO with retcode $?' ERR TERM

_BIN_NAME=rustdesk
_GITHUB_REPO=rustdesk/rustdesk

## Install deps
INSTALLER='sudo pacman -Sy --noconfirm --needed'
for c in curl jq; do
  which $c &>/dev/null || $INSTALLER $c
done

## Get latest version
_LATEST_JSON=$(curl -sS "https://api.github.com/repos/${_GITHUB_REPO}/releases")
_LATEST_VERSION=$(jq -r 'map(select(.tag_name != "nightly")) | first | .tag_name' <<< "$_LATEST_JSON")

## Download and install
_DOWNLOAD_URL=$(jq -r 'map(select(.tag_name != "nightly")) | first | .assets[] | select(.browser_download_url | test("tar.zst")).browser_download_url' <<< "$_LATEST_JSON")
if ! which "$_BIN_NAME" &>/dev/null || [[ "$($_BIN_NAME --version)" != "$_LATEST_VERSION" ]]; then
  $INSTALLER "$_DOWNLOAD_URL"
fi

## Post install
if [[ -d "${BASH_SOURCE%/*}/.config/$_BIN_NAME" ]]; then
  ## Local users with sudo rights
  while IFS= read -r line; do
    user=$(cut -d: -f1 <<< "$line")
    ## is a sudoer?
    sudo -lU "$user" | grep -q 'not allowed' && continue
    homedir=$(cut -d: -f6 <<< "$line")
    sudo cp -uvrnd "${BASH_SOURCE%/*}/.config/$_BIN_NAME" "$homedir/.config/" || continue
    sudo chown -R "$user" "$homedir/.config/$_BIN_NAME"
  done < <(getent passwd | grep -v nologin)
fi

sudo systemctl daemon-reload
sudo systemctl enable rustdesk
sudo systemctl restart rustdesk
