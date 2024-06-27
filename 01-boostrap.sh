#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script failed at line $LINENO with retcode $?' ERR TERM

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

pacman-key --init
pacman-key --populate archlinux
# pacman-key --refresh-keys

INSTALLER='pacman -Sy --noconfirm --needed'
## Install deps
for c in sudo sed grep efibootmgr os-prober; do
  which $c &>/dev/null || $INSTALLER $c
done

# shellcheck disable=SC1091
. "${BASH_SOURCE%/*}/_initool.sh"
sudo cp /etc/pacman.conf{,."$(date +%F_%H%M%S)"}
INI_CMD="ini --pass-through set /etc/pacman.conf"
## Relax pacman signature requirement. DAGNER!
$INI_CMD options RemoteFileSigLevel Optional | sudo tee /etc/pacman.conf >/dev/null
## Enable multilib (32bit repo)
$INI_CMD multilib Include /etc/pacman.d/mirrorlist | sudo tee /etc/pacman.conf >/dev/null

## Crude efi check
efibootmgr || exit 0
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
