#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script $BASH_SOURCE failed at line $LINENO with retcode $?' ERR TERM

## Fixes rendering issues with WebKitGTK based apps like Whatsapp, Minigalaxy, Journal Viewer
grep -qP '^WEBKIT_DISABLE_DMABUF_RENDERER' /etc/environment || \
  sudo sed -i -E 's,^[#\s]*(WEBKIT_DISABLE_DMABUF_RENDERER).+,\1=1,' /etc/environment

grep -qP '^QT_AUTO_SCREEN_SCALE_FACTOR' /etc/environment || \
  sudo sed -i -E 's,^[#\s]*(QT_AUTO_SCREEN_SCALE_FACTOR).+,\1=1,' /etc/environment

grep -qP '^QT_QPA_PLATFORMTHEME' /etc/environment || \
  sudo sed -i -E 's,^[#\s]*(QT_QPA_PLATFORMTHEME).+,\1=qt6ct,' /etc/environment

INSTALLER='sudo pacman -Sy --noconfirm --needed'
$INSTALLER gdm \
  gnome-themes-extra gnome-system-monitor gnome-keyring gnome-shell-extensions gnome-control-center gnome-logs dconf-editor \
  gvfs-smb appmenu-gtk-module font-manager xorg-xhost wmctrl \
  eog-plugins libheif evince strawberry vlc obs-studio xcolor rnote \
  meld nemo-preview nemo-share nemo-theme-glacier nemo-fileroller \
  gedit baobab doublecmd-qt6 \
  nm-connection-editor freerdp remmina grsync gparted gsmartcontrol \
  libunrar xarchiver \
  qt5ct qt6ct qt5-wayland qt6-wayland kvantum papirus-icon-theme \
  keepassxc x11-ssh-askpass xclip wl-clipboard \
  openrgb \
  thunderbird \
  virt-manager qemu-desktop \
  discord

## https://wiki.archlinux.org/title/GDM#Wayland_and_the_proprietary_NVIDIA_driver
UDEV_RULES='/etc/udev/rules.d/61-gdm.rules'
[[ -L "$UDEV_RULES" ]] || \
  sudo ln -s /dev/null "$UDEV_RULES"
