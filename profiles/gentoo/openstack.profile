part sda 1 83 128M
part sda 2 8e +

part sdb 1 83 128M
part sdb 2 8e +

mdraid md1 -l 1 -n 2 /dev/sda1 /dev/sdb1 -e 0.90
mdraid md2 -l 1 -n 2 /dev/sda2 /dev/sdb2 -e 0.90

lvm_volgroup system /dev/md2
lvm_logvol   system 2G swap
lvm_logvol   system 8G root
lvm_logvol   system 2G var
lvm_logvol   system 8G home

format /dev/md1         ext4 "-L _boot"
format /dev/system/swap swap "-L _swap"
format /dev/system/root ext4 "-L _root"
format /dev/system/var  ext4 "-L _var"
format /dev/system/home ext4 "-L _home"

# needs appropriate /etc/mdadm.conf added to initrd to properly map/keep /dev/mdX mappings
# set in profile, auto mappings (usually in the 126-127ish range) will suffice with genkernel
# 'domdadm' setup scripts
mountfs /dev/md1         ext4  /boot    noauto,noatime
mountfs /dev/system/swap swap
mountfs /dev/system/root ext4  /        noatime
mountfs /dev/system/var  ext4  /var     noatime,nodev,nosuid,async,nouser
mountfs /dev/system/home ext4  /home    noatime,nodev,nosuid,async,nouser
mountfs tmpfs            tmpfs /tmp     nodev,size=40%
mountfs tmpfs            tmpfs /var/tmp nodev

# retrieve latest autobuild stage version for stage_uri
[ "${arch}" == "x86" ]   && stage_latest $(uname -m)
[ "${arch}" == "amd64" ] && stage_latest amd64
tree_type   snapshot    http://distfiles.gentoo.org/snapshots/portage-latest.tar.bz2

# get kernel dotconfig from the official running kernel
cat /proc/config.gz | gzip -d > /dotconfig
grep -v CONFIG_EXTRA_FIRMWARE /dotconfig > /dotconfig2 ; mv /dotconfig2 /dotconfig
grep -v LZO                   /dotconfig > /dotconfig2 ; mv /dotconfig2 /dotconfig
#kernel_config_file       /dotconfig
kernel_uri 				 http://xenlet.stu.neva.ru/kernel.conf
kernel_sources           gentoo-sources
initramfs_builder
genkernel_kernel_opts    --loglevel=5
genkernel_initramfs_opts --loglevel=5 --dmraid --mdadm --lvm

locale_set              "en en_US ISO-8859-1 en_US.UTF-8 UTF-8"
timezone                UTC
rootpw                  cl0udAdmin
bootloader              grub
bootloader_kernel_args  "vga=0x317 domdadm dolvm"
keymap                  us
hostname                gentoo-mdraid
extra_packages          mdadm lvm2 dhcpcd syslog-ng vim openssh iproute2 acpid curl# vixie-cron syslog-ng openssh gpm

rcadd                   mdadm            boot
rcadd                   lvm              boot
rcadd                   dhcpcd           default
#rcadd                   vixie-cron       default
#rcadd                   syslog-ng        default
#rcadd                   gpm              default

pre_build_kernel() {
    # NOTE we need lvm2 *before* the kernel to build the initramfs
    spawn_chroot "emerge lvm2 -q" || die "could not emerge lvm2"
}
