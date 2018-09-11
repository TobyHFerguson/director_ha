# Director HA

A conf system to build an HA Cloudera cluster using Director in AWS.

Tested on Director 2.8

## Resulting Architecture
The `aws.conf` file is the tip of several files which together can be used to build an HA cluster with `HDFS` and `HIVE` services, assuming up to three Availability Zones and three subnets. It is expected that a load balancer and an external MySQL compatible database server will be available (along with security groups, routing tables etc.). As currently configured Director and the instances it spawns must have outbound access to the internet (for access to AWS services and/or external repositories). 

## director
This is used to build the AWS based HA architecture. The various configuration data are in `site.xml` - you'll need to edit that file to adjust to your infrastructure etc.

It is expected that director is on an instance (something like a `c4.2xlarge`) with access to the VPC and subnets into which the clusters will be deployed. (Easiest is to just have director in the exact same VPC!). The `site.conf` file contains most of the parameters required to be changed. 

## Overall Workflow
### Build out your AWS Infrastructure
At a minimum you need:
* VPC
* Subnet with internet access outbound
* Security Group with ssh access inbound
* MySQL database
* Load balancer
* Custom AMI built using the information in the `faster-bootstrap` directory located in the [Cloudera director-scripts github repo](https://github.com/cloudera/director-scripts)
* Instance (`c4.large`) on which to install Director

### Director
1. Install director as per the [Cloudera docs](https://www.cloudera.com/documentation/director/latest/topics/director_get_started_aws_install_dir_server.html) (I'll assume you setup the username/password as `admin/admin`
1. On the director instance clone this repo
1. In the `director` subdirectory
    1. Edit `site.xml` to reflect your AWS infrastructure
    1. Execute `cloudera-director bootstrap-remote aws.conf --lp.remote.username=admin --lp.remote.password=admin`

This should build out a 13 node HA cluster. 
