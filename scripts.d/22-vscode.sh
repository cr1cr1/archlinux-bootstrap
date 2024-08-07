#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script $BASH_SOURCE failed at line $LINENO with retcode $?' ERR TERM

VSCODE_HOME="${VSCODE_HOME:-/usr/local/vscode}"
_GITHUB_REPO=microsoft/vscode

## Install deps
INSTALLER='sudo pacman -Sy --noconfirm --needed'
for c in curl jq tar; do
  which $c &>/dev/null || $INSTALLER $c
done

[[ -d "${VSCODE_HOME}" ]] || sudo mkdir -p "${VSCODE_HOME}"

## Get latest version
_LATEST_VERSION=$(curl -sS "https://api.github.com/repos/${_GITHUB_REPO}/releases/latest" | jq -r .tag_name)

## Check current version
[[ "$_LATEST_VERSION" == $(jq -r '.version' "$VSCODE_HOME/resources/app/package.json") ]] && exit 0

## Download and install
curl -L 'https://code.visualstudio.com/sha/download?build=stable&os=linux-x64' | \
  sudo tar -xzf - -C "${VSCODE_HOME}" --strip-components=1

DESKTOP_FILE_DIR=/usr/local/share/applications
[[ ! -d "$DESKTOP_FILE_DIR" ]] && sudo mkdir -p "$DESKTOP_FILE_DIR"
sudo cp -uvrnd "${BASH_SOURCE%/*}/usr/local/share/applications/vscode.desktop" "$DESKTOP_FILE_DIR"

sudo update-desktop-database
