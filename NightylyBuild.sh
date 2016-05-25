baseUrl="http://192.168.153.17/users/neeru/image/"
#baseUrl="http://kite.ggn.in.guavus.com/users/abhishekc/images/"
#baseUrl="http://192.168.104.78/snoopy/work/atlas-release-atlas3.4.rc2_st_cherry_picks_5_4/output/product-guavus-x86_64/release/image/"
#baseUrl="http://station117.ggn.in.guavus.com/release/platform/5.4/v5.4.0.sqa.atlas/"
#baseUrl="http://station117.ggn.in.guavus.com/release/platform/temp/"
#baseUrl="http://station117.ggn.in.guavus.com/release/platform/5.0/v5.0.0.ea.atlas/"
#baseUrl="http://kite.ggn.in.guavus.com/snoopy/work/platform-release-platform-5.2/output/product-guavus-x86_64/release/mfgcd/"
#baseUrl="http://kite.ggn.in.guavus.com/snoopy/work/atlas-release-atlas3.4.rc2_st_cherry_picks/output/product-guavus-x86_64/release/image/"
#baseUrl="http://kite.ggn.in.guavus.com/snoopy/work/atlas-release-atlas3.4.rc2_st_cherry_picks_5_2/output/product-guavus-x86_64/release/image/"
#baseUrl="http://kite.ggn.in.guavus.com/snoopy/work/atlas-release-atlas3.4.rc2_st_cherry_picks_5_4/output/product-guavus-x86_64/release/image/"
#baseUrl="http://station117.ggn.in.guavus.com/release/platform/5.4/v5.4.0.d1.atlas/"
#baseUrl="http://kite.ggn.in.guavus.com/snoopy/work/atlas-release-atlas3.4.rc2_st_cherry_picks_5_0/output/product-guavus-x86_64/release/image/"
#baseUrl="http://192.168.160.61/snoopy/work/atlas-release-atlas3.4.rc2_st_cherry_picks_4_2/output/product-guavus-x86_64/release/image/"
#baseUrl="http://kite.ggn.in.guavus.com/users/ashishk/"
#baseUrl="http://station117.ggn.in.guavus.com/release/platform/5.2/v5.2.0.sqa.atlas/"
#baseUrl="http://station117.ggn.in.guavus.com/release/platform/4.2/v4.2.4.d2.atlas/"
#baseUrl="http://station117.ggn.in.guavus.com/release/platform/4.2/v4.2.4.rc1.atlas/"
#baseUrl="http://station117.ggn.in.guavus.com/release/platform/5.2/v5.2.0.d2.atlas/"

lastImgEpoch=0
admin="abhishek.choudhary@guavus.com"
recipient="abhishek.choudhary@guavus.com"
scriptName=`basename $0`
MAX_SERVER_DOWN_RETRIES=5
NO_NEW_IMAGE_ALERT_AT=8
SSH_OPTIONS="-q -o ConnectTimeout=5 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"

export TZ="Asia/Kolkata"

LOCKFILE=/tmp/nightyly-build.pid
trap "rm -f ${LOCKFILE}; exit" INT TERM

stopPreviousRun(){
	if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}` 2>/dev/null; then
		if grep -q $scriptName /proc/`cat ${LOCKFILE}`/cmdline 2>/dev/null ;then
			cat ${LOCKFILE} | xargs -r kill -9
		fi
	fi
}

get_mimetype(){
	file --mime-type "$1" | sed 's/.*: //'
}

noImageEmail() {
cat<<EOF | sendmail -t
From:AutoMated Crux Sanity<$admin>
To:$recipient
Subject: Error: Wrong Nightly Image URL

Image Not Found at Configured Base Url

URL: $baseUrl

Image Fetch tried at :`date +"%d-%b-%Y %H:%M"`
Next Image check will be tried after One Hour.

Regards
AutoMated Crux Sanity
EOF
}

noNewBuildEmail(){
cat<<EOF | sendmail -t
From:AutoMated Crux Sanity<$admin>
To:$recipient
Subject: Info: No New Nightly Build Yet

There is no new build yet

Last Image was of : `date +"%d-%b-%Y" --date="$currImgDate"`

At Base Url: $baseUrl

Regards
AutoMated Crux Sanity
EOF
}


builStartEmail(){
cat<<EOF | sendmail -t
From:AutoMated Crux Sanity<$admin>
To:$recipient
Subject: Info: Cluster Manufacture Started `date +"%d-%b-%Y %H:%M"`

Cluster Manufacture Started : `date +"%d-%b-%Y %H:%M"`

Image URL  : $baseUrl
Image File : $newImgName

Regards
AutoMated Crux Sanity
EOF
}


buildEndEmail(){
{
printf '%s\n' "From:AutoMated Crux Sanity<$admin>
To:$recipient
Subject: Info: Cluster Manufacture Complete `date +"%d-%b-%Y %H:%M"`

Cluster Manufacture Completed at : `date +"%d-%b-%Y %H:%M"`

Image Used: $fullImageUrl

--------------------------------------
 Setup Image details
--------------------------------------

"

ssh -l root $SSH_OPTIONS 192.168.160.217 "echo 'show version' | /opt/tms/bin/cli -m config"

printf '%s\n' "
Regards
AutoMated Crux Sanity
"
} | sendmail -t -oi

}


buildErrorEmail() {
errorCode=$1

case $errorCode in
	1) errorSubject="VM Boot Failed Check Manually"
		;;
	2) errorSubject="YARN RM is not coming Up"
		;;
	3) errorSubject="Oozie is not coming Up"
		;;
	4) errorSubject="Insta is not coming Up"
		;;
	5) errorSubject="Ib Generation Failed"
		;;
	\?) errorSubject="Unknown Error"
		;;
esac
subject="ERROR: $errorSubject `date +\"%d-%b-%Y %H:%M\"`"
boundary="ZZ_/afg6432dfgkl.94531q"

