# ArchLinux bootstrapping scripts

This repository contains scripts to bootstrap an ArchLinux installation and most of the software I use as a daily driver

## Usage

1. Boot into the ArchLinux live environment
2. Install using:
   1. Grub
   2. btrfs
3. Do not reboot, chroot immediately after the installation is finished
4. As standard user with sudo rights:
    1. Clone this repository
    2. `./01-bootstrap.sh`
    3. `./02-arch.sh`
