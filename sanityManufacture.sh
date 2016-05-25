#***************************************************************************
#
#					sanityManuFactureVMs.sh
#
#  Script to manufacture 2 NN + 2 DN yarn setup on base machines
#
#  a). 192.168.160.89 ( NN - 192.168.160.213, DN - 192.168.160.215 )
#  b). 192.168.160.90 ( NN - 192.168.160.214, DN - 192.168.160.216 )
#
#***************************************************************************


#---------------------------------------
# Variables
#---------------------------------------

admin="abhishek.choudhary@guavus.com"
recipient="abhishek.choudhary@guavus.com"

startTime=$(date +%s)
cli="/opt/tms/bin/cli -m config"
pmx="/opt/tms/bin/pmx"
baseDir="/data/manufactureVM"

SSH_OPTIONS="-q -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
VM_CREATE_SLEEP=1500
MAX_RETRIES=50
export TZ="Asia/Kolkata"

validUsers="root admin"
validNodes="192.168.160.89 192.168.160.90"
validVMs="192.168.160.213 192.168.160.214 192.168.160.215 192.168.160.216"
instaIP="192.168.160.216"

selfHostAccess=$(mktemp)
machine89Script=$(mktemp)
machine90Script=$(mktemp)
nameNodeConfig=$(mktemp)
dataNodeConfig=$(mktemp)
emailSetup=$(mktemp)
acumeSetup=$(mktemp)
key89="ssh-dss AAAAB3NzaC1kc3MAAACBALRHjREAGdRmdVPsAkF56jM1Cw0lnmOI/mrsmH41LlUZoEB03GFAt8ohCSqKVgrIj0U67lrgJr3IICiKZOswwXkWrQsjiy2nfLEQQ+i9oiXg36etR70Wr5sbB6VPqjTw1ob5xR4Ttc2eRz60yxtyp/QQq//UPS//T46lIq7DxyS5AAAAFQCy+1n9SWC31nAzW06HRYGebKuYjQAAAIEAmTYMxiQ/0HyNXXiJLrVn0o8aQIEMkzQi91rb9ZOBvFO/jsdCP+Eei+7xpP1nwRCW5IPBYCJ2erKJDv65Edikfvf9NE/DFLXTBfJXPH3b947tuYsdbEFt27gaY+cHZdTxU4A2MyQaG5hPu35lHlxyqO2yox7vBsUa+XWrLIltgKoAAACBAJh8Y71+VYBpc1X2Z8OLoVDpE1X82REgcMbH+DLYdQqvpZCIMTlo9+lw6ecSaSktGwgzzLRZK9K3+L5xSTob6P770tV8OW93L0lDtAk5mxuMtBupo+Dy4P5aW8LsfhSYyvrBIu/NKG78/Pin5ulfiStT4ABjzN8xxv48NsekprmO"
key90="ssh-dss AAAAB3NzaC1kc3MAAACBALfX4lc4hLI6FDKIyd0FM/mJy5LGbuloRL4P6yad7Lnc9qJncURCM6E+NSF9TZVcSOj/ZbOm5grCPQpcZBGFj4O1fXtnqfCYmPv8gRnUpwMPYdsc63uueN+gxpk3s/qoZEcrFtN5BVi6XE7kCUHRU8TDLL0z5fq9pVH8ZBl+CcSpAAAAFQDIu3Ksn5OlP66Dg7ktksZif1W1OwAAAIAxuc/3jOJEKT0LgBYE3/QhBKjPlsPjSvp3AjuhLhOAG0qooRiyPOGBLIECHW1Mp/60udQ9myjt1+bpmHUlQfdJ+OYhtZdH87cg9+Fc5GfaigjHToUbXrVVPRjxPDcraoCnIKGUaOgVt58OpN+SjT6Xr+sxkUFVTXKW5FyA6usK5AAAAIBDJ44A1q9U3d+zgFFCXcCdhrKJyRXkx6fp4itSmiTVwJ8GBk3r/yZCfvaeoWdOxtVMGZszGiWTlJuIFO8n68AFR8e7ILV4uccq2gHzQhhuSlYjS17APhkgCnf/shDT8NZ81L190ykdpyLxVpoAr9KprJS2If9WSPrBIXONdRwAfA=="
keyLaptop="ssh-dss AAAAB3NzaC1kc3MAAACBAIQsQUDcO/uKYTDcU93NVgEnmzTrCi66MFihDMbwWL6pgzosdxE8GCkcFEKMMKl/NdfbfGGv7ewukB4yOrzkWWXar7hT9pfI94HyIWbwjwvGTaaepK020LPmvgLynIBYrhhlARb7eW9HfHb14ga1/DRlYis4enfFJFAOuHJR1sxnAAAAFQDmUKUYZ9SWKus29SAdtcJK4rv8DQAAAIAHM+jHj+L0SxK/Hu+/q54GUNquFxLoV2kly1wc4zo+A3p/HXKomY71nbH9dtPDTXa0qN2W+UFNzq7EwWc4k+4+x2AiR/942lN7KEwQ5aRbJlaqgjuHmjdJcssE8R3pgwG7a9KpW4g2KOXvJHQW0eFJS/aBuaxdslQ8u5gARx/NkQAAAIAnC37Uwr5wlnVVGPhyFXeUJ/DcCIAD5PQpGWTkbxoqB6xJKRP1Zm4vpdbBvY7qcfVaB+jVNfk0/6uvetrGrgY7y44An9+kWQXE8GJIOkYlgUjg0u8GBUk5U9kDSdtF9KFL1GVNPZcPyyR8eXkTnA5uQ9oUJENDEhAbzwuWSOowqw=="

#-------------------------------------------------------
# Functions : All the functions used are defined below
#-------------------------------------------------------

#-------------------------------------------------------
# Function to show usage for using this script
#-------------------------------------------------------

showUsage () {
echo -e "Usage: `basename $0` -[ih]";
echo -e "\t -i: Image File path with which Yarn Cluster needs to be Manufactured"
echo -e "\t -h: help "
}


#-------------------------------------------------------
# Function to clean all temp files
# created during script execution
#-------------------------------------------------------

cleanUpFiles() {
rm -rf $selfHostAccess
rm -rf $machine89Script
rm -rf $machine90Script
rm -rf $nameNodeConfig
rm -rf $dataNodeConfig
rm -rf $emailSetup
rm -rf $acumeSetup
}

#-------------------------------------------------------
# Function to check password less access by doing ssh
#-------------------------------------------------------

isKeyLessSSH(){
	var=$(ssh -q -oBatchMode=yes -oPreferredAuthentications=publickey -l $1 $2 'exit' || echo "false")
	echo $var | grep -q 'UNIX shell commands cannot be executed using this account'
	if [[ $? -eq 0 ]]
	then
		echo "Allowed"
	else
		if [[ $var = "false" ]];then
			echo "Denied"
		else
			echo "Allowed"
		fi
	fi
}



#-------------------------------------------------------
# Function to check password less access among all the
# base machines on which VMs will be created
#-------------------------------------------------------


checkAllNodeAccess() {
	for tHost in ${validNodes[@]}
	do
		for usr in ${validUsers[@]}
		do
			testOut=$(isKeyLessSSH $usr $tHost)
			echo $usr"@"$tHost":"$testOut
		done
	done >$selfHostAccess
}


#-------------------------------------------------------
# Function to check if all manufactured VMs are up or not
# once they are up configuration step will start afterwards
#-------------------------------------------------------


checkIfAllVMsUp() {
	waitForNode=0
	vmRetries=0
	while [[ 1 ]];do
		if [[ $vmRetries -eq $MAX_RETRIES ]];then
			echo "VM Boot Failed. Total Retries : $MAX_RETRIES"
			exit 1
		fi
		for node in ${validVMs[@]}
		do
			isMachineUp=$(ping -c 10 $node | grep 'packets' | cut -d ',' -f2 | awk '{print $1}')
			if [[ $isMachineUp -lt 1 ]];then
				echo "VM not booted yet: $node "
				waitForNode=1
			fi
		done
		if [[ $waitForNode -eq 0 ]];then
			break;
		else
			sleep 20
			waitForNode=0
			vmRetries=$((vmRetries+1))
		fi
	done
}

#-------------------------------------------------------
# Function to setup no password on root user
# so that all scp works perfectly
#-------------------------------------------------------

setupRootLessAccess(){
	for vm in ${validVMs[@]}
	do
		expect <<EOF
		set timeout 10
		spawn ssh $SSH_OPTIONS -l admin $vm
		expect "password"
		send "admin@123 \n"
		expect ">"
		send "en \n"
		expect "#"
		send "_shell \n"
		expect "#"
		send "cli -m config \n"
		expect "#"
		send "no username root disable \n"
		expect "#"
		send "username root nopassword \n"
		expect "#"
		send "ssh client user admin authorized-key sshv2 \"${key89}\" \n"
		expect "#"
		send "ssh client user admin authorized-key sshv2 \"${key90}\" \n"
		expect "#"
		send "configuration write \n"
		expect "#"
EOF
	sleep 10
	done

}



#-------------------------------------------------------
# Function to setup tall maple cluster config
# using guavus clis (on hard coded ips)
# check "clusterVMs" variable used insde function
#-------------------------------------------------------

setUpTallMapleCluster() {
	clusterVMs="192.168.160.213 192.168.160.214"
	for vm in ${clusterVMs[@]}
	do
		expect <<EOF
		set timeout 10
		spawn ssh $SSH_OPTIONS -l admin $vm
		expect "password"
		send "admin@123 \n"
		expect ">"
		send "en \n"
		expect "#"
		send "_shell \n"
		expect "#"
		send "cli -m config \n"
		expect "#"
		send "ssh client global host-key-check no \n"
		expect "#"
		send "ssh client user admin identity dsa2 generate \n"
		expect "#"
		send "cluster expected-nodes 2 \n"
		expect "#"
		send "cluster id 818882 \n"
		expect "#"
		send "cluster master address vip 192.168.160.217 /24 \n"
		expect "#"
		send "cluster name yarn-ha-sanity \n"
		expect "#"
		send "cluster enable \n"
		expect "#"
		send "configuration write  \n"
		expect "#"
EOF
	wait 20
	done
}


#-------------------------------------------------------
# Function to get keys of both namenodes
# this will be shared among all the DNs
#-------------------------------------------------------


getTheKeys() {
	key213=$(ssh $SSH_OPTIONS -l root 192.168.160.213 "echo 'show ssh client' | /opt/tms/bin/cli -m config | sed -n '/DSAv2 Public key:/, / /p' | tail -1")
	key214=$(ssh $SSH_OPTIONS -l root 192.168.160.214 "echo 'show ssh client' | /opt/tms/bin/cli -m config | sed -n '/DSAv2 Public key:/, / /p' | tail -1")
}


#-------------------------------------------------------
# Function to get real ip address of master and standby
# nodes
#-------------------------------------------------------

getRealIps(){
	masterIP=$(ssh $SSH_OPTIONS -l root 192.168.160.217 " ifconfig | grep -w inet | grep '192.168.160' | grep -v '\.217' | awk '{print \$2}' | cut -d ':' -f2")
	if [[ $masterIP = "192.168.160.213" ]];then
		standbyIP="192.168.160.214"
	else
		standbyIP="192.168.160.213"
	fi
}


#-------------------------------------------------------
# Function to check if Yarn RM is up or not
# (on hard coded ip)
#-------------------------------------------------------

checkIfRMUp() {
	rmRetries=0
	isRmUp=$(ssh -q -l root 192.168.160.217 "ps -ef | grep proc_resourcemanager | grep -v grep | awk '{print \$2}'")
	while [[ 1 ]];do
		if [[ $rmRetries -eq $MAX_RETRIES ]];then
			echo "YARN RM Process is not coming up. Total Retries : $MAX_RETRIES"
			exit 2
		fi
		if [[ $isRmUp != "" ]];then
			echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: YARN is UP Now"
			break
		else
			sleep 20
			rmRetries=$((rmRetries + 1))
			isRmUp=$(ssh -q -l root 192.168.160.217 "ps -ef | grep proc_resourcemanager | grep -v grep | awk '{print \$2}'")
		fi
	done
}

#-------------------------------------------------------
# Function to check if Oozie server is up or not
# (on hard coded ip)
#-------------------------------------------------------

checkIfOozieUp() {
	oozieRetries=0
	isOozieUp=$(ssh -q -l root 192.168.160.217 "ps -ef | grep "/opt/oozie/oozie-server/conf/" | grep -v grep | awk '{print \$2}'")
	while [[ 1 ]];do
		if [[ $oozieRetries -eq $MAX_RETRIES ]];then
			echo "Oozie Process is not coming up. Total Retries : $MAX_RETRIES"
			exit 3
		fi
		if [[ $isOozieUp != "" ]];then
			echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Ooize is UP Now"
			break
		else
			sleep 20
			oozieRetries=$((oozieRetries + 1))
			isOozieUp=$(ssh -q -l root 192.168.160.217 "ps -ef | grep "/opt/oozie/oozie-server/conf/" | grep -v grep | awk '{print \$2}'")
		fi
	done
}


#-------------------------------------------------------
# Function to check if Insta is up or not. It will be
# used to generate IBs before running job
# (on hard coded ip)
#-------------------------------------------------------

checkIfInstaUp() {
	instaRetries=0
	isInstaUp=$(ssh -q -l root $instaIP "echo 'insta infinidb get-status-info' | $cli | grep 'Infinidb Adaptor status' | cut -d ':' -f2 | sed -e 's/^ *//g' -e 's/,//'")
	while [[ 1 ]];do
		if [[ $instaRetries -eq $MAX_RETRIES ]];then
			echo "Insta Process is not coming up. Total Retries : $MAX_RETRIES"
			exit 4
		fi
		if [[ $isInstaUp == "Adaptor Running" ]];then
			echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Insta is UP Now"
			break
		else
			sleep 30
			instaRetries=$((instaRetries + 1))
			isInstaUp=$(ssh -q -l root $instaIP "echo 'insta infinidb get-status-info' | $cli | grep 'Infinidb Adaptor status' | cut -d ':' -f2 | sed -e 's/^ *//g' -e 's/,//'")
		fi
	done
}


checkIfInstaUpNew() {
	instaRetries=0
	isInstaUp=$(ssh $SSH_OPTIONS -T -l root $instaIP "netstat -natp | grep 11111 | awk '{print \$NF}' | cut -d '/' -f2")
	while [[ 1 ]];do
		if [[ $instaRetries -eq $MAX_RETRIES ]];then
			echo "Insta Process is not coming up. Total Retries : $MAX_RETRIES"
			exit 4
		fi
		if [[ $isInstaUp == "insta" ]];then
			echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Insta is UP Now"
			break
		else
			sleep 30
			instaRetries=$((instaRetries + 1))
			isInstaUp=$(ssh $SSH_OPTIONS -T -l root $instaIP "netstat -natp | grep 11111 | awk '{print \$NF}' | cut -d '/' -f2")
		fi
	done
}


#-------------------------------------------------------
# Function to run all the  required cli to config insta
#-------------------------------------------------------

setupInstaServer(){
ssh $SSH_OPTIONS -T -l root $instaIP<<EOF

mount -o remount,rw /
touch /etc/infinidb_install_version

cat<<EOF1 |$cli
insta adapters infinidb cluster-name CRUX-INSTA
insta adapters infinidb set install-mode single-server-install
insta adapters infinidb set module-install-type combined
insta adapters infinidb set storage-type local
insta adapters infinidb set storage-type local
insta adapters infinidb dbroot 1
insta adapters infinidb module 1
insta adapters infinidb modulecount 1
insta adapters infinidb module 1 ip $instaIP
insta instance-id create 0
insta instance 0 active-adapter infinidb
insta instance 0 cubes-database crux
insta instance 0 cubes-xml /opt/tms/xml_schema/cubedefinition/cisco_mur.xml
insta instance 0 dataRetentionPeriod 0
insta instance 0 deletion-flag true
insta instance 0 metadata-location ""
insta instance 0 migration-to-flat-schema disable
insta instance 0 mode default
insta instance 0 pull-mode disable
insta instance 0 qe set collector-output-path ""
insta instance 0 qe set record-database ""
insta instance 0 qe set record-xml ""
insta instance 0 qe set service-port 0
insta instance 0 qe set storage-location ""
insta instance 0 schema-type star
insta instance 0 service-port 11111
insta instance 0 store-location /guavus/insta/
insta instance 0 string-id-map-xml ""
insta instance-id create 1
insta instance 1 active-adapter infinidb
insta instance 1 cubes-database mr
insta instance 1 cubes-xml /opt/tms/xml_schema/cubedefinition/cisco_mur.xml
insta instance 1 dataRetentionPeriod 0
insta instance 1 deletion-flag true
insta instance 1 metadata-location ""
insta instance 1 migration-to-flat-schema disable
insta instance 1 mode default
insta instance 1 pull-mode disable
insta instance 1 qe set collector-output-path ""
insta instance 1 qe set record-database ""
insta instance 1 qe set record-xml ""
insta instance 1 qe set service-port 0
insta instance 1 qe set storage-location ""
insta instance 1 schema-type star
insta instance 1 service-port 22222
insta instance 1 store-location /guavus/insta/
insta instance 1 string-id-map-xml ""
insta ipc serviceport 55555
pm process insta restart
show pm process insta
EOF1

sleep 5

echo "insta infinidb install" |$cli
EOF
}

#-------------------------------------------------------
# Function to setup Aggregation Center and generate
# all the required IBs on namenode(s)
#-------------------------------------------------------


