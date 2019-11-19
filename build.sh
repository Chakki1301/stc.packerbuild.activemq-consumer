#!/bin/bash
# build.sh <customer> <class>  --> codes: (ab cp1|ak ct1|az cp2|la cp2|ms |nh |oh |tn |wv |wy ) .. wa, mt...
# . . . not all environments are supported YET.
# as of 5/7 we will use Jenkins secrets for nexus creds; but should detect and pivot to .netrc for desktop builds...
set -e 
export version="v1.1.0"
version="$(git tag)"
usage="USAGE: ./build.sh <customer> <class>"

### start homepage package env
nexus_source="nexus.stchealthops.com"

# start oldschool packerbuild build script:
[ -z "$1" ] && echo "customer. ${usage}" && exit 1
[ -z "$2" ] && echo "class . ${usage}" && exit 1
customer_name=$1
export customer_name
customer_class=$2
export customer_class
customer_configfile="customer.conf"
region_configfile="region.conf"
[[ ! -f ${customer_configfile} ]] && echo "customer config file ${customer_configfile} missing." && exit 1
[[ ! -f ${region_configfile} ]] && echo "region config file ${region_configfile} missing." && exit 1

this_customer="$(cat ${customer_configfile} | grep -v "^#.*" | grep "^customer_${customer_name}.${customer_class}" )"
export this_customer
[[ ! ${this_customer} ]] && echo "specified customer not found in ${customer_configfile}" && exit 1
this_region="$(echo ${this_customer} | cut -d',' -f2)"
export this_region
this_region_vals="$(cat ${region_configfile} | grep -v "^#" | grep "${this_region}")"
export this_region_vals

#build region
b_rgn="$(echo ${this_customer} | cut -d',' -f2)"
export b_rgn
b_vpc="$(echo ${this_region_vals} | cut -d',' -f2)"
export b_vpc
b_sn="$(echo ${this_region_vals} | cut -d',' -f3)" 
export b_sn
b_sg="$(echo ${this_region_vals} | cut -d',' -f4)" 
export b_sg 
b_ami="$(echo ${this_region_vals} | cut -d',' -f5)"
export b_ami 
b_wf="$(echo ${this_customer} | cut -d',' -f3)"
export b_wf
b_db="$(echo ${this_customer} | cut -d',' -f4 | cut -d"=" -f2)"
export b_db
b_afx="$(echo ${this_customer} | cut -d',' -f5 | cut -d"=" -f2)"
export b_afx
b_voms="$(echo ${this_customer} | cut -d',' -f6 | cut -d"=" -f2)"
export b_voms
b_redis="$(echo ${this_customer} | cut -d',' -f7 | cut -d"=" -f2)"
export b_redis
b_nvm="$(echo ${this_customer} | cut -d',' -f8 | cut -d"=" -f2)"
export b_nvm
b_pm2="$(echo ${this_customer} | cut -d',' -f9 | cut -d"=" -f2)"
export b_pm2
version="$(git tag)"
export version

echo "this_region: ${this_region}"
echo "this_region_vals: ${this_region_vals}"
echo "this_customer: ${this_customer}"
echo "b_rgn: ${b_rgn}"
echo "b_vpc: ${b_vpc}"
echo "b_sn: ${b_sn}"
echo "b_sg: ${b_sg}"
echo "b_ami: ${b_ami}"
echo "b_wf: ${b_wf}"
echo "b_db: ${b_db}"
echo "b_afx: ${b_afx}"
echo "b_voms: ${b_voms}"
echo "b_redis: ${b_redis}"
echo "b_nvm: ${b_nvm}"
echo "b_pm2: ${b_pm2}"

# need to grab packer and install it:
if [[ "$(whoami)" == "jenkins" ]] ; then
    # we're on the build server
    PATH="$PATH:/var/lib/jenkins/tools/" 
    if [[ ! -f "/var/lib/jenkins/tools/packer" ]] ; then 
        echo "retrieving packer binary from nexus:"
        # on jenkins; rely on $nxrmu and $nxrmp for nexus basic auth credentials
        curl -v --user ${nxrmu}:${nxrmp} --url https://${nexus_source}/repository/raw-hosted/hashicorp/packer/1.4.0/linux_amd64/packer_1.4.0_linux_amd64.zip -o /var/lib/jenkins/tools/packer_1.4.0_linux_amd64.zip
        curl -v --user ${nxrmu}:${nxrmp} --url https://${nexus_source}/repository/raw-hosted/stedolan/jq/1.5/linux64/jq-linux64 -o /var/lib/jenkins/tools/jq
        chmod +x /var/lib/jenkins/tools/jq
        unzip /var/lib/jenkins/tools/packer_1.4.0_linux_amd64.zip -d/var/lib/jenkins/tools/
        rm /var/lib/jenkins/tools/packer_1.4.0_linux_amd64.zip
        PATH="$PATH:/var/lib/jenkins/tools/" 
    fi
    packer build -var "b_ami=${b_ami}" -var "customer_name=${customer_name}" -var "b_rgn=${b_rgn}" -var "b_vpc=${b_vpc}" -var "b_sn=${b_sn}" -var "b_sg=${b_sg}" -var "b_wf=${b_wf}" -var "version=${version}" -var "b_db=${b_db}" -var "b_afx=${b_afx}" -var "b_voms=${b_voms}" -var "b_redis=${b_redis}" -var "b_nvm=${b_nvm}" -var "b_pm2=${b_pm2}" -color=false ./packer.json
    rm -rf ./-*
    rm -rf .git*
    rm -rf *
fi 
packer build -var "b_ami=${b_ami}" -var "customer_name=${customer_name}" -var "b_rgn=${b_rgn}" -var "b_vpc=${b_vpc}" -var "b_sn=${b_sn}" -var "b_sg=${b_sg}" -var "b_wf=${b_wf}" -var "version=${version}" -var "b_db=${b_db}" -var "b_afx=${b_afx}" -var "b_voms=${b_voms}" -var "b_redis=${b_redis}" -var "b_nvm=${b_nvm}" -var "b_pm2=${b_pm2}" -color=false ./packer.json

exit 0
