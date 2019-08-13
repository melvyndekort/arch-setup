#!/bin/sh

## Configure all preconditions for further setups
setup_pre_conditions() {
  sudo pacman -Sy --needed base-devel

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
  yay -Sy --sudoloop --answerclean No --nodiffmenu --noeditmenu --noupgrademenu --removemake --needed - < pkglist-base.txt

  pip install --upgrade --user -r ~/bin/requirements.txt
}

## Install all applications for development purposes
setup_development() {
  yay -Sy --sudoloop --answerclean No --nodiffmenu --noeditmenu --noupgrademenu --removemake --needed - < pkglist-devel.txt

  sudo systemctl enable NetworkManager.service
}

## Install all applications needed for any UI option
setup_ui_base() {
  yay -Sy --sudoloop --answerclean No --nodiffmenu --noeditmenu --noupgrademenu --removemake --needed - < pkglist-ui-base.txt
}

## Install all applications for suckless dwm
setup_ui_dwm() {
  yay -Sy --sudoloop --answerclean No --nodiffmenu --noeditmenu --noupgrademenu --removemake --needed - < pkglist-dwm.txt

  sudo systemctl enable lightdm.service
}

## Install all applications for i3
setup_ui_i3() {
  yay -Sy --sudoloop --answerclean No --nodiffmenu --noeditmenu --noupgrademenu --removemake --needed - < pkglist-i3.txt

  sudo systemctl enable lightdm.service
}

## Install all applications for Gnome
setup_ui_gnome() {
  yay -Sy --sudoloop --answerclean No --nodiffmenu --noeditmenu --noupgrademenu --removemake --needed - < pkglist-gnome-1.txt

  sudo pacman -Rcnsu - < pkglist-gnome-2.txt

  sudo systemctl enable gdm.service
}

## Install all extra applications
setup_extra() {
  yay -Sy --sudoloop --answerclean No --nodiffmenu --noeditmenu --noupgrademenu --removemake --needed - < pkglist-extra.txt
}

## Configure dotfiles
setup_dotfiles() {
  cd $HOME

  rm -rf $HOME/.shellcfg $HOME/.git

  git init --separate-git-dir=$HOME/.shellcfg $HOME
  git config status.showUntrackedFiles no

  git remote add origin git@github.com:melvyndekort/shellcfg.git
  git fetch
  git checkout -f -t origin/master

  chmod 600 $HOME/.ssh/config $HOME/.ssh/config.d/*
}


## Ask the user for input which groups he wants to install
cmd=(dialog --separate-output --checklist "Select which groups you want to install:" 22 76 16)
options=(1 "Pre conditions" off
         2 "Base" off
         3 "Suckless DWM" off
         4 "i3wm" off
         5 "GNOME" off
         6 "Development" off
         7 "Extra" off
         8 "Dotfiles" off)
choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)
clear

for choice in $choices
do
    case $choice in
        1)
            setup_pre_conditions
            ;;
        2)
            setup_ui_base
            ;;
        3)
            setup_ui_dwm
            ;;
        4)
            setup_ui_i3
            ;;
        5)
            setup_ui_gnome
            ;;
        6)
            setup_development
            ;;
        7)
            setup_extra
            ;;
        8)
            setup_dotfiles
            ;;
    esac
done
