#!/bin/sh

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
  yay -Sy --sudoloop --answerclean No --nodiffmenu --noeditmenu --noupgrademenu --removemake --noconfirm --needed - < pkglist-base.txt
}

## Install all applications for development purposes
setup_development() {
  pip install --upgrade --user -r pkglist-pip.txt
  yay -Sy --sudoloop --answerclean No --nodiffmenu --noeditmenu --noupgrademenu --removemake --noconfirm --needed - < pkglist-development.txt
  sudo systemctl enable NetworkManager.service
}

## Install all applications needed for any UI option
setup_ui_base() {
  yay -Sy --sudoloop --answerclean No --nodiffmenu --noeditmenu --noupgrademenu --removemake --noconfirm --needed - < pkglist-ui-base.txt
}

## Install all applications for suckless dwm
setup_ui_dwm() {
  yay -Sy --sudoloop --answerclean No --nodiffmenu --noeditmenu --noupgrademenu --removemake --noconfirm --needed - < pkglist-dwm.txt
  sudo systemctl enable lightdm.service
}

## Install all applications for i3
setup_ui_i3() {
  yay -Sy --sudoloop --answerclean No --nodiffmenu --noeditmenu --noupgrademenu --removemake --noconfirm --needed - < pkglist-i3.txt
  sudo systemctl enable lightdm.service
}

## Install all applications for Gnome
setup_ui_gnome() {
  yay -Sy --sudoloop --answerclean No --nodiffmenu --noeditmenu --noupgrademenu --removemake --noconfirm --needed - < pkglist-gnome-1.txt
  yay -Rcnsu --sudoloop --noconfirm - < pkglist-gnome-2.txt
  sudo systemctl enable gdm.service
}

## Install all work related applications
setup_work() {
  yay -Sy --sudoloop --answerclean No --nodiffmenu --noeditmenu --noupgrademenu --removemake --noconfirm --needed - < pkglist-work.txt
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
         5 "Development" off
         6 "Work" off
         7 "Dotfiles" off)
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
            setup_pre_conditions
            setup_development
            ;;
        6)
            setup_pre_conditions
            setup_work
            ;;
        7)
            setup_dotfiles
            ;;
    esac
done
