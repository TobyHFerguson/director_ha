# Solutions for Director training exercise for MACkathon Sept 2018

There are two high level directories - director and faster-bootstrap  
**director** - Config files and scripts to build a cluster  
**faster-bootstrap** - packer config files and scripts to build a self contained custom image for AWS, Azure and GCP

## director
To use director first setup all the environment configurations in site.conf. There are some additional configurations in scripts and config files that needs to be updated. To launch a cluster build in an evironment where proxy is needed for outside access run 

```
DIRECTOR_CLIENT_JAVA_OPTS="-Dhttp.proxyHost=10.7.0.5 -Dhttp.proxyPort=3128 \
 -Dhttp.nonProxyHosts=localhost|127.*|[::1]|169.254.169.254|.trng201809.lab|10.* \
 -Dhttps.proxyHost=10.7.0.5 -Dhttps.proxyPort=3128" cloudera-director \
 bootstrap-remote azure.conf --lp.remote.username=<user> \
 --lp.remote.password=<password> --lp.remote.tlsEnabled=true
```

Please note that in some of the config files passwords are embedded in plain text. These can be handled in few ways. The passwords can be passed as custom data and referred in the scripts. For commands such as joining the VM instance to the AD domain, A kerberos ticket cache can be used instead of password. For this case a keytab can be either be downloaded from a safe location at the time of bootstrap or the keytab be embedded as part of the image.

## faster-bootstrap
To use faster bootstrap first download the packer utility from packer.io. Next customize the appropriate config file named packer-var-aws.json, packer-var-azure.json or packer-var-gcp.json. You can then launch the image build by using the command

```
./packer build -on-error=ask -var-file=packer-var-azure.json packer-json/azure-rhel.json
```
