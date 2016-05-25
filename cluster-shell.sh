function _setup_ (){
	Nodes=()
	#Nodes=('NN-AN' 'NN-SBN' 'DN-1' 'DN-2' 'DN-3');

	CLI="/opt/tms/bin/cli -m config"
	SSH_OPTIONS="-q -T -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -l admin"
	HISTORY_FILE="$HOME/.cluster_history"
	FORBIDDEN_COMMANDS="$HOME/.cluster_forbidden"
	touch $HISTORY_FILE

	if [[ ${#Nodes[@]} -eq 0 ]];then
		Nodes=($(echo "show running-config" | $CLI | grep -E "slave/values|namenode1/value|namenode2/value|journalnodes/values|master/value"  | \
			awk '{print $NF}'|sort -u | xargs -IFile grep File /etc/hosts | awk '{print $NF}'| \
			sort -u | tr '\n' ' ' | sed 's/.$//' ))

		if [[ ${#Nodes[@]} -lt 1 ]];then
			echo "Some Error in getting hostnames. Please Declare var:  \"Nodes\"
				Inside script if you are not running it on YARN/HADOOP Cluster"
			return 1
		fi
	fi

	if [[ ! -s $FORBIDDEN_COMMANDS ]];then
		echo -e "vi\nvim\nless\nmore\ntail\ntailf\nssh" >$FORBIDDEN_COMMANDS
	fi
}

function _run_cluster_cmd_ () {
	cmdLine=($(echo $cmdToRun))
	firstUnixCmd=${cmdLine[0]}
	if [[ $cmdToRun = "quit" ]] || [[ $cmdToRun = "exit" ]];then
		break;
	elif grep -q $firstUnixCmd $FORBIDDEN_COMMANDS 2>/dev/null ;then
		if [[ $term_out = "true" ]];then
			echo "$(tput setaf 1)	Not Supported Command over cluster prompt $(tput sgr 0)"
		else
			echo "Not Supported Command over cluster prompt"
		fi
	elif [[ $firstUnixCmd = "clear" ]];then
		clear
	elif [[ $cmdToRun != "" ]];then
		history -s "$cmdToRun"
		history -w $HISTORY_FILE
		for host in "${Nodes[@]}";do
			if [[ -t 1 ]];then
				echo "$(tput setaf 1)[$(tput setaf 3) $host $(tput setaf 1)] $(tput setaf 2)${cmdToRun} $(tput sgr 0)"
			else
				echo "[ $host ] ${cmdToRun} "
			fi
			\ssh $SSH_OPTIONS ${host} <<ENDSSH
enable
_shell
${cmdToRun}
ENDSSH
		echo ""
		done
	fi
}

function cluster() {
	_setup_
	if [[ -t 0 ]]; then
		term_out="true"
		echo "$(tput setaf 2)Welcome to cluster shell. Type the shell command to execute on all the nodes.$(tput sgr 0)"
		history -r $HISTORY_FILE
		while [[ 1 ]];do
			read -r -e -d $'\n' -p "$(tput setaf 5)(cluster) $(tput sgr 0)" cmdToRun
			if [[ ! -z $cmdToRun ]];then
				_run_cluster_cmd_
			fi
		done
	else
		term_out="false"
		while read cmdToRun; do
			_run_cluster_cmd_
		done
	fi
}
