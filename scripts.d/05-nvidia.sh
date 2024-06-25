#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script failed at line $LINENO with retcode $?' ERR TERM

## Install deps
INSTALLER='sudo pacman -Sy --noconfirm'
for p in jq curl lshw; do
  which "$p" &> /dev/null || $INSTALLER "$p"
done

## Detect hardware
if [[ $(lshw -C video -json | jq -r '.[].vendor') != 'NVIDIA Corporation' ]]; then
  echo "No NVIDIA card found" 1>&2
  exit 0
fi

NVIDIA_LATEST=$(curl -sSL "https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=120&pfid=929&osID=12&languageCode=1033&beta=0&isWHQL=0&dltype=-1&dch=0&upCRD=0&qnf=0&sort1=1&numberOfResults=1")
VERSION=$(jq -r '.IDS[0].downloadInfo.DisplayVersion' <<< "$NVIDIA_LATEST")

## Check current version
grep -qP "Module\s+$VERSION" /proc/driver/nvidia/version && exit 0

## Install NVIDIA drivers
$INSTALLER nvtop linux-headers
[[ -f /tmp/nvidia-driver.run ]] || \
  curl -L "https://us.download.nvidia.com/XFree86/Linux-x86_64/${VERSION}/NVIDIA-Linux-x86_64-${VERSION}.run" > /tmp/nvidia-driver.run
sudo bash /tmp/nvidia-driver.run -s
