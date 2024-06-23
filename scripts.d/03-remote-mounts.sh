#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script failed at line $LINENO with retcode $?' ERR TERM

INSTALLER='sudo pacman -Sy --noconfirm'
$INSTALLER nfs-utils nfsidmap cifs-utils

SERVICE_DIR=/usr/local/lib/systemd/system
[[ -d "$SERVICE_DIR" ]] || sudo mkdir -p "$SERVICE_DIR"

MOUNTS_FILE="${BASH_SOURCE%/*}/.config/mounts/remote.mounts"
while IFS= read -r line; do
  [[ -z "$line" || $line =~ ^# ]] && continue

  NAME=$(awk '{print $1}' <<< "$line")
  WHAT=$(awk '{print $2}' <<< "$line")
  WHERE=$(awk '{print $3}' <<< "$line")
  TYPE=$(awk '{print $4}' <<< "$line")
  OPTIONS=
  CREDS=

  M=${WHERE#*/}
  SERVICE_FILE=${M//\//-}.mount

  [[ -d "$WHERE" ]] || sudo mkdir -p "$WHERE"
  sudo chmod ugo=rwx "$WHERE" || true

  if [[ "$TYPE" == "cifs" ]]; then
    ## https://systemd.io/CREDENTIALS/
    read -r -p "$NAME username: " USERNAME
    echo "$USERNAME"
    read -r -s -p "$NAME password: " PASSWORD
    [[ -d /etc/samba ]] || sudo mkdir -p /etc/samba
    CREDS_FILE=/etc/samba/$NAME.creds
    echo "username=$USERNAME
  password=$PASSWORD" > "$CREDS_FILE"
    chmod u=rw,go= "$CREDS_FILE"
    ## FIXME Does not work yet for mounts :( - https://github.com/systemd/systemd/issues/23535
    ## Ideally would use credentials=\$CREDENTIALS_DIRECTORY/$NAME
    # CREDS=$(systemd-creds encrypt -p --name="$NAME" "$CREDS_FILE" -)
    # if [[ -f "$CREDS_FILE" ]]; then
    #     shred -f -v "$CREDS_FILE"
    #     rm -fv "$CREDS_FILE"
    # fi
    OPTIONS="iocharset=utf8,file_mode=0777,dir_mode=0777,credentials=$CREDS_FILE,_netdev"
  elif [[ "$TYPE" == "nfs" ]]; then
    ## https://www.thegeekdiary.com/common-nfs-mount-options-in-linux/
    OPTIONS="rw,nosuid,soft,nfsvers=4,noacl,async,nocto,nconnect=16,_netdev,timeo=10,retrans=2,bg"
  fi

  cat <<! | sudo tee "$SERVICE_DIR/$SERVICE_FILE" >/dev/null
[Unit]
Description=Mount unit for $NAME
After=network.target local-fs.target

[Mount]
What=$WHAT
Where=$WHERE
Type=$TYPE
$CREDS
Options=$OPTIONS

[Install]
WantedBy=multi-user.target
!

  sudo systemctl daemon-reload
  sudo systemctl enable "$SERVICE_FILE"
  sudo systemctl start "$SERVICE_FILE" || continue
done < "$MOUNTS_FILE"
