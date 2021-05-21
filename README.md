# Melvyn's Arch setup

## Setting up a clean install

```
sh setup.sh
```

## Setting up an encrypted UEFI installation

The following setup guide will set up an encrypted Arch installation on UEFI hardware.

### Verify boot mode

```
ls /sys/firmware/efi/efivars
```

### Connect to WiFi

```
wifi-menu
```

### Update the system clock

```
timedatectl set-ntp true
```

### Partition the disk

```
parted /dev/sda
  mklabel gpt
  mkpart primary fat32 0% 500M
  set 1 esp on
  mkpart primary 500M 100%
  quit
```

### Encrypt the disk and setup LVM

```
cryptsetup luksFormat /dev/sda2
cryptsetup luksOpen /dev/sda2 crypt

pvcreate /dev/mapper/crypt
vgcreate ssd /dev/mapper/crypt

lvcreate -L 16G -n swap ssd
lvcreate -L 50G -n root ssd
lvcreate -l 100%FREE -n home ssd
```

### Format the partitions

```
mkfs.fat -F32 -n esp /dev/sda1
mkfs.ext4 -L root /dev/mapper/ssd-root
mkfs.ext4 -L home /dev/mapper/ssd-home
mkswap -L swap /dev/mapper/ssd-swap
```

### Mount the partitions

```
mount /dev/mapper/ssd-root /mnt
mkdir /mnt/boot /mnt/home
mount /dev/sda1 /mnt/boot
mount /dev/mapper/ssd-home /mnt/home
swapon /dev/mapper/ssd-swap
```

### Install essential packages

Edit the mirrorlist.
```
vim /etc/pacman.d/mirrorlist
```

Install the base packages.
```
pacstrap /mnt base linux linux-firmware dialog cryptsetup lvm2 dosfstools efibootmgr sudo pacman-contrib git neovim
```

### Setup disk mounts

```
genfstab -U /mnt >> /mnt/etc/fstab
```

### Chroot

```
arch-chroot /mnt
```

### Set the timezone

```
ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
hwclock --systohc
```

### Set the locale

Edit `/etc/locale.gen` and remove the `#` from the `en_US.UTF-8` line.

```
locale-gen
echo 'LANG=en_US.UTF-8' > /etc/locale.conf
```

### Set the hostname

```
echo HOSTNAME > /etc/hostname
```

Edit `/etc/hosts` and add the following lines:

```
127.0.0.1  localhost
::1        localhost
127.0.1.1  HOSTNAME.localdomain HOSTNAME
```

### Create initramfs

Change the `HOOKS=(...)` line to:

```
HOOKS=(...block encrypt lvm2 filesystems...)
```

And run:

```
mkinitcpio -P
```

### Set root password

```
passwd
```

### Create user

```
useradd -m -G wheel USER
passwd USER
```

### Set up sudo

Run `visudo` and make sure it contains the wheel configuration.

```
EDITOR=nvim visudo
```

```
## Uncomment to allow members of group wheel to execute any command
%wheel ALL=(ALL) ALL

## Same thing without a password
%wheel ALL=(ALL) NOPASSWD: /usr/bin/chvt
```

### Install boot loader

```
bootctl install
```

Create `/boot/loader/loader.conf`
```
default	arch.conf
timeout 0
#console-mode keep
```

Create `/boot/loader/entries/arch.conf`
```
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options	cryptdevice=UUID=<UUID OF SDA2>:cryptlvm root=UUID=<UUID OF ROOT> rw
```

### Exit chroot and boot into Arch
```
exit
umount -R /mnt
reboot
```

### Configure the rest of the system without SSH
```
pacman -Sy openssh-askpass
curl -sl https://assets.mdekort.nl/secure/ssh.txt | gpg -d | ssh-add -
```

### Finalize installation
```
mkdir ~/src
cd ~/src
git clone git@github.com:melvyndekort/arch-setup.git
cd arch-setup
./setup.sh

vim /etc/libvirt/qemu.conf
user = "root"
group = "root"
dynamic_ownership = 0

usermod -a -G libvirt,docker,kvm,tfenv melvyn
systemctl enable docker
systemctl enable libvirtd

reboot
```
