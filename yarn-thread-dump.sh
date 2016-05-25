Servers=( `echo "show running-config"| /opt/tms/bin/cli -m config | grep -E "slave/values"  | awk '{print $NF}'|sort -u | xargs -IFile grep File /etc/hosts | awk '{print $NF}' | tr '\n' ' ' | sed 's/.$//'` )
selfPID=$$
scriptName=`basename $0`

SSH_OPTIONS="-q -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
DUMP_FREQUENCY=1

showUsage () {
	echo -e "Usage: `basename $0` -[ifash]";
	echo -e "\t -i: To Initiate Thread Dump Across Cluster "
	echo -e "\t -f: Frequency of Thread Dump (in seconds)"
	echo -e "\t -a: Run Thread Dump for Input Application ID"
	echo -e "\t -s: To Stop Thread Dump Across Cluster"
	echo -e "\t -h: help "
}


stopThreadDump() {

	for dn in "${Servers[@]}"
	do
		ssh $SSH_OPTIONS -T -l root $dn 'cat /tmp/javathreaddump.pid 2>/dev/null | xargs -r kill -9 2>/dev/null'
	done
}


trap stopThreadDump SIGINT SIGKILL

startThreadDumpOn() {
ssh $SSH_OPTIONS -T -l root $1<<EOF
echo \$\$ > /tmp/javathreaddump.pid
NodeManager=\`ps -fu admin | grep java | tr -s ' ' ',' | cut -d"," -f2,9 | grep  proc_nodemanager | cut -d"," -f1\`
if [[ \$NodeManager == "" ]]
then
	NodeManager=\`ps -f -u \${USER} | grep -v grep | grep NodeManager | while read user pid ppid time; do echo \$pid; done\`
fi
if [[ \$NodeManager == "" ]]
then
	NodeManager=\`jps | grep NodeManager | while read i j; do echo \$i; done;\`
fi

if [[ \$NodeManager == "" ]]
then
	echo "\`hostname\` : No NodeManager Running...exiting"
	>/tmp/javathreaddump.pid
	exit 1
fi

while [ 1 ]
do
	ps -f  --ppid \$NodeManager | grep \$NodeManager | awk '{print \$2}' | tr "\n" "," | sed 's/,$//' | xargs -r ps -o pid -o cmd --no-heading --ppid | grep "$appID" |awk '{print \$1}'  |while read i; do kill -QUIT \$i; done
	if (( \$? != 0))
	then
		echo "\`hostname\` :Exiting dump stacks, as signal send failed"
		>/tmp/javathreaddump.pid
		exit
	fi
	sleep $DUMP_FREQUENCY
done
EOF
}

if [ ${#Servers[@]} -lt 1 ]
then
		echo "Some Error in getting hostnames. Please run this script on NameNode (master/standby) Only"
		exit 1
fi

start=0

while getopts ishf:a: opt ; do
	case "$opt" in
		s)
			echo "Stopping Running Thread Dump Across Cluster If Any"
			stopThreadDump
			exit 0
			;;
		f)
			DUMP_FREQUENCY="$OPTARG"
			;;
		a)
			appID="$OPTARG"
			;;
		i)
			start=1
			;;
		h)
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

if [[ $start -eq 1 ]];then
		stopThreadDump
		for dn in "${Servers[@]}"
		do
			(startThreadDumpOn $dn) &
		done
		exit 0
fi