setupAggregationCenter(){
setupServer=$1
isMaster=$2

scp $SSH_OPTIONS /data/SanityData/ib_file.tgz admin@$setupServer:/data/
scp $SSH_OPTIONS /data/SanityData/ib_patch.tgz admin@$setupServer:/data/
ssh $SSH_OPTIONS -T -l root $setupServer<<EOF
mount -o remount,rw /
pmx="/opt/tms/bin/pmx"

cat<<EOF1 >/opt/etc/oozie/CruxEdr/spark.properties
spark.master yarn-cluster
spark.executor.memory 6096m
spark.executor.instances 6
spark.executor.cores 2
spark.eventLog.enabled true
spark.eventLog.dir hdfs:///spark/events/
spark.sql.shuffle.partitions=40
spark.sql.hive.convertMetastoreParquet true
spark.sql.parquet.binaryAsString true
spark.sql.parquet.useDataSourceApi false
EOF1

cp /opt/etc/oozie/CruxEdr/crux.properties /opt/etc/oozie/CruxEdr/crux2.properties

cat<<EOF1 >>/opt/etc/oozie/CruxEdr/crux.properties
crux.insta.override.tablename=false
EOF1

cat<<EOF1 >>/opt/etc/oozie/CruxEdr/crux2.properties
crux.insta.output.cube.from.xml=true
#crux.instaInit.xml.path=/opt/tms/xml_schema/cubedefinition/cisco_mur.xml
crux.instaInit.xml.path=/data/cisco_mural.xml
EOF1


touch /opt/catalogue/atlas/collection_center.list
touch /opt/catalogue/bulk_stats/schema_metric_name_14.map
tar -zxvf /data/ib_file.tgz -C /data/
tar -zxvf /data/ib_patch.tgz -C /data/
tpsPath=\$(find / -name 'pmx.py' -type f  | xargs dirname | xargs dirname)
cp /data/ib_patch/patch/usr/lib64/python2.6/site-packages/guavus/tps/cli/cli_* \${tpsPath}/cli/
cp /data/ib_patch/patch/usr/lib64/python2.6/site-packages/guavus/tps/lib/parse_ib.py \${tpsPath}/lib/parse_ib.py

echo "Master Node: " $isMaster

if [[ $isMaster = "false" ]];then
	echo "subshell aggregation_center fetch all ibs from inbox" | $pmx
	mount -o remount,ro /
	exit 0
fi

echo "subshell aggregation_center fetch all ibs from image" | $pmx

sleep 5

for ibFile in \$(find /data/ib_file -type f)
do
	ib=\$(basename \$ibFile)
	echo "subshell aggregation_center edit ib \$ib add bulk \$ibFile" | $pmx
done

genrateOutput=\$( $pmx subshell aggregation_center generate all ibs)
successFul=\$(echo "\$genrateOutput" | grep 'Successful IBs' |awk '{print \$4}')
totalIbs=\$(echo "\$genrateOutput" | grep 'Successful IBs' |awk '{print \$NF}')
if [[ \$successFul -ne \$totalIbs ]] || [[ \$totalIbs = "" ]];then
	isInstaUP=\$(ssh $SSH_OPTIONS -T -l root $instaIP "netstat -natp | grep 11111 | awk '{print \$NF}' | cut -d '/' -f2")
	if [[ \$isInstaUP = "insta" ]];then
		echo "yes its Up"
	else
		echo "Nopes its down"
	fi
	sleep 60
	genrateOutput=\$( $pmx subshell aggregation_center generate all ibs)
	successFul=\$(echo "\$genrateOutput" | grep 'Successful IBs' |awk '{print \$4}')
	totalIbs=\$(echo "\$genrateOutput" | grep 'Successful IBs' |awk '{print \$NF}')
	if [[ \$successFul -ne \$totalIbs ]] || [[ \$totalIbs = "" ]];then
		echo "Try 2 Failed"
		exit 5
	fi
fi

sleep 15

echo "
subshell aggregation_center add ib_destination 192.168.160.213
subshell aggregation_center add ib_destination 192.168.160.214
subshell aggregation_center push all ibs
subshell aggregation_center fetch all ibs from inbox
" | $pmx

mount -o remount,ro /
exit 0
EOF
}



#-------------------------------------------------------
# Function to gereate a vm manufature script for
# base machine 192.168.160.89
# later on this script will be copied on this server and
# run over ssh
#-------------------------------------------------------

