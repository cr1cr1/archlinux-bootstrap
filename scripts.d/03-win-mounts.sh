#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script failed at line $LINENO with retcode $?' ERR TERM

INSTALLER='sudo pacman -Sy --noconfirm --needed'
which ntfs-3g &>/dev/null || $INSTALLER ntfs-3g

SERVICE_DIR=/usr/local/lib/systemd/system
[[ -d "$SERVICE_DIR" ]] || sudo mkdir -p "$SERVICE_DIR"

MOUNTS_FILE="${BASH_SOURCE%/*}/.config/mounts/$(hostname).winmounts"
[[ -f "$MOUNTS_FILE" ]] || exit 0

while IFS= read -r line; do
  [[ -z "$line" || $line =~ ^# ]] && continue

  NAME=$(awk '{print $1}' <<< "$line")
  WHAT=$(awk '{print $2}' <<< "$line")
  WHERE=$(awk '{print $3}' <<< "$line")

  M=${WHERE#*/}
  SERVICE_FILE=${M//\//-}.mount

  [[ -d "$WHERE" ]] || sudo mkdir -p "$WHERE"
  sudo chmod ugo=rwx "$WHERE" || true

  cat <<! | sudo tee "$SERVICE_DIR/$SERVICE_FILE" >/dev/null
[Unit]
Description=Mount unit for $NAME

[Mount]
What=$WHAT
Where=$WHERE
#Type=ntfs-3g
#Options=auto,rw,uid=$(id -u),gid=$(id -g),dmask=027,fmask=077,dev,exec,noatime,iocharset=utf8,windows_names,big_writes,suid
Type=ntfs3
Options=auto,rw,uid=$(id -u),gid=$(id -g),dmask=027,fmask=077,dev,exec,noatime,iocharset=utf8,windows_names,suid

[Install]
WantedBy=multi-user.target
!

  sudo systemctl daemon-reload
  sudo systemctl enable "$SERVICE_FILE" || continue
  sudo systemctl restart "$SERVICE_FILE" || continue
done < "$MOUNTS_FILE"
