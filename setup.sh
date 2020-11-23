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

## Configure reflector as a service to update pacman mirrorlist at every boot
configure_reflector() {
  cat << EOF | sudo tee /etc/systemd/system/reflector.service > /dev/null
[Unit]
Description=Pacman mirrorlist update
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/reflector --latest 20 --country Netherlands --country Germany --age 24 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

[Install]
RequiredBy=multi-user.target
EOF
  sudo systemctl enable reflector
}

## Install all applications for a base CLI only system
setup_base() {
  $YAY < pkglist-base.txt
  sudo systemctl daemon-reload
  sudo systemctl enable linux-modules-cleanup
  configure_reflector
  sudo ln -sfT dash /usr/bin/sh
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

## Install all applications for tiling window managers
setup_ui_tiling() {
  $YAY < pkglist-tiling.txt
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
  export XDG_CONFIG_HOME=$HOME/.config
  export XDG_DATA_HOME=$HOME/.local/share
  export GNUPGHOME="$XDG_DATA_HOME"/gnupg
  export GPG_TTY=$(tty)
  mkdir -p $XDG_CONFIG_HOME $GNUPGHOME
  chmod 700 $GNUPGHOME
  
  curl -sL https://gist.githubusercontent.com/melvyndekort/072e302aa02ed43b1052002f90da564e/raw/4ce43c8435f9f6ae8a86a10d217ab74a9f73bc35/melvyn |\
  gpg --decrypt |\
  gpg --import
  
  echo
  echo
  echo '============================================================================'
  echo '  Now importing the private GPG key, you need to ultimately trust the key:'
  echo '    # enter 5<RETURN>'
  echo '    # enter y<RETURN>'
  echo '============================================================================'
  echo
  echo
  gpg --edit-key melvyn@mdekort.nl trust quit

  chezmoi init --apply https://github.com/melvyndekort/dotfiles.git
  chezmoi source remote -- set-url --push origin git@github.com:melvyndekort/dotfiles.git
}

## Install precondition to run the rest of this script
if ! command -v dialog; then
  sudo pacman -Sy --noconfirm dialog
fi

## Ask the user for input which groups he wants to install
tempfile=/tmp/dialog-$$
dialog --separate-output --checklist "Select which groups you want to install:" 22 76 16 \
1 "Base" off \
2 "Tiling" off \
3 "GNOME" off \
4 "Setup src folders" off \
5 "Development" off \
6 "Work" off \
7 "Dotfiles" off 2> $tempfile
clear

choices=`cat $tempfile`
for i in $choices; do
  case $i in
    1)
        setup_pre_conditions
        setup_base
        ;;
    2)
        setup_pre_conditions
        setup_ui_base
        setup_ui_tiling
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
rm -f $tempfile