generateMachine89Setup(){
cat <<EOF >${machine89Script}
#! /bin/sh
TZ="${TZ}"
rm -rf /var/home/root/.ssh/known_hosts
touch /var/home/root/.ssh/known_hosts

echo "
virt vm NN-1 power off
virt vm DN-1 power off
no virt vm NN-1
no virt vm DN-1
conf write" | $cli

#-------------------------------------------------------
# Function to check if VM is manufactured yet or not
# once manufacutred it will bring it up with provided IP and
# other config settings
#-------------------------------------------------------

bringUpVM(){

	VM_NAME=\$1
	IP_ADDR=\$2
	IP_GATEWAY=\$3
	VM_HOSTNAME=\$4
	SUBNET=\$5
	GMS_KEY="ssh-dss AAAAB3NzaC1kc3MAAACBALKwXCMsZbAuK5B6Ag35ApLMDEF+rLvRLI8Hrldgp4codWz6vlY3zbF2ndewdQasqQHASHjT3UoA1zZVWuiaVWzI/SbME6j6ZBJEo7QiLv0rudCQ5eB+FTjwtUPDGSn+asCGUniHiPn6H7T5MkxWrhwltXjHkr3A8gfQiAhqiaohAAAAFQC98JzL6u7wlzoJpfsyLpnnCvg7TQAAAIAQBArXTuB6vqBkStjwsAEWR3RlUONhUYA5m2i3HmBJ8tSlyF6lD+5NKkuuKzz4Istg3x/jOQijAOPfcss2pihvxO5XF6ezunqYMr85gSCkIcrye+IBBlus8tz3LcnshBGScQb1/CgRvrk+XN1hkEZaIvro1B8X5XsSWScnrEWqyQAAAIEAgUxGpCUTKYOYLCpFfbRmd6kLSwOkOPxksgq1TkClPmfTBFIQWzznGTFgR4woUPs6tNbSyb96KQ1dpkj77y1pk1iIuFDLkx2lrQeW/SCiwybnljZl78QzVfX3HOrzIvx+tNWNZvo1WW50tJ7QkKVEX7p+G57/XUYN887F32KEzbU=\n"
	CONFIG_DRIVE=\${VM_NAME}.iso
	RANDOM_SEED=\$(openssl rand  -hex 10)
	TZ="${TZ}"

	isInstallInProgress=\$(echo "show virt vm" | $cli | sed -n "/\$VM_NAME/,/ / p" | grep 'INSTALL IN PROGRESS')
	if [[ \$isInstallInProgress != "" ]];then
		echo "[\$(date "+%Y-%m-%d %H:%M:%S")] \$VM_NAME: Manufacture Process Still In Progress..waiting.."
	fi
	while [[ \$isInstallInProgress != "" ]];do
		sleep 30
		isInstallInProgress=\$(echo "show virt vm" | $cli | sed -n "/\$VM_NAME/,/ / p" | grep 'INSTALL IN PROGRESS')
	done

	mkdir -p CD/openstack/latest
	cat >CD/openstack/latest/meta_data.json<<EOF1
	{"admin_pass": "admin_pass", "random_seed": "\${RANDOM_SEED}", "name": "\${VM_NAME}", "availability_zone": "nova", "hostname": "\${VM_HOSTNAME}", "launch_index": 0, "meta": {"ipgw": "\${IP_GATEWAY}", "interface_name": "eth0", "ipaddr": "\${IP_ADDR}/\${SUBNET}"}, "public_keys": {"gmsauthkey": "\${GMS_KEY}"}, "uuid": "65460feb-2314-436f-a304-157f07b706e3"}
EOF1

	/usr/bin/mkisofs -v -J -R -iso-level 3  -o \${CONFIG_DRIVE} CD/
	mv -f \${CONFIG_DRIVE} /data/virt/pools/default/
	rm -r CD

	echo "virt vm \${VM_NAME} storage device bus ide drive-number new source file \${CONFIG_DRIVE}" | $cli
	echo "virt vm \${VM_NAME} power on" | $cli
}

rm -rf /data/virt/pools/default/*.img
rm -rf /data/virt/pools/default/*.iso
rm -rf /var/opt/tms/images/*

qemu-img create /data/virt/pools/default/NN-1-A.img 20G
qemu-img create /data/virt/pools/default/NN-1-B.img 100G
qemu-img create /data/virt/pools/default/DN-1-A.img 20G
qemu-img create /data/virt/pools/default/DN-1-B.img 160G

chown qemu /data/virt/pools/default/*.img
chgrp qemu /data/virt/pools/default/*.img
chmod 777  /data/virt/pools/default/*.img

echo "Fetching Image on Host Machine: 192.168.160.89"

wget -q -N -P /var/opt/tms/images/ ${imageFile}

echo "Image Fetch Complete: 192.168.160.89"

echo "
virt vm NN-1
virt vm NN-1 memory 40960
virt vm NN-1 vcpus count 8
virt vm NN-1 interface 1 bridge br0
virt vm NN-1 storage device bus virtio drive-number 1 source file NN-1-A.img mode read-write
virt vm NN-1 storage device bus virtio drive-number 2 source file NN-1-B.img mode read-write
conf write
" | $cli

sleep 10

echo "virt vm NN-1 manufacture image ${imageName} model VM_2D connect-console text" | $cli

(sleep $VM_CREATE_SLEEP
bringUpVM NN-1 192.168.160.213 192.168.160.1 YARN-NN-1 24)&

echo "
virt vm DN-1
virt vm DN-1 memory 153600
virt vm DN-1 vcpus count 12
virt vm DN-1 interface 1 bridge br0
virt vm DN-1 storage device bus virtio drive-number 1 source file DN-1-A.img mode read-write
virt vm DN-1 storage device bus virtio drive-number 2 source file DN-1-B.img mode read-write
conf write
" | $cli

sleep 10

echo "virt vm DN-1 manufacture image ${imageName} model VM_2D connect-console text" | $cli

(sleep $VM_CREATE_SLEEP
bringUpVM DN-1 192.168.160.215 192.168.160.1 YARN-DN-1 24)&

wait
exit

EOF
}


#-------------------------------------------------------
# Function to gereate a vm manufature script for
# base machine 192.168.160.90
# later on this script will be copied on this server and
# run over ssh
#-------------------------------------------------------

generateMachine90Setup(){
cat <<EOF >${machine90Script}
#! /bin/sh
TZ="${TZ}"
rm -rf /var/home/root/.ssh/known_hosts
touch /var/home/root/.ssh/known_hosts

echo "
virt vm NN-2 power off
virt vm DN-2 power off
no virt vm NN-2
no virt vm DN-2
conf write
" | $cli

rm -rf /data/virt/pools/default/*.img
rm -rf /data/virt/pools/default/*.iso
rm -rf /var/opt/tms/images/*

qemu-img create /data/virt/pools/default/NN-2-A.img 20G
qemu-img create /data/virt/pools/default/NN-2-B.img 100G
qemu-img create /data/virt/pools/default/DN-2-A.img 20G
qemu-img create /data/virt/pools/default/DN-2-B.img 160G

chown qemu /data/virt/pools/default/*.img
chgrp qemu /data/virt/pools/default/*.img
chmod 777  /data/virt/pools/default/*.img


echo "Fetching Image on Host Machine: 192.168.160.90"

wget -q -N -P /var/opt/tms/images/ ${imageFile}

echo "Image Fetch Complete: 192.168.160.90"

#-------------------------------------------------------
# Function to check if VM is manufactured yet or not
# once manufacutred it will bring it up with provided IP and
# other config settings
#-------------------------------------------------------

bringUpVM(){

	VM_NAME=\$1
	IP_ADDR=\$2
	IP_GATEWAY=\$3
	VM_HOSTNAME=\$4
	SUBNET=\$5
	GMS_KEY="ssh-dss AAAAB3NzaC1kc3MAAACBALKwXCMsZbAuK5B6Ag35ApLMDEF+rLvRLI8Hrldgp4codWz6vlY3zbF2ndewdQasqQHASHjT3UoA1zZVWuiaVWzI/SbME6j6ZBJEo7QiLv0rudCQ5eB+FTjwtUPDGSn+asCGUniHiPn6H7T5MkxWrhwltXjHkr3A8gfQiAhqiaohAAAAFQC98JzL6u7wlzoJpfsyLpnnCvg7TQAAAIAQBArXTuB6vqBkStjwsAEWR3RlUONhUYA5m2i3HmBJ8tSlyF6lD+5NKkuuKzz4Istg3x/jOQijAOPfcss2pihvxO5XF6ezunqYMr85gSCkIcrye+IBBlus8tz3LcnshBGScQb1/CgRvrk+XN1hkEZaIvro1B8X5XsSWScnrEWqyQAAAIEAgUxGpCUTKYOYLCpFfbRmd6kLSwOkOPxksgq1TkClPmfTBFIQWzznGTFgR4woUPs6tNbSyb96KQ1dpkj77y1pk1iIuFDLkx2lrQeW/SCiwybnljZl78QzVfX3HOrzIvx+tNWNZvo1WW50tJ7QkKVEX7p+G57/XUYN887F32KEzbU=\n"
	CONFIG_DRIVE=\${VM_NAME}.iso
	RANDOM_SEED=\$(openssl rand  -hex 10)
	TZ="${TZ}"

	isInstallInProgress=\`echo "show virt vm" | $cli | sed -n "/\$VM_NAME/,/ / p" | grep 'INSTALL IN PROGRESS'\`
	if [[ \$isInstallInProgress != "" ]];then
		echo "[\$(date "+%Y-%m-%d %H:%M:%S")] \$VM_NAME: Manufacture Process Still In Progress..waiting.."
	fi
	while [[ \$isInstallInProgress != "" ]];do
		sleep 30
		isInstallInProgress=\`echo "show virt vm" | $cli | sed -n "/\$VM_NAME/,/ / p" | grep 'INSTALL IN PROGRESS'\`
	done

	mkdir -p CD/openstack/latest
	cat >CD/openstack/latest/meta_data.json<<EOF1
	{"admin_pass": "admin_pass", "random_seed": "\${RANDOM_SEED}", "name": "\${VM_NAME}", "availability_zone": "nova", "hostname": "\${VM_HOSTNAME}", "launch_index": 0, "meta": {"ipgw": "\${IP_GATEWAY}", "interface_name": "eth0", "ipaddr": "\${IP_ADDR}/\${SUBNET}"}, "public_keys": {"gmsauthkey": "\${GMS_KEY}"}, "uuid": "65460feb-2314-436f-a304-157f07b706e3"}
EOF1

	/usr/bin/mkisofs -v -J -R -iso-level 3  -o \${CONFIG_DRIVE} CD/
	mv -f \${CONFIG_DRIVE} /data/virt/pools/default/
	rm -r CD

	echo "virt vm \${VM_NAME} storage device bus ide drive-number new source file \${CONFIG_DRIVE}" | $cli
	echo "virt vm \${VM_NAME} power on" | $cli

}

echo "
virt vm NN-2
virt vm NN-2 memory 40960
virt vm NN-2 vcpus count 8
virt vm NN-2 interface 1 bridge br0
virt vm NN-2 storage device bus virtio drive-number 1 source file NN-2-A.img mode read-write
virt vm NN-2 storage device bus virtio drive-number 2 source file NN-2-B.img mode read-write
configuration write
" | $cli

sleep 10

echo "virt vm NN-2 manufacture image ${imageName} model VM_2D connect-console text" | $cli

(sleep $VM_CREATE_SLEEP
bringUpVM NN-2 192.168.160.214 192.168.160.1 YARN-NN-2 24)&


echo "
virt vm DN-2
virt vm DN-2 memory 153600
virt vm DN-2 vcpus count 12
virt vm DN-2 interface 1 bridge br0
virt vm DN-2 storage device bus virtio drive-number 1 source file DN-2-A.img mode read-write
virt vm DN-2 storage device bus virtio drive-number 2 source file DN-2-B.img mode read-write
configuration write
" | $cli

sleep 10

echo "virt vm DN-2 manufacture image ${imageName} model VM_2D connect-console text" | $cli

(sleep $VM_CREATE_SLEEP
bringUpVM DN-2 192.168.160.216 192.168.160.1 YARN-DN-2 24  )&

wait
exit

EOF
}


#-------------------------------------------------------
# Function to setup Namenodes for
# 1. Hostnames Mapping
# 2. Keys Sharing
# 3. Yarn Configuration
# 4. Oozie Server Configuration
# 5. Oozie Jobs Configurations
#
# Check var nameNodes inside this function
# for list of namesnodes (hard coded)
#
#-------------------------------------------------------


setupNameNodes(){

cat<<EOF >${nameNodeConfig}

#------------------------------------
# IP HOST MAPPINGS
#------------------------------------
ip host CRUX-SANITY 192.168.160.217
ip host YARN-NN-1 192.168.160.213
ip host YARN-NN-2 192.168.160.214
ip host YARN-DN-1 192.168.160.215
ip host YARN-DN-2 192.168.160.216

#------------------------------------
# Key - Sharing
#------------------------------------

ip default-gateway 192.168.160.1
ssh client user admin authorized-key sshv2 "${key89}"
ssh client user admin authorized-key sshv2 "${key90}"
ssh client user admin authorized-key sshv2 "${key213}"
ssh client user admin authorized-key sshv2 "${key214}"
ssh client user admin authorized-key sshv2 "${keyLaptop}"


#------------------------------------
# Sm Service For IB Generation
#------------------------------------

sm service create PS::BLOCKING:1
sm service modify PS::BLOCKING:1 service-info ps-server-1
sm service-info create ps-server-1
sm service-info modify ps-server-1 port 11111
sm service-info modify ps-server-1 host $instaIP
sm service-info modify ps-server-1 service-type TCP_SOCKET

#------------------------------------
# PG SQL for SparkSql and INSTA As API
#------------------------------------

pgsql mode external
pm process pgsqld restart
pm process pgsqld launch auto
tps sparksql set-attribute metastore-ip value 192.168.160.217
tps sparksql set-attribute mapred-job-queue-name value default


#######################################
# Configure HADOOP_YARN
#######################################
pmx register hadoop_yarn
pmx set hadoop_yarn config_ha True
pmx set hadoop_yarn journalnodes 192.168.160.213
pmx set hadoop_yarn journalnodes 192.168.160.214
pmx set hadoop_yarn journalnodes 192.168.160.215
pmx set hadoop_yarn monitor On
pmx set hadoop_yarn namenode1 YARN-NN-1
pmx set hadoop_yarn namenode2 YARN-NN-2
pmx set hadoop_yarn nameservice yarnNameService
pmx set hadoop_yarn slave 192.168.160.215
pmx set hadoop_yarn slave 192.168.160.216
pmx set hadoop_yarn state UNINIT
pmx set hadoop_yarn yarn.scheduler.maximum-allocation-mb 122880
pmx subshell hadoop_yarn set config dnprofile default attribute property yarn.nodemanager.resource.memory-mb 122880

#######################################
# Configure OOZIE
#######################################
pmx register oozie
pmx set oozie nameService yarnNameService
pmx set oozie namenode 192.168.160.217
pmx set oozie oozieServer 192.168.160.217
pmx set oozie snapshotPath /data/snapshot
pmx set oozie sparksqlServer 192.168.160.217
pmx set oozie sshHost 127.0.0.1
pmx set oozie tmp /tmp


######################################
# DataSets
######################################
#------------------
# THRIFT_EDRFLOW
#------------------
pmx subshell oozie add dataset THRIFT_EDRFLOW
pmx subshell oozie set dataset THRIFT_EDRFLOW attribute doneFile .*_DONE
pmx subshell oozie set dataset THRIFT_EDRFLOW attribute endOffset 1
pmx subshell oozie set dataset THRIFT_EDRFLOW attribute frequency 5
pmx subshell oozie set dataset THRIFT_EDRFLOW attribute inputStreamName MuralFLOW
pmx subshell oozie set dataset THRIFT_EDRFLOW attribute outputOffset 0
pmx subshell oozie set dataset THRIFT_EDRFLOW attribute path /data/collector/thrift/output/edrflow/%Y/%M/%D/%H/%mi
pmx subshell oozie set dataset THRIFT_EDRFLOW attribute pathType hdfs
pmx subshell oozie set dataset THRIFT_EDRFLOW attribute startOffset 12
pmx subshell oozie set dataset THRIFT_EDRFLOW attribute startTime 2015-01-15T02:00Z
#------------------
# THRIFT_EDRHTTP
#------------------
pmx subshell oozie add dataset THRIFT_EDRHTTP
pmx subshell oozie set dataset THRIFT_EDRHTTP attribute doneFile .*_DONE
pmx subshell oozie set dataset THRIFT_EDRHTTP attribute endOffset 1
pmx subshell oozie set dataset THRIFT_EDRHTTP attribute frequency 5
pmx subshell oozie set dataset THRIFT_EDRHTTP attribute inputStreamName MuralHTTP
pmx subshell oozie set dataset THRIFT_EDRHTTP attribute outputOffset 0
pmx subshell oozie set dataset THRIFT_EDRHTTP attribute path /data/collector/thrift/output/edrhttp/%Y/%M/%D/%H/%mi
pmx subshell oozie set dataset THRIFT_EDRHTTP attribute pathType hdfs
pmx subshell oozie set dataset THRIFT_EDRHTTP attribute startOffset 12
pmx subshell oozie set dataset THRIFT_EDRHTTP attribute startTime 2015-01-15T02:00Z
#------------------
# PARQUET_EDRFLOW
#------------------
pmx subshell oozie add dataset PARQUET_EDRFLOW
pmx subshell oozie set dataset PARQUET_EDRFLOW attribute doneFile .*_DONE
pmx subshell oozie set dataset PARQUET_EDRFLOW attribute endOffset 1
pmx subshell oozie set dataset PARQUET_EDRFLOW attribute frequency 5
pmx subshell oozie set dataset PARQUET_EDRFLOW attribute inputStreamName MuralFLOW
pmx subshell oozie set dataset PARQUET_EDRFLOW attribute outputOffset 0
pmx subshell oozie set dataset PARQUET_EDRFLOW attribute path /data/collector/parquet/output/edrflow/%Y/%M/%D/%H/%mi
pmx subshell oozie set dataset PARQUET_EDRFLOW attribute pathType hdfs
pmx subshell oozie set dataset PARQUET_EDRFLOW attribute startOffset 12
pmx subshell oozie set dataset PARQUET_EDRFLOW attribute startTime 2015-01-15T02:00Z
#------------------
# PARQUET_EDRHTTP
#------------------
pmx subshell oozie add dataset PARQUET_EDRHTTP
pmx subshell oozie set dataset PARQUET_EDRHTTP attribute doneFile .*_DONE
pmx subshell oozie set dataset PARQUET_EDRHTTP attribute endOffset 1
pmx subshell oozie set dataset PARQUET_EDRHTTP attribute frequency 5
pmx subshell oozie set dataset PARQUET_EDRHTTP attribute inputStreamName MuralHTTP
pmx subshell oozie set dataset PARQUET_EDRHTTP attribute outputOffset 0
pmx subshell oozie set dataset PARQUET_EDRHTTP attribute path /data/collector/parquet/output/edrhttp/%Y/%M/%D/%H/%mi
pmx subshell oozie set dataset PARQUET_EDRHTTP attribute pathType hdfs
pmx subshell oozie set dataset PARQUET_EDRHTTP attribute startOffset 12
pmx subshell oozie set dataset PARQUET_EDRHTTP attribute startTime 2015-01-15T02:00Z
#------------------
# CRUX_BASE_CUBES
#------------------
pmx subshell oozie add dataset CRUX_BASE_CUBES
pmx subshell oozie set dataset CRUX_BASE_CUBES attribute doneFile _DONE
pmx subshell oozie set dataset CRUX_BASE_CUBES attribute endOffset 0
pmx subshell oozie set dataset CRUX_BASE_CUBES attribute frequency 60
pmx subshell oozie set dataset CRUX_BASE_CUBES attribute outputOffset 0
pmx subshell oozie set dataset CRUX_BASE_CUBES attribute path /data/output/CruxMuralBaseCubes/%Y/%M/%D/%H/
pmx subshell oozie set dataset CRUX_BASE_CUBES attribute pathType hdfs
pmx subshell oozie set dataset CRUX_BASE_CUBES attribute startOffset 0
pmx subshell oozie set dataset CRUX_BASE_CUBES attribute startTime 2015-01-15T02:00Z
#------------------
# INSTA_CUBES
#------------------
pmx subshell oozie add dataset INSTA_CUBES
pmx subshell oozie set dataset INSTA_CUBES attribute doneFile _DONE
pmx subshell oozie set dataset INSTA_CUBES attribute endOffset 0
pmx subshell oozie set dataset INSTA_CUBES attribute frequency 60
pmx subshell oozie set dataset INSTA_CUBES attribute outputOffset 0
pmx subshell oozie set dataset INSTA_CUBES attribute path /data/output/InstaBaseCubes/%Y/%M/%D/%H/
pmx subshell oozie set dataset INSTA_CUBES attribute pathType hdfs
pmx subshell oozie set dataset INSTA_CUBES attribute startOffset 0
pmx subshell oozie set dataset INSTA_CUBES attribute startTime 2015-01-15T02:00Z
#------------------
# CRUX_OPS_CUBES
#------------------
pmx subshell oozie add dataset CRUX_OPS_CUBES
pmx subshell oozie set dataset CRUX_OPS_CUBES attribute doneFile _DONE
pmx subshell oozie set dataset CRUX_OPS_CUBES attribute endOffset 0
pmx subshell oozie set dataset CRUX_OPS_CUBES attribute frequency 60
pmx subshell oozie set dataset CRUX_OPS_CUBES attribute outputOffset 0
pmx subshell oozie set dataset CRUX_OPS_CUBES attribute path /data/output/CruxAllOPS/%Y/%M/%D/%H/
pmx subshell oozie set dataset CRUX_OPS_CUBES attribute pathType hdfs
pmx subshell oozie set dataset CRUX_OPS_CUBES attribute startOffset 0
pmx subshell oozie set dataset CRUX_OPS_CUBES attribute startTime 2015-01-15T03:00Z
#------------------
# CUBE_1
#------------------
pmx subshell oozie add dataset CUBE_1
pmx subshell oozie set dataset CUBE_1 attribute doneFile .*_SUCCESS
pmx subshell oozie set dataset CUBE_1 attribute endOffset 0
pmx subshell oozie set dataset CUBE_1 attribute frequency 60
pmx subshell oozie set dataset CUBE_1 attribute inputStreamName RAT_DEV_URL
pmx subshell oozie set dataset CUBE_1 attribute outputOffset 0
pmx subshell oozie set dataset CUBE_1 attribute path /data/output/CruxMuralBaseCubes/%Y/%M/%D/%H/RAT_DEV_URL
pmx subshell oozie set dataset CUBE_1 attribute pathType hdfs
pmx subshell oozie set dataset CUBE_1 attribute startOffset 0
pmx subshell oozie set dataset CUBE_1 attribute startTime 2015-01-15T03:00Z
#------------------
# CUBE_2
#------------------
pmx subshell oozie add dataset CUBE_2
pmx subshell oozie set dataset CUBE_2 attribute doneFile .*_SUCCESS
pmx subshell oozie set dataset CUBE_2 attribute endOffset 0
pmx subshell oozie set dataset CUBE_2 attribute frequency 60
pmx subshell oozie set dataset CUBE_2 attribute inputStreamName RAT_DEV_APP
pmx subshell oozie set dataset CUBE_2 attribute outputOffset 0
pmx subshell oozie set dataset CUBE_2 attribute path /data/output/CruxMuralBaseCubes/%Y/%M/%D/%H/RAT_DEV_APP
pmx subshell oozie set dataset CUBE_2 attribute pathType hdfs
pmx subshell oozie set dataset CUBE_2 attribute startOffset 0
pmx subshell oozie set dataset CUBE_2 attribute startTime 2015-01-15T03:00Z
#------------------
# CUBE_3
#------------------
pmx subshell oozie add dataset CUBE_3
pmx subshell oozie set dataset CUBE_3 attribute doneFile .*_SUCCESS
pmx subshell oozie set dataset CUBE_3 attribute endOffset 0
pmx subshell oozie set dataset CUBE_3 attribute frequency 60
pmx subshell oozie set dataset CUBE_3 attribute inputStreamName APN_SEG_URL
pmx subshell oozie set dataset CUBE_3 attribute outputOffset 0
pmx subshell oozie set dataset CUBE_3 attribute path /data/output/CruxMuralBaseCubes/%Y/%M/%D/%H/APN_SEG_URL
pmx subshell oozie set dataset CUBE_3 attribute pathType hdfs
pmx subshell oozie set dataset CUBE_3 attribute startOffset 0
pmx subshell oozie set dataset CUBE_3 attribute startTime 2015-01-15T03:00Z
#------------------
# CUBE_4
#------------------
pmx subshell oozie add dataset CUBE_4
pmx subshell oozie set dataset CUBE_4 attribute doneFile .*_SUCCESS
pmx subshell oozie set dataset CUBE_4 attribute endOffset 0
pmx subshell oozie set dataset CUBE_4 attribute frequency 60
pmx subshell oozie set dataset CUBE_4 attribute inputStreamName APN_SEG_APP
pmx subshell oozie set dataset CUBE_4 attribute outputOffset 0
pmx subshell oozie set dataset CUBE_4 attribute path /data/output/CruxMuralBaseCubes/%Y/%M/%D/%H/APN_SEG_APP
pmx subshell oozie set dataset CUBE_4 attribute pathType hdfs
pmx subshell oozie set dataset CUBE_4 attribute startOffset 0
pmx subshell oozie set dataset CUBE_4 attribute startTime 2015-01-15T03:00Z
#------------------
# MR_BASE_CUBE
#------------------
pmx subshell oozie add dataset MR_BASE_CUBE
pmx subshell oozie set dataset MR_BASE_CUBE attribute doneFile _DONE
pmx subshell oozie set dataset MR_BASE_CUBE attribute endOffset 0
pmx subshell oozie set dataset MR_BASE_CUBE attribute frequency 60
pmx subshell oozie set dataset MR_BASE_CUBE attribute outputOffset 0
pmx subshell oozie set dataset MR_BASE_CUBE attribute path /data/output/AtlasBaseCubes/%Y/%M/%D/%H
pmx subshell oozie set dataset MR_BASE_CUBE attribute pathType hdfs
pmx subshell oozie set dataset MR_BASE_CUBE attribute startOffset 0
pmx subshell oozie set dataset MR_BASE_CUBE attribute startTime 2015-01-15T02:00Z
#------------------
# MR_ROLLUP
#------------------
pmx subshell oozie add dataset MR_ROLLUP
pmx subshell oozie set dataset MR_ROLLUP attribute doneFile _DONE
pmx subshell oozie set dataset MR_ROLLUP attribute endOffset 0
pmx subshell oozie set dataset MR_ROLLUP attribute frequency 60
pmx subshell oozie set dataset MR_ROLLUP attribute outputOffset 0
pmx subshell oozie set dataset MR_ROLLUP attribute path /data/output/AtlasRollupCubes/%Y/%M/%D/%H
pmx subshell oozie set dataset MR_ROLLUP attribute pathType hdfs
pmx subshell oozie set dataset MR_ROLLUP attribute startOffset 0
pmx subshell oozie set dataset MR_ROLLUP attribute startTime 2015-01-15T02:00Z
#------------------
# MR_SBUSCRIBERDEVICEMPH
#------------------
pmx subshell oozie add dataset MR_SBUSCRIBERDEVICEMPH
pmx subshell oozie set dataset MR_SBUSCRIBERDEVICEMPH attribute doneFile _DONE
pmx subshell oozie set dataset MR_SBUSCRIBERDEVICEMPH attribute endOffset 0
pmx subshell oozie set dataset MR_SBUSCRIBERDEVICEMPH attribute frequency 60
pmx subshell oozie set dataset MR_SBUSCRIBERDEVICEMPH attribute outputOffset 0
pmx subshell oozie set dataset MR_SBUSCRIBERDEVICEMPH attribute path /data/output/AtlasSubscriberDeviceMPH/%Y/%M/%D/%H
pmx subshell oozie set dataset MR_SBUSCRIBERDEVICEMPH attribute pathType hdfs
pmx subshell oozie set dataset MR_SBUSCRIBERDEVICEMPH attribute startOffset 0
pmx subshell oozie set dataset MR_SBUSCRIBERDEVICEMPH attribute startTime 2015-01-15T02:00Z
#------------------
# MR_SUBBYTES
#------------------
pmx subshell oozie add dataset MR_SUBBYTES
pmx subshell oozie set dataset MR_SUBBYTES attribute doneFile _DONE
pmx subshell oozie set dataset MR_SUBBYTES attribute endOffset 1
pmx subshell oozie set dataset MR_SUBBYTES attribute frequency 60
pmx subshell oozie set dataset MR_SUBBYTES attribute outputOffset 0
pmx subshell oozie set dataset MR_SUBBYTES attribute path /data/output/AtlasSubcrBytes/%Y/%M/%D/%H
pmx subshell oozie set dataset MR_SUBBYTES attribute pathType hdfs
pmx subshell oozie set dataset MR_SUBBYTES attribute startOffset 1
pmx subshell oozie set dataset MR_SUBBYTES attribute startTime 2015-01-15T02:00Z
#------------------
# MR_SUBDEV
#------------------
pmx subshell oozie add dataset MR_SUBDEV
pmx subshell oozie set dataset MR_SUBDEV attribute doneFile _DONE
pmx subshell oozie set dataset MR_SUBDEV attribute endOffset 0
pmx subshell oozie set dataset MR_SUBDEV attribute frequency 60
pmx subshell oozie set dataset MR_SUBDEV attribute outputOffset 0
pmx subshell oozie set dataset MR_SUBDEV attribute path /data/output/AtlasSubDev/%Y/%M/%D/%H
pmx subshell oozie set dataset MR_SUBDEV attribute pathType hdfs
pmx subshell oozie set dataset MR_SUBDEV attribute startOffset 0
pmx subshell oozie set dataset MR_SUBDEV attribute startTime 2015-01-15T02:00Z
#------------------
# MR_TOPN
#------------------
pmx subshell oozie add dataset MR_TOPN
pmx subshell oozie set dataset MR_TOPN attribute doneFile _DONE
pmx subshell oozie set dataset MR_TOPN attribute endOffset 0
pmx subshell oozie set dataset MR_TOPN attribute frequency 60
pmx subshell oozie set dataset MR_TOPN attribute outputOffset 0
pmx subshell oozie set dataset MR_TOPN attribute path /data/output/TopN/%Y/%M/%D/%H
pmx subshell oozie set dataset MR_TOPN attribute pathType hdfs
pmx subshell oozie set dataset MR_TOPN attribute startOffset 0
pmx subshell oozie set dataset MR_TOPN attribute startTime 2015-01-15T02:00Z
######################################
# Insta DataSets
######################################
# COLLECTOR_DUMP
#------------------
pmx subshell oozie add instaDataset COLLECTOR_DUMP
pmx subshell oozie set instaDataset COLLECTOR_DUMP attribute dbName crux_input
pmx subshell oozie set instaDataset COLLECTOR_DUMP attribute aggregationInterval 5
pmx subshell oozie set instaDataset COLLECTOR_DUMP attribute frequency 5
pmx subshell oozie set instaDataset COLLECTOR_DUMP attribute startTime 2015-01-15T02:00Z
pmx subshell oozie set instaDataset COLLECTOR_DUMP attribute startOffset 12
pmx subshell oozie set instaDataset COLLECTOR_DUMP attribute endOffset 1
pmx subshell oozie set instaDataset COLLECTOR_DUMP attribute frequencyUnit minute
#------------------
# INSTA_TO_INSTA
#------------------
pmx subshell oozie add instaDataset INSTA_TO_INSTA
pmx subshell oozie set instaDataset INSTA_TO_INSTA attribute dbName crux_input
pmx subshell oozie set instaDataset INSTA_TO_INSTA attribute aggregationInterval 60
pmx subshell oozie set instaDataset INSTA_TO_INSTA attribute frequency 60
pmx subshell oozie set instaDataset INSTA_TO_INSTA attribute startTime 2015-01-15T02:00Z
#------------------
# INSTA_BASE_CUBE
#------------------
pmx subshell oozie add instaDataset INSTA_BASE_CUBE
pmx subshell oozie set instaDataset INSTA_BASE_CUBE attribute dbName parquet_out
pmx subshell oozie set instaDataset INSTA_BASE_CUBE attribute aggregationInterval 3600
pmx subshell oozie set instaDataset INSTA_BASE_CUBE attribute frequency 60
pmx subshell oozie set instaDataset INSTA_BASE_CUBE attribute startTime 2015-01-15T02:00Z
#------------------
# INSTA_ROLLBACK_TEST
#------------------
pmx subshell oozie add instaDataset INSTA_ROLLBACK_TEST
pmx subshell oozie set instaDataset INSTA_ROLLBACK_TEST attribute dbName rollback_test
pmx subshell oozie set instaDataset INSTA_ROLLBACK_TEST attribute aggregationInterval 3600
pmx subshell oozie set instaDataset INSTA_ROLLBACK_TEST attribute binSource 60min
pmx subshell oozie set instaDataset INSTA_ROLLBACK_TEST attribute frequency 60
pmx subshell oozie set instaDataset INSTA_ROLLBACK_TEST attribute startTime 2015-01-15T02:00Z
######################################
# Oozie Jobs
######################################
#------------------
# CRUX-EDR
#------------------
pmx subshell oozie add job CRUX-EDR SparkEDRCubes /opt/etc/oozie/CruxEdr/
pmx subshell oozie set job CRUX-EDR attribute jobStart 2015-01-15T03:00Z
pmx subshell oozie set job CRUX-EDR attribute jobEnd 2015-01-15T06:00Z
pmx subshell oozie set job CRUX-EDR action SparkEDRAction attribute inputDatasets THRIFT_EDRHTTP
pmx subshell oozie set job CRUX-EDR action SparkEDRAction attribute inputDatasets THRIFT_EDRFLOW
pmx subshell oozie set job CRUX-EDR action SparkEDRAction attribute outputDatasets CRUX_BASE_CUBES
pmx subshell oozie set job CRUX-EDR action SparkEDRAction attribute jarFile local:/opt/tms/java/crux/crux-sample2.0-atlas3.4.jar
pmx subshell oozie set job CRUX-EDR action SparkEDRAction attribute mainClass com.guavus.crux.df.core.CruxMain
pmx subshell oozie set job CRUX-EDR action SparkEDRAction attribute sparkConfigFile /opt/etc/oozie/CruxEdr/spark.properties
pmx subshell oozie set job CRUX-EDR action SparkEDRAction attribute configFile /opt/etc/oozie/CruxEdr/crux.properties
pmx subshell oozie set job CRUX-EDR action SparkEDRAction attribute xmlConfigFile /opt/etc/oozie/CruxEdr/mural.xml
#------------------
# PARQUET-EDR
#------------------
pmx subshell oozie add job PARQUET-EDR SparkEDRCubes /opt/etc/oozie/CruxEdr/
pmx subshell oozie set job PARQUET-EDR attribute jobStart 2015-01-15T03:00Z
pmx subshell oozie set job PARQUET-EDR attribute jobEnd 2015-01-15T06:00Z
pmx subshell oozie set job PARQUET-EDR action SparkEDRAction attribute inputDatasets PARQUET_EDRHTTP
pmx subshell oozie set job PARQUET-EDR action SparkEDRAction attribute inputDatasets PARQUET_EDRFLOW
pmx subshell oozie set job PARQUET-EDR action SparkEDRAction attribute outputDatasets INSTA_BASE_CUBE
pmx subshell oozie set job PARQUET-EDR action SparkEDRAction attribute jarFile local:/opt/tms/java/crux/crux-sample2.0-atlas3.4.jar
pmx subshell oozie set job PARQUET-EDR action SparkEDRAction attribute mainClass com.guavus.crux.df.core.CruxMain
pmx subshell oozie set job PARQUET-EDR action SparkEDRAction attribute sparkConfigFile /opt/etc/oozie/CruxEdr/spark.properties
pmx subshell oozie set job PARQUET-EDR action SparkEDRAction attribute configFile /opt/etc/oozie/CruxEdr/crux.properties
pmx subshell oozie set job PARQUET-EDR action SparkEDRAction attribute xmlConfigFile /opt/etc/oozie/CruxEdr/parq_mural_to_insta.xml
#------------------
# CRUX-EXPORTER
#------------------
pmx subshell oozie add job CRUX-EXPORTER CruxExporterJob /opt/ooziecore/genericjobs/CruxExporter/
pmx subshell oozie set job CRUX-EXPORTER attribute jobStart 2015-01-15T03:00Z
pmx subshell oozie set job CRUX-EXPORTER attribute jobEnd 2015-01-15T06:00Z
pmx subshell oozie set job CRUX-EXPORTER attribute jobFrequency 60
pmx subshell oozie set job CRUX-EXPORTER action CruxExporterAction attribute aggregationInterval 3600
pmx subshell oozie set job CRUX-EXPORTER action CruxExporterAction attribute appDefinition /opt/etc/oozie/CruxEdr/mural.xml
pmx subshell oozie set job CRUX-EXPORTER action CruxExporterAction attribute binInterval 3600
pmx subshell oozie set job CRUX-EXPORTER action CruxExporterAction attribute className com.guavus.crux.exporter.CruxExporter
pmx subshell oozie set job CRUX-EXPORTER action CruxExporterAction attribute cruxProperties /opt/etc/oozie/CruxEdr/crux.properties
pmx subshell oozie set job CRUX-EXPORTER action CruxExporterAction attribute fileType Seq
pmx subshell oozie set job CRUX-EXPORTER action CruxExporterAction attribute instaHost 192.168.160.216
pmx subshell oozie set job CRUX-EXPORTER action CruxExporterAction attribute instaPort 11111
pmx subshell oozie set job CRUX-EXPORTER action CruxExporterAction attribute jarName /opt/tms/java/crux2.0-atlas3.4-jar-with-dependencies.jar
pmx subshell oozie set job CRUX-EXPORTER action CruxExporterAction attribute maxTimeout -1
pmx subshell oozie set job CRUX-EXPORTER action CruxExporterAction attribute minTimeout -1
pmx subshell oozie set job CRUX-EXPORTER action CruxExporterAction attribute retrySleep 300
pmx subshell oozie set job CRUX-EXPORTER action CruxExporterAction attribute solutionName atlas
pmx subshell oozie set job CRUX-EXPORTER action CruxExporterAction attribute srcDatasets CRUX_BASE_CUBES
#------------------
# CRUX-OPS
#------------------
pmx subshell oozie add job CRUX-OPS SparkEDRCubes /opt/etc/oozie/CruxEdr/
pmx subshell oozie set job CRUX-OPS attribute jobStart 2015-01-15T03:00Z
pmx subshell oozie set job CRUX-OPS attribute jobEnd 2015-01-15T06:00Z
pmx subshell oozie set job CRUX-OPS action SparkEDRAction attribute inputDatasets CUBE_1
pmx subshell oozie set job CRUX-OPS action SparkEDRAction attribute inputDatasets CUBE_2
pmx subshell oozie set job CRUX-OPS action SparkEDRAction attribute inputDatasets CUBE_3
pmx subshell oozie set job CRUX-OPS action SparkEDRAction attribute inputDatasets CUBE_4
pmx subshell oozie set job CRUX-OPS action SparkEDRAction attribute outputDatasets CRUX_OPS_CUBES
pmx subshell oozie set job CRUX-OPS action SparkEDRAction attribute jarFile local:/opt/tms/java/crux/crux-sample2.0-atlas3.4.jar
pmx subshell oozie set job CRUX-OPS action SparkEDRAction attribute mainClass com.guavus.crux.df.core.CruxMain
pmx subshell oozie set job CRUX-OPS action SparkEDRAction attribute sparkConfigFile /opt/etc/oozie/CruxEdr/spark.properties
pmx subshell oozie set job CRUX-OPS action SparkEDRAction attribute configFile /opt/etc/oozie/CruxEdr/crux.properties
pmx subshell oozie set job CRUX-OPS action SparkEDRAction attribute xmlConfigFile /opt/etc/oozie/CruxEdr/crux-operations.xml
#------------------
# COLLECTOR-TO-INSTA
#------------------
pmx subshell oozie add job COLLECTOR-TO-INSTA SparkEDRCubes /opt/etc/oozie/CruxEdr/
pmx subshell oozie set job COLLECTOR-TO-INSTA attribute jobStart 2015-01-15T02:05Z
pmx subshell oozie set job COLLECTOR-TO-INSTA attribute jobEnd 2015-01-15T03:05Z
pmx subshell oozie set job COLLECTOR-TO-INSTA attribute binInterval 300
pmx subshell oozie set job COLLECTOR-TO-INSTA attribute jobFrequency 5
pmx subshell oozie set job COLLECTOR-TO-INSTA action SparkEDRAction attribute inputDatasets THRIFT_EDRHTTP
pmx subshell oozie set job COLLECTOR-TO-INSTA action SparkEDRAction attribute inputDatasets THRIFT_EDRFLOW
pmx subshell oozie set job COLLECTOR-TO-INSTA action SparkEDRAction attribute outputDatasets COLLECTOR_DUMP
pmx subshell oozie set job COLLECTOR-TO-INSTA action SparkEDRAction attribute jarFile local:/opt/tms/java/crux/crux-sample2.0-atlas3.4.jar
pmx subshell oozie set job COLLECTOR-TO-INSTA action SparkEDRAction attribute mainClass com.guavus.crux.df.core.CruxMain
pmx subshell oozie set job COLLECTOR-TO-INSTA action SparkEDRAction attribute sparkConfigFile /opt/etc/oozie/CruxEdr/spark.properties
pmx subshell oozie set job COLLECTOR-TO-INSTA action SparkEDRAction attribute configFile /opt/etc/oozie/CruxEdr/crux.properties
pmx subshell oozie set job COLLECTOR-TO-INSTA action SparkEDRAction attribute xmlConfigFile /opt/etc/oozie/CruxEdr/collector_to_insta.xml
#------------------
# INSTA-EDR
#------------------
pmx subshell oozie add job INSTA-EDR SparkEDRCubes /opt/etc/oozie/CruxEdr/
pmx subshell oozie set job INSTA-EDR attribute jobStart 2015-01-15T03:00Z
pmx subshell oozie set job INSTA-EDR attribute jobEnd 2015-01-15T04:00Z
pmx subshell oozie set job INSTA-EDR action SparkEDRAction attribute inputDatasets COLLECTOR_DUMP
pmx subshell oozie set job INSTA-EDR action SparkEDRAction attribute outputDatasets INSTA_TO_INSTA
pmx subshell oozie set job INSTA-EDR action SparkEDRAction attribute jarFile local:/opt/tms/java/crux/crux-sample2.0-atlas3.4.jar
pmx subshell oozie set job INSTA-EDR action SparkEDRAction attribute mainClass com.guavus.crux.df.core.CruxMain
pmx subshell oozie set job INSTA-EDR action SparkEDRAction attribute sparkConfigFile /opt/etc/oozie/CruxEdr/spark.properties
pmx subshell oozie set job INSTA-EDR action SparkEDRAction attribute configFile /opt/etc/oozie/CruxEdr/crux.properties
pmx subshell oozie set job INSTA-EDR action SparkEDRAction attribute xmlConfigFile /opt/etc/oozie/CruxEdr/insta_mural.xml
#------------------
# INSTA-FROM-XML
#------------------
pmx subshell oozie add job INSTA-FROM-XML SparkEDRCubes /opt/etc/oozie/CruxEdr/
pmx subshell oozie set job INSTA-FROM-XML attribute jobStart 2015-01-15T03:00Z
pmx subshell oozie set job INSTA-FROM-XML attribute jobEnd 2015-01-15T06:00Z
pmx subshell oozie set job INSTA-FROM-XML action SparkEDRAction attribute inputDatasets PARQUET_EDRHTTP
pmx subshell oozie set job INSTA-FROM-XML action SparkEDRAction attribute inputDatasets PARQUET_EDRFLOW
pmx subshell oozie set job INSTA-FROM-XML action SparkEDRAction attribute outputDatasets INSTA_ROLLBACK_TEST
pmx subshell oozie set job INSTA-FROM-XML action SparkEDRAction attribute jarFile local:/opt/tms/java/crux/crux-sample2.0-atlas3.4.jar
pmx subshell oozie set job INSTA-FROM-XML action SparkEDRAction attribute mainClass com.guavus.crux.df.core.CruxMain
pmx subshell oozie set job INSTA-FROM-XML action SparkEDRAction attribute sparkConfigFile /opt/etc/oozie/CruxEdr/spark.properties
pmx subshell oozie set job INSTA-FROM-XML action SparkEDRAction attribute configFile /opt/etc/oozie/CruxEdr/crux2.properties
pmx subshell oozie set job INSTA-FROM-XML action SparkEDRAction attribute xmlConfigFile /opt/etc/oozie/CruxEdr/insta_from_xml_test.xml
#------------------
# MR-EDR
#------------------
pmx subshell oozie add job MR-EDR EDRCubes /opt/etc/oozie/EDRCubes/
pmx subshell oozie set job MR-EDR attribute jobStart 2015-01-15T03:00Z
pmx subshell oozie set job MR-EDR attribute jobEnd 2015-01-15T06:00Z
pmx subshell oozie set job MR-EDR attribute jobFrequency 60
pmx subshell oozie set job MR-EDR action EDRBaseCubes attribute binaryInput true
pmx subshell oozie set job MR-EDR action EDRBaseCubes attribute inputDatasets THRIFT_EDRHTTP
pmx subshell oozie set job MR-EDR action EDRBaseCubes attribute inputDatasets THRIFT_EDRFLOW
pmx subshell oozie set job MR-EDR action EDRBaseCubes attribute jarFile /opt/tms/java/CubeCreator-atlas3.4.jar
pmx subshell oozie set job MR-EDR action EDRBaseCubes attribute mainClass com.guavus.mapred.atlas.job.EdrJob.EdrCubes
pmx subshell oozie set job MR-EDR action EDRBaseCubes attribute outputDataset MR_BASE_CUBE
pmx subshell oozie set job MR-EDR action EDRBaseCubes attribute override_ibs true
pmx subshell oozie set job MR-EDR action Rollup attribute inputDatasets MR_BASE_CUBE
pmx subshell oozie set job MR-EDR action Rollup attribute jarFile /opt/tms/java/CubeCreator-atlas3.4.jar
pmx subshell oozie set job MR-EDR action Rollup attribute mainClass com.guavus.mapred.atlas.job.rollup.Main
pmx subshell oozie set job MR-EDR action Rollup attribute outputDataset MR_ROLLUP
pmx subshell oozie set job MR-EDR action Rollup attribute timeout -1
pmx subshell oozie set job MR-EDR action Rollup attribute topnDataset MR_TOPN
pmx subshell oozie set job MR-EDR action SubcrBytesAgg attribute inputDatasets MR_BASE_CUBE
pmx subshell oozie set job MR-EDR action SubcrBytesAgg attribute jarFile /opt/tms/java/CubeCreator-atlas3.4.jar
pmx subshell oozie set job MR-EDR action SubcrBytesAgg attribute mainClass com.guavus.mapred.atlas.job.SubscriberBytesAggregator.SubscriberBytesAggregator
pmx subshell oozie set job MR-EDR action SubcrBytesAgg attribute outputDataset MR_SUBBYTES
pmx subshell oozie set job MR-EDR action SubcrBytesAgg attribute snapshotDatasets MR_SUBBYTES
pmx subshell oozie set job MR-EDR action SubcrBytesAgg attribute timeout 0
pmx subshell oozie set job MR-EDR action SubcrDev attribute inputDatasets MR_BASE_CUBE
pmx subshell oozie set job MR-EDR action SubcrDev attribute jarFile /opt/tms/java/CubeCreator-atlas3.4.jar
pmx subshell oozie set job MR-EDR action SubcrDev attribute mainClass com.guavus.mapred.atlas.job.subdevmapib.SubDevMapIBCreator
pmx subshell oozie set job MR-EDR action SubcrDev attribute outputDataset MR_SUBDEV
pmx subshell oozie set job MR-EDR action SubcrDev attribute timeout 0
pmx subshell oozie set job MR-EDR action SubscriberDeviceMPH attribute Interval 24
pmx subshell oozie set job MR-EDR action SubscriberDeviceMPH attribute inputDataset MR_SUBDEV
pmx subshell oozie set job MR-EDR action SubscriberDeviceMPH attribute outputDataset MR_SBUSCRIBERDEVICEMPH
pmx subshell oozie set job MR-EDR action TopN attribute inputDatasets MR_BASE_CUBE
pmx subshell oozie set job MR-EDR action TopN attribute jarFile /opt/tms/java/CubeCreator-atlas3.4.jar
pmx subshell oozie set job MR-EDR action TopN attribute mainClass com.guavus.mapred.atlas.job.TopNJob.TopN
pmx subshell oozie set job MR-EDR action TopN attribute outputDataset MR_TOPN
pmx subshell oozie set job MR-EDR action TopN attribute timeout 0
pmx subshell oozie set job MR-EDR action TopN attribute topApp 100
pmx subshell oozie set job MR-EDR action TopN attribute topDev 200
pmx subshell oozie set job MR-EDR action TopN attribute topSP 100
pmx subshell oozie set job MR-EDR action TopN attribute topTTApp 100
pmx subshell oozie set job MR-EDR action TopN attribute topUnCatTACs 100
pmx subshell oozie set job MR-EDR action TopN attribute topUnCatUAs 1000
pmx subshell oozie set job MR-EDR action TopN attribute topUnCatUrls 1000
#------------------
# CUBE-EXPORTER
#------------------
pmx subshell oozie add job CUBE-EXPORTER ExporterJob /opt/ooziecore/genericjobs/CubeExporter/
pmx subshell oozie set job CUBE-EXPORTER attribute jobStart 2015-01-15T03:00Z
pmx subshell oozie set job CUBE-EXPORTER attribute jobEnd 2015-01-15T06:00Z
pmx subshell oozie set job CUBE-EXPORTER attribute jobFrequency 60
pmx subshell oozie set job CUBE-EXPORTER action ExporterAction attribute aggregationInterval 3600
pmx subshell oozie set job CUBE-EXPORTER action ExporterAction attribute binInterval 3600
pmx subshell oozie set job CUBE-EXPORTER action ExporterAction attribute className com.guavus.exporter.Exporter
pmx subshell oozie set job CUBE-EXPORTER action ExporterAction attribute fileType Seq
pmx subshell oozie set job CUBE-EXPORTER action ExporterAction attribute instaHost 192.168.160.216
pmx subshell oozie set job CUBE-EXPORTER action ExporterAction attribute instaPort 22222
pmx subshell oozie set job CUBE-EXPORTER action ExporterAction attribute jarName /opt/tms/java/mapred-crux.jar
pmx subshell oozie set job CUBE-EXPORTER action ExporterAction attribute maxTimeout -1
pmx subshell oozie set job CUBE-EXPORTER action ExporterAction attribute minTimeout -1
pmx subshell oozie set job CUBE-EXPORTER action ExporterAction attribute retrySleep 100
pmx subshell oozie set job CUBE-EXPORTER action ExporterAction attribute solutionName atlas
pmx subshell oozie set job CUBE-EXPORTER action ExporterAction attribute srcDatasets MR_ROLLUP


no ntp disable
no ntp server 123.108.225.6
ntp server 123.108.225.6 version 4
ntpdate 123.108.225.6

configuration write
EOF

nameNodes="192.168.160.213 192.168.160.214"
for vm in ${nameNodes[@]}
do
	scp  $SSH_OPTIONS ${nameNodeConfig} admin@$vm:/data/config.cfg
	ssh  $SSH_OPTIONS -l root $vm 'cat /data/config.cfg | /opt/tms/bin/cli -m config'
	sleep 5
done

}

#-------------------------------------------------------
# Function to setup Datanodes for
# 1. Hostnames Mapping
# 2. Keys sharing
#
# Check var dataNodes inside this function
# for list of dataNodes (hard coded)
#
#-------------------------------------------------------

setupDataNodes(){
	cat<<EOF >${dataNodeConfig}
ssh client user admin authorized-key sshv2 "${key89}"
ssh client user admin authorized-key sshv2 "${key90}"
ssh client user admin authorized-key sshv2 "${key213}"
ssh client user admin authorized-key sshv2 "${key214}"
ssh client user admin authorized-key sshv2 "${keyLaptop}"
ip default-gateway 192.168.160.1
ip host CRUX-SANITY 192.168.160.217
ip host YARN-NN-1 192.168.160.213
ip host YARN-NN-2 192.168.160.214
ip host YARN-DN-1 192.168.160.215
ip host YARN-DN-2 192.168.160.216
no ntp disable
no ntp server 123.108.225.6
ntp server 123.108.225.6 version 4
ntpdate 123.108.225.6
configuration write
EOF
dataNodes="192.168.160.215 192.168.160.216"
for vm in ${dataNodes[@]}
do
	scp  $SSH_OPTIONS $dataNodeConfig admin@$vm:/data/config.cfg
	ssh  $SSH_OPTIONS -l root $vm 'cat /data/config.cfg | /opt/tms/bin/cli -m config'
done
}

#-------------------------------------------------------
# Function to run a tps restart once all the required
# configs are done on each node of cluster
#-------------------------------------------------------


startYarnCluster() {

	ssh  $SSH_OPTIONS -l root 192.168.160.215 'echo -e "hostname YARN-DN-1\nconf w" | /opt/tms/bin/cli -m config'
	ssh  $SSH_OPTIONS -l root 192.168.160.216 'echo -e "hostname YARN-DN-2\nconf w" | /opt/tms/bin/cli -m config'
	ssh  $SSH_OPTIONS -l root 192.168.160.213 'echo -e "hostname YARN-NN-1\nconf w" | /opt/tms/bin/cli -m config'
	ssh  $SSH_OPTIONS -l root 192.168.160.213 'echo "cluster enable" | /opt/tms/bin/cli -m config'
	ssh  $SSH_OPTIONS -l root 192.168.160.213 'echo "pm process tps restart" | /opt/tms/bin/cli -m config'
	ssh  $SSH_OPTIONS -l root 192.168.160.214 'echo -e "hostname YARN-NN-2\nconf w" | /opt/tms/bin/cli -m config'
	ssh  $SSH_OPTIONS -l root 192.168.160.214 'echo "cluster enable" | /opt/tms/bin/cli -m config'
	ssh  $SSH_OPTIONS -l root 192.168.160.214 'echo "pm process tps restart" | /opt/tms/bin/cli -m config'
	ssh  $SSH_OPTIONS -l root 192.168.160.213 'echo "tps sparksql stop" | /opt/tms/bin/cli -m config'
	ssh  $SSH_OPTIONS -l root 192.168.160.214 'echo "tps sparksql stop" | /opt/tms/bin/cli -m config'

}


#-------------------------------------------------------
# Function to generate a script which will be copied
# on cluster master and will monitor oozie jobs
# will send emails for job status and will also
# report error if oozie server didnt start any job
#-------------------------------------------------------


setupMailConfiguration(){
cat<<EOF >$emailSetup
export TZ="Asia/Kolkata"
admin="${admin}"
recipient="${recipient}"

oozie="/opt/oozie/bin/oozie"
oozieServerUrl="http://127.0.0.1:8080/oozie"
oozieUrl="http://192.168.160.217:8080/oozie"
jobSetupDone=\$(date +"%s")
sendFullStatusAt=\$(date --date '+2 hour' +"%s")
selfIP=\$(ifconfig | grep -w inet | grep '192.168.160' | grep -v '\.217' | awk '{print \$2}' | cut -d ':' -f2)


#-------------------------------------------------------
# Function to populate sendemail configuration
# using clis ,required for sending emails from shell script
#-------------------------------------------------------

emailSettings(){
echo "
ip name-server 204.232.241.167 
email autosupport recipient abhishek.choudhary@guavus.com
email mailhub 192.168.104.25
no email notify event CIL-input-file-received-alarm
no email notify event HDFS-namenode-status
no email notify event anomaly-count-exceed
no email notify event clear-link-util-exceed
no email notify event cluster-join
no email notify event cluster-leave
no email notify event cluster-role-master
no email notify event cluster-role-standby-normal
no email notify event cmc-new-client
no email notify event cmc-status-failure
no email notify event cmc-status-ok
no email notify event cmc-version-mismatch
no email notify event collector-data-resume
no email notify event collector-dropped-flow-alarm-cleared
no email notify event collector-dropped-flow-thres-crossed
no email notify event collector-peak-flow-alarm-cleared
no email notify event collector-peak-flow-thres-crossed
no email notify event collector-resume-interface-input
no email notify event cpu-util-high
no email notify event cpu-util-ok
no email notify event data-process-time-exceeded
no email notify event data-process-time-exceeded-alarm-cleared
no email notify event data-receive-fail-alarm-cleared
no email notify event data-receive-failed
no email notify event data-transfer-fail-alarm-cleared
no email notify event data-transfer-failed
no email notify event data-transfer-stall
no email notify event data-transfer-stall-alarm-cleared
no email notify event disk-io-high
no email notify event disk-io-ok
no email notify event disk-space-low
no email notify event disk-space-ok
no email notify event drbd-setprimary-failed
no email notify event file-record-count-mismatch-trap
no email notify event file-record-count-mismatch-trap-clear
no email notify event file-sequence-missed-trap
no email notify event file-sequence-missed-trap-clear
no email notify event file-unzip-error-trap
no email notify event file-unzip-error-trap-clear
no email notify event gms-reconfig-failed-clear
no email notify event gms-reconfig-failed-raise
no email notify event input-data-available-trap-cleared
no email notify event input-data-incomplete-trap
no email notify event input-data-missing-task-failed
no email notify event input-data-missing-task-ok
no email notify event input-data-not-usable-task-failed
no email notify event input-data-not-usable-task-ok
no email notify event insta-adaptor-down
no email notify event insta-adaptor-up
no email notify event insta-backup-status
no email notify event insta-backup-status-clear
no email notify event invalid-record-thresh-cleared
no email notify event invalid-record-thresh-trap
no email notify event link-util-exceed
no email notify event liveness-failure
no email notify event long-time-taken-to-transfer-data
no email notify event long-time-taken-to-transfer-data-alarm-cleared
no email notify event low-threshold-input-data-trap-cleared
no email notify event low-threshold-input-data-trap-raised
no email notify event lun-all-paths-down
no email notify event lun-all-paths-ok
no email notify event memusage-high
no email notify event memusage-ok
no email notify event netusage-high
no email notify event netusage-ok
no email notify event new-arca-anomaly
no email notify event no-collector-data
no email notify event no-collector-interface-input
no email notify event ntp-sync-loss
no email notify event ntp-sync-loss-clear
no email notify event paging-high
no email notify event paging-ok
no email notify event pgsql-basebackup-fail
no email notify event pgsql-basebackup-ok
no email notify event pgsql-startup-fail
no email notify event pgsql-startup-ok
no email notify event pgsql-streaming-replication-fail
no email notify event pgsql-streaming-replication-ok
no email notify event process-crash
no email notify event process-crash-relaunched
no email notify event process-exit
no email notify event process-liveness-relaunched
no email notify event process-relaunched
no email notify event received-data-validation-fail
no email notify event received-data-validation-success
no email notify event received-fs-mount-failed-alarm
no email notify event received-fs-mount-ok-alarm
no email notify event received-mountpoint-readonly-alarm
no email notify event received-mountpoint-readonly-clear-alarm
no email notify event rubix-adaptive-eviction-finished
no email notify event rubix-adaptive-eviction-trigerred
no email notify event smart-warning
no email notify event snmp-authtrap
no email notify event test-mail
no email notify event test-trap
no email notify event tps-drbd-down-clear
no email notify event tps-drbd-down-raise
no email notify event unexpected-cluster-join
no email notify event unexpected-cluster-leave
no email notify event unexpected-cluster-size
no email notify event unexpected-shutdown
no email notify event user-login
no email notify event user-logout
no email notify event using-empty-IB-trap
no email notify event valid-IB-available-trap
email notify recipient abhishek.choudhary@guavus.com class failure
email notify recipient abhishek.choudhary@guavus.com class info
email notify recipient abhishek.choudhary@guavus.com detail
email return-addr abhishek.choudhary@guavus.com
"
}

emailSettings | $cli

#-------------------------------------------------------
# Function to send an error email when no job was submitted
# to oozie once cluster is manufactured
#-------------------------------------------------------

noJobErrorEmail(){
subject="Error: No Job Started yet on oozie"
if [[ \$selfIP = "$standbyIP" ]];then
	subject="\$subject After SwitchOver"
fi
cat<<EOF1 | sendmail -t
From:AutoMated Crux Sanity<\$admin>
To:\$recipient
Subject: \$subject

Please Check oozie setup. Looks like some config issue.

Regards
AutoMated Crux Sanity
EOF1
}

#-------------------------------------------------------
# Function to send a job status email
#-------------------------------------------------------


jobStatusEmail(){
{
subject="Job:\$1 Status \$2"
if [[ \$selfIP = "$standbyIP" ]];then
	subject="\$subject After SwitchOver"
fi

printf '%s\n' "From:AutoMated Crux Sanity<\$admin>
To: \$recipient
Subject: \$subject

"
if [[ \$2 = "KILLED" ]];then
printf '%s\n' "
Error in Oozie Job :-

\$temp
"
else
printf '%s\n' "
Job = \$1
Final Status = \$2
Oozie Job Id = \$3
"
fi
printf '%s\n' "
Command for detailed status

--------------------------------------------
Command:
\$oozie job -info \$3 -oozie \$oozieUrl
--------------------------------------------

Please Check Manually Now !!!

Regards
AutoMated Crux Sanity
"
} | sendmail -t

}

get_mimetype(){
file --mime-type "\$1" | sed 's/.*: //'
}


checkIfSanityFailed(){

	getOozieDetailedDump

	grep -E '^000|Job Name' detailed.txt | awk '{if(NF==4){jobName=\$NF} else{print jobName" "\$2} }' | sort -u >.process.txt

	while read line;do
		jobStatus=\$(echo "\$line" | awk '{print \$2}')
		if [[ \$jobStatus = "KILLED" ]];then
			return 1
		fi
	done<.process.txt
	return 0
}

getOozieDetailedDump(){
>.status.txt
>detailed.txt

output=\$(\$oozie jobs -jobtype coordinator status -oozie \$oozieServerUrl | grep '^00')
echo "\$output" | \
while read line;do
	jobId=\$(echo \$line | awk '{print \$1}')
	temp=\$(\$oozie job -info \$jobId -oozie \$oozieServerUrl)
	{
		echo "\$temp" | sed '1d'
		echo ""
		echo ""
	}>>detailed.txt

	jobName=\$(echo "\$temp" | grep -E '^(Workflow|Job) Name' | awk '{print \$NF}')
	jobStatus=\$(echo "\$temp" | grep -E '^Status' | awk '{print \$NF}')
	echo "\$jobName \$jobStatus" >>.status.txt
done
}

sendDetailedEmail() {

sts=\$1


if [[ \$sts = 0 ]];then
	subject="Sanity Passed : Detailed Status \$(date +"%d-%b-%Y %H:%M")"
	echo "COMPLETED" > /var/home/root/.sanity
	yarn application -list -appStates ALL | grep '^application' | awk '{print \$1}' | while read line;do
		mkdir -p /data/sanityLogs/\$line
		yarn logs -applicationId \$line > /data/sanityLogs/\$line/log.txt
	done
elif [[ \$sts = 1 ]];then
	subject="Sanity Failed : Detailed Status \$(date +"%d-%b-%Y %H:%M")"
	echo "FAILED" > /var/home/root/.sanity
	yarn application -list -appStates ALL | grep '^application' | awk '{print \$1}' | while read line;do
		mkdir -p /data/sanityLogs/\$line
		yarn logs -applicationId \$line > /data/sanityLogs/\$line/log.txt
	done
else
	subject="Update: Sanity Detailed Status \$(date +"%d-%b-%Y %H:%M")"
fi

if [[ \$selfIP = "$standbyIP" ]];then
	subject="\$subject After SwitchOver"
fi

getOozieDetailedDump

boundary="ZZ_/afg6432dfgkl.94531q"

declare -a attachments
attachments=( "detailed.txt" )
local recipient="\${recipient}"
{
printf '%s\n' "From:AutoMated Crux Sanity<\$admin>
To: \$recipient
Subject: \$subject
Mime-Version: 1.0
Content-Type: multipart/mixed; boundary=\"\$boundary\"

--\${boundary}
Content-Type: text/plain; charset=\"US-ASCII\"
Content-Transfer-Encoding: 7bit
Content-Disposition: inline

All jobs were started at: \$(date -d@\$jobSetupDone +"%d-%b-%Y %H:%M")

Detailed Status at : \$(date -d@\$sendFullStatusAt +"%d-%b-%Y %H:%M")

All Oozie Coordinator Jobs Summary:
"

awk '
	BEGIN{ \\
		maxWidth=30; \\
		space=" "; \\
		border=sprintf("+%"maxWidth+1"s+%"maxWidth+1"s+",space,space); \\
		print sepLine; \\
		gsub(/ /,"-",border); \\
		print border; \\
		rowFormat="| %-"maxWidth"s| %-"maxWidth"s|\n"; \\
		printf rowFormat,"Job Name","Status"; \\
		print border; \\
	}\\
	{\\
		printf rowFormat,\$1,\$2; \\
	}\\
	END{\\
		print border; \\
	}\\
' .status.txt

printf '%s\n' "

Jobs Description :-

	MR-EDR             - Mural Job using MR framework (Yarn only)
	CUBE-EXPORTER      - Mural Cube Exporter
	CRUX-EDR           - Mural Crux job on thrift :input and sequnce-file :output
	CRUX-OPS           - Dummy Job to test all crux operations sequence-file :input and sequnce-file :output
	CRUX-EXPORTER      - Crux Exporter on sequnce file
	PARQUET-EDR        - Mural Crux job for parquet-in :input and insta-out :output
	COLLECTOR-TO-INSTA - Crux job to test thrift :input and insta-out :output
	INSTA-EDR          - Crux job to test insta-in :input and insta-out :output
	INSTA-FROM-XML     - Crux job to test from-xml feature parquet-in :input and insta-out :output

Status Meaning :-

	SUCCEEDED     - All workflow were good
	KILLED        - All workflows failed / Stopped manually (Check them again)
	DONEWITHERROR - Few workflow failed. (Check attached detailed status)
	RUNNING       - Something is stuck. Check manually Now

-----------------------------------------
Setup Image Details:
-----------------------------------------

"

echo "show version" | $cli

printf '%s\n' "

------------------------------------------------------------------------------
Note :  For Detailed debugging use jobIDs mentioned in attached file.
------------------------------------------------------------------------------


Regards
AutoMated Crux Sanity
"

for file in "\${attachments[@]}"; do

[ ! -f "\$file" ] && echo "Warning: attachment \$file not found, skipping" >&2 && continue

mimetype=\$(get_mimetype "\$file")

printf '%s\n' "--\${boundary}
Content-Type: $mimetype
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename=\"\$file\"
"

base64 "\$file"
echo
done

# print last boundary with closing --
printf '%s\n' "--\${boundary}--"

}| sendmail -t -oi


}

checkAnyJobRunning() {
	isAnyJobRunning=\$(\$oozie jobs -jobtype coordinator -filter status=RUNNING status -oozie \$oozieUrl | awk '{print \$1}' | tr '[a-z]' '[A-Z]'| head -1)
	if [[ \$isAnyJobRunning = "NO" ]];then
		return 0
	else
		return 1
	fi
}


runHAScenario() {
	isAnyJobRunning=\$(\$oozie jobs -jobtype coordinator -filter status=RUNNING status -oozie \$oozieUrl | awk '{print \$1}' | tr '[a-z]' '[A-Z]'| head -1)
	if [[ \$isAnyJobRunning = "NO" ]];then

		if checkIfSanityFailed ;then
			sendDetailedEmail 0
		else
			sendDetailedEmail 1
		fi

		echo "subshell oozie rollback job PARQUET-EDR" | $pmx
		if [[ \$imageVersion != "4.2"* ]];then
			echo "subshell oozie rollback job INSTA-FROM-XML" | $pmx
		fi
		ssh $SSH_OPTIONS -l root $standbyIP 'sh /var/home/root/checkJobStatus.sh </dev/null >/data/acumeSetupHas.log 2>&1 &'
		ssh $SSH_OPTIONS -l root $standbyIP  'sh /var/home/root/acumeSetup.sh </dev/null >/data/acumeSetupHas.log 2>&1 &'
		echo "reload" | $cli
		exit
	fi
}

main() {

	grep -q 'FromLineOverride=YES' /etc/ssmtp.conf
	if [[ \$? -ne 0 ]];then
		echo "FromLineOverride=YES" >>/etc/ssmtp.conf
	fi
	sentFullStatus="false"
	ignoreJobIds=\`mktemp\`
	imageVersion=\$(echo "show version" | $cli  | grep 'Product release' | awk '{print \$3}')
	echo "000000-dummy-oozie-admin-W">\$ignoreJobIds
	TOTAL_OOZIE_JOB_RETRY=5
	jobNotFound=0
	while [[ 1 ]];do
		sendStatus="true"
		noJobEmailDone="false"
		output=\$(\$oozie jobs -jobtype coordinator status -oozie \$oozieServerUrl | grep '^00')
		if [[ \$output = "" ]];then
			sendStatus="false"
			if [[ \$jobNotFound -gt \$TOTAL_OOZIE_JOB_RETRY ]] && [[ \$noJobEmailDone = "false" ]];then
				noJobErrorEmail
				noJobEmailDone="true"
				jobNotFound=0
			else
				jobNotFound=\$(( \$jobNotFound + 1 ))
			fi
			sleep 5m
			continue
		fi
		echo "\$output"  | grep -vEw "\`cat \${ignoreJobIds}\`" | \
		while read line;do
			jobId=\$(echo \$line | awk '{print \$1}')
			temp=\$(\$oozie job -info \$jobId -oozie \$oozieServerUrl)
			jobName=\$(echo "\$temp" | grep -E '^(Workflow|Job) Name' | awk '{print \$NF}')
			jobStatus=\$(echo "\$temp" | grep -E '^Status' | awk '{print \$NF}')
			if [[ \$jobStatus != "RUNNING" ]] && [[ \$jobStatus != "SUCCEEDED" ]] && [[ \$jobStatus != "" ]];then
				jobStatusEmail \$jobName \$jobStatus \$jobId
				echo "\$(cat \${ignoreJobIds})|\${jobId}">\$ignoreJobIds
			fi
		done

		if [[ \$(date +"%s") -gt \$sendFullStatusAt  &&  \$sendStatus != "false" && \$sentFullStatus = "false" ]];then
			sentFullStatus="true"
			sendDetailedEmail
		elif checkAnyJobRunning && [[ \$sentFullStatus = "false" ]] ;then
			sentFullStatus="true"
			if checkIfSanityFailed ;then
				sendDetailedEmail 0
			else
				sendDetailedEmail 1
			fi
		fi

		if [[ \$(date +"%s") -gt \$sendFullStatusAt || checkAnyJobRunning ]] && [[ \$selfIP != "$standbyIP" ]];then
			echo "Not Running HA Scenario"
                        #runHAScenario
		fi

		sleep 5
	done
}
main &
exit 0
EOF
}

generateHBaseUpdateScript() {
cat <<EOF1 >updateForHbase.sh
#!/bin/bash
SSH_OPTIONS="-q -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
sh /opt/hbase/bin/stop-hbase.sh
mount -o remount,rw /
SSH_OPTIONS="-q -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
# HBase configurations
rm -rf /data/zx
sed -i "s/machine117:9000/yarnNameService/g" /opt/hbase/conf/hbase-site.xml 
sed -i "s/machine117/YARN-NN-2,YARN-DN-1,YARN-DN-2/g" /opt/hbase/conf/hbase-site.xml
sed -i "s/2183/2181/g" /opt/hbase/conf/hbase-site.xml
sed -i '/<configuration>/a<property>\n\t<name>hbase.coprocessor.user.region.classes</name>\n\t<value>org.apache.spark.sql.hbase.CheckDirEndPointImpl</value>\n</property>\n' /opt/hbase/conf/hbase-site.xml
printf '%s\n' "YARN-NN-2" "YARN-DN-1" "YARN-DN-2"> /opt/hbase/conf/regionservers
sed -i "s/# export HBASE_CLASSPATH=/export HBASE_CLASSPATH=\/opt\/tms\/java\/hbase-spark\/spark-hbase_2.10-1.3.1-jar-with-dependencies.jar:\/opt\/spark\/lib\/datanucleus-api-jdo-3.2.6.jar:\/opt\/spark\/lib\/datanucleus-core-3.2.10.jar:\/opt\/spark\/lib\/datanucleus-rdbms-3.2.9.jar:\/opt\/spark\/lib\/spark-1.3.1-yarn-shuffle.jar:\/opt\/spark\/lib\/spark-assembly-1.3.1-hadoop2.4.0.jar/g" /opt/hbase/conf/hbase-env.sh
source scripts/sync-all.sh
syncAll /opt/hbase/conf/regionservers /opt/hbase/conf/hbase-site.xml /opt/hbase/conf/hbase-env.sh

nameNodes="192.168.160.213 192.168.160.214 192.168.160.215 192.168.160.216"
for vm in \${nameNodes[@]}
do
  ssh -q -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -l root \$vm 'rm -rf /opt/hbase/logs'
  ssh -q -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -l root \$vm 'mkdir -p /data/hbase_logs'
done

sh /opt/hbase/bin/start-hbase.sh
EOF1
}


#-------------------------------------------------------
# Function to generate a script which will configure
# Accume lite once data is populated in insta from
# crux job
#-------------------------------------------------------

configureAcume(){
	cat<<EOF >$acumeSetup
admin="${admin}"
recipient="${recipient}"
imageTag="$buildTag"
#-------------------------------------------------------
# Function to send error email when no configXml found
#-------------------------------------------------------

noAccumeConfigXml(){
cat<<EOF1 | sendmail -t
From:AutoMated Crux Sanity<\$admin>
To:\$recipient
Subject: Error: No Accume Config Xml Found

No Accume Config Xml Found at path: /opt/tms/java/

Regards
AutoMated Crux Sanity
EOF1
}


dataValidationEmail(){
local status=\$1
local TC1status=\$2
local TC2status=\$3
local TC3status=\$4
local TC4status=\$5
{
if [[ \$# -eq 1 ]];then

printf '%s\n' "From:AutoMated Crux Sanity<\$admin>
To: \$recipient
Subject: Acume: Data Validation \$status

Tried a simple query on Acume Lite and it \$status

Sample Query: -
--------------------------------------
"
cat \$HOME/req.txt
printf '%s\n' "
-------------------------------------
"
if [[ \$status = "Failed" ]];then
printf '%s\n' "

Output Response :

"
cat \$HOME/run_result.txt
fi

printf '%s\n' "

Regards
AutoMated Crux Sanity
"

else
printf '%s\n' "From:AutoMated Crux Sanity<\$admin>
To: \$recipient
Subject: Acume: Data Validation \$status

Tried a simple sql query on Acume and it \$TC1status

Sample Query: -
--------------------------------------
"
cat \$HOME/req_sql_1.txt
printf '%s\n' "
-------------------------------------
"
if [[ \$TC1status = "Failed" ]];then
printf '%s\n' "

Output Response :

"
cat \$HOME/run_result_sql_1.txt
fi

printf '%s\n' "
Tried a simple sql on Acume  and it \$TC2status

Sample Query: -
--------------------------------------
"
cat \$HOME/req_sql_2.txt
printf '%s\n' "
-------------------------------------
"
if [[ \$TC2status = "Failed" ]];then
printf '%s\n' "

Output Response :

"
cat $HOME/run_result_sql_2.txt
fi

printf '%s\n' "
Tried a simple aggregate query on Acume  and it \$TC3status

Sample Query: -
--------------------------------------
"
cat $HOME/req_agg.txt
printf '%s\n' "
-------------------------------------
"
if [[ \$TC3status = "Failed" ]];then
printf '%s\n' "

Output Response :

"
cat $HOME/run_result_agg.txt
fi

printf '%s\n' "
Tried a simple time-series query on Acume  and it \$TC4status

Sample Query: -
--------------------------------------
"
cat $HOME/req_ts.txt
printf '%s\n' "
-------------------------------------
"
if [[ \$TC4status = "Failed" ]];then
printf '%s\n' "

Output Response :

"
cat \$HOME/run_result_ts.txt
fi

printf '%s\n' "

Regards
AutoMated Crux Sanity
	"
fi
} | sendmail -t -oi

}


#-------------------------------------------------------
# Function to configure AcumeLite
#-------------------------------------------------------
setupAcumeLite() {
echo "[INFO] Inside setupAcumeLite"
cat<<EOF1 | $cli
rubix add-app acumeThinClient config-xml \$configXml
rubix modify-app acumeThinClient add-instance 1
rubix modify-app acumeThinClient modify-instance 1 enable
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute applyServicePermission value true
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute channelReceiverPort value 4000
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute connectorPort value 9080
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute connectorPortAJP value 9029
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute customNamingStrategyEnabledHibernate value false
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute debugPort value 0
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute isCaseInsensitive value true
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute keyStoreName value /sso.jks
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute pojoNameForCustomTablename value Filter
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute pojoNamesToUseHibernateSequence value ""
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute protectedFileExtension value swf
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute samlValidator value com.guavus.rubix.user.management.sso.SAML20Validator
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute serverPort value 6005
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute solutionDBVersion value 0.0
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute ssoIssuerId value ssoTest
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute staticSecurityManagerEnabledShiroEnv value false
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute tomcatClusterInfo value ""
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute tomcatClusterName value tomcat-cluster
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute umDBVersion value 0.0
rubix modify-app acumeThinClient modify-instance 1 set adv-attribute unRestrictedResources value main.swf
rubix modify-app acumeThinClient modify-instance 1 set attribute MAXPERMSIZE value 512m
rubix modify-app acumeThinClient modify-instance 1 set attribute PERMSIZE value 512m
rubix modify-app acumeThinClient modify-instance 1 set attribute acumeCoreAppConfig value solutionInfrastucture.SolutionAppConfig
rubix modify-app acumeThinClient modify-instance 1 set attribute cacheBaselayerBusinessCubeXml value /data/cubedefinition_acume.xml
rubix modify-app acumeThinClient modify-instance 1 set attribute cacheBaselayerCubedefinitionXml value /opt/tms/xml_schema/CubeDefinition.xml
rubix modify-app acumeThinClient modify-instance 1 set attribute cacheBaselayerStorageType value text
rubix modify-app acumeThinClient modify-instance 1 set attribute cacheCoreRRCacheConcurrenyLevel value 3
rubix modify-app acumeThinClient modify-instance 1 set attribute cacheCoreRRCacheSize value 502
rubix modify-app acumeThinClient modify-instance 1 set attribute cacheCoreTimezone value GMT
rubix modify-app acumeThinClient modify-instance 1 set attribute cacheDeleteFirstBinPersistedTime value ""
rubix modify-app acumeThinClient modify-instance 1 set attribute cacheDeleteLastBinPersistedTime value ""
rubix modify-app acumeThinClient modify-instance 1 set attribute cacheExecuteQLtype value sql
rubix modify-app acumeThinClient modify-instance 1 set attribute cacheRRCacheLoader value com.guavus.acume.cache.workflow.RequestResponseCache
rubix modify-app acumeThinClient modify-instance 1 set attribute cachedbname value parquet_out
rubix modify-app acumeThinClient modify-instance 1 set attribute coreEnableJDBCServer value false
rubix modify-app acumeThinClient modify-instance 1 set attribute coreudfconfigurationxml value /data/instances/acumeThinClient/1/app/WEB-INF/classes/udfConfiguration.xml
rubix modify-app acumeThinClient modify-instance 1 set attribute docBase value /data/instances/acumeThinClient/1/app
rubix modify-app acumeThinClient modify-instance 1 set attribute nodeUniqueIdentifier value localhost
rubix modify-app acumeThinClient modify-instance 1 set attribute redirectPort value 6443
rubix modify-app acumeThinClient set adv-attribute L2CacheClusterName value infinispan-hibernate-cluster
rubix modify-app acumeThinClient set adv-attribute connectionPoolSize value 2
rubix modify-app acumeThinClient set adv-attribute connectionProviderClass value org.hibernate.connection.C3P0ConnectionProvider
rubix modify-app acumeThinClient set adv-attribute currentSessionContextClass value thread
rubix modify-app acumeThinClient set adv-attribute customPolicyClass value com.guavus.rubix.user.management.policy.DefaultCustomUserMgmtPolicies
rubix modify-app acumeThinClient set adv-attribute distributedConnectionDriverClass value org.postgresql.Driver
rubix modify-app acumeThinClient set adv-attribute distributedConnectionUrl value jdbc:postgresql://192.168.160.217:5432/rubixdb
rubix modify-app acumeThinClient set adv-attribute distributedDialect value com.guavus.rubix.hibernate.dialect.PostgreSQLCustomDialect
rubix modify-app acumeThinClient set adv-attribute hibernateCacheInfinispanCfg value cluster-infinispan-configs.xml
rubix modify-app acumeThinClient set adv-attribute hibernateCacheRegionFactoryClass value org.hibernate.cache.infinispan.InfinispanRegionFactory
rubix modify-app acumeThinClient set adv-attribute hibernateQueryCache value true
rubix modify-app acumeThinClient set adv-attribute hibernateRubixFile value um.sql
rubix modify-app acumeThinClient set adv-attribute hibernateSecondLevelCache value true
rubix modify-app acumeThinClient set adv-attribute hibernateSolutionFile value solution.sql
rubix modify-app acumeThinClient set adv-attribute infinispanJgroupConfigFile value um-jgroups.xml
rubix modify-app acumeThinClient set adv-attribute passwordExpiryInDays value 0
rubix modify-app acumeThinClient set adv-attribute passwordHistoryCount value 0
rubix modify-app acumeThinClient set adv-attribute rootCAPath value root.crt
rubix modify-app acumeThinClient set adv-attribute sessionCookieDomain value .guavus.com
rubix modify-app acumeThinClient set adv-attribute sslModeForDBConnection value disable
rubix modify-app acumeThinClient set adv-attribute umBindPort value 7900
rubix modify-app acumeThinClient set adv-attribute umDiscoveryTimeout value 12000
rubix modify-app acumeThinClient set adv-attribute umInitialHost value localhost[7900]
rubix modify-app acumeThinClient set adv-attribute umNumInitialMembers value 3
rubix modify-app acumeThinClient set adv-attribute umPortRange value 1
rubix modify-app acumeThinClient set attribute acumeSparkPropertyLocation value ""
rubix modify-app acumeThinClient set attribute apacheTomcatRoot value /opt/tms/acume/tomcat/*
rubix modify-app acumeThinClient set attribute applicationPath value \$appPath
rubix modify-app acumeThinClient set attribute distributedConnectionUserName value rubix
rubix modify-app acumeThinClient set attribute ipAddress value localhost
rubix modify-app acumeThinClient set attribute rubixClusterId value unknown_cluster
rubix modify-app acumeThinClient set attribute solutionName value unknown_solution
rubix modify-app acumeThinClient enable
conf w
EOF1
}

#-------------------------------------------------------
# Function to configure Acume
#-------------------------------------------------------

setupAcume(){
echo "[INFO]: Setting acume clis"
cat<<EOF1 | /opt/tms/bin/cli -m config 
   rubix delete-app acume
   rubix add-app acume config-xml \$configXml
   rubix modify-app acume add-instance 0
rubix modify-app acume set adv-attribute HIVEUSEINSTA value false
   rubix modify-app acume set adv-attribute JMXPORT value 8811
   rubix modify-app acume set adv-attribute L2CacheClusterName value infinispan-hibernate-cluster
   rubix modify-app acume set adv-attribute LDAPSEARCHGROUPNAME value TESTGROUP
   rubix modify-app acume set adv-attribute LDAPURL value ldaps://localhost:636
   rubix modify-app acume set adv-attribute LDAPUSERDNTEMPLATE value uid={0},DC=test,DC=verizon,DC=com
   rubix modify-app acume set adv-attribute acumeAppQueueName value default
   rubix modify-app acume set adv-attribute applyServicePermission value true
   rubix modify-app acume set adv-attribute blazedsLoggingLevel value DEBUG
   rubix modify-app acume set adv-attribute c3p0LoggingLevel value INFO
   rubix modify-app acume set adv-attribute channelReceiverPort value 4000
   rubix modify-app acume set adv-attribute compressBackups value TRUE
   rubix modify-app acume set adv-attribute connectionPoolSize value 2
   rubix modify-app acume set adv-attribute connectionProviderClass value org.hibernate.connection.C3P0ConnectionProvider
   rubix modify-app acume set adv-attribute connectorPort value 6080
   rubix modify-app acume set adv-attribute connectorPortAJP value 6029
   rubix modify-app acume set adv-attribute currentSessionContextClass value thread
   rubix modify-app acume set adv-attribute customNamingStrategyEnabledHibernate value false
   rubix modify-app acume set adv-attribute customPolicyClass value com.guavus.rubix.user.management.policy.DefaultCustomUserMgmtPolicies
   rubix modify-app acume set adv-attribute debugPort value 8099
   rubix modify-app acume set adv-attribute distributedConnectionDriverClass value org.postgresql.Driver
   rubix modify-app acume set adv-attribute distributedConnectionUrl value jdbc:postgresql://192.168.160.217:5432/hivedb
   rubix modify-app acume set adv-attribute distributedDialect value com.guavus.rubix.hibernate.dialect.PostgreSQLCustomDialect
   rubix modify-app acume set adv-attribute executorLogBackups value 10
   rubix modify-app acume set adv-attribute executorLogFileSize value 1000000000
   rubix modify-app acume set adv-attribute executorLoggingLevel value INFO
   rubix modify-app acume set adv-attribute flexLoggingLevel value INFO
   rubix modify-app acume set adv-attribute hibernateCacheInfinispanCfg value cluster-infinispan-configs.xml
   rubix modify-app acume set adv-attribute hibernateCacheRegionFactoryClass value org.hibernate.cache.infinispan.InfinispanRegionFactory
   rubix modify-app acume set adv-attribute hibernateQueryCache value true
   rubix modify-app acume set adv-attribute hibernateRubixFile value um.sql
   rubix modify-app acume set adv-attribute hibernateSecondLevelCache value true
   rubix modify-app acume set adv-attribute hibernateSolutionFile value solution.sql
   rubix modify-app acume set adv-attribute infinispanJgroupConfigFile value um-jgroups.xml
   rubix modify-app acume set adv-attribute isCaseInsensitive value true
   rubix modify-app acume set adv-attribute jgroupsLoggingLevel value ERROR
   rubix modify-app acume set adv-attribute keyStoreName value /sso.jks
   rubix modify-app acume set adv-attribute mailErrCheckInterval value 3600
   rubix modify-app acume set adv-attribute maxNumberOfDays value 30
   rubix modify-app acume set adv-attribute passwordExpiryInDays value 0
   rubix modify-app acume set adv-attribute passwordHistoryCount value 0
   rubix modify-app acume set adv-attribute pojoNameForCustomTablename value Filter
   rubix modify-app acume set adv-attribute pojoNamesToUseHibernateSequence value ""
   rubix modify-app acume set adv-attribute protectedFileExtension value swf
   rubix modify-app acume set adv-attribute requestResponseLoggingLevel value INFO
   rubix modify-app acume set adv-attribute rootCAPath value root.crt
   rubix modify-app acume set adv-attribute rootLoggingLevel value INFO
   rubix modify-app acume set adv-attribute samlValidator value com.guavus.rubix.user.management.sso.SAML20Validator
   rubix modify-app acume set adv-attribute serverPort value 6005
   rubix modify-app acume set adv-attribute sessionCookieDomain value .guavus.com
   rubix modify-app acume set adv-attribute solutionDBVersion value 0
   rubix modify-app acume set adv-attribute sslModeForDBConnection value disable
   rubix modify-app acume set adv-attribute ssoIssuerId value ssoTest
   rubix modify-app acume set adv-attribute staticSecurityManagerEnabledShiroEnv value false
   rubix modify-app acume set adv-attribute tomcatClusterInfo value ""
   rubix modify-app acume set adv-attribute tomcatClusterName value tomcat-cluster
   rubix modify-app acume set adv-attribute umBindPort value 7900
   rubix modify-app acume set adv-attribute umDBVersion value 0
   rubix modify-app acume set adv-attribute umDiscoveryTimeout value 12000
   rubix modify-app acume set adv-attribute umInitialHost value ""
   rubix modify-app acume set adv-attribute umNumInitialMembers value 3
   rubix modify-app acume set adv-attribute umPortRange value 1
   rubix modify-app acume set adv-attribute unRestrictedResources value main.swf
   rubix modify-app acume set attribute ACUMEAPPCONFIG value com.guavus.acume.core.configuration.AcumeAppConfig
   rubix modify-app acume set attribute ACUMEBASEGRANULARITY value 1h
   rubix modify-app acume set attribute ACUMEBINSOURCE value __DEFAULT_BINSRC__
   rubix modify-app acume set attribute ACUMEBUSINESSCUBEXML value /data/cubedefinition_acume.xml
   rubix modify-app acume set attribute ACUMECACHEBASEDIRECTORY value /data/acume
   rubix modify-app acume set attribute ACUMECACHEDIRECTORY value /data/acume
   rubix modify-app acume set attribute ACUMECLASSIFICATIONMAXALLOWEDQUERIES value default:25
   rubix modify-app acume set attribute ACUMECORECACHEAVAILABILITYMAPPOLICY value com.guavus.acume.core.scheduler.AcumeCacheAvailabilityPolicy
   rubix modify-app acume set attribute ACUMECUBEDEFINITIONXML value /data/cisco_mur.xml
   rubix modify-app acume set attribute ACUMEDATASOURCEINTERPRETERPOLICY value com.guavus.acume.core.DsInterpreterPolicyImpl
   rubix modify-app acume set attribute ACUMEDBNAME value parquet_out
   rubix modify-app acume set attribute ACUMEDEFAULTDATASOURCE value cache
   rubix modify-app acume set attribute ACUMEENABLEJDBCSERVER value false
   rubix modify-app acume set attribute ACUMEINSTAAVAILABILITYPOLLINTERVAL value 300
   rubix modify-app acume set attribute ACUMEINSTACOMBOPOINTS value 24
   rubix modify-app acume set attribute ACUMEMAXQUERYLOGRECORD value 10
   rubix modify-app acume set attribute ACUMEQUERYTIMEOUT value 7200
   rubix modify-app acume set attribute ACUMESCHEDULERCHECKINTERVAL value 300
   rubix modify-app acume set attribute ACUMESCHEDULERMAXSEGMENTDURATION value 86400
   rubix modify-app acume set attribute ACUMESCHEDULERPOLICYCLASS value com.guavus.acume.core.scheduler.VariableGranularitySchedulerPolicy
   rubix modify-app acume set attribute ACUMESCHEDULERPREFETCHTASKRETRYINTERVAL value 300000
   rubix modify-app acume set attribute ACUMESCHEDULERQUERYPOOLPOLICYCLASS value com.guavus.acume.core.QueryPoolPolicyImpl
   rubix modify-app acume set attribute ACUMESCHEDULERQUERYPREFETCHTASKNUMRETRIES value 3
   rubix modify-app acume set attribute ACUMESCHEDULERQUERYTIMEOUT value 7200
   rubix modify-app acume set attribute ACUMESCHEDULERTHREADPOOLSIZE value 2
   rubix modify-app acume set attribute ACUMESCHEDULERVARIABLERETENTIONCOMBINEPOINTS value 1
   rubix modify-app acume set attribute ACUMESCHEDULERVARIABLERETENTIONMAP value 1h:24
   rubix modify-app acume set attribute ACUMESPRINGRESOLVER value com.guavus.acume.core.spring.AcumeResolver
   rubix modify-app acume set attribute ACUMESQLCORRECTOR value com.guavus.acume.cache.sql.AcumeCacheSQLCorrector
   rubix modify-app acume set attribute ACUMESQLPARSER value com.guavus.acume.cache.sql.AcumeCacheSQLParser
   rubix modify-app acume set attribute ACUMESUPERUSER value admin
   rubix modify-app acume set attribute ACUMETHREADPOOLSIZE value 25
   rubix modify-app acume set attribute ACUMETIMEZONE value GMT
   rubix modify-app acume set attribute ACUMETIMEZONEDBPATH value /opt/tms/rubix/zoneinfo
   rubix modify-app acume set attribute ACUMEUDFCONFIGURATIONXML value udfConfiguration.xml
   rubix modify-app acume set attribute CACHEBASELAYERSTORAGETYPE value insta
   rubix modify-app acume set attribute CACHEBESTCUBECLASSNAME value com.guavus.qb.bestcube.AcumeBestCube
   rubix modify-app acume set attribute CACHECACHETYPECONFIGCLASS value com.guavus.acume.cache.core.AcumeCacheType
   rubix modify-app acume set attribute CACHEDATASOURCEENABLE value true
   rubix modify-app acume set attribute CACHEDEFAULTCACHETYPE value AcumeFlatSchemaTreeCache
   rubix modify-app acume set attribute CACHEDISABLETOTALQUERY value false
   rubix modify-app acume set attribute CACHEEVICTIONPOLICYCLASS value com.guavus.acume.cache.eviction.AcumeTreeCacheEvictionPolicy
   rubix modify-app acume set attribute CACHELEVELPOLICYMAP value 1h:720
   rubix modify-app acume set attribute CACHERRCACHECONCURRENYLEVEL value 16
   rubix modify-app acume set attribute CACHERRCACHELOADER value com.guavus.acume.cache.workflow.RequestResponseCache
   rubix modify-app acume set attribute CACHERRCACHESIZE value 0
   rubix modify-app acume set attribute CACHESCHEDULERENABLE value true
   rubix modify-app acume set attribute CACHESINGLEENTITYCACHESIZE value 50
   rubix modify-app acume set attribute CACHETIMESERIESLEVELPOLICYMAP value 1h:24
   rubix modify-app acume set attribute HBASEBESTCUBECLASSNAME value com.guavus.qb.bestcube.HBaseBestCube
   rubix modify-app acume set attribute HBASEDATASOURCEENABLE value true
   rubix modify-app acume set attribute HBASEDISABLETOTALQUERY value false
   rubix modify-app acume set attribute HBASERRCACHECONCURRENYLEVEL value 16
   rubix modify-app acume set attribute HBASERRCACHELOADER value com.guavus.acume.cache.workflow.RequestResponseCache
   rubix modify-app acume set attribute HBASERRCACHESIZE value 0
   rubix modify-app acume set attribute HBASESCHEDULERENABLE value false
   rubix modify-app acume set attribute HBASETIMESERIESLEVELPOLICYMAP value 1h:24
   rubix modify-app acume set attribute HBASEUSEINSTA value false
   rubix modify-app acume set attribute HIVEBASELAYERSTORAGETYPE value insta
   rubix modify-app acume set attribute HIVEDATASOURCEENABLE value false
   rubix modify-app acume set attribute HIVEDISABLETOTALQUERY value false
   rubix modify-app acume set attribute HIVERRCACHECONCURRENYLEVEL value 16
   rubix modify-app acume set attribute HIVERRCACHELOADER value com.guavus.acume.cache.workflow.RequestResponseCache
   rubix modify-app acume set attribute HIVERRCACHESIZE value 1000
   rubix modify-app acume set attribute HIVESCHEDULERENABLE value false
   rubix modify-app acume set attribute HIVETIMESERIESLEVELPOLICYMAP value 1h:24
   rubix modify-app acume set attribute JMXAUTHENTICATE value false
   rubix modify-app acume set attribute JMXSSL value false
   rubix modify-app acume set attribute MAXPERMSIZE value 512m
   rubix modify-app acume set attribute PERMSIZE value 512m
   rubix modify-app acume set attribute acumeSparkPropertyLocation value ""
   rubix modify-app acume set attribute apacheTomcatRoot value /opt/tms/acume/tomcat/*
   rubix modify-app acume set attribute applicationPath value /opt/tms/java/acume-war-atlas3.4/
   rubix modify-app acume set attribute authenticateClient value false
   rubix modify-app acume set attribute connectionTimeout value 20000
   rubix modify-app acume set attribute distributedConnectionUserName value rubix
   rubix modify-app acume set attribute docBase value /data/instances/acume/0/app
   rubix modify-app acume set attribute ipAddress value 192.168.160.217
   rubix modify-app acume set attribute keepAliveTimeout value 20000
   rubix modify-app acume set attribute keystoreFile value keystore
   rubix modify-app acume set attribute keystorePassword value rubix123
   rubix modify-app acume set attribute keystoreType value JKS
   rubix modify-app acume set attribute maxKeepAliveRequests value 50
   rubix modify-app acume set attribute maxUsersCount value 2147483647
   rubix modify-app acume set attribute nodeUniqueIdentifier value localhost
   rubix modify-app acume set attribute obfuscateUsername value true
   rubix modify-app acume set attribute redirectPort value 6443
   rubix modify-app acume set attribute rubixClusterId value unknown_cluster
   rubix modify-app acume set attribute runOnlyOnMaster value true
   rubix modify-app acume set attribute solutionConf value solution.ini
   rubix modify-app acume set attribute solutionName value unknown_solution
   rubix modify-app acume set attribute truststoreFile value keystore
   rubix modify-app acume set attribute truststorePassword value rubix123
   rubix modify-app acume set attribute truststoreType value JKS
   rubix modify-app acume enable
   rubix modify-app acume modify-instance 0 enable

configuration write
EOF1

}


#-------------------------------------------------------
# Function to generate compare scp
#-------------------------------------------------------
generateCompareScript() {
baseline=\$1
output=\$2
	cat <<EOF1 >compare.py
import json
import sys
with open("\$output") as json_file:
	run_data = json.load(json_file)
with open("\$baseline") as json_file:
	orig_data = json.load(json_file)
print cmp (orig_data, run_data)
EOF1
}

generateAcumeHbaseJobScript() {
cat <<EOF2 > runAcumeHbaseJob.sh
#!/bin/bash

# copying data into hbase
# copy from 160.89 /data/SanityData/HBaseData/hbase-data-export to /data/
hdfs dfs -copyFromLocal /data/hbase-data-export/ /data/
echo "create 'final4tab1','cf1' ; create 'final4tab2','cf1' ; create 'final4tab3','cf1' "| /opt/hbase/bin/hbase shell
/opt/hbase/bin/hbase org.apache.hadoop.hbase.mapreduce.Import final4tab1 /data/hbase-data-export/final4tab1
/opt/hbase/bin/hbase org.apache.hadoop.hbase.mapreduce.Import final4tab2 /data/hbase-data-export/final4tab2
/opt/hbase/bin/hbase org.apache.hadoop.hbase.mapreduce.Import final4tab3 /data/hbase-data-export/final4tab3

# for running acume
cp /opt/hbase/conf/hbase-site.xml /opt/tms/java/acume-war-atlas3.4/WEB-INF/classes/
# scp admin@192.168.160.89:/data/SanityData/HBaseData/cubedefinition_acume_hbase.xml /data/
cat <<CONFIGS | /opt/tms/bin/cli -m config 
rubix modify-app acume set attribute HBASEDISABLETOTALQUERY value true
rubix modify-app acume set attribute ACUMEBUSINESSCUBEXML value /data/cubedefinition_acume_hbase.xml
configuration write
CONFIGS
echo "pm process rubix restart" | /opt/tms/bin/cli -m config 

# add partition bin availability map to default db 
echo "use default; alter table bin_metatable add partition (binsource='__DEFAULT_BINSRC__',aggregationinterval=3600,mintimestamp=1432015200,maxtimestamp=1432188000,maxexporttimestamp=1432188000);" | /opt/spark/bin/spark-sql
EOF2
}



#-------------------------------------------------------
# Main flow
#-------------------------------------------------------

main(){

#find the proper config-xml
configXml=\$(ls -1 /opt/tms/java/acume-*/WEB-INF/classes/acumeCliConfiguration.xml 2>/dev/null)

