#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script failed at line $LINENO with retcode $?' ERR TERM

INSTALLER='sudo pacman -Sy --noconfirm --needed'

## Deps
which paru &>/dev/null || "${BASH_SOURCE%/*}/00-paru.sh"
which lshw &>/dev/null || $INSTALLER lshw

## NVIDIA Drivers
if [[ $(sudo lshw -C video -json | jq -r '.[].vendor') == 'NVIDIA Corporation' ]]; then
  $INSTALLER nvidia
  paru -Sy --noconfirm --needed nvidia-patch
fi

## System apps
$INSTALLER mc tldr \
  git git-delta jq ripgrep \
  openssh age openssl-1.1 \
  htop btop atop iotop sysstat ctop strace systemctl-tui i2c-tools lm_sensors hwinfo hddtemp \
  wget curl inetutils net-tools dnsutils mtr trippy gping rsync ssh-tools nmap tcpdump termshark gnu-netcat wireguard-tools networkmanager-openvpn \
  eza gdu duf fd fzf skim lsof tree lnav xfsprogs \
  tmux zsh zsh-syntax-highlighting less bat zoxide stern screenfetch \
  scrcpy android-tools \
  go python-pip kubectl sops xorriso

## System files
for d in etc usr; do
  sudo cp -uvrnd "${BASH_SOURCE%/*}/$d" /
done

## Post install
for s in sshd systemd-modules-load; do
  sudo systemctl enable "$s"
  sudo systemctl restart "$s"
done

#sudo sensors-detect

systemctl --user enable ssh-agent
systemctl --user restart ssh-agent
