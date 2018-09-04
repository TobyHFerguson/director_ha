#!/usr/bin/env bash

set -x
exec > ~/bootstrap-cdsw.$(date +%Y%m%d%H%M%S).log 2>&1

PATH=$PATH:/usr/sbin:/sbin

CDSW_DOMAIN="cdsw.trng201809.lab"

lsblk
cat /etc/fstab
mount

umount /data0
umount /data1

yum install -y e4fsprogs


# Mount one volume for application data
#device="/dev/nvme1n1"
device="/dev/sdc"
mount="/var/lib/cdsw"

echo "Making file system"
mkfs.ext4 -F -E lazy_itable_init=1 "$device" -m 0

echo "Mounting $device on $mount"
if [ ! -e "$mount" ]; then
  mkdir -p "$mount"
fi

mount -o defaults,noatime "$device" "$mount"

#sed -i '/nvme1n1/d' /etc/fstab
#sed -i '/nvme2n1/d' /etc/fstab

sed -i '/sdc/d' /etc/fstab
sed -i '/sdd/d' /etc/fstab

echo "$device $mount ext4 defaults,noatime 0 0" >> /etc/fstab


yum -y install dnsmasq
cat /etc/resolv.conf | grep nameserver > /etc/dnsmasq.resolv.conf
chmod a+r /etc/dnsmasq.resolv.conf
perl -pi -e "s|^.*?resolv-file.*?$|resolv-file=/etc/dnsmasq.resolv.conf|" /etc/dnsmasq.conf
echo address=/${CDSW_DOMAIN}/$(hostname -I) > /etc/dnsmasq.d/cdsw.conf
systemctl start dnsmasq
chkconfig dnsmasq on

# Add DNS(dnsmasq on local)
chattr -i /etc/resolv.conf
perl -pi -e "s/nameserver.*$/nameserver $(hostname -I)/" /etc/resolv.conf
#echo "nameserver  $(hostname -I)" >> /etc/resolv.conf
chattr +i /etc/resolv.conf

exit 0

