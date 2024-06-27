#!/bin/bash

set -u -e -o pipefail

trap 'echo Script failed at line $LINENO with retcode $?' ERR TERM

if who | grep -P '\(:[0-9]+\)$'; then
  echo "An X user session is active, run this in 'runlevel 3' or with no sessions and lightdm stopped"
  exit 0
fi

INSTALLER='sudo pacman -Sy --noconfirm --needed'
$INSTALLER lightdm lightdm-slick-greeter xorg-xauth xorg-server-xephyr plymouth
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

export DISPLAY=${DISPLAY:-:0}

## Install Deps
for p in arandr xauth; do
  which $p &> /dev/null || $INSTALLER $p
done

## Get magic cookie for the lightdm user
COOKIE=$(sudo -u lightdm xauth list | grep 'unix:0' | awk '{print $3}') || exit 0
[[ -n "$COOKIE" ]] && sudo xauth add :0 . "$COOKIE"

## Get the highest resolution and refresh rate for the primary display
PRIMARY_DISPLAY=$(xrandr --query | grep -P ' connected( primary)*' | head -n 1 | cut -d ' ' -f1)
HIGHEST_MODE=$(xrandr --query | grep "$PRIMARY_DISPLAY connected" -A100 | grep -v " connected" | grep -Eo '[0-9]+x[0-9]+.*' | sort -nr | head -n 1)
read -ra MODES <<< "$HIGHEST_MODE"
readarray -t MODES_SORTED < <(printf '%s\n' "${MODES[@]:1}" | sort -nr)

REFRESH_RATE=$(grep -oP '\d+\.\d+' <<< "${MODES_SORTED[0]}")
RESOLUTION=$(echo "$HIGHEST_MODE "| cut -d ' ' -f1)
XRANDR_CMD="xrandr --output $PRIMARY_DISPLAY --mode $RESOLUTION --rate $REFRESH_RATE"

## Write the xinit script
XINIT_SCRIPT=/etc/lightdm/xinit-script.sh
cat <<! | sudo tee $XINIT_SCRIPT >/dev/null
#!/bin/bash
$XRANDR_CMD
!
sudo chmod +x $XINIT_SCRIPT

## Write lightdm config
"${INI_CMD[@]}" -k display-setup-script -v $XINIT_SCRIPT | sudo tee /etc/lightdm/lightdm.conf > /dev/null

sudo systemctl restart lightdm
