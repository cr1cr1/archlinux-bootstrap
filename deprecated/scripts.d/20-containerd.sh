#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script failed at line $LINENO with retcode $?' ERR TERM

_BIN_NAME=nerdctl
_BASE_PATH=/usr/local
_GITHUB_REPO=containerd/nerdctl

## Install deps
INSTALLER='sudo pacman -Sy --noconfirm --needed'
for c in curl jq tar; do
  which $c &>/dev/null || $INSTALLER $c
done

## Get latest version
_LATEST_JSON=$(curl -sS "https://api.github.com/repos/${_GITHUB_REPO}/releases/latest")
_LATEST_VERSION=$(jq -r .tag_name <<< "$_LATEST_JSON")

## Check current version
[[ "$($_BIN_NAME version -f '{{json .Client.Version}}' | xargs)" == "$_LATEST_VERSION" ]] && exit 0

## Download and install
_DOWNLOAD_URL=$(jq -r '.assets[] | select(.name | test("full.+linux-amd64")).browser_download_url' <<< "$_LATEST_JSON")
curl -L "$_DOWNLOAD_URL" | sudo tar -C "${_BASE_PATH}" -xzf -

[[ -d /opt/cni ]] || sudo mkdir -p /opt/cni
[[ -r /opt/cni/bin ]] || sudo ln -s "${_BASE_PATH}/libexec/cni" /opt/cni/bin

[[ -r "${_BASE_PATH}/bin/docker" ]] || sudo ln -s ${_BASE_PATH}/bin/{$_BIN_NAME,docker}

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
