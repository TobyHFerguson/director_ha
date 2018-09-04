#!/usr/bin/env bash

set -x
exec > ~/bootstrap-sssd.$(date +%Y%m%d%H%M%S).log 2>&1

PATH=$PATH:/sbin:/usr/sbin; export $PATH


host=$(hostname -f)
ad_domain=trng201809.lab
ad_realm=TRNG201809.LAB
join_user=joiner
join_pwd="aaaaaaaaaaaa"
ad_site="Default-First-Site-Name"
primary_gid=568201110
ad_server=trng2018-ad.trng201809.lab

yum install -y realmd sssd oddjob oddjob-mkhomedir adcli samba-common samba-common-tools krb5-workstation openldap-clients

cat << EOF > /etc/krb5.conf
[libdefaults]
 dns_lookup_realm = false
 dns_lookup_kdc = false
 ticket_lifetime = 10h
 renew_lifetime = 7d
 forwardable = true
 rdns = false
 default_realm = ${ad_realm}
 udp_preference_limit = 1
 kdc_timeout = 3000

[realms]
 ${ad_realm} = {
  kdc = ${ad_server}
 }

[domain_realm]
 .${ad_domain} = ${ad_realm}
EOF

chmod 644 /etc/krb5.conf

systemctl enable realmd
systemctl restart dbus
systemctl restart realmd
systemctl restart NetworkManager && systemctl restart systemd-logind

set +o history
echo ${join_pwd} | kinit ${join_user}@${ad_realm}
set -o history

#Cleanup any DNS entries from previous unsuccessful runs
host_ip=$(hostname -I)

#Delete all A records related to this hosts IP
for resolved_host in $(dig +noall +answer +nocomments +short -x ${host_ip}); do
  nsupdate -g <<-EOF
update delete $resolved_host A
send
EOF
done

#Delete the PTR record for this IP
reverse_ip=$(echo $host_ip | awk -F. -vOFS=. '{print $4,$3,$2,$1,"in-addr.arpa"}')
nsupdate -g <<-EOF
update delete $reverse_ip PTR
send
EOF

## Delete all PTR records related to hostname 
#for ip in $(dig +noall +answer +nocomments +short ${host}); do
#  # Now lookup each ip and delete all hostnames mapped to ip
#  for resolved_host in $(dig +noall +answer +nocomments +short -x ${ip}); do
#    nsupdate -g <<-EOF
#update delete $resolved_host A
#send
#EOF
#  done
#  reverse_ip=$(echo $ip | awk -F. -vOFS=. '{print $4,$3,$2,$1,"in-addr.arpa"}')
#  nsupdate -g <<-EOF
#update delete $reverse_ip PTR
#send
#EOF
#done

# Delete the A record for this hostname
nsupdate -g <<-EOF
update delete $host A
send
EOF

realm join ${ad_domain} -v --membership-software=samba --computer-ou="OU=hosts,OU=trng,OU=cloudera,DC=trng201809,DC=lab" --automatic-id-mapping=yes --user-principal=host/${host}@${ad_realm}

kdestroy

systemctl stop sssd

cat <<EOF > /etc/sssd/sssd.conf
[sssd]
config_file_version = 2
reconnection_retries = 3
sbus_timeout = 30
services = nss, pam
domains = ${ad_realm}
 
[nss]
filter_groups = root,mysql,hadoop,yarn,hdfs,mapred,kms,httpfs,hbase,hive,sentry,spark,solr,sqoop,oozie,hue,flume,impala,llama,postgres,sqoop2
filter_users = root,mysql,cloudera-scm,zookeeper,yarn,hdfs,mapred,kms,httpfs,hbase,hive,sentry,spark,solr,sqoop,oozie,hue,flume,impala,llama,sqoop2,postgres,gdm
reconnection_retries = 3
 
[pam]
reconnection_retries = 3
 
[domain/${ad_realm}]
debug_level = 1
subdomains_provider = none
ad_enable_gc = False
cache_credentials = True
ldap_id_mapping = True
full_name_format = %1\$s
fallback_homedir = /home/%u
default_shell = /bin/bash
ignore_group_members = True
override_gid = ${primary_gid}
krb5_realm = ${ad_realm}
ad_domain = ${ad_domain}
id_provider = ad
chpass_provider = ad
auth_provider = ad
access_provider = simple
simple_allow_groups = cloudera_admins,cloudera_users
ad_site = ${ad_site}
case_sensitive = False
enumerate = True
ldap_schema = ad
ldap_user_principal = nosuchattr
ldap_force_upper_case_realm = True
ldap_purge_cache_timeout = 0
ldap_access_order = filter,expire
ldap_account_expire_policy = ad
ldap_referrals = false
use_fully_qualified_names = False
ldap_use_tokengroups = False
krb5_validate = False
ldap_idmap_range_size = 2000000

ldap_group_search_base = OU=groups,OU=trng,OU=cloudera,DC=trng201809,DC=lab?subtree?(&(objectClass=group)(sAMAccountName=cloudera_*))
ldap_user_search_base = DC=trng201809,DC=lab?subtree?(|(memberOf=CN=cloudera_users,OU=groups,OU=trng,OU=cloudera,DC=trng201809,DC=lab)(memberOf=CN=cloudera_admins,OU=groups,OU=trng,OU=cloudera,DC=trng201809,DC=lab))

dyndns_update = true
dyndns_refresh_interval = 3600
dyndns_update_ptr = true
dyndns_ttl = 3600
EOF

chmod 600 /etc/sssd/sssd.conf

rm -f /var/lib/sss/db/* /var/lib/sss/mc/*  /var/log/sssd/*

systemctl start sssd

# Ignore intermittent errors
exit 0
