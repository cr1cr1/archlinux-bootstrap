#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script failed at line $LINENO with retcode $?' ERR TERM

INSTALLER='sudo pacman -Sy --noconfirm'

## System apps
$INSTALLER mc tldr \
  git git-delta jq ripgrep \
  openssh age openssl-1.1 \
  htop btop strace systemctl-tui i2c-tools lm_sensors hwinfo hddtemp \
  wget curl inetutils net-tools dnsutils mtr rsync ssh-tools nmap tcpdump wireguard-tools networkmanager-openvpn \
  eza gdu duf fd fzf skim lsof tree lshw lnav \
  tmux zsh zsh-syntax-highlighting bat zoxide stern screenfetch \
  scrcpy android-tools

## System files
for d in etc usr; do
  sudo cp -uvan "${BASH_SOURCE%/*}/$d" /
done

## Post install
for s in sshd systemd-modules-load; do
  sudo systemctl enable "$s"
  sudo systemctl restart "$s"
done

#sudo sensors-detect