if [[ -z \$configXml ]];then
	noAccumeConfigXml
	exit 1
fi

appPath=\$(ls -1d /opt/tms/java/acume-*/ 2>/dev/null)

# Find the image version and configure accordingly
imageVersion=\$(echo "show version" | $cli  | grep 'Product release' | awk '{print \$3}')


if [[ \$imageVersion = "4.2"* ]];then
	mount -o remount,rw /

	#update web-xml
	webXml="\${appPath}/WEB-INF/web.xml"

	#stLnNo=\$((\$(grep -nE -- '<servlet-name>\s*AcumeInitServlet' \$webXml | awk -F ':' '{print \$1}') - 1))
	#enLnNo=\$((\$stLnNo + 4 ))

	#sed -i -e ''\$stLnNo' s/</<!-- </' -e ''\$enLnNo' s/>/> -->/' \$webXml

	#stLnNo=\$((\$(grep -nE -- '<servlet-name>\s*HiveInitServlet' \$webXml | awk -F ':' '{print \$1}') -1))
	#enLnNo=\$((\$stLnNo + 4 ))

	#sed -i -e ''\$stLnNo' s/<!-- </</' -e ''\$enLnNo' s/> -->/>/' \$webXml

	#cp /data/acumeCliConfiguration.xml \$configXml

	#-------------------------------------
	# Place the jar at proper location:
	#-------------------------------------
	cp /data/qa-0.1-SNAPSHOT.jar "\${appPath}/WEB-INF/lib/"

	mount -o remount,ro /

	setupAcumeLite
