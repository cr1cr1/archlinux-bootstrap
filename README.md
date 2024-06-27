# ArchLinux bootstrapping scripts

This repository contains scripts to bootstrap an ArchLinux installation and most of the software I use as a daily driver

## Usage

1. Boot into the ArchLinux live environment
2. Install using:
   1. Grub
   2. btrfs
3. Do not reboot, chroot immediately after the installation is finished
4. As root:
    1. Clone this repository
    2. `./01-bootstrap.sh`
    3. Optional: `useradd --shell /usr/bin/zsh --create-home -G sudo <user>`
    4. Reboot
5. As standard user with sudo rights:
   1. Clone this repository
   2. `sudo machinectl shell --uid $UID` [to be able to use DBus](https://www.reddit.com/r/podman/comments/12931nx/comment/kixlv1w/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)
   3. `./02-arch.sh`
