#!/bin/env bash

set -u -e -o pipefail

trap 'echo Script $BASH_SOURCE failed at line $LINENO with retcode $?' ERR TERM

_help() {
  echo "Usage: $0 [file-list]"
  echo "  file-list: [optional] file with list of programs to install, one or more per line, space separated"
  echo "-h, --help: Show this help"
  exit 0
}

# check in all arguments for -h or --help
for arg in "$@"; do
  [[ "$arg" == "-h" || "$arg" == "--help" ]] && _help
done

## Configuration functions
configure_atuin() {
  which atuin >/dev/null || return

  ATUIN_SCRIPT_PATH=/usr/local/libexec/atuin
  [[ -d "$ATUIN_SCRIPT_PATH" ]] || sudo mkdir -p "$ATUIN_SCRIPT_PATH"
  sudo curl -sSL https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh -o "$ATUIN_SCRIPT_PATH/bash-preexec.sh"

  grep -q 'bash-preexec\.sh' /etc/bash.bashrc || \
    echo "[[ -f $ATUIN_SCRIPT_PATH/bash-preexec.sh ]] && source $ATUIN_SCRIPT_PATH/bash-preexec.sh" | sudo tee -a /etc/bash.bashrc
  # shellcheck disable=SC2016
  grep -q 'atuin init' /etc/bash.bashrc || \
    printf "%s\n\n" 'eval "$(atuin init bash)"' | sudo tee -a /etc/bash.bashrc
}

configure_papirus-folders-catppuccin-git() {
  papirus-folders -C cat-mocha-lavender --theme Papirus-Dark
}

configure_catppuccin-mocha-grub-theme-git() {
  sudo sed -i -E 's,^#*(GRUB_THEME=).+,\1/usr/share/grub/themes/catppuccin-mocha/theme.txt,' /etc/default/grub
  sudo grub-mkconfig -o /boot/grub/grub.cfg || true
}

configure_gnome-ssh-askpass4-git() {
  if grep -q SSH_ASKPASS /etc/environment; then
    sudo sed -i -E 's,^#*(SSH_ASKPASS=).+,\1/usr/lib/ssh/gnome-ssh-askpass4,' /etc/environment
  else
    echo 'SSH_ASKPASS=/usr/lib/ssh/gnome-ssh-askpass4' | sudo tee -a /etc/environment >/dev/null
  fi
}

configure_rustdesk-bin() {
  _BIN_NAME=rustdesk
  if [[ -d "${BASH_SOURCE%/*}/.config/$_BIN_NAME" ]]; then
    ## Local users with sudo rights
    while IFS= read -r line; do
      user=$(cut -d: -f1 <<< "$line")
      ## is a sudoer?
      sudo -lU "$user" | grep -q 'not allowed' && continue
      homedir=$(cut -d: -f6 <<< "$line")
      sudo cp -uvrnd "${BASH_SOURCE%/*}/.config/$_BIN_NAME" "$homedir/.config/" || continue
      sudo chown -R "$user" "$homedir/.config/$_BIN_NAME"
    done < <(getent passwd | grep -v nologin)
  fi
  #sudo systemctl enable rustdesk
  #sudo systemctl start rustdesk || true
}

configure_sunshine-bin() {
  SUNSHINE_PATH=$(readlink -f "$(which sunshine)")
  set -x
  sudo setcap cap_sys_admin+p "$SUNSHINE_PATH"
  { set +x; } 2>/dev/null
}

configure_btop-theme-catppuccin() {
  if [[ $EUID -ne 0 ]]; then
    [[ -d "$HOME/.config/btop" ]] || \
      { set -x; mkdir -p "$HOME/.config/btop"; { set +x; } 2>/dev/null; }
    [[ -f "$HOME/.config/btop/btop.conf" ]] || \
      { set -x; cp "${BASH_SOURCE%/*}/.config/btop/btop.conf" "$HOME/.config/btop/"; { set +x; } 2>/dev/null; }
    return
  fi
  while IFS= read -r line; do
    user=$(cut -d: -f1 <<< "$line")
    user_home=$(cut -d: -f6 <<< "$line")
    [[ -d "$user_home" && "$user_home" != "/"  ]] || continue
    [[ -d "$user_home/.config/btop" ]] || \
      { set -x; sudo -u "$user" -- mkdir -p "$user_home/.config/btop"; { set +x; } 2>/dev/null; }
    [[ -f "$user_home/.config/btop/btop.conf" ]] || \
      { set -x; sudo -u "$user" -- cp "${BASH_SOURCE%/*}/.config/btop/btop.conf" "$user_home/.config/btop/"; { set +x; } 2>/dev/null; }
  done < <(getent passwd | grep -v nologin)
}

configure_yazi() {
  if [[ $EUID -ne 0 ]]; then
    ## Plugins
    for p in full-border smart-filter git chmod max-preview; do
      set -x
      ya pack -a yazi-rs/plugins:$p || true
      { set +x; } 2>/dev/null
    done
    ## Flavors
    for f in catppuccin-mocha catppuccin-frappe catppuccin-macchiato; do
      set -x
      ya pack -a yazi-rs/flavors:$f
      { set +x; } 2>/dev/null
    done
    ## Update all
    set -x
    ya pack -u || true
    { set +x; } 2>/dev/null
    [[ -d ~/.config/yazi ]] || mkdir -p ~/.config/yazi
    set -x
    cp -n -f "${SCRIPT_PATH%/*}"/.config/yazi/* ~/.config/yazi/
    { set +x; } 2>/dev/null
  fi
}

## Deps
which paru &>/dev/null || "${BASH_SOURCE%/*}/00-paru.sh"
INSTALLER='sudo pacman -Sy --noconfirm --needed'
sudo pacman -Q base-devel &>/dev/null || $INSTALLER base-devel

## Install programs with paru
SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
DEFAULT_LISTS_PATH=${SCRIPT_PATH%/*}/.config/paru
LISTS="${*:-$DEFAULT_LISTS_PATH/_all.txt $DEFAULT_LISTS_PATH/$(hostname).txt}"

# shellcheck disable=SC2046,SC2086
paru -Sy --noconfirm --needed $(cat $LISTS | grep -v '^#' | tr '\n' ' ')

for f in $LISTS; do
  [[ -f "$f" ]] || continue
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    func="configure_${line/\//_}"
    if type -t "$func" &>/dev/null; then
      printf -- '-%.0s' $(seq 1 "$(tput cols)")
      echo " + Configuring $line"
      eval "$func"
    fi
  done < "$f"
done