else
	setupAcume
fi


#wait till crux job populates data in insta
TIMELOOP=0
while [ "\$TIMELOOP" -lt 12 ]
do
	insta_out=\$(/opt/ooziecore/utils/instaAPI.sh  getBinAvailability parquet_out __DEFAULT_BINSRC__ 3600 2> /dev/null| sed '1,2 d')
	if [[ \$insta_out != "" ]] && [[ \$insta_out != "0,0" ]] && [[ \$insta_out = "1421287200,1421294400" ]];then
		echo "Insta availability results found"
		break;
        else
           echo "Insta availability not returning results"
	   date	
           sleep 300
           TIMELOOP=\$((\$TIMELOOP + 1 ))
        fi
done


#Start Acume

generateAcumeHbaseJobScript
#sh runAcumeHbaseJob.sh

echo "pm process rubix restart" | $cli
sleep 60

#wait till tomcat is up
echo "[INFO] Checking for tomcat"
while [[ 1 ]];do
	tomcatUP=\$(ps -ef | grep '/data/instances/acume' | grep -- 'java -cp' | grep -v grep )
	if [[ \$tomcatUP != "" ]];then
		break
	fi
	sleep 10
done

echo "[INFO] Tomcat up"

if [[ \$imageVersion = "4.2"* ]];then

	#Run the TCs here !!!
	echo "SELECT device, down_bytes, hit_count FROM global WHERE starttime <= 1421287200 AND endtime >= 1421287200 ORDER BY down_bytes DESC LIMIT 10;">\$HOME/req.txt
	curl -s -X POST -d @\$HOME/req.txt -k "https://192.168.160.217:6443/queryresponse/sql?user=admin&password=admin123" --header "Content-Type:text/html" -o \$HOME/run_result.txt
	generateCompareScript \$HOME/orig_result.txt \$HOME/run_result.txt
	compareData=\$(python compare.py 2>/dev/null)
	if [[ \$compareData != 0 ]];then
		dataValidationEmail "Failed"
	else
		dataValidationEmail "Passed"
	fi

	exit 0
