#! /bin/sh

cli="/opt/tms/bin/cli"
baseDir="/data/imageUpgrade"
SSH_OPTIONS="-q -l root -o ConnectTimeout=5"
[[ -d $baseDir ]]|| mkdir -p $baseDir

generateUpgradeScript(){
cat <<EOF >${TEMP_FILE}
#! /bin/sh
sleepTime=\$1
[[ -f $errorFile ]]&&rm $errorFile
[[ -f $successFile ]]&&rm $successFile

anyUpgrade=\`ps -ef | grep "${baseDir}" | grep 'run_upgrade\.sh' | grep '	/bin/sh' | grep -v \$\$  | grep -v grep | awk '{print \$2}' \`

if [[ \$anyUpgrade != "" ]]
then
	echo "[\`date "+%Y-%m-%d %H:%M:%S"\`] ERROR: Another Upgrade Already in Progress with PID: \$anyUpgrade"
	touch $errorFile
	exit 1	
fi

echo "[\`date \"+%Y-%m-%d %H:%M:%S\"\`] INFO: Cleaning old img Files.."

rm -rf /var/opt/tms/images/*

nameServer=\`grep 204.232.241.167 /var/opt/tms/output/resolv.conf\`

if [[ \$nameServer = "" ]]
then
	echo "ip name-server 204.232.241.167" | $cli -m config
fi

echo "[\`date \"+%Y-%m-%d %H:%M:%S\"\`] INFO: Image Fetch Will Start in: \$sleepTime seconds"

sleep \$sleepTime

echo "[\`date \"+%Y-%m-%d %H:%M:%S\"\`] INFO: Starting Image Fetch.."

wget -q -N -P /var/opt/tms/images/ ${imageFile}

if [[ \$? -ne 0 ]]
then
	echo "[\`date "+%Y-%m-%d %H:%M:%S"\`] ERROR: Failure in image Fetch"
	touch $errorFile
	exit 1
fi

echo "[\`date \"+%Y-%m-%d %H:%M:%S\"\`] INFO: Image Fetched Successfully..."
echo "[\`date \"+%Y-%m-%d %H:%M:%S\"\`] INFO: Starting Image Install..."

$cli -t "en" "image install ${imageName}"

if [[ \$? -ne 0 ]]
then
	echo "[\`date \"+%Y-%m-%d %H:%M:%S\"\`] ERROR: Failure in image install"
	touch $errorFile
	exit 1
fi

echo "[\`date \"+%Y-%m-%d %H:%M:%S\"\`] INFO: Image Installed Successfully..."
echo "[\`date \"+%Y-%m-%d %H:%M:%S\"\`] INFO: Starting Image Boot Next..."
echo "image boot next" | $cli -m config

if [[ \$? -ne 0 ]]
then
	echo "[\`date \"+%Y-%m-%d %H:%M:%S\"\`] ERROR: Failure in image boot next"
	touch $errorFile
	exit 1
fi

echo "[\`date \"+%Y-%m-%d %H:%M:%S\"\`] INFO: Setup Done...restarting machine"

touch $successFile
[[ -f $errorFile ]]&&rm $errorFile

$cli -t "en" "reload"
EOF
}
mode=""
showUsage () {
    echo -e "Usage: `basename $0` -[rtuih]";
    echo -e "\t -u: To Upgrade Servers With An Image"
    echo -e "\t -i: Image File Path "
    echo -e "\t\t mendatory with -u option"
    echo -e "\t -t: To List Status Of Last Upgrade From All Servers"
    echo -e "\t -r: To Retry Upgrade again if failed last time "
    echo -e "\t -h: help "
}

Servers=( `cli -t "en" "show running-config" | grep -E "slave/values|namenode1/value|namenode2/value|journalnodes/values|master/value|client/values"  | awk '{print $NF}'|sort -u | xargs -IFile grep File /etc/hosts | awk '{print $NF}' | sort -u | tr '\n' ' ' | sed 's/.$//'` )

if [ ${#Servers[@]} -lt 1 ]
then
        echo "Some Error in getting hostnames. Please run this script on NameNode (master/standby) Only"
        exit 1
fi

while getopts i:htru opt ; do
        case "$opt" in
           i)
                imageFile="$OPTARG"
                ;;
           h)
                showUsage
                exit 1
                ;;
           t)
                if [[ $mode = "UPGRADE" ]]
                then
                    echo "-u flag can only be used with -i flag...exiting..."
                    exit 1
                fi

                mode="TEST"

                echo "*******************************"
                echo "Upgrade Status @ [`date "+%Y-%m-%d %H:%M:%S"`]"
                echo "*******************************"

                lastRunDir=$baseDir"/"`ls -lrt $baseDir|tail -1 |awk '{print $9}'`

                if [[ ${lastRunDir} = "" ]] || [[ "${lastRunDir}" = "${baseDir}/" ]]
                then
                    echo "-------------------------------"
                    echo "ERROR: No Previous Upgrade run found..."
                    echo "-------------------------------"
                    exit 1
                fi
                for host in "${Servers[@]}"
                do
                    echo "-------------------------------"
                    echo "Host: $host"
                    echo "-------------------------------"
                    ssh ${SSH_OPTIONS} $host "[[ -f ${lastRunDir}/_SUCCESS ]] && (echo 'Successfully Upgraded';)||(cat ${lastRunDir}/log.txt)"
                    if [[ $? -ne 0 ]]
                    then
                        echo "Some error in fetching logs. Please Check manually. !!!!"
                    fi
                done
                ;;
           r)
                if [[ $mode = "UPGRADE" ]]
                then
                    echo "-u flag can only be used with -i flag...exiting..."
                    exit 1
                fi

                mode="RETRY"

                echo "*******************************"
                echo "Upgrade Retry Status @ [`date "+%Y-%m-%d %H:%M:%S"`]"
                echo "*******************************"

                lastRunDir=$baseDir"/"`ls -lrt $baseDir|tail -1 |awk '{print $9}'`

                if [[ ${lastRunDir} = "" ]] || [[ "${lastRunDir}" = "${baseDir}/" ]]
                then
                    echo "-------------------------------"
                    echo "ERROR: No Previous Upgrade run found..."
                    echo "-------------------------------"
                    exit 1
                fi

                for host in "${Servers[@]}"
                do
                    echo "-------------------------------"
                    echo "Host: $host"
                    echo "-------------------------------"
                    ssh ${SSH_OPTIONS} $host "[[ ! -f ${lastRunDir}/_ERROR ]]&&(echo -e \"No Upgrade Script Error Found\";exit 0;)||(echo \"Upgrade restarted at \`hostname\`\"; (${lastRunDir}/run_upgrade.sh 0 >${lastRunDir}/log.txt 2>&1 &);exit 0)"
                    if [[ $? -ne 0 ]]
                    then
                        echo "Some error in connecting. Please Check manually. !!!!"
                    fi

                done
                ;;
           u)
                if [[ $mode != "" ]]
                then
                    echo "-u flag can't be used with -t or -r flag"
                    exit 1
                fi

                mode="UPGRADE"
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

if [[ $mode = "UPGRADE" ]]
then
    if [[ $imageFile = "" ]]
    then
        showUsage
        exit 1
    fi

    echo "*******************************"
    echo "Upgrade"
    echo "*******************************"

    imageHost=`echo $imageFile| sed 's#\(.*\)://\(.*\)#\2#' | cut -d '/' -f1`
    imageName=`echo $imageFile | sed 's#\(.*\)/\(.*\)#\2#'`
    imageExt=`echo $imageName| cut -d '.' -f2`

    if [[ $imageName = "" ]] || [[ $imageExt != "img" ]]
    then
        echo "Image: ${imageName}"
        echo "ERROR: Wrong Image Name or wrong ext. Looking for img file"
        exit
    fi

    echo "[`date "+%Y-%m-%d %H:%M:%S"`] INFO: Checking node access and any upgrade already in progress"

    startUpgrade=0
    hostUp=0
    for host in "${Servers[@]}"
    do
        anyRunningUpg=`ssh ${SSH_OPTIONS} $host "ps -ef | grep ${baseDir} |grep 'run_upgrade\.sh' | grep '/bin/sh' | grep -v grep | awk '{print \$2}'" `
        if [[ $? -ne 0 ]]
        then
            hostUp=1
            echo "[`date "+%Y-%m-%d %H:%M:%S"`] ERROR: Unreachable Host: $host. Please check manually..!!!!"
        fi
        if [[ $anyRunningUpg != "" ]]
        then
            startUpgrade=1
            echo "[`date "+%Y-%m-%d %H:%M:%S"`] ERROR: Upgrade already in progress @ Host: $host."
        fi
    done

    if [[ $startUpgrade -ne 0 ]] || [[ $hostUp -ne 0 ]]
    then
        echo "Exiting Upgrade ..."
        exit 1
    fi

    echo "[`date "+%Y-%m-%d %H:%M:%S"`] INFO: Checking host info and access"

    ping -c 5 $imageHost > /dev/null 2>&1
    if [[ $? -ne 0 ]]
    then
        echo "ip name-server 204.232.241.167" | $cli -m config
        ping -c 5 $imageHost > /dev/null 2>&1

        if [[ $? -ne 0 ]]
        then
            echo "Host: $imageHost is not reachable. Terminating"
        fi
    fi

    runDir=`date "+%Y-%m-%d-%H-%M"`
    runDir=${baseDir}"/"${runDir}
    logFile=${runDir}"/log.txt"
    runUpgrade=${runDir}"/run_upgrade.sh"
    errorFile=${runDir}"/_ERROR"
    successFile=${runDir}"/_SUCCESS"
    TEMP_FILE=`mktemp`

    echo "[`date "+%Y-%m-%d %H:%M:%S"`] INFO: Creating run dirs on each node"

    for host in "${Servers[@]}"
    do
        ssh ${SSH_OPTIONS} $host "mkdir -p ${runDir}" &
    done
    wait

    generateUpgradeScript

    echo "[`date "+%Y-%m-%d %H:%M:%S"`] INFO: Transferring Script on each node"

    for host in "${Servers[@]}"
    do
        scp -q ${TEMP_FILE} root@${host}:${runUpgrade}
    done

    echo "[`date "+%Y-%m-%d %H:%M:%S"`] INFO: Image Upgrade Script Transferred on each node"
    echo "[`date "+%Y-%m-%d %H:%M:%S"`] INFO: Upgrade Script: ${runUpgrade}"
    echo "[`date "+%Y-%m-%d %H:%M:%S"`] INFO: Log File: ${logFile}"
    echo "[`date "+%Y-%m-%d %H:%M:%S"`] INFO: Starting Upgrade on Each Node.........."

    i=0
    for host in "${Servers[@]}"
    do
        ssh -q root@${host} "chmod 744 ${runUpgrade}; ( ${runUpgrade} $i >${logFile} 2>&1 & ) ;  exit 0"
        i=`expr $i + 60`
    done
    echo "[`date "+%Y-%m-%d %H:%M:%S"`] INFO: Upgrade Started. Use: sh `basename $0` -t to check progress."

elif [[ $mode = "" ]]; then
    showUsage
    exit 1
fi
exit 0
