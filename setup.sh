#!/bin/sh

YAY='yay -Sy --sudoloop --answerclean No --nodiffmenu --noeditmenu --noupgrademenu --removemake --noconfirm --needed -'

## Configure X11 configuration
set_x11_config() {
  sudo localectl --no-convert set-x11-keymap us pc104 euro compose:rctrl,compose:menu,compose:rwin,terminate:ctrl_alt_bksp,lv3:lalt_switch,eurosign:5
  sudo cp configs/xorg/* /etc/X11/xorg.conf.d/
}

## Enable GDM daemon
enable_gdm() {
  sudo systemctl enable gdm.service
  sudo systemctl daemon-reload
}

## Configure all preconditions for further setups
setup_pre_conditions() {
  sudo pacman -Sy --noconfirm --needed base-devel

  if ! command -v yay; then
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin.git
    cd /tmp/yay-bin.git
    makepkg -si
    cd -
    rm -rf /tmp/yay-bin.git
  fi
}

## Install all applications for a base CLI only system
setup_base() {
  $YAY < pkglist-base.txt
  sudo systemctl daemon-reload
  sudo systemctl enable linux-modules-cleanup
}

## Install all applications for development purposes
setup_development() {
  pip install --upgrade --user -r pkglist-pip.txt
  $YAY < pkglist-development.txt
  sudo systemctl daemon-reload
  sudo systemctl enable NetworkManager.service
}

## Install all applications needed for any UI option
setup_ui_base() {
  $YAY < pkglist-ui-base.txt
}

## Install all applications for i3
setup_ui_i3() {
  $YAY < pkglist-i3.txt
  set_x11_config
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
  git clone -q git@github.com:melvyndekort/lmserver.git
  git clone -q git@github.com:melvyndekort/melvyndekort.github.io.git

  cd -
}

## Install all work related applications
setup_work() {
  $YAY < pkglist-work.txt
  sudo systemctl enable displaylink.service
  sudo sed -i 's/^load-module module-suspend-on-idle/#load-module module-suspend-on-idle/' /etc/pulse/default.pa
  systemctl --user daemon-reload
  systemctl --user restart pulseaudio.service
}

## Configure managed dotfiles
setup_dotfiles() {
  cd $HOME

  chezmoi init https://github.com/melvyndekort/dotfiles.git --apply
  chezmoi source remote -- set-url --push origin git@github.com:melvyndekort/dotfiles.git

  cd -
}

## Install precondition to run the rest of this script
if ! command -v dialog; then
  sudo pacman -Sy --noconfirm dialog
fi

## Ask the user for input which groups he wants to install
cmd=(dialog --separate-output --checklist "Select which groups you want to install:" 22 76 16)
options=(1 "Base" off
         2 "i3" off
         3 "GNOME" off
         4 "Setup src folders" off
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
            setup_ui_i3
            ;;
        3)
            setup_pre_conditions
            setup_ui_base
            setup_ui_gnome
            ;;
        4)
            setup_src_folders
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
