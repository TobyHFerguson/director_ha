#!/usr/bin/env bash

set -x
exec > ~/cleanup-cluster.$(date +%Y%m%d%H%M%S).log 2>&1

PATH=$PATH:/sbin:/usr/sbin; export $PATH

ad_dc="trng2018-ad.trng201809.lab"
ad_service_ou="OU=services,OU=trng,OU=cloudera,DC=trng201809,DC=lab"
ad_server_ou="OU=hosts,OU=trng,OU=cloudera,DC=trng201809,DC=lab"
join_user=joiner
ad_realm="TRNG201809.LAB"
join_pwd="aaaaaaaaaaaa"

protocol="http"
cm_port=$(echo ${DEPLOYMENT_HOST_PORT} | cut -d ':' -f 2)
if [ ${cm_port} -eq "7183" ]; then 
  protocol="https"
else
  protocol="http"
fi

IFS=$'\r\n'; GLOBIGNORE='*';
set +o history
echo ${join_pwd} | kinit ${join_user}@${ad_realm}
set -o history

# Get all cluster hosts from CM, this list does not include CM host
hosts=$(/usr/bin/curl --noproxy "*" --insecure -su ${CM_USERNAME}:${CM_PASSWORD} -X GET "${protocol}://${DEPLOYMENT_HOST_PORT}/api/v19/hosts" | python -c 'import json, sys; j=json.load(sys.stdin);print " ".join(i["hostname"] for i in j["items"])')

IFS=' ' read -a hosts_arr <<< "${hosts}"
for host in  "${hosts_arr[@]}"; do

  # Delete the Computer object created with join realm
  dn=$(/usr/bin/ldapsearch -LLL -o ldif-wrap=no -H ldap://${ad_dc} -b "${ad_server_ou}" "(&(objectClass=computer)(serviceprincipalname=host/${host}))" dn | sed 's/^dn:\ //;s/#.*$//')
  if [ -n "${dn}" ]; then
    /usr/bin/ldapdelete -H ldap://${ad_dc} "$dn"
  fi

  # Delete all reverse-ips
  for ip in $(dig +noall +answer +nocomments +short ${host}); do
    reverse_ip=$(echo $ip | awk -F. -vOFS=. '{print $4,$3,$2,$1,"in-addr.arpa"}')
    nsupdate -g <<-EOF
update delete $reverse_ip PTR
send
EOF
    # Now lookup each ip and delete all hostnames mapped to ip
    for resolved_host in $(dig +noall +answer +nocomments +short -x ${ip}); do
      nsupdate -g <<-EOF
update delete $resolved_host A
send
EOF
    done
  done
  #Delete the original hostname
  nsupdate -g <<-EOF
update delete $host A
send
EOF
done

# Now cleanup CM itself
cm_ip=$(echo ${DEPLOYMENT_HOST_PORT} | cut -d ':' -f 1)
reverse_ip=$(echo $cm_ip | awk -F. -vOFS=. '{print $4,$3,$2,$1,"in-addr.arpa"}')
nsupdate -g <<-EOF
update delete $reverse_ip PTR
send
EOF
for resolved_host in $(dig +noall +answer +nocomments +short -x ${cm_ip}); do
  dn=$(/usr/bin/ldapsearch -LLL -o ldif-wrap=no -H ldap://${ad_dc} -b "${ad_server_ou}" "(&(objectClass=computer)(serviceprincipalname=host/${resolved_host}))" dn | sed 's/^dn:\ //;s/#.*$//')
  if [ -n "${dn}" ]; then
    /usr/bin/ldapdelete -H ldap://${ad_dc} "$dn"
  fi

  nsupdate -g <<-EOF
update delete $resolved_host A
send
EOF
done


#not required anymore as Director cleans this up
## Delete all the principals created by CM
#principals=$(/usr/bin/curl --noproxy "*" --insecure -su ${CM_USERNAME}:${CM_PASSWORD} -X GET "${protocol}://${DEPLOYMENT_HOST_PORT}/api/v19/cm/kerberosPrincipals" | python -c 'import json, sys; j=json.load(sys.stdin);print " ".join (i for i in j["items"])')
#
#IFS=' ' read -a principals_arr <<< "${principals}"
#
#for principal in ${principals_arr[@]}; do
#
#  echo $principal
#
#  dn=$(/usr/bin/ldapsearch -LLL -o ldif-wrap=no -H ldap://${ad_dc} -b "${ad_service_ou}" "(&(objectClass=user)(userprincipalname=${principal}))" dn | sed 's/^dn:\ //;s/#.*$//')
#  /usr/bin/ldapdelete -H ldap://${ad_dc} "$dn"
#
#done

kdestroy

exit 0
