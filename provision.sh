#!/bin/bash
echo "##### BEGIN Provisioning script - timestamp=$(date "+%Y-%m-%d %H:%M:%S,%3N") #####"

echo "##### Configure repositories - timestamp=$(date "+%Y-%m-%d %H:%M:%S,%3N") #####"
########################################
# Retrieve secrets and configure repositories
########################################
nxrmurl="nexus.stchealthops.com"
sudo tar -xvf /tmp/awscli-bundle.tar 
sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
aws --version
sudo rm /tmp/awscli-bundle.tar
echo "retrieve secrets from jenkins_build"
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): locate secrets with db creds using secret jenkins_build"
export NEXSEC=$(aws secretsmanager get-secret-value --secret-id jenkins_build --region us-east-2 --output=text | grep "username" | sed 's/^.*{//g' | sed 's/}.*$//g' )
echo "uninstalling awscli bundle"
sudo rm -rf /usr/local/aws
sudo rm /usr/local/bin/aws
if [[ $NEXSEC ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): Retrieved secret jenkins_build" ; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve secret jenkins_build" ; exit 1; fi
export NEXSECVEC=(${NEXSEC//,/ })
if [[ $NEXSECVEC ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): NEXSECVEC: ****" ; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve NEXSECVEC" ; exit 1; fi
for i in "${NEXSECVEC[@]}"
do
    [[ ${i} =~ "username" ]] && export UN=(${i//?username?:/}) && UN=(${UN//\"/})
    [[ ${i} =~ "password" ]] && export PW=(${i//?password?:/}) && PW=(${PW//\"/})
done
if [[ $UN ]]; then echo "$(date +%M%s): UN: ****" ; else echo "$(date +%M%s): ERROR: Failed to retrieve UN" ; exit 1; fi
if [[ $PW ]]; then echo "$(date +%M%s): PW: ****" ; else echo "$(date +%M%s): ERROR: Failed to retrieve PW" ; exit 1; fi
echo "$(date +%M%s): clear creds from env vars."
NEXSEC=""
NEXSECVEC=""

declare -a configfiles=(/etc/yum.repos.d/adiscon-nexus.repo /etc/yum.repos.d/epel-nexus.repo /etc/yum.repos.d/nexus.repo /etc/pip.conf)
for f in "${configfiles[@]}"
do 
    sudo sed -i -e "s/unplaceholder/${UN}/g" $f
    sudo sed -i -e "s/pwplaceholder/${PW}/g" $f
done

echo "Update about dashboard, IQ and AFIX"
touch /tmp/db_afx_iq
sudo echo ${db_in} > /tmp/db_afx_voms
sudo echo ${afx_in} >> /tmp/db_afx_voms
sudo echo ${voms_in} >> /tmp/db_afx_voms
echo "cat /tmp/db_afx_iq"
cat /tmp/db_afx_voms

echo "##### update and install packages - timestamp=$(date "+%Y-%m-%d %H:%M:%S,%3N") #####"

########################################
# Update Server
########################################
# echo "update and install deps"
sudo yum update -y -q
# maybe fix boot-slowness?
sudo yum install -y -q haveged
sudo yum install -y -q rng-tools
sudo systemctl enable haveged.service
sudo systemctl start haveged.service
sudo systemctl start rngd
cat /proc/sys/kernel/random/entropy_avail
sudo systemctl start systemd-random-seed.service
sudo systemctl enable systemd-random-seed.service
sudo yum install -y -q vim 
sudo yum install -y -q bc
sudo yum install -y -q unzip 
sudo yum install -y -q librelp
sudo yum install -y -q  net-tools openssl-devel git bzip2 vim-enhanced ntp tmux dos2unix patch 
# install additional tools and utilities
sudo yum install -y -q sysstat
sudo systemctl start sysstat.service
sudo systemctl enable sysstat.service
sudo yum install -y -q htop
sudo yum list rsyslog
# OPS-2810 NDP
sudo yum install -y -q moreutils
sudo yum install -y -q jq
# enabled for troubleshooting 502 errors: OPS-2161
sudo yum install strace -y -q
sudo yum install lsof -y -q
sudo yum install perf -y -q
sudo yum install tcpdump -y -q
sudo yum install nmap-ncat -y -q

# Chronyd config:
echo "server 169.254.169.123 prefer iburst" | sudo tee -a /etc/chrony.conf

echo "Install pip"
sudo yum install -y -q  python-pip
echo "confirm pip version"
sudo pip -V
echo "install awscli"
sudo pip install --quiet awscli

echo "confirm aws version"
sudo aws --version

echo "install bind-utils for dig"
sudo yum install -y bind-utils

echo "##### setup Oracle support tools - timestamp=$(date "+%Y-%m-%d %H:%M:%S,%3N") #####"
echo "install Oracle support tools"
sudo yum install -y -q https://${UN}:${PW}@nexus.stchealthops.com/repository/yum-ora-hosted/oracle/sqlplus/12.2.0.1.0-1/x86_64/oracle-instantclient12.2-basic-12.2.0.1.0-1.x86_64.rpm
sudo yum install -y -q https://${UN}:${PW}@nexus.stchealthops.com/repository/yum-ora-hosted/oracle/sqlplus/12.2.0.1.0-1/x86_64/oracle-instantclient12.2-sqlplus-12.2.0.1.0-1.x86_64.rpm
echo "sudo rpm -qa | grep -i oracle"
sudo rpm -qa | grep -i oracle
sudo sh -c "echo /usr/lib/oracle/12.2/client64/lib > /etc/ld.so.conf.d/oracle-instantclient.conf"
echo "cat /etc/ld.so.conf.d/oracle-instantclient.conf"
sudo cat /etc/ld.so.conf.d/oracle-instantclient.conf
sudo ldconfig
echo "PATH=$PATH:/usr/lib/oracle/12.2/client64/bin" | sudo tee -a /etc/environment

# Update oracle.sh file. 
sudo touch /etc/profile.d/oracle.sh
sudo sh -c "echo \"export OCI_LIB_DIR=/usr/lib/oracle/12.1/client64/lib\" >> /etc/profile.d/oracle.sh"
sudo sh -c "echo \"export OCI_INC_DIR=/usr/include/oracle/12.1/client64\" >> /etc/profile.d/oracle.sh"
echo " source oracle.sh and sudo cat /etc/profile.d/oracle.sh"
source /etc/profile.d/oracle.sh
ls -l /etc/profile.d/oracle.sh
sudo cat /etc/profile.d/oracle.sh

#Update versions.sh
sudo touch /etc/profile.d/versions.sh
sudo sh -c "echo \"export REDIS_VERSION=${redis_vers}\" >> /etc/profile.d/versions.sh"
sudo sh -c "echo \"export NVM_VERSION=${nvm_vers}\" >> /etc/profile.d/versions.sh"
sudo sh -c "echo \"export PM2_VERSION=${pm2_vers}\" >> /etc/profile.d/versions.sh"
echo " source versions.sh and sudo cat /etc/profile.d/versions.sh"
source /etc/profile.d/versions.sh
ls -l /etc/profile.d/versions.sh
sudo cat /etc/profile.d/versions.sh

echo "Configuring the Server"
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
sudo setenforce 0
sudo sed -i 's/SELINUXTYPE=targeted/SELINUX=permissive/g' /etc/selinux/config

###
echo "Create Node User"
sudo adduser node

#Install Node NVM NPM 
echo "Install Node"
sudo su - node << EOF
if [ ! -d ~/.nvm ]; then
  curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.32.1/install.sh | bash
  source ~/.bashrc
  echo "This is nvm vers - ${NVM_VERSION}"
  echo "Installing required version of Nodejs"
  nvm install ${NVM_VERSION}
  nvm use ${NVM_VERSION}
  nvm alias default ${NVM_VERSION}
  echo "Installing PM2"
  npm install pm2@${PM2_VERSION} -g
fi

EOF

#####
echo "Install Redis"
echo "*****************************************"
echo " 1. Prerequisites: Install updates, install GCC and make"
echo "*****************************************"
sudo yum install -y wget gcc gcc-c++ make moreutils
echo "*****************************************"
echo " 2. Download, Untar and Make Redis 2.6"
echo "*****************************************"
cd /usr/local/src
sudo yum install -y tcl
redis_port="6379"
sudo curl --user ${UN}:${PW} -o redis-${redis_vers}.tar.gz --url https://nexus.stchealthops.com/repository/raw-hosted/redislabs/redis/${redis_vers}/noarch/redis-${redis_vers}.tar.gz
sudo tar -xvzf redis-${redis_vers}.tar.gz
sudo rm -f redis-${redis_vers}.tar.gz
cd redis-${redis_vers}
sudo make
sudo make test
sudo make install
sudo sed -i -e 's/^notify-keyspace-events.*/notify-keyspace-events EKx/' /etc/redis/6379.conf
echo "*****************************************"
echo " 3. Auto-Enable Redis-Server"
echo "*****************************************"
echo -e "6379\n/etc/redis/6379.conf\n/var/log/redis_6379.log\n/var/lib/redis/6379\n/usr/local/bin/redis-server\n" | sudo utils/install_server.sh
#sudo chkconfig --add redis_${redis_port}
#sudo chkconfig --level 345 redis_${redis_port}
#echo "Added chkconfig and starting redis"
#sudo /etc/init.d/redis_${redis_port} start || die "Failed starting redis service..."
echo "*****************************************"
echo " 4. Check Status of Redis Server"
echo "*****************************************"
sudo systemctl status redis_6379
echo "*****************************************"
echo " Complete installing dependencies!"
echo "Install Redis complete"
####


#setup voms app
iq_app_vers=$(echo ${warfile} | cut -d'-' -f1)
export iq_app_vers
echo "iq app vers - ${iq_app_vers}"

echo "Write iq app vers to a file"
echo "${iq_app_vers}" > /tmp/iq_version
sudo cp /tmp/iq_version /home/node/
echo "cat /home/node/iq_version"
sudo cat /home/node/iq_version

nxrmrepourl="https://nexus.stchealthops.com/repository/raw-hosted/stc"
prodname="IQ"
prodver="${warfile}"
echo "nxrmrepourl: ${nxrmrepourl}"
echo "prodname: ${prodname}"
echo "prodver: ${prodver}"
echo "Retrieve ${prodname}-${prodver}.tar.gz file from Nexus"
echo "from: ${nxrmrepourl}/${prodname}/${iq_app_vers}/noarch/${prodname}-${prodver}.tar.gz"
echo "to: /tmp/${prodname}-${prodver}.tar.gz"

sudo curl --user ${UN}:${PW} -o /tmp/interop-${prodver}.tar.gz --url ${nxrmrepourl}/${prodname}/${iq_app_vers}/noarch/interop-${warfile}.tar.gz 

echo "download file's size is:"
wc -c < /tmp/interop-${prodver}.tar.gz
echo "test file type (if file was not on Nexus; it may download an html file with a 404 message)."
file /tmp/interop-${prodver}.tar.gz
# typical good output looks like this:
# VOMS-core-February_2019.war: Zip archive data, at least v2.0 to extract

filetype=$(file /tmp/interop-${prodver}.tar.gz)
[[ ${filetype} =~ "HTML document" ]] && exit 1 
    # then the file name we asked for, from nexus, was not there, and we got an HTML file saying: 404, probably
    # this commonly happens when the wrong filename was uploaded, OR wrong filename was specified in customer.conf
    # like a typo.

sudo mkdir -p /home/node/json_files

sudo cp /tmp/iq_process.json /home/node/json_files/

echo "Archiving IQ TAR GZ file from /tmp to /home/node"
sudo tar -xvzf /tmp/interop-${prodver}.tar.gz -C /home/node/interop
echo "ls -latrh /home/node and /home/node/interop"
sudo ls -latrh /home/node/
sudo ls -latrh /home/node/interop/

echo "##### Prepare ami for storage - timestamp=$(date "+%Y-%m-%d %H:%M:%S,%3N") #####"

echo "wipe secrets from config files"
for f in "${configfiles[@]}"
do 
    sudo sed -i -e "s/${UN}/unplaceholder/g" $f
    sudo sed -i -e "s/${PW}/pwplaceholder/g" $f
done

#now: set up startup to run on next boot via systemd; NOT effing cloud-init
sudo chmod +x /tmp/startup.sh
sudo chown root:root /tmp/startup.sh
{ echo "[Unit]"; 
    echo "Description=stc voms startup.sh service";
    echo "After=cloud-config.target";
    echo "[Service]";
    echo "Type=simple";
    echo "ExecStart=/tmp/startup.sh";
    echo "TimeoutStartSec=0";
    echo "[Install]";
    echo "WantedBy=default.target";
} | sudo tee /etc/systemd/system/stcstartup.service
sudo systemctl daemon-reload 
sudo systemctl enable stcstartup.service

sleep 5
echo "##### END timestamp=$(date "+%Y%m%d%H%M%s%N") #####"
sleep 10
