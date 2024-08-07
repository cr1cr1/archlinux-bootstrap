#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script $BASH_SOURCE failed at line $LINENO with retcode $?' ERR TERM

## Install deps
INSTALLER='sudo pacman -Sy --noconfirm --needed'
for c in curl xmllint tar; do
  which $c &>/dev/null || $INSTALLER $c
done

THUNDERBIRD_HOME="${THUNDERBIRD_HOME:-/usr/local/thunderbird}"

[[ -d "${THUNDERBIRD_HOME}" ]] || sudo mkdir -p "${THUNDERBIRD_HOME}"

## Get latest version
_LATEST_VERSION=$(curl -sS "https://www.thunderbird.net/en-US/thunderbird/releases/atom.xml" | xmllint --xpath '//*[local-name()="entry"][1]/*[local-name()="title"]/text()' -)

## Check current version
[[ $("${THUNDERBIRD_HOME}/thunderbird-bin" --version) == "$_LATEST_VERSION" ]] && exit 0

## Download and install
curl -L "https://download.mozilla.org/?product=thunderbird-${_LATEST_VERSION#* }-SSL&os=linux64&lang=en-US" | \
  sudo tar -xjf - -C "${THUNDERBIRD_HOME}" --strip-components=1

DESKTOP_FILE_DIR=/usr/local/share/applications
[[ ! -d "$DESKTOP_FILE_DIR" ]] && sudo mkdir -p "$DESKTOP_FILE_DIR"
sudo cp -uvrnd "${BASH_SOURCE%/*}/usr/local/share/applications/thunderbird.desktop" "$DESKTOP_FILE_DIR"

sudo update-desktop-database
