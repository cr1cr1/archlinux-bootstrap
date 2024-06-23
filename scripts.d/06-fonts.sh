#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script failed at line $LINENO with retcode $?' ERR TERM

_GITHUB_REPO=ryanoasis/nerd-fonts

## Install deps
INSTALLER='sudo pacman -Sy --noconfirm'
pacman -Q noto-fonts-emoji || $INSTALLER noto-fonts-emoji
which unzip &> /dev/null || $INSTALLER unzip

_LATEST_VERSION=$(curl -sS "https://api.github.com/repos/${_GITHUB_REPO}/releases/latest" | jq -r .tag_name)

for f in JetBrainsMono NerdFontsSymbolsOnly; do
  DEST=/usr/share/fonts/nerdfonts/${f,,}
  [[ -d "$DEST" ]] || sudo mkdir -p "$DEST"

  DOWNLOAD_DEST=/tmp/nerdfonts-$f.zip
  grep -q "$_LATEST_VERSION" "$DEST/version" && continue

  [[ -f "$DOWNLOAD_DEST" ]] || \
    curl -L "https://github.com/${_GITHUB_REPO}/releases/download/${_LATEST_VERSION}/$f.zip" > "$DOWNLOAD_DEST"
  unzip -o "$DOWNLOAD_DEST" -d "$DEST"
  echo "$_LATEST_VERSION" > "$DEST/version"
  rm -f "$DOWNLOAD_DEST"
done

fc-cache -f
