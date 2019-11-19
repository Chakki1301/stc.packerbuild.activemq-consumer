# stc.packerbuild.voms

## BUILD INSTRUCTIONS:

- to build:
- in bash, you should have AWS credentials set up, python, pip, aws command line tools, and packer 1.4.0 installed.

run:
`./build.sh <customer> <class>`

##Variables
Customer.conf file has VOMS TAR file version, If dashboard/IQ/AFIX URL needed or not, and NVM, REDIS, PM2 versions.

##Source of files. New version should be updloaded in the similar format. 
https://nexus.stchealthops.com/#browse/browse:raw-hosted - stc/VOMS/2.23.0/noarch/VOMS-2.23.0-rc2.tar.gz
https://nexus.stchealthops.com/#browse/browse:yum-ora-hosted - 	oracle/sqlplus/12.2.0.1.0-1/x86_64/
https://nexus.stchealthops.com/#browse/browse:raw-hosted - redislabs/redis/3.2.10/noarch/redis-3.2.10.tar.gz

#Deployment
https://opsso2web.stchealthops.com/jenkins/view/Packerbuild/ - Triggered via Jenkins job. 

## UPDATE:
Every 6 months or so, Centos releases a new "community ami" release for Centos 7, which is our current upstream source for all of our AMI's.  As of now (5/1/2019), we're running the 1901_1 version.  They provide 4 different ami-id's for the 4 different regions we run in: us-east-1, us-east-2, us-west-1, us-west-2.  

When RedHat releases a new update, we grab the ami id's off their web site.  We update the stc.packerbuild.base.centos7 build sources, and rebuild those.  This is important, because this build changes the repositories from the community repositories to the custom repositories on our nexus server (then it disables them, which LOCKS all the software to a certain version - no software can be updated on a deployed ami!). When we build stc.packerbuild.base.centos7, it outputs 4 new ami-id's.  THOSE are the source id's we use for stc.packerbuild.bastion_centos, stc.packerbuild.logserver, stc.packerbuild.iwebapp, and stc.packerbuild.phcapp, and any other "downstream" centos-based packerbuild ami.  It's all set up with our nexus repositories - but you have to use the same provision.sh script to re-enable, then disable them, so you can get the lates yum updates when you build your downstream ami.

These base_centos7 ami's are specified in the file: *region.conf*, which is used by build.sh.

usage: `packer build -var-file="<customer_code>.json" ./packer.json`

# Terraform code for Packer AMI build environments

## This repo manages our AWS build environment for Packer AMI's

0. Prerequsites
    - Admin console access to AWS
    - aws-cli installed on local
    - LastPass access
    - Git installed on local
    - GitHub access to this repo

1. Setup
    1.1 Create User (AWS Console)
    - IAM->Users->Create User
    Name: Terraform-Apply-User
    - programmatic access checked
    - aws management console access unchecked
    - attach "Administrator Access" policy directly

    1.2 Save keys (LastPass)

    1.3 Config local profile (local)
    - PS> aws configure --profile terraform
    - (enter key)
    - (enter secret key)
    - default region: us-east-2
    - default output: json



