#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script $BASH_SOURCE failed at line $LINENO with retcode $?' ERR TERM

INSTALLER='sudo pacman -Sy --noconfirm --needed'

## Deps
which paru &>/dev/null || "${BASH_SOURCE%/*}/00-paru.sh"
which lshw &>/dev/null || $INSTALLER lshw

## NVIDIA Drivers
if sudo lshw -C video -json | jq -r '.[].vendor=="NVIDIA Corporation"' | grep -q 'true'; then
  paru -Sy --noconfirm --needed nvidia nvidia-patch opencl-nvidia lib32-nvidia-utils lib32-opencl-nvidia
fi

## System apps
$INSTALLER mc tldr \
  git git-delta jq ripgrep htmlq jless xh pv unarchiver \
  openssh age openssl-1.1 \
  htop btop atop iotop sysstat ctop strace watchexec systemctl-tui dmidecode i2c-tools lm_sensors hwinfo hddtemp \
  wget curl inetutils net-tools bridge-utils dnsutils mtr trippy gping rsync rclone syncthing ssh-tools nmap tcpdump termshark gnu-netcat wireguard-tools networkmanager-openvpn iptraf-ng \
  eza gdu duf fd fzf skim lsof tree lnav xfsprogs expac direnv \
  kitty tmux zsh zsh-syntax-highlighting less bat zoxide stern screenfetch socat difftastic ueberzug \
  scrcpy android-tools \
  go python-pip sops xorriso kondo \
  snap-pac grub-btrfs \
  krew

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

for k in 8DFE60B7327D52D6 93BDB53CD4EBC740 F4A7678C9C6B0B2B 6C429F1D8D84F46E 38DBBDC86092693E B8AC08600F108CDF; do
  gpg --list-keys "$k" &>/dev/null || gpg --keyserver keyserver.ubuntu.com --recv-key "$k"
done