else
	sleep 120
	
	echo "[INFO] Test Case Run started"
	#TC-1-SQL-1

	echo "select TT_FLOW_COUNT,BYTES,HIT_COUNT, TT_BYTES,DC,DEVICE FROM global  WHERE starttime = 1421287200 AND endtime = 1421294400 ORDER BY TT_BYTES DESC LIMIT 10;">\$HOME/req_sql_1.txt
	curl -s -X POST -d @\$HOME/req_sql_1.txt -k "https://192.168.160.217:6443/queryresponse/sql?super=YWRtaW5AYWRtaW4xMjMvYWRtaW4=" --header "Content-Type:text/plain" -o \$HOME/run_result_sql_1.txt
	generateCompareScript \$HOME/orig_result_sql_1.txt \$HOME/run_result_sql_1.txt
	compareDataTC1=\$(python compare.py 2>/dev/null)
	if [[ \$compareDataTC1 != 0 ]];then
		TC1Status="Failed"
	else
		TC1Status="Passed"
	fi

	#TC-2-SQL-2

	echo "select ts,DC,DEVICE,TT_FLOW_COUNT,BYTES,HIT_COUNT, TT_BYTES FROM global  WHERE starttime = 1421287200 AND endtime = 1421294400 ORDER BY TT_BYTES DESC LIMIT 10;">\$HOME/req_sql_2.txt
    curl -s -X POST -d @\$HOME/req_sql_2.txt -k "https://192.168.160.217:6443/queryresponse/sql?super=YWRtaW5AYWRtaW4xMjMvYWRtaW4=" --header "Content-Type:text/plain" -o \$HOME/run_result_sql_2.txt
    generateCompareScript \$HOME/orig_result_sql_2.txt \$HOME/run_result_sql_2.txt
    compareDataTC2=\$(python compare.py 2>/dev/null)
    if [[ \$compareDataTC2 != 0 ]];then
            TC2Status="Failed"
    else
            TC2Status="Passed"
    fi

	#TC-3-AGGREGATE

    echo "{"responseMeasures":["TT_FLOW_COUNT","BYTES","HIT_COUNT", "TT_BYTES"],"responseDimensions":["DC","DEVICE"],"filterData":[],"sortProperty":"BYTES","sortDirection":"ASC","maxResults":0,"maxResultOffset":0,"length":20,"offset":0,"startTime":1421287200,"endTime":1421294400,"timeGranularity":0}">\$HOME/req_agg.txt
    curl -s -X POST -d @\$HOME/req_agg.txt -k "https://192.168.160.217:6443/queryresponse/aggregate?super=YWRtaW5AYWRtaW4xMjMvYWRtaW4=" --header "Content-Type:application/json" -o \$HOME/run_result_agg.txt
    generateCompareScript \$HOME/orig_result_agg.txt \$HOME/run_result_agg.txt
    compareDataTC3=\$(python compare.py 2>/dev/null)
    if [[ \$compareDataTC3 != 0 ]];then
            TC3Status="Failed"
    else
            TC3Status="Passed"
    fi

	#TC-4-TimeSeries

    echo "{"responseMeasures":["TT_FLOW_COUNT","BYTES","HIT_COUNT", "TT_BYTES"],"responseDimensions":["DC","DEVICE"],"filterData":[],"sortProperty":"BYTES","sortDirection":"ASC","maxResults":0,"maxResultOffset":0,"length":20,"offset":0,"startTime":1421287200,"endTime":1421294400,"timeGranularity":0}">\$HOME/req_ts.txt
    curl -s -X POST -d @\$HOME/req_ts.txt -k "https://192.168.160.217:6443/queryresponse/timeseries?super=YWRtaW5AYWRtaW4xMjMvYWRtaW4=" --header "Content-Type:application/json" -o \$HOME/run_result_ts.txt
    generateCompareScript \$HOME/orig_result_ts.txt \$HOME/run_result_ts.txt
    compareDataTC4=\$(python compare.py 2>/dev/null)
    if [[ \$compareDataTC4 != 0 ]];then
            TC4Status="Failed"
    else
            TC4Status="Passed"
    fi

	#move this out of if block when baselines for 4.2 image are available

	if [[ \$TC1Status == "Passed" ]] && [[ \$TC2Status == "Passed" ]] && [[ \$TC3Status == "Passed" ]] && [[ \$TC4Status == "Passed" ]];then
		overallStatus="Passed"
	else
		overallStatus="Failed"
	fi
	
	echo "[INFO] Test Case Run Completed"
	dataValidationEmail "\$overallStatus" "\$TC1Status" "\$TC2Status" "\$TC3Status" "\$TC4Status"

