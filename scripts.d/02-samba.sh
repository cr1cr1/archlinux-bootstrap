#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script failed at line $LINENO with retcode $?' ERR TERM

SMB_DEFAULT_GROUP=${SMB_DEFAULT_GROUP:-smb}

INSTALLER='sudo pacman -Sy --noconfirm --needed'
$INSTALLER samba avahi
which fd &>/dev/null || $INSTALLER fd
which hostname &>/dev/null || $INSTALLER inetutils

sudo systemctl enable avahi-daemon
sudo systemctl start avahi-daemon

SMB_CONF_DIR="/etc/samba/smb.conf.d"
[[ -d "$SMB_CONF_DIR" ]] || sudo mkdir -p "$SMB_CONF_DIR"

## Generate shares
while IFS= read -r m; do
  [[ -z "$m" || $m =~ ^# ]] && continue

  NAME=$(awk '{print $1}' <<< "$m")
  WHERE=$(awk '{print $3}' <<< "$m")

  M=${NAME#*/}
  CONF_FILE=${M//\//-}.conf

  cat <<! | sudo tee "$SMB_CONF_DIR/$CONF_FILE" >/dev/null
[$NAME]
comment = $NAME
path = $WHERE
valid users = @$SMB_DEFAULT_GROUP
public = no
writable = yes
!
done < "${BASH_SOURCE%/*}/.config/mounts/$(hostname).winmounts"

## Post configuration
sudo cp -uva "${BASH_SOURCE%/*}/etc/samba" /etc/

for f in $(fd '\.conf$' "$SMB_CONF_DIR"); do
  CONF_FILE="$f"
  sudo grep -qP "^include\s*=\s*$CONF_FILE" "/etc/samba/smb.conf" || \
    sudo tee -a "/etc/samba/smb.conf" <<< "include = $CONF_FILE" >/dev/null
done

sudo getent group "$SMB_DEFAULT_GROUP" &>/dev/null || sudo groupadd "$SMB_DEFAULT_GROUP"

## Local users with sudo rights
for u in $(getent passwd | grep -v nologin | cut -d: -f1 | grep -v '^root$'); do
  ## is a sudoer?
  sudo -lU "$u" | grep -q 'not allowed' && continue
  ## is in $SMB_DEFAULT_GROUP?
  # shellcheck disable=SC2076
  [[ $(id -Gn "$u") =~ " $SMB_DEFAULT_GROUP " ]] || sudo usermod -aG "$SMB_DEFAULT_GROUP" "$u"
  ## is in samba user db?
  sudo pdbedit -L | grep -qP "^$u:" || { set -x; sudo smbpasswd -L -a "$u"; { set +x; } 2>/dev/null; }
done

sudo systemctl enable smb
sudo systemctl restart smb
