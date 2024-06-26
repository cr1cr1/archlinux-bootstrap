#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script failed at line $LINENO with retcode $?' ERR TERM

## Fixes rendering issues with WebKitGTK based apps like Whatsapp, Minigalaxy, Journal Viewer
grep -qP '^WEBKIT_DISABLE_DMABUF_RENDERER' /etc/environment || \
  sudo sed -i -E 's,^[#\s]*(WEBKIT_DISABLE_DMABUF_RENDERER)=1,\1=1,' /etc/environment

INSTALLER='sudo pacman -Sy --noconfirm --needed'
$INSTALLER budgie network-manager-applet papirus-icon-theme budgie-desktop-view arc-gtk-theme \
  gnome-themes-extra gnome-console gnome-calculator gnome-system-monitor gnome-keyring gnome-packagekit gnome-logs \
  gvfs-smb appmenu-gtk-module dconf-editor font-manager xorg-xhost \
  eog-plugins libheif evince strawberry vlc obs-studio \
  meld nemo-preview nemo-share nemo-theme-glacier \
  gedit baobab doublecmd-gtk2 libunrar freerdp remmina transmission-remote-gtk grsync gparted gsmartcontrol xarchiver \
  keepassxc x11-ssh-askpass \
  openrgb \
  thunderbird \
  virt-manager qemu-desktop \
  discord