fi

exit 0


}
main &
exit 0

EOF
}



#-----------------------------------------------------
# Main Execution Start Point for the Script
# once initial validations are passed
# it will use above declared functions
#-----------------------------------------------------


# input argument validation

while getopts i:h opt ; do
	case "$opt" in
		i)
			imageFile="$OPTARG"
			;;
		t)
			buildTag="$OPTARG"
			;;
		h)
			showUsage
			exit 1
			;;
		\?)
			showUsage
			exit 1
			;;
	esac
done

if [[ $# -eq 0 ]]
then
	showUsage
	exit 1
fi

if [[ $imageFile = "" ]];then
	showUsage
	exit 1
fi


# input image name and ext validation

imageName=$(echo $imageFile | sed 's#\(.*\)/\(.*\)#\2#')
imageExt=$(echo $imageName| awk -F '.' '{print $NF}')

if [[ $imageName = "" ]] || [[ $imageExt != "img" ]]
then
	echo "[$(date "+%Y-%m-%d %H:%M:%S")] ERROR: Wrong Image Name or wrong ext. Looking for img file"
	echo "Image: ${imageName}"
	exit
fi

echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Checking Host Machine Access"


# All base machine password less access validation

checkAllNodeAccess

grep -q 'Denied' $selfHostAccess
if [[ $? -eq 0 ]];then
	echo "[$(date "+%Y-%m-%d %H:%M:%S")] ERROR: In Accessing Nodes"
	cat $selfHostAccess
	cleanUpFiles
	exit 1
fi

echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Generating Setup Files for Manufacturing"

# Generate vm manufacture script for each base machine

generateMachine89Setup
generateMachine90Setup


echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Transferring run file for Manufacturing"

# copy vm manufacture script on each base machine

ssh -q -l root 192.168.160.89 'mkdir -p /data/vms/'
ssh -q -l root 192.168.160.90 'mkdir -p /data/vms/'
scp -q ${machine89Script} admin@192.168.160.89:/data/vms/generateVMs.sh
scp -q ${machine90Script} admin@192.168.160.90:/data/vms/generateVMs.sh


echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Starting Manufacturing in Background"

# Trigger vm creation on each base machine

rm log.txt 2>/dev/null
( ssh -q -l root 192.168.160.90 'nohup sh /data/vms/generateVMs.sh ' >>log.txt 2>&1 )&
( ssh -q -l root 192.168.160.89 'nohup sh /data/vms/generateVMs.sh ' >>log.txt 2>&1  )&
mStartTime=$(date +%s)

echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Manufacturing Started"

echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Waitinng for (Might Take More time for VM Creation) : $(date -u -d @$VM_CREATE_SLEEP +%T)"

#-----------------------------------------------------------------------------
# This wait is required to check if
# All the VMs are manufactured or not yet
# if not then we should not apply any config on them
#------------------------------------------------------------------------------
wait

mEndime=$(date +%s)

echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: VMs Creation Done"

mDuration=$(($mEndime - $mStartTime))

echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Total Manufacturing time: $(date -d @$mDuration +%T)"

echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Waiting for VMs to boot up"

# Check if all manufactured VMs are up or not yet

checkIfAllVMsUp 2>/dev/null 1>>log.txt

echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: All VMs are Up Now"

echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Setting Up Root Access"


# Setup no password config for root user on all the manufactured machines

setupRootLessAccess 2>/dev/null 1>>log.txt

echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: All Access Done"


echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Setting Up Tall Maple Cluster And SSH Keys"

# Set cluster using guavus clis

setUpTallMapleCluster 2>/dev/null 1>>log.txt

echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Cluster Setup Done"

echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Setting Up Hadoop and Oozie Configs"


# Perform configs for all the NNs and DNs in the cluster

getTheKeys 2>/dev/null 1>>log.txt
setupDataNodes 2>/dev/null 1>>log.txt
setupNameNodes 2>/dev/null 1>>log.txt


echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Starting Hadoop Cluster"

# Perform a TPS restart on master and standby node both

startYarnCluster 2>/dev/null 1>>log.txt

echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: SCP Sample data on both namenodes"
exit 0

# SCP sample data and few job xmls from base machine to both nodes master

imageVersion=$(ssh -l root $SSH_OPTIONS 192.168.160.217 "echo 'show version' | /opt/tms/bin/cli -m config | grep 'Product release' | awk '{print \$3}' ")

nameNodes="192.168.160.213 192.168.160.214"
for vm in ${nameNodes[@]}
do
	( scp -r $SSH_OPTIONS /data/SanityData/collector admin@$vm:/data
	ssh $SSH_OPTIONS -l root $vm 'mount -o remount,rw /'
	scp -r $SSH_OPTIONS /data/SanityData/crux-operations.xml admin@$vm:/opt/etc/oozie/CruxEdr/
	scp -r $SSH_OPTIONS /data/SanityData/collector_to_insta.xml admin@$vm:/opt/etc/oozie/CruxEdr/
	scp -r $SSH_OPTIONS /data/SanityData/insta_mural.xml admin@$vm:/opt/etc/oozie/CruxEdr/
	scp -r $SSH_OPTIONS /data/SanityData/parq_mural_to_insta.xml admin@$vm:/opt/etc/oozie/CruxEdr/
	scp -r $SSH_OPTIONS /data/SanityData/insta_from_xml_test.xml admin@$vm:/opt/etc/oozie/CruxEdr/
	scp -r $SSH_OPTIONS /data/SanityData/scripts admin@$vm:
	scp $SSH_OPTIONS /data/SanityData/.bashrc admin@$vm:
	scp $SSH_OPTIONS /data/SanityData/.sanity admin@$vm:
	scp $SSH_OPTIONS updateForHbase.sh admin@$vm:
	scp -r $SSH_OPTIONS /data/SanityData/crux-sanity-data-validation admin@$vm:/data/
	scp -r $SSH_OPTIONS /data/SanityData/HBaseData/hbase-data-export admin@$vm:/data/
	scp $SSH_OPTIONS /data/SanityData/HBaseData/cubedefinition_acume_hbase.xml admin@$vm:/data/

	if [[ $imageVersion = "4.2"* ]];then
		ssh $SSH_OPTIONS -l root $vm 'sed -i "/timeZone/ d" /opt/etc/oozie/CruxEdr/collector_to_insta.xml'
	fi

	ssh $SSH_OPTIONS -l root $vm 'mount -o remount,ro /'
	)&
done




echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Configuring INSIA on: $instaIP"

# Setup Insta server using guavus clis

setupInstaServer 2>/dev/null 1>>log.txt


echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Waiting for Insta to come up"
checkIfInstaUpNew  &
instaCheckPid=$!


echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Waiting for hdfs to come up"
checkIfRMUp  &
rmCheckPid=$!

echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Waiting for Oozie to come up"
checkIfOozieUp  &
oozieCheckPid=$!


#---------------------------------------------
# This wait is required to check if
#	1. Insta is UP
#	2. Yarn is UP
#	3. Oozie is UP
#----------------------------------------------

wait $instaCheckPid
instaRetStatus=$?
wait $rmCheckPid
rmRetStatus=$?
wait $oozieCheckPid
oozieRetStatus=$?

if [[ $instaRetStatus -gt 0 ]];then
	exit $instaRetStatus
elif [[ $rmRetStatus -gt 0 ]];then
	exit $rmRetStatus
elif [[ $oozieRetStatus -gt 0 ]];then
	exit $oozieRetStatus
fi


echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Generating IBs on: 192.168.160.217"

# Generate IBs and push on both master and standby node

setupAggregationCenter "192.168.160.217" "true" 2>&1 1>>log.txt
ibSetupRetStatus=$?


if [[ $ibSetupRetStatus -gt 0 ]];then
	exit $ibSetupRetStatus
else
	#Get real ips for master and standby machines and then generate IBs on
	#stand by machine too in oder to do a switch over
        getRealIps
	setupAggregationCenter $standbyIP "false" 2>&1 1>>log.txt
fi

echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Copying Data On HDFS"

ssh $SSH_OPTIONS -l root 192.168.160.217 'hdfs dfs -mkdir -p /data /spark/events' 2>&1 1>>log.txt
ssh $SSH_OPTIONS -l root 192.168.160.217 'hdfs dfs -put /data/collector /data/' 2>&1 1>>log.txt

echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Setting Up Email Configuration on MasterNode"

# Generate Oozie job monitor script which will notify through emails

setupMailConfiguration

## Setup Hbase on the cluster 
echo  '[INFO] Setting up Hbase on cluster'
generateHBaseUpdateScript
vm='192.168.160.217'
scp $SSH_OPTIONS updateForHbase.sh  admin@$vm:/var/home/root/updateForHbase.sh 2>&1 1>>log.txt
ssh $SSH_OPTIONS -l root $vm 'sh /var/home/root/updateForHbase.sh </dev/null >updateForHbase.log 2>/dev/null &'
sleep 120
# Copy and start oozie monitor script on master node

nameNodes="192.168.160.213 192.168.160.214"
for vm in ${nameNodes[@]}
do
	scp $SSH_OPTIONS $emailSetup admin@$vm:/var/home/root/checkJobStatus.sh 2>&1 1>>log.txt

done



echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Setting up AcumeLite Configs"

# Generate Acume config
echo "[INFO] Going to call configure Acume"
configureAcume 2>&1 1>>log.txt
echo "[INFO] configure Acume Over"

# Copy and start Acume Lite on maste node
nameNodes="192.168.160.213 192.168.160.214"
for vm in ${nameNodes[@]}
do
        scp $SSH_OPTIONS /data/SanityData/acumeCliConfiguration.xml admin@$vm:/data/
        scp $SSH_OPTIONS /data/SanityData/qa-0.1-SNAPSHOT.jar admin@$vm:/data/
        scp $SSH_OPTIONS /data/SanityData/cubedefinition_acume.xml admin@$vm:/data/
        scp $SSH_OPTIONS /data/SanityData/cisco_mural.xml admin@$vm:/data/
        scp $SSH_OPTIONS /data/SanityData/cisco_mur.xml admin@$vm:/data/
        scp $SSH_OPTIONS /data/SanityData/orig_result.txt admin@$vm:
        scp $SSH_OPTIONS /data/SanityData/orig_result_sql_1.txt admin@$vm:
        scp $SSH_OPTIONS /data/SanityData/orig_result_sql_2.txt admin@$vm:
        scp $SSH_OPTIONS /data/SanityData/orig_result_agg.txt admin@$vm:
        scp $SSH_OPTIONS /data/SanityData/orig_result_ts.txt admin@$vm:
        scp $SSH_OPTIONS $acumeSetup admin@$vm:/var/home/root/acumeSetup.sh 2>&1 1>>log.txt
done

# Copy and start Acume Lite on maste node
dataNodes="192.168.160.215 192.168.160.216"
for vm in ${dataNodes[@]}
do
        scp $SSH_OPTIONS /data/SanityData/cisco_mural.xml admin@$vm:/data/
done




ssh $SSH_OPTIONS -l root 192.168.160.217 'sh /var/home/root/checkJobStatus.sh </dev/null >/dev/null 2>/dev/null &'


echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Triggring Job"

# Trigger all the configured oozie jobs from base machine

if [[ $imageVersion = "4.2"* ]];then
	ssh $SSH_OPTIONS -l root 192.168.160.217 'echo "subshell oozie run job PARQUET-EDR" | /opt/tms/bin/pmx' 2>&1 1>>log.txt
	ssh $SSH_OPTIONS -l root 192.168.160.217 'echo "subshell oozie run job CRUX-EDR" | /opt/tms/bin/pmx' 2>&1 1>>log.txt
	ssh $SSH_OPTIONS -l root 192.168.160.217 'echo "subshell oozie run job CRUX-EXPORTER" | /opt/tms/bin/pmx' 2>&1 1>>log.txt
	ssh $SSH_OPTIONS -l root 192.168.160.217 'echo "subshell oozie run job CUBE-EXPORTER" | /opt/tms/bin/pmx' 2>&1 1>>log.txt
	ssh $SSH_OPTIONS -l root 192.168.160.217 'echo "subshell oozie run job INSTA-EDR" | /opt/tms/bin/pmx' 2>&1 1>>log.txt
	ssh $SSH_OPTIONS -l root 192.168.160.217 'echo "subshell oozie run job COLLECTOR-TO-INSTA" | /opt/tms/bin/pmx' 2>&1 1>>log.txt
	ssh $SSH_OPTIONS -l root 192.168.160.217 'echo "subshell oozie run job CRUX-OPS" | /opt/tms/bin/pmx' 2>&1 1>>log.txt
	ssh $SSH_OPTIONS -l root 192.168.160.217 'echo "subshell oozie run job MR-EDR" | /opt/tms/bin/pmx' 2>&1 1>>log.txt
	ssh $SSH_OPTIONS -l root 192.168.160.217 'echo "tps sparksql stop" | /opt/tms/bin/cli -m config' 2>&1 1>>log.txt
else
	ssh $SSH_OPTIONS -l root 192.168.160.217 'echo "subshell oozie run job PARQUET-EDR" | /opt/tms/bin/pmx' 2>&1 1>>log.txt
	ssh $SSH_OPTIONS -l root 192.168.160.217 'echo "subshell oozie run job CRUX-EDR" | /opt/tms/bin/pmx' 2>&1 1>>log.txt
	ssh $SSH_OPTIONS -l root 192.168.160.217 'echo "subshell oozie run job CRUX-EXPORTER" | /opt/tms/bin/pmx' 2>&1 1>>log.txt
	ssh $SSH_OPTIONS -l root 192.168.160.217 'echo "subshell oozie run job CUBE-EXPORTER" | /opt/tms/bin/pmx' 2>&1 1>>log.txt
	ssh $SSH_OPTIONS -l root 192.168.160.217 'echo "subshell oozie run job INSTA-EDR" | /opt/tms/bin/pmx' 2>&1 1>>log.txt
	ssh $SSH_OPTIONS -l root 192.168.160.217 'echo "subshell oozie run job COLLECTOR-TO-INSTA" | /opt/tms/bin/pmx' 2>&1 1>>log.txt
	ssh $SSH_OPTIONS -l root 192.168.160.217 'echo "subshell oozie run job CRUX-OPS" | /opt/tms/bin/pmx' 2>&1 1>>log.txt
	ssh $SSH_OPTIONS -l root 192.168.160.217 'echo "subshell oozie run job INSTA-FROM-XML" | /opt/tms/bin/pmx' 2>&1 1>>log.txt
	ssh $SSH_OPTIONS -l root 192.168.160.217 'echo "subshell oozie run job MR-EDR" | /opt/tms/bin/pmx' 2>&1 1>>log.txt
	ssh $SSH_OPTIONS -l root 192.168.160.217 'echo "tps sparksql stop" | /opt/tms/bin/cli -m config' 2>&1 1>>log.txt
fi


echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Setting up AcumeLite Configs"

echo -e "\n[INFO] Calling crux_test"
nohup sh /data/SanityData/crux_test.sh "192.168.160.217" 1> crux_test.log 2>&1 < /dev/null &
echo -e "\n[INFO] crux_test started in background"

ssh $SSH_OPTIONS -l root 192.168.160.217 'sh /var/home/root/acumeSetup.sh </dev/null >/data/acumeSetup.log 2>/data/acumeSetup.log &'
ssh $SSH_OPTIONS -l root 192.168.160.217 'sh /data/crux-sanity-data-validation/Validate.sh </dev/null >/dev/null 2>/dev/null &'

cleanUpFiles

endTime=$(date +%s)
totalDur=$(($endTime - $startTime))

echo "[$(date "+%Y-%m-%d %H:%M:%S")] Total Time in Setup: $(date -u -d @$totalDur +%T)"

echo "[$(date "+%Y-%m-%d %H:%M:%S")] INFO: Done !!! Now Check Manually"

# Boom You did it...exit Happily !!!

exit 0
