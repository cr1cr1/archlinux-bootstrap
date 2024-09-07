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
$INSTALLER budgie network-manager-applet papirus-icon-theme budgie-desktop-view arc-gtk-theme \
  gnome-themes-extra gnome-console kitty gnome-calculator gnome-system-monitor gnome-keyring gnome-logs \
  gvfs-smb appmenu-gtk-module dconf-editor font-manager xorg-xhost qt5ct qt6ct kvantum \
  eog-plugins libheif evince strawberry vlc obs-studio xcolor rnote \
  meld nemo-preview nemo-share nemo-theme-glacier nemo-fileroller \
  gedit baobab doublecmd-qt6 libunrar freerdp remmina grsync gparted gsmartcontrol xarchiver \
  keepassxc x11-ssh-askpass \
  openrgb \
  thunderbird \
  virt-manager qemu-desktop \
  discord
