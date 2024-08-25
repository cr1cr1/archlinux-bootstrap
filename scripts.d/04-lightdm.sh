#!/bin/bash

set -u -e -o pipefail

trap 'echo Script $BASH_SOURCE failed at line $LINENO with retcode $?' ERR TERM

if who | grep -P '\(:[0-9]+\)$'; then
  echo "An X user session is active, run this in 'runlevel 3' or with no sessions and lightdm stopped"
  exit 0
fi

INSTALLER='sudo pacman -Sy --noconfirm --needed'
$INSTALLER lightdm lightdm-slick-greeter xorg-xauth xorg-server-xephyr plymouth xauth
## Uninstall the default greeter
sudo pacman -Q lightdm-gtk-greeter &>/dev/null && sudo pacman -R --nosave --noconfirm lightdm-gtk-greeter

GREETER_SESSION=lightdm-slick-greeter

## Enable the service
sudo systemctl enable lightdm

sudo cp -uvrnd "${BASH_SOURCE%/*}/etc/lightdm" /etc/

# shellcheck disable=SC1091
. "${BASH_SOURCE%/*}/../_initool.sh"
# shellcheck disable=SC2089
INI_CMD=(ini set /etc/lightdm/lightdm.conf 'Seat:*')
## Write /etc/lightdm/lightdm.conf
"${INI_CMD[@]}" greeter-session $GREETER_SESSION | sudo tee /etc/lightdm/lightdm.conf > /dev/null
"${INI_CMD[@]}" greeter-hide-users false | sudo tee /etc/lightdm/lightdm.conf > /dev/null
"${INI_CMD[@]}" greeter-show-manual-login true | sudo tee /etc/lightdm/lightdm.conf > /dev/null

sudo systemctl restart lightdm
