#!/bin/sh

YAY='yay -Sy --sudoloop --answerclean No --nodiffmenu --noeditmenu --noupgrademenu --removemake --noconfirm --needed -'

## Configure X11 configuration
set_X11_config() {
  sudo localectl --no-convert set-x11-keymap us pc104 euro compose:rctrl,compose:menu,compose:rwin,terminate:ctrl_alt_bksp,lv3:lalt_switch,eurosign:5
  sudo cp configs/xorg/* /etc/X11/xorg.conf.d/
}

## Enable SLiM daemon
enable_slim() {
  sudo systemctl enable slim.service
}

## Enable GDM daemon
enable_gdm() {
  sudo systemctl enable gdm.service
}

## Configure all preconditions for further setups
setup_pre_conditions() {
  sudo pacman -Sy --noconfirm --needed base-devel

  if ! command -v yay; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay.git
    cd /tmp/yay.git
    makepkg -si
    cd -
    rm -rf /tmp/yay.git
  fi
}

## Install all applications for a base CLI only system
setup_base() {
  $YAY < pkglist-base.txt
}

## Install all applications for development purposes
setup_development() {
  pip install --upgrade --user -r pkglist-pip.txt
  $YAY < pkglist-development.txt
  sudo systemctl enable NetworkManager.service
}

## Install all applications needed for any UI option
setup_ui_base() {
  $YAY < pkglist-ui-base.txt
}

## Install all applications for suckless dwm
setup_ui_dwm() {
  $YAY < pkglist-dwm.txt
  set_x11_config
  enable_slim
}

## Install all applications for i3
setup_ui_i3() {
  $YAY < pkglist-i3.txt
  set_x11_config
  enable_slim
}

## Install all applications for Gnome
setup_ui_gnome() {
  $YAY < pkglist-gnome-1.txt
  yay -Rcnsu --sudoloop --noconfirm - < pkglist-gnome-2.txt
  enable_gdm
}

## Clone most used git repos
setup_src_folders() {
  cd $HOME/src

  git clone -q git@github.com:melvyndekort/arch-setup.git
  git clone -q git@github.com:melvyndekort/st.git
  git clone -q git@github.com:melvyndekort/dwm.git
  git clone -q git@github.com:melvyndekort/lmserver.git
  git clone -q git@github.com:melvyndekort/melvyndekort.github.io.git
}

## Install all work related applications
setup_work() {
  $YAY < pkglist-work.txt
}

## Configure dotfiles
setup_dotfiles() {
  cd $HOME

  rm -rf $HOME/.dotfiles $HOME/.git

  git init --separate-git-dir=$HOME/.dotfiles $HOME
  git config status.showUntrackedFiles no

  git remote add origin git@github.com:melvyndekort/dotfiles.git
  git fetch
  git checkout -f -t origin/master

  chmod 600 $HOME/.ssh/config $HOME/.ssh/config.d/*
}

## Install precondition to run the rest of this script
if ! command -v dialog; then
  sudo pacman -Sy --noconfirm dialog
fi

## Ask the user for input which groups he wants to install
cmd=(dialog --separate-output --checklist "Select which groups you want to install:" 22 76 16)
options=(1 "Base" off
         2 "Suckless DWM" off
         3 "i3" off
         4 "GNOME" off
         5 "Setup src folders" off
         6 "Development" off
         7 "Work" off
         8 "Dotfiles" off)
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear

for choice in $choices
do
    case $choice in
        1)
            setup_pre_conditions
            setup_base
            ;;
        2)
            setup_pre_conditions
            setup_ui_base
            setup_ui_dwm
            ;;
        3)
            setup_pre_conditions
            setup_ui_base
            setup_ui_i3
            ;;
        4)
            setup_pre_conditions
            setup_ui_base
            setup_ui_gnome
            ;;
        5)
            setup_src_folders
            ;;
        6)
            setup_pre_conditions
            setup_development
            ;;
        7)
            setup_pre_conditions
            setup_work
            ;;
        8)
            setup_dotfiles
            ;;
    esac
done
