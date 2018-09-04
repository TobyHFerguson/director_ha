#!/bin/bash

set -x
exec > ~/bootstrap-java.$(date +%Y%m%d%H%M%S).log 2>&1

export JDK_URL=http://download.oracle.com/otn-pub/java/jdk/8u141-b15/336fa29ff2bb4ef291e347e091f7f4a7/jdk-8u141-linux-x64.rpm
yum -y install wget
wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" $JDK_URL -O /tmp/jdk.rpm
yum localinstall -y /tmp/jdk.rpm
rm -f /tmp/jdk.rpm

JAVA_HOME=/usr/java/jdk1.8.0_141

wget -O /tmp/jce_policy-8.zip --no-cookies --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip"
unzip -j -o /tmp/jce_policy-8.zip "UnlimitedJCEPolicyJDK8/*.jar" -d ${JAVA_HOME}/jre/lib/security
rm -f  /tmp/jce_policy-8.zip
chmod a+r ${JAVA_HOME}/jre/lib/security/local_policy.jar ${JAVA_HOME}/jre/lib/security/US_export_policy.jar

mkdir -p /opt/cloudera/security/pki
chmod a+rx /opt/cloudera /opt/cloudera/security /opt/cloudera/security/pki
cat << 'EOF' >> /opt/cloudera/security/pki/ca-certs.pem
-----BEGIN CERTIFICATE-----
MIIDhTCCAm2gAwIBAgIQLACaK4akdpRAW8CowxnBsDANBgkqhkiG9w0BAQsFADBV
MRMwEQYKCZImiZPyLGQBGRYDbGFiMRowGAYKCZImiZPyLGQBGRYKdHJuZzIwMTgw
OTEiMCAGA1UEAxMZdHJuZzIwMTgwOS10cm5nMjAxOC1hZC1DQTAeFw0xODA4Mjgx
ODA4NTFaFw0yMzA4MjgxODE4NTBaMFUxEzARBgoJkiaJk/IsZAEZFgNsYWIxGjAY
BgoJkiaJk/IsZAEZFgp0cm5nMjAxODA5MSIwIAYDVQQDExl0cm5nMjAxODA5LXRy
bmcyMDE4LWFkLUNBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1uG0
IzpbuZWkigqe9K/mmzE+O0xwLiBflwg7Uc1TKhdCAy+NMHPv/ITkDxE3/cpLcxnG
uULtjsAO8DcultxPiaUD825neKfl/rgmKyqYfBi6tYWog1M9TY0ZYtEWM0mx1Ocz
pRpvesOtrWtdEUqUhmeUjHFz6neoXshg3c4eLbWbebHdxzD8Bl4d9XTOu8EmCbbB
ped7DF9fOGpiVrYmjoy80ugwDZzEDap+GpoKlnN7HlOj+Y+NPZ7RZfqP1FwXb75Y
Eo+iqIBRBIaUE+Us1+eD1LtzHjUhuhNO576MSHXgoAvP5LT0h43gQ6jb7fjT8twn
PUWWs3yskFY71+UhGQIDAQABo1EwTzALBgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUw
AwEB/zAdBgNVHQ4EFgQU/flmUPA63O5J2rmrSCDcIruPVBswEAYJKwYBBAGCNxUB
BAMCAQAwDQYJKoZIhvcNAQELBQADggEBAKnaYHWZmmAKqB7up9Ql6RDsyM+KNtXo
dW72ZdDpBS5ZEpwTj6XoCnQzMOx/x+0u9i18cH9NZt31MarqEGQ+IbG3N3NtXPxH
NqG7w3SgXBo308sOiurDCHY0KfL4Gfbh6FUwaN8sz8R8YAH/g49/WBA82VkNTBNT
/0VWH8U0DqrfhddMDV7nW+7Mmt+BuNns3iEj+6FZt28pYrmgQfo0j81AbVRNuOK3
pQ7ALyxvqKE/eVHXnH0lHEbUi5vx2Bky27bD4c2/38UbAOA6YAANIHnRw/gYyTwF
yWh5awQK0pBYGG/A/wDkubnvQvssw3U5/aSLMb3YExjUef9ReSxrySk=
-----END CERTIFICATE-----
EOF
chmod a+r /opt/cloudera/security/pki/ca-certs.pem
cp ${JAVA_HOME}/jre/lib/security/cacerts ${JAVA_HOME}/jre/lib/security/jssecacerts
${JAVA_HOME}/bin/keytool -importcert -noprompt -keystore ${JAVA_HOME}/jre/lib/security/jssecacerts -alias ADCA -storepass changeit -file /opt/cloudera/security/pki/ca-certs.pem
chmod a+r ${JAVA_HOME}/jre/lib/security/jssecacerts
