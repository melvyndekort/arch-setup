#!/bin/sh

set -e

alias install_pacman='sudo pacman -Sy --noconfirm --needed'
alias install_yay='yay -Sy --sudoloop --answerclean No --nodiffmenu --noeditmenu --noupgrademenu --removemake --noconfirm --needed'
alias build_and_install='makepkg -cCfi --noconfirm'

## Configure all preconditions for further setups
setup_pre_conditions() {
  install_pacman base-devel

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
  install_yay < pkglist-base.txt
  sudo systemctl daemon-reload
  sudo systemctl enable linux-modules-cleanup
}

## Install or upgrade all custom packages
setup_custom_packages() {
  (
    cd packages/mdekort-reflector
    build_and_install
  )

  (
    cd packages/mdekort-polkit
    build_and_install
  )
}

## Install all applications for development purposes
setup_development() {
  install_yay < pkglist-development.txt
  pip install --upgrade --user -r pkglist-pip.txt
}

## Install all applications for tiling window managers
setup_ui() {
  install_yay < pkglist-ui.txt

  (
    cd packages/xorg-mdekort
    build_and_install
  )
}

## Clone most used git repos
setup_src_folders() {
  cd $HOME/src

  [ -d 'arch-setup' ] || git clone -q git@github.com:melvyndekort/arch-setup.git
  [ -d 'aws-mdekort' ] || git clone -q git@github.com:melvyndekort/aws-mdekort.git
  [ -d 'cheatsheets' ] || git clone -q git@github.com:melvyndekort/cheatsheets.git
  [ -d 'lmserver' ] || git clone -q git@github.com:melvyndekort/lmserver.git
  [ -d 'melvyndekort.github.io' ] || git clone -q git@github.com:melvyndekort/melvyndekort.github.io.git
  [ -d 'pihole' ] || git clone -q git@github.com:melvyndekort/pihole.git
  [ -d 'scheduler' ] || git clone -q git@github.com:melvyndekort/scheduler.git

  cd -
}

## Install all work related applications
setup_work() {
  install_yay < pkglist-work.txt

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

  while true; do
    curl -sL https://assets.mdekort.nl/secure/gpg.txt |\
    gpg --decrypt |\
    gpg --import

    if [ $? -eq 0 ]; then
        break
    fi

    echo "Failed, try again..."
    sleep 1
  done
  
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

  [ ! -d "$HOME/.password-store" ] && git clone git@github.com:melvyndekort/password-store.git $HOME/.password-store

  chezmoi init --apply melvyndekort
  chezmoi git remote -- set-url --push origin git@github.com:melvyndekort/dotfiles.git
}

## Enable Network Manager (usually used in laptop setups)
setup_nm() {
  sudo systemctl enable NetworkManager.service
}

## Install precondition to run the rest of this script
if ! command -v dialog; then
  install_pacman dialog
fi

## Ask the user for input which groups he or she wants to install
tempfile=/tmp/dialog-$$
dialog --separate-output --checklist "Select which groups you want to install:" 22 76 16 \
1 "Base" off \
2 "UI" off \
3 "Setup src folders" off \
4 "Development" off \
5 "Work" off \
6 "Dotfiles" off \
7 "Enable Network Manager" off \
8 "Upgrade custom packages" off 2> $tempfile
clear

choices=`cat $tempfile`
for i in $choices; do
  case $i in
    1)
        setup_pre_conditions
        setup_base
        setup_custom_packages
        ;;
    2)
        setup_pre_conditions
        setup_ui
        ;;
    3)
        setup_src_folders
        ;;
    4)
        setup_pre_conditions
        setup_development
        ;;
    5)
        setup_pre_conditions
        setup_work
        ;;
    6)
        setup_dotfiles
        ;;
    7)
        setup_nm
        ;;
    8)
        setup_custom_packages
        ;;
  esac
done
rm -f $tempfile
