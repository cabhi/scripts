#!/bin/bash
function syncAll() {

#---------------------------------------------------------------------
# Run this script/function on HADOOP/YARN cluster to sync a file
# from name node to all of the cluster
# if you want to run it without setting up a HADOOP/YARN cluster
# then Populate array "Servers" with the hostnames/ips
# on which you want to sync a file
# Just make sure you have setup password less acess across them
#---------------------------------------------------------------------

	local CLI="/opt/tms/bin/cli -m config"
	local RSYNC_OPTIONS="-rlW --force"
	local SSH_OPTIONS="-q -l root -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
	local Servers=()
	#Servers=('NN-AN' 'NN-SBN' 'DN-1' 'DN-2' 'DN-3');

	if [[ $# -lt 1 ]];then
		echo "Please Provide a File to Sync"
		return 1
	fi

	currHost=`hostname`

	if [[ ${#Servers[@]} -eq 0 ]];then
		Servers=($(echo "show running-config" | $CLI | grep -E "slave/values|namenode1/value|namenode2/value|journalnodes/values|master/value"  | \
			awk '{print $NF}'|sort -u | xargs -IFile grep File /etc/hosts | awk '{print $NF}'| \
			sed "/^$currHost$/ d"| sort -u | tr '\n' ' ' | sed 's/.$//' ))

		if [[ ${#Servers[@]} -lt 1 ]];then
			echo "Some Error in getting hostnames. Please Declare var:  \"Servers\"
				Inside script if you are not running it on YARN/HADOOP Cluster"
			return 1
		fi
	fi

	# Lets Sync All the Input args to rest of the Servers
	while [[ $# -gt 0 ]];do
		fileName=$1
		# Lets Gets it full path on this machine
		echo "-----------------------------"
		if [[ -d $fileName ]];then
			echo "DIR : $(basename $fileName)"
			srcPath=$(cd $fileName && pwd )
		elif [[ -f $fileName ]];then
			echo "FILE : $(basename $fileName)"
			srcPath=$(cd $(dirname "$fileName") && pwd )/$(basename "$fileName")
		else
			echo "DIR/FILE : $(basename $fileName)"
			echo "    ERROR: Non existant , Skipping"
			shift
			continue
		fi

		destPath=$(dirname $srcPath)

		for host in "${Servers[@]}";do
			echo "    Syncing on Host: $host"
			ssh $SSH_OPTIONS -l root ${host} 'mount -o remount,rw /'
			rsync $RSYNC_OPTIONS -e "ssh $SSH_OPTIONS" ${srcPath} ${host}:${destPath}
		done
		#Lets Sync Next Input
		shift
	done
}

