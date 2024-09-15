#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script $BASH_SOURCE failed at line $LINENO with retcode $?' ERR TERM

INSTALLER='sudo paru -Sy --noconfirm --needed'
$INSTALLER hyprland \
  gum network-manager-applet waybar
