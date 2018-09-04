#!/usr/bin/env bash

set -x
exec > ~/bootstrap-dns.$(date +%Y%m%d%H%M%S).log 2>&1

PATH=$PATH:/sbin:/usr/sbin; export $PATH
host_prefix=trng
nameserver="10.7.0.7"
dns_domain="trng201809.lab"


ip=$(hostname -I)
#host_short=$(echo ${ip} | sed -e "s/\./-/g")
#host_short="$(echo ${host_prefix}$(curl -s http://169.254.169.254/latest/meta-data/instance-id | cut -c3-11) | tr '[:upper:]' '[:lower:]')"
host_short=$(hostname -s)
host=${host_short}.${dns_domain}

# Set hostname
hostname $host
sed -i -e "s/^HOSTNAME=\(.*\)/HOSTNAME=${host}/g" /etc/sysconfig/network
echo "${host}" > /etc/hostname

# Configure cloud-init for future reboots
#cloud_config="/etc/cloud/cloud.cfg.d/99_hostname.cfg"
#echo "#cloud-config" > $cloud_config
#echo "hostname: ${host_short}" >> $cloud_config
#echo "fqdn: ${host} " >> $cloud_config

cat <<EOF > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

${ip}	${host}	${host_short}
EOF

echo ${host} > /etc/hostname

chattr +i /etc/hostname


cat <<EOF > /etc/resolv.conf
search ${dns_domain}
nameserver ${nameserver}
EOF

chattr +i /etc/resolv.conf

systemctl stop chronyd
systemctl stop ntpd
systemctl disable ntpd.service

sed -i.$(date +%Y%m%d%H%M%S).bak -e "s/server 0.centos.pool.ntp.org iburst/server ${nameserver}  iburst/g; \
s/server 1.centos.pool.ntp.org iburst/#server 1.centos.pool.ntp.org iburst/g; \
s/server 2.centos.pool.ntp.org iburst/#server 2.centos.pool.ntp.org iburst/g; \
s/server 3.centos.pool.ntp.org iburst/#server 3.centos.pool.ntp.org iburst/g" /etc/chrony.conf

systemctl restart network

systemctl start chronyd

