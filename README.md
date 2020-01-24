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
lvcreate -L 200G -n home ssd
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

```
pacstrap /mnt base linux linux-firmware dialog wpa_supplicant dhcpcd netctl cryptsetup lvm2 dosfstools efibootmgr sudo pacman-contrib git vim
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
HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt lvm2 filesystems fsck)
```

And run:

```
mkinitcpio -P
```

### Set root password

```
passwd
```

### Install boot loader

```
efibootmgr -v -c -L "Arch Linux" -l /vmlinuz-linux -u 'cryptdevice=UUID=<LUKS UUID>:cryptlvm root=/dev/ssd/root rw initrd=\initramfs-linux.img'
```

### Exit chroot and boot into Arch
```
exit
umount -R /mnt
reboot
```

### Set up mirrorlist

```
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
sed -i 's/^#Server/Server/' /etc/pacman.d/mirrorlist.backup
rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist
```

### Create user

```
useradd -G wheel melvyn
passwd melvyn
EDITOR=vim visudo
```

### Set up sudo

Run `visudo` and make sure it contains the following configuration:

```
## Uncomment to allow members of group wheel to execute any command
%wheel ALL=(ALL) ALL

## Same thing without a password
%wheel ALL=(ALL) NOPASSWD: /usr/bin/chvt
```
