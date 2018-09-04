#!/usr/bin/env bash

set -x
exec > ~/bootstrap-jdbc.$(date +%Y%m%d%H%M%S).log 2>&1

yum install -y wget
useradd -r sqoop
mkdir -p /var/lib/sqoop
chown sqoop:sqoop /var/lib/sqoop 
chmod 755 /var/lib/sqoop

mkdir -p /usr/share/java
chmod a+rx /usr/share/java
wget -O /tmp/mysql-connector-java-5.1.46.zip http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.zip
unzip -j -o /tmp/mysql-connector-java-5.1.46.zip mysql-connector-java-5.1.46/mysql-connector-java-5.1.46-bin.jar -d  /usr/share/java/
cp /opt/java/lib/misc/mysql-connector-java-5.1.46-bin.jar /usr/share/java

chmod a+r /usr/share/java/mysql-connector-java-5.1.46-bin.jar
cd /usr/share/java
ln -sf mysql-connector-java-5.1.46-bin.jar mysql-connector-java.jar

cp /usr/share/java/mysql-connector-java-5.1.46-bin.jar /var/lib/sqoop
chown sqoop:sqoop /var/lib/sqoop/*
chmod a+r /var/lib/sqoop/*
