#!/bin/bash

export STARTUPLOGFILE="/var/log/startupenv.log"
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): startup.sh script - runs once on instance startup" | sudo tee -a "$STARTUPLOGFILE" 

iq_app_vers=$(cat /home/node/iq_version)
export iq_app_vers
echo "IQ app ver is ${iq_app_vers}"  | sudo tee -a "$STARTUPLOGFILE"

echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): pull values from meta-data endpoint." | sudo tee -a "$STARTUPLOGFILE"
export INSTANCEID=$(curl http://169.254.169.254/latest/meta-data/instance-id); echo "$INSTANCEID"
if [[ $INSTANCEID ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): INSTANCEID: $INSTANCEID" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve INSTANCEID" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi

export AVAILZONE=$(curl http://169.254.169.254/latest/meta-data/placement/availability-zone); echo "$AVAILZONE"
if [[ $AVAILZONE ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): AVAILZONE: $AVAILZONE" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve AVAILZONE" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi

export REGION=$(echo $AVAILZONE | rev | cut -c 2- | rev); echo "$REGION"
if [[ $REGION ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): REGION: $REGION" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve REGION" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi

export AMIID=$(curl http://169.254.169.254/latest/meta-data/ami-id); echo "$AMIID"
if [[ $AMIID ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): AMIID: $AMIID" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve AMIID" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi

export MAC=$(curl http://169.254.169.254/latest/meta-data/mac); echo "$AMIID"
if [[ $MAC ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): MAC: $MAC" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve MAC" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi

export PRIVIP=$(curl http://169.254.169.254/latest/meta-data/network/interfaces/macs/$MAC/local-ipv4s); echo "$AMIID"
if [[ $PRIVIP ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): PRIVIP: $PRIVIP" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve PRIVIP" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi

echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): wait for describe-tags to be available." | sudo tee -a "$STARTUPLOGFILE"
export DTSTATUS=1
while [[ "${DTSTATUS}" -ne 0 ]] ; do
    echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): check describe-tags..." | sudo tee -a "$STARTUPLOGFILE"
    export MYNAME=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=Name" --region $REGION --output=text | cut -f5); echo "$MYNAME"
    echo "MNAME is: $MYNAME"
    echo "DTSTATUS is: $DTSTATUS"
    if [[ $MYNAME ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): describe-tags returned a value" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): describe-tags not yet available" | sudo tee -a "$STARTUPLOGFILE"; fi
    if [[ $MYNAME ]]; then DTSTATUS=0; fi
    sleep 1
    echo "DTSTATUS is: $DTSTATUS"
done
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): confirmed describe-tags to be available." | sudo tee -a "$STARTUPLOGFILE"

echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): pull values from instance tags via describe-tags." | sudo tee -a "$STARTUPLOGFILE"
export MYNAME=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=Name" --region $REGION --output=text | cut -f5); echo "$MYNAME"
if [[ $MYNAME ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): MYNAME: $MYNAME" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve MYNAME" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi

export MYENV=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=environment" --region $REGION --output=text | cut -f5); echo "$MYENV"
if [[ $MYENV ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): MYENV: $MYENV" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve MYENV" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi

export STATE_CODE=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=environment" --region $REGION --output=text | cut -f5 | cut -d'.' -f1); echo "$STATE_CODE"
if [[ $STATE_CODE ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): State_Code: $STATE_CODE" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve State_Code" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi

export ETZ=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=tzdata2018e" --region $REGION --output=text | cut -f5); echo "$TZ"
if [[ $ETZ ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ETZ: $ETZ" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve ETZ" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi

export HOSTEDZONE=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCEID" "Name=key,Values=hostedzone" --region $REGION --output=text | cut -f5); echo "$HOSTEDZONE"
if [[ $HOSTEDZONE ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): HOSTEDZONE: $HOSTEDZONE" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve HOSTEDZONE" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi

echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): parse vars." | sudo tee -a "$STARTUPLOGFILE"
export MYENVNODOT=(${MYENV//./})
if [[ $MYENVNODOT ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): MYENVNODOT: $MYENVNODOT" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve MYENVNODOT" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi

export IWEBDBDNS="iwebdb.${MYENVNODOT}.$HOSTEDZONE"
if [[ $IWEBDBDNS ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): IWEBDBDNS: $IWEBDBDNS" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve IWEBDBDNS" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi

export IWEBRDS="${MYENVNODOT}iwebrds"
export IWEBRDSDNS=$(aws rds describe-db-instances --db-instance-identifier $IWEBRDS --region $REGION --output=text | grep -i ENDPOINT | awk '{print $2}')
if [[ IWEBRDSDNS ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): IWEBRDSDNS: $IWEBRDSDNS" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve IWEBRDSDNS" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi

export PQRDS="${MYENVNODOT}iqrds"
if [[ PQRDS ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): POSTGRESRDS: $PQRDS" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve POSTGRESRDS" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi

export MDB_IP=""

export LOGGERDNS="logserver.${MYENVNODOT}.$HOSTEDZONE"
if [[ $LOGGERDNS ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): LOGGERDNS: $LOGGERDNS" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve LOGGERDNS" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi

echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): set server timezone." | sudo tee -a "$STARTUPLOGFILE"
sudo timedatectl set-timezone $ETZ

echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): locate secrets with db creds using secret iwebdb.${MYENV}" | sudo tee -a "$STARTUPLOGFILE"
export IWEBSEC=$(aws secretsmanager get-secret-value --secret-id iwebdb.${MYENV} --region $REGION --output=text | grep "sid" | sed 's/^.*{//g' | sed 's/}.*$//g' )
if [[ $IWEBSEC ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): Retrieved secret iwebdb.${MYENV}" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve secret iwebdb.${MYENV}" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi

echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): parse vars." | sudo tee -a "$STARTUPLOGFILE"
export AIWEBSEC=(${IWEBSEC//,/ })
if [[ $AIWEBSEC ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): AIWEBSEC: ****" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve AIWEBSEC" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi

echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): parse dbcreds into vars." | sudo tee -a "$STARTUPLOGFILE"
for i in "${AIWEBSEC[@]}"
do
    [[ ${i} =~ "username" ]] && export IWEBUN=(${i//?username?:/}) && IWEBUN=(${IWEBUN//\"/})
    [[ ${i} =~ "password" ]] && export IWEBPW=(${i//?password?:/}) && IWEBPW=(${IWEBPW//\"/})
    [[ ${i} =~ "sid" ]] && export IWEBSID=(${i//?sid?:/}) && IWEBSID=(${IWEBSID//\"/})
done
if [[ $IWEBUN ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): IWEBUN: ****" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve IWEBUN" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi
if [[ $IWEBPW ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): IWEBPW: ****" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve IWEBPW" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi
if [[ $IWEBSID ]]; then echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): IWEBSID: $IWEBSID" | sudo tee -a "$STARTUPLOGFILE"; else echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): ERROR: Failed to retrieve IWEBSID" | sudo tee -a "$STARTUPLOGFILE"; exit 1; fi

echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): clear creds from env vars." | sudo tee -a "$STARTUPLOGFILE"
IWEBSEC=""
AIWEBSEC=""

echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): dump env vars in log." | sudo tee -a "$STARTUPLOGFILE"
env >> "$STARTUPLOGFILE"
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): end of env vars dump." | sudo tee -a "$STARTUPLOGFILE"

# find the sso endpoint's URL:
export KCSEC=$(aws secretsmanager get-secret-value --secret-id keycloakrds.${MYENV} --region $REGION --output=text | grep "name" | sed 's/^.*{//g' | sed 's/}.*$//g' )
export AKCSEC=(${KCSEC//,/ })
for i in "${AKCSEC[@]}"
do
    [[ ${i} =~ "kc_endpoint" ]] && export KC_ENDPOINT=(${i//?kc_endpoint?:/}) && KC_ENDPOINT=(${KC_ENDPOINT//\"/})
    [[ ${i} =~ "kc_auth_url" ]] && export KC_AUTH_URL=(${i//?kc_auth_url?:/}) && KC_AUTH_URL=(${KC_AUTH_URL//\"/})
    [[ ${i} =~ "jasperbase" ]] && export JASPERBASE=(${i//?jasperbase?:/}) && JASPERBASE=(${JASPERBASE//\"/})
    [[ ${i} =~ "vomsurl" ]] && export VOMSURL=(${i//?vomsurl?:/}) && VOMSURL=(${VOMSURL//\"/})
    [[ ${i} =~ "iweburl" ]] && export IWEBURL=(${i//?iweburl?:/}) && IWEBURL=(${IWEBURL//\"/})
    [[ ${i} =~ "phcurl" ]] && export PHCURL=(${i//?phcurl?:/}) && PHCURL=(${PHCURL//\"/})
    [[ ${i} =~ "afixurl" ]] && export AFIXURL=(${i//?afixurl?:/}) && AFIXURL=(${AFIXURL//\"/})
    [[ ${i} =~ "iqurl" ]] && export IQURL=(${i//?iqurl?:/}) && IQURL=(${IQURL//\"/})
    [[ ${i} =~ "dashboard" ]] && export DASHBOARD=(${i//?dashboard?:/}) && DASHBOARD=(${DASHBOARD//\"/})
    [[ ${i} =~ "pq_un" ]] && export PQ_UN=(${i//?pq_un?:/}) && PQ_UN=(${PQ_UN//\"/})
    [[ ${i} =~ "pq_pw" ]] && export PQ_PW=(${i//?pq_PW?:/}) && PQ_UN=(${PQ_PW//\"/})
    [[ ${i} =~ "prog_name" ]] && export PROG_NAME=(${i//?prog_name?:/}) && PROG_NAME=(${PROG_NAME//\"/})
    [[ ${i} =~ "ph_no" ]] && export PH_NO=(${i//?ph_no?:/}) && PH_NO=(${PH_NO//\"/})
done

echo "Jasper and Voms host without https" | sudo tee -a "$STARTUPLOGFILE"
JASPER_HOST=`echo "${JASPERBASE}" | awk -F "//" '{print $2}'`
VOMS_HOST=`echo "${VOMSURL}" | awk -F "//" '{print $2}'`
IQ_HOST=`echo "${IQURL}" | awk -F "//" '{print $2}'`
export JASPER_HOST
export VOMS_HOST
export IQ_HOST

echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): configuring kc endpoint: ${KC_ENDPOINT} for IQ." | sudo tee -a "$STARTUPLOGFILE"
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): configuring auth url: ${KC_AUTH_URL} for IQ." | sudo tee -a "$STARTUPLOGFILE"
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): configuring jasper base url: ${JASPERBASE} for IQ." | sudo tee -a "$STARTUPLOGFILE"
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): configuring jasper host: ${JASPER_HOST} for IQ." | sudo tee -a "$STARTUPLOGFILE"
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): configuring voms host: ${VOMS_HOST} for IQ." | sudo tee -a "$STARTUPLOGFILE"
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): configuring voms url: ${VOMSURL} for IQ." | sudo tee -a "$STARTUPLOGFILE"
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): configuring iweb url: ${IWEBURL} for IQ." | sudo tee -a "$STARTUPLOGFILE"
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): configuring phc url: ${PHCURL} for IQ." | sudo tee -a "$STARTUPLOGFILE"
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): configuring afix url: ${AFIXURL} for IQ." | sudo tee -a "$STARTUPLOGFILE"
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): configuring iq url: ${IQURL} for IQ." | sudo tee -a "$STARTUPLOGFILE"
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): configuring iq host: ${IQ_HOST} for IQ." | sudo tee -a "$STARTUPLOGFILE"
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): configuring dashboard url: ${DASHBOARD} for IQ." | sudo tee -a "$STARTUPLOGFILE"
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): configuring program name: ${PROG_NAME} for IQ." | sudo tee -a "$STARTUPLOGFILE"
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): configuring phone contact: ${PH_NO} for IQ." | sudo tee -a "$STARTUPLOGFILE"

#Replace JSON files with real values
echo "NODE JSON files replacement"
export NODE_HOME="/home/node"
export IQ_PROCESS_JSON="${NODE_HOME}/json_files/iq_process.json"
export KC_URL_SAML="${KC_ENDPOINT}/protocol/saml"
export IQ_APPS_JSON="${NODE_HOME}/json_files/apps.json"

# --> POPULATE "process.json" with VVOMSEC values ...

echo -e "--> Updating \"${IQ_PROCESS_JSON}\" file \t\t\t ${_timestamp}\n" | sudo tee -a "$STARTUPLOGFILE"

if [[ -z ${IWEBRDSDNS} ]]; then
    sudo sed -i"" -e "s|<SIIS_HOST>|${IWEBDBDNS}|g" ${IQ_PROCESS_JSON}
else
    sudo sed -i"" -e "s|<SIIS_HOST>|${IWEBRDSDNS}|g" ${IQ_PROCESS_JSON}
fi

for f in "${IQ_PROCESS_JSON}"
do
    sudo sed -i"" -e "s|<KEYCLOAK_URL_WITH_REALM>|${KC_URL_SAML}|g" $f
    sudo sed -i"" -e "s|<JASPER_URL>|${JASPER_HOST}|g" $f
    sudo sed -i"" -e "s|<SIIS_USERNAME>|${IWEBUN}|g" $f
    sudo sed -i"" -e "s|<SIIS_PW>|${IWEBPW}|g" $f
    sudo sed -i"" -e "s|<SIIS_SID>|${IWEBSID}|g" $f
    sudo sed -i"" -e "s|<IWEB_URL>|${IWEBURL}/|g" $f
    sudo sed -i"" -e "s|<IQ_URL>|${IQ_HOST}|g" $f
    sudo sed -i"" -e "s|<STATE_CODE>|${STATE_CODE}|g" $f
    sudo sed -i"" -e "s|<IQ_VER>|${iq_app_vers}|g" $f
    sudo sed -i"" -e "s|<IQ_POSTGRES_UN>|${PQ_UN}|g" $f
    sudo sed -i"" -e "s|<IQ_POSTGRES_PW>|${PQ_PW}|g" $f
    sudo sed -i"" -e "s|<PQ_RDS>|${PQRDS}|g" $f
    sudo sed -i"" -e "s|<MDB_UN>|${MDB_UN}|g" $f
    sudo sed -i"" -e "s|<MDB_PW>|${MDB_PW}|g" $f
    sudo sed -i"" -e "s|<MDB_IP>|${MDB_IP}|g" $f
done

for f in "${IQ_APPS_JSON}"
do
    sudo sed -i"" -e "s|<IWEB_URL>|${IWEBURL}|g" $f
    sudo sed -i"" -e "s|<PHC_HUB_URL>|${PHCURL}|g" $f
    sudo sed -i"" -e "s|<IQ_URL>|${IQURL}|g" $f
done

echo "set value for dashboard, afix, voms" | sudo tee -a "$STARTUPLOGFILE"
b_db=`sed -n '1p' /tmp/db_afx_voms`
b_afx=`sed -n '2p' /tmp/db_afx_voms`
b_voms=`sed -n '3p' /tmp/db_afx_voms`
export b_db
export b_afx
export b_voms

if [[ ${b_db} == 'y' ]] ; then
    echo "Dashboard is set to yes so URL is updated" | sudo tee -a "$STARTUPLOGFILE"
    sudo sed -i"" -e "s|<DASHBOARD_URL>|${DASHBOARD}|g" ${IQ_APPS_JSON}
else
    echo "Dashboard set to NO" | sudo tee -a "$STARTUPLOGFILE"
fi

if [[ ${b_afx} == 'y' ]] ; then
    echo "AFIX is set to yes so URL is updated" | sudo tee -a "$STARTUPLOGFILE"
    sudo sed -i"" -e "s|<SMART_AFIX>|${AFIXURL}|g" ${IQ_APPS_JSON}
else
    echo "AFIX set to NO" | sudo tee -a "$STARTUPLOGFILE"
fi

if [[ ${b_voms} == 'y' ]] ; then
    echo "VOMS is set to yes so URL is updated" | sudo tee -a "$STARTUPLOGFILE"
    sudo sed -i"" -e "s|<VOMS_URL>|${VOMSURL}|g" ${IQ_APPS_JSON}
else
    echo "VOMS set to NO" | sudo tee -a "$STARTUPLOGFILE"
fi

echo "Backup the default files to json_files dir" | sudo tee -a "$STARTUPLOGFILE"
sudo mv -f ${NODE_HOME}/process.json ${NODE_HOME}/json_files/process.json.bkup
sudo mv -f ${NODE_HOME}/interop/src/shared/helpers/appActions/apps.json ${NODE_HOME}/json_files/apps.json.bkup

echo "copy value replaced json files from json_files dir to destination in IQ folder" | sudo tee -a "$STARTUPLOGFILE"
sudo mv -f ${IQ_PROCESS_JSON} ${NODE_HOME}/interop/process.json
sudo mv -f ${IQ_APPS_JSON} ${NODE_HOME}/interop/src/shared/helpers/appActions/apps.json

echo "set /home/node permission to node user" | sudo tee -a "$STARTUPLOGFILE"
sudo chown -R node:node ${NODE_HOME}
sudo ls -latrh /home/node | sudo tee -a "$STARTUPLOGFILE"
echo "cat ${NODE_HOME}/interop/process.json" | sudo tee -a "$STARTUPLOGFILE"
sudo cat ${NODE_HOME}/interop/process.json | sudo tee -a "$STARTUPLOGFILE"
echo "cat ${NODE_HOME}/interop/src/shared/helpers/appActions/apps.json" | sudo tee -a "$STARTUPLOGFILE"
sudo cat ${NODE_HOME}/interop/src/shared/helpers/appActions/apps.json | sudo tee -a "$STARTUPLOGFILE"

sudo su - node << EOF
echo "Stop all Node services"
pm2 stop all
echo "start all Services"
pm2 start interop/process.json
pm2 save

EOF

#this requires the oracle client install; there's no tnsping apparently, but we can use sqlplus...

##############################################################################
# Setup is complete, ready to test connection and startup application server
##############################################################################
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): test db connection with sqlplus." | sudo tee -a "$STARTUPLOGFILE"
ORASTATUS=1
COUNT=0
ORAOUT=""
while [[ "${ORASTATUS}" -ne 0 ]] ; do
    echo "test for Oracle connectivity to IWEBDB"
    if [[ -z ${IWEBRDSDNS} ]]; then
        ORAOUT=$(echo "quit" | /usr/lib/oracle/12.2/client64/bin/sqlplus -L -S "${IWEBUN}/${IWEBPW}@${IWEBDBDNS}:1521/${IWEBSID}" )
    else
        ORAOUT=$(echo "quit" | /usr/lib/oracle/12.2/client64/bin/sqlplus -L -S "${IWEBUN}/${IWEBPW}@${IWEBRDSDNS}:1521/${IWEBSID}" )
    fi
    ORASTATUS=$(echo $? )
    COUNT=$(expr $COUNT + 1)
    TSTAMP=$(date)
    echo "Oracle Tries: ${COUNT}, at ${TSTAMP}  with status: ${ORASTATUS} and output ${ORAOUT}" | sudo tee -a "$STARTUPLOGFILE"
    sleep 1
done
echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): db config confirmed for IWEBDB." | sudo tee -a "$STARTUPLOGFILE"

echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): clear creds from env vars." | sudo tee -a "$STARTUPLOGFILE"
IWEBUN=""
IWEBPW=""

echo "$(date "+%Y-%m-%d %H:%M:%S,%3N"): startup.sh script - end of script" | sudo tee -a "$STARTUPLOGFILE" 

