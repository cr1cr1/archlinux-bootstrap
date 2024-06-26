#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script failed at line $LINENO with retcode $?' ERR TERM

sudo pacman-key --init
sudo pacman-key --populate archlinux
# sudo pacman-key --refresh-keys

# shellcheck disable=SC1091
. "${BASH_SOURCE%/*}/_initool.sh"
sudo cp /etc/pacman.conf{,."$(date +%F_%H%M%S)"}
INI_CMD="ini --pass-through set /etc/pacman.conf"
## Relax pacman signature requirement. DAGNER!
$INI_CMD options RemoteFileSigLevel Optional | sudo tee /etc/pacman.conf >/dev/null
## Enable multilib (32bit repo)
$INI_CMD multilib Include /etc/pacman.d/mirrorlist | sudo tee /etc/pacman.conf >/dev/null

INSTALLER='sudo pacman -Sy --noconfirm --needed'
## Install deps
for c in sed grep efibootmgr os-prober; do
  which $c &>/dev/null || $INSTALLER $c
done

## Grub
which grub-install &>/dev/null || $INSTALLER grub
[[ -d /boot/grub ]] || sudo mkdir -p /boot/grub
## Enable OS prober
sudo sed -i -E 's,#*(GRUB_DISABLE_OS_PROBER=).*,\1false,' /etc/default/grub
## Enable Intel iommu
sudo grep -q 'intel_iommu=on' /etc/default/grub || \
  sudo sed -i -E 's,^#*(GRUB_CMDLINE_LINUX_DEFAULT.+[^"]+),\1 intel_iommu=on,' /etc/default/grub
## Install grub
sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=ArchLinux
sudo grub-mkconfig -o /boot/grub/grub.cfg