declare -a attachments
attachments=( "build.log" "log.txt" )


# Build headers
{

printf '%s\n' "From:AutoMated Crux Sanity<$admin>
To: $recipient
Subject: $subject
Mime-Version: 1.0
Content-Type: multipart/mixed; boundary=\"$boundary\"

--${boundary}
Content-Type: text/plain; charset=\"US-ASCII\"
Content-Transfer-Encoding: 7bit
Content-Disposition: inline

Cluster Setup Failed

Image used: $fullImageUrl

Script wont retry to manfucture/setup cluster again with same Image.
If Re-manufacture is required with same image ,re-run Scrit: $scriptName


Regards
AutoMated Crux Sanity
"


for file in "${attachments[@]}"; do

  [ ! -f "$file" ] && echo "Warning: attachment $file not found, skipping" >&2 && continue

  mimetype=$(get_mimetype "$file")

  printf '%s\n' "--${boundary}
Content-Type: $mimetype
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename=\"$file\"
"

  base64 "$file"
  echo
done

# print last boundary with closing --
printf '%s\n' "--${boundary}--"

}| sendmail -t -oi

}

getSleepTime(){
	nextHourString=`date "+%Y-%m-%d %H:00" --date="+ 1hour"`
	nextHourEpoch=`date +"%s" --date "$nextHourString"`
	currEpoch=`date "+%s"`
	currSleepTime=`expr $nextHourEpoch - $currEpoch`
	echo $currSleepTime
}


serverDown=0
main (){

rm -rf /var/opt/tms/images/*

grep -q 'FromLineOverride=YES' /etc/ssmtp.conf
if [[ $? -ne 0 ]];then
	echo "FromLineOverride=YES" >>/etc/ssmtp.conf
fi

lastEmailDay=`date -d@0 +"%Y%m%d"`

#sleep $(getSleepTime)

while [[ 1 ]];do
		latestImageOnBaseMachine=`ls -1rt /var/opt/tms/images/*.img 2>/dev/null | head -1 | xargs -r basename`
		hrefLink=`curl -s $baseUrl | grep -E '\.img' | sed 's/\(.*\)\<a\(.*\)<\/a>\(.*\)/\2/' | sed -e 's/href=//' -e 's/"//g' -e 's/^ *//'`
		if [[ $hrefLink = "" ]];then
			if [[ $serverDown -eq $MAX_SERVER_DOWN_RETRIES ]];then
				lastEmailDay=`date +"%Y%m%d"`
				noImageEmail
				serverDown=0
			else
				serverDown=`expr $serverDown + 1`
			fi
			sleep $(getSleepTime)
			continue
		fi
		serverDown=0
		hrefForImg=`echo $hrefLink | awk -F '>' '{print $1 }'`
		newImgName=`echo $hrefLink | awk -F '>' '{print $2 }'`
		lastImgDate=`echo $latestImageOnBaseMachine | sed -e 's/\(.*\)\([0-9]\{8\}\)-\([0-9]\{6\}\)\(.*\)/\2\3/' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/'`

		if [[ $lastImgDate != "" ]];then
			lastImgEpoch=`date -d "$lastImgDate" "+%s"`
		fi

		currImgDate=`echo $newImgName | sed -e 's/\(.*\)\([0-9]\{8\}\)-\([0-9]\{6\}\)\(.*\)/\2\3/' | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/'`
		currImgEpoch=`date -d "$currImgDate" "+%s"`

		if [[ $currImgEpoch -gt $lastImgEpoch ]];then
			lastImgEpoch=$currImgEpoch
			fullImageUrl="${baseUrl}${newImgName}"
			lastEmailDay=`date +"%Y%m%d"`
			builStartEmail
			sh sanityManufacture.sh -i "${fullImageUrl}" 2>&1 1>build.log
			retStatus=$?
			lastEmailDay=`date +"%Y%m%d"`
			if [[ "$retStatus" -eq 0 ]];then
				buildEndEmail
			else
				buildErrorEmail $retStatus
			fi
                        rm -rf /var/opt/tms/images/$latestImageOnBaseMachine
			sleep $(getSleepTime)
		else
			today=`date +"%Y%m%d"`
			imgDate=`date -d "$currImgDate" +"%Y%m%d"`
			currentHour=`date +"%H"`
			if [[ $today -gt $imgDate ]] && [[ $currentHour -ge $NO_NEW_IMAGE_ALERT_AT ]] && [[ $today -gt $lastEmailDay ]];then
				lastEmailDay=$today
				noNewBuildEmail
			fi
			sleep $(getSleepTime)
		fi
done
}
stopPreviousRun
echo "Starting Nightly Build Crux Sanity daemon ..."
main &
echo $! >${LOCKFILE}
exit 0
