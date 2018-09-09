#!/usr/bin/env bash
# Use the AWS time service
# As per https://aws.amazon.com/blogs/aws/keeping-time-with-amazon-time-sync-service/

set -x
exec > ~/bootstrap-chronyd.$(date +%Y%m%d%H%M%S).log 2>&1

systemctl stop chronyd
systemctl stop ntpd
systemctl disable ntpd.service
sed -i.$(date +%Y%m%d%H%M%S).bak -e "s/server 0.centos.pool.ntp.org iburst/server 169.254.169.123 prefer iburst/"
systemctl start chronyd

