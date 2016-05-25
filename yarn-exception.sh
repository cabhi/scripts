function yarnExceptions(){
if [[ $# -ne 1 ]];then
        echo "Please Enter a Valid Yarn Application Id"
        return 1
fi

RESULT_FILE="$HOME/result.txt"
EXCEPTION_FILE="$HOME/unique_exception.txt"
ERROR_FILE=`mktemp`
yarn logs -applicationId $* 2>$ERROR_FILE |sed -r -n '
:start
'/^[0-9]{2}\\/[0-9]{2}/'{
                h
                n
                :loop
                '/^[0-9]/' {
                                x
                                n
                                b loop
                                }
                '/^[0-9]/!'{
                                '/java\|hadoop/' {
                                                i\
-->
                                                x
                                                p
                                                x
                                                :loop2
                                                p
                                                n
                                                '/^[[:space:]]/' {
                                                                b loop2
                                                }
                                                '/Caused[[:space:]]by/' {
                                                                b loop2
                                                }
                                                '/Driver[[:space:]]stacktrace/' {
                                                                b loop2
                                                }
                                                b start
                                }
                }
                d
}
'>$RESULT_FILE
if [[ ! -s $RESULT_FILE ]];then
	if grep -q 'Invalid ApplicationId specified' $ERROR_FILE;then
		cat $ERROR_FILE
	else
		echo "No Exception Found"
	fi
	rm -rf $ERROR_FILE
	return
fi 
tDir=`mktemp -d`
fCount=0
while IFS= read -r line
do
                if [[ $line = "-->" ]];
                then
                                fCount=`expr $fCount + 1`
                                continue
                fi
                if [[ ! -f $tDir/$fCount ]];then
                                touch $tDir/$fCount
                else
                                echo "${line}" >>$tDir/$fCount
                fi
done<$RESULT_FILE
MD5SUM_FILE=`mktemp`
lastCheckSum=""
ls -l $tDir/* 2>/dev/null | grep -v '^total' | sort -r -n -k4,4 | awk '{print $9}' | xargs md5sum| while read -r ckSum fName;do
if [[ $lastCheckSum != $ckSum ]];then
	grep -q "$ckSum" $MD5SUM_FILE 2>/dev/null
	if [[ $? -ne 0 ]];then 
                echo "==========================================="
                cat $fName
                lastCheckSum=$ckSum
		echo $ckSum>>$MD5SUM_FILE
	fi
fi
done>$EXCEPTION_FILE
rm -rf $ERROR_FILE
rm -rf $MD5SUM_FILE
#rm -rf $tDir
cat $EXCEPTION_FILE
}
