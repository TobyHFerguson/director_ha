#!/bin/bash
# 

set -x
exec > ~/bootstrap-misc.$(date +%Y%m%d%H%M%S).log 2>&1


# Adding missing path to /usr/sbin so root user can find blockdev
echo 'PATH=$PATH:/usr/sbin' >> /root/.bashrc
echo 'export PATH' >> /root/.bashrc

echo 'PATH=$PATH:/usr/sbin' >> /home/centos/.bashrc
echo 'export PATH' >> /home/centos/.bashrc

cat << 'EOF' >> /etc/yum.conf
proxy=http://10.7.0.5:3128
EOF
mkdir -p /opt/cloudera/director
chmod 755 /opt/cloudera
chmod 755 /opt/cloudera/director
cat << 'EOF' >> /opt/cloudera/director/rhel-key
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.5 (GNU/Linux)

mQGiBEpBgEURBAC+CL1a6BfVEoKAX1KcOHqq9Z10WdPGOgTM+AtnOVPJdJvIZcDk
YGUmycpaGxY3+xX1x8ZvxNb7WXiei8FMPm4sR/xQC/CF2iS5399tjLJqcDEjdqTV
/whQ4Rrg1JLGaHUjR0YmrOteT71xikEwlCalToxQuhBz7Nz4aBeDDPf9lwCgvG+x
CaOxict+He03g4HNSTZ0T0UEAIxKITpCA6ZvUPoEGhpn+Gt+wJK/ScB0FKCfW8Au
QQZP6tgxDEg0baasT8MxuXXE2+opaaWPTVa64ws7OvbyH5z1xhBOx4qRVBx8bZsF
YQUk/1PBvg6yA4Rmaqi7nTToHatP69/JMLfTyH8sXETMQ8z5T0LAD6a5ELAYBqql
bJWRA/4lkbaGIwkyLcOAop/g0SCERHt66ML1pwdjxvzE2rRKFUbjUbRZsHTqVq5E
BgpcTIeTuRy02yQ+Bh+JaBtYhn0AY5+t7jcCdJeTahS/7RKJPYPiSfbgI6zwpHM9
kX4FT+0yDgnVF1H/h9p19Uv/3ahIgt7op/M1eAdH0/eP6Dv04rQnWXVtIE1haW50
YWluZXIgPHdlYm1hc3RlckBjbG91ZGVyYS5jb20+iGAEExECACAFAkpBgEUCGwMG
CwkIBwMCBBUCCAMEFgIDAQIeAQIXgAAKCRD5DA2P6PhqzRo1AKCIHNWJSd7OipbZ
qp58f/BWaIBlDACggNRH4Hvg92t3xtwYFdohRWF2Xbi5Ag0ESkGARxAIAMaPPGfQ
vsLkyLyM3ePtkkHi0bew0XGW1CYxWOZLMu8wnJgMHpfPD2dLgp6PEh+zpi2SM1ie
QGAW6K040TSuC9P+LcZB7SxanIE7lONHjz7spGQift30WFZcaIgF+MuyZIihNh7v
tZ9ip8JZYPA88XRNU1CKuXx4r8iCDJ4ICksFKeOwQUuzf/IRJapzEZ0ixfVTwx91
yG10TvHK63BRLXYHBML4Og9FaPZgFq2N9Yz4Wpu/Pn6tjZAMeSJXm2qNO2PSoTC/
kapubpMwSmOBlZqrHi9lcIWricXE9dcyaGVRAf3CJRlX4ZNuwcQjyks5BFibU3/z
qlzP6KgwTgDmaaMAAwUH/04KRM3k6Ow2KkDt2BKWveOI24mkIQahUJ7/iZlKsL27
3VcGQZ7jU28GT0FH9iYeAgbpLrrEuDAFZpGm9RoOVJGnxWX3DVL1+qkiS56pXfU+
8atZlkCGx09IilJgf0ATlmYxbTtYliTRPK4lQYOfNB1v23bdlBwISjcDRkWu22ao
atSBzr/FARL6fdZZqp2qfWOmcteiLagioo6s0ogxKNQH5PldUQy9n2W/oOXss5sC
lnUNvzKlzzx/pFkT8ZUAvuLY0v8gykk586vbjiuPkg8uAOBhtnsSWwJ6nEPaRCnu
iwlqGxgXmnJ7UMzOimkuf0XvqavhkMEEAqRJkNLyWVuISQQYEQIACQUCSkGARwIb
DAAKCRD5DA2P6PhqzUV2AJ0eV3C407Y3Xi4d27clLsz/wW0HMgCghcxCmiOT2kWH
6Ya7d9nkKz2UM+Y=
=+VR8
-----END PGP PUBLIC KEY BLOCK-----
EOF

cat << 'EOF' >> /root/.curlrc
proxy=10.7.0.5:3128
noproxy=localhost,127.0.0.1,169.254.169.254,.trng201809.lab
EOF

cat << 'EOF' >> /root/.wgetrc
use_proxy=on
http_proxy=http://10.7.0.5:3128
https_proxy=http://10.7.0.5:3128
ftp_proxy=http://10.7.0.5:3128
no_proxy=localhost,127.0.0.1,169.254.169.254,.trng201809.lab
EOF

# workaround to prevent director from installing mysql-connector-java
cat <<-\EOF > /sbin/yum
#!/bin/bash

#prevent director from installing mysql-connector-java

YUM_PARAMS=$@

if ([[ $YUM_PARAMS == *"install"* ]] && [[ $YUM_PARAMS == *"mysql-connector-java"* ]]) \
    || ([[ $YUM_PARAMS == *"install"* ]] && [[ $YUM_PARAMS == *"mysql-devel"* ]]); then
  echo "Cowardly refusing to install mysql packaged! Moving on."
  exit 0
fi

/usr/bin/yum $@

EOF

chmod +x /sbin/yum

rm -f /etc/yum.repos.d/cloudera-*.repo

echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo never > /sys/kernel/mm/transparent_hugepage/enabled

echo "echo never > /sys/kernel/mm/transparent_hugepage/defrag" >> /etc/rc.local
echo "echo never > /sys/kernel/mm/transparent_hugepage/enabled" >> /etc/rc.local

yum install -y nscd

sed -i.$(date +%Y%m%d%H%M%S).bak "s,[ \t]*enable-cache[ \t]*passwd[ \t]*.*,        enable-cache            passwd          no,;s,[ \t]*enable-cache[ \t]*group[ \t]*.*,        enable-cache            group           no," /etc/nscd.conf

systemctl enable nscd.service
systemctl restart nscd

# rewrite SELINUX config to disable and turn off enforcement
sed -i.bak "s/^SELINUX=.*$/SELINUX=disabled/" /etc/selinux/config
setenforce 0
# stop firewall and disable
systemctl stop iptables
systemctl iptables off
# RHEL 7.x uses firewalld
systemctl stop firewalld
systemctl disable firewalld
# Disable tuned so it does not overwrite sysctl.conf
service tuned stop
systemctl disable tuned
# update config to disable IPv6 and disable
echo "# Disable IPv6" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
# swappniess is set by Director in /etc/sysctl.conf
# Poke sysctl to have it pickup the config change.
sysctl -p

