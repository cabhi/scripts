#!/usr/bin/env bash
#--------------------------------------------------------------------
#			How to Use
#  Put this shell script into home dir and make sure home dir has
#  write permissions. This script write two temp files as use them
#  for storing command syntax and last ls output
#
# 			One small HACK
#  If current path is in buffer but you want to do a fresh search
#  put any valid wild card in the end of current path and script will
#  perform a new hdfs path completion rather than showing results from
#  last buffer
#----------------------------------------------------------------------

# This variable will control depth of next level of files/dir  search
# with current path location and handle that buffer accordingly
# user can change these values from 0-5
# for higher values it might take extra time

searchNextLevel=3

# two temporary files in order to make tab responses fast

complitonFile="$HOME/.auto_yarn_cmd"
hadoopLs="$HOME/.auto_hadoop_ls"
#isSnakeBite=$(which snakebite 2>/dev/null)

[[ -f $complitonFile ]] && source $complitonFile || touch $complitonFile
[[ ! -f $hadoopLs ]] && touch $hadoopLs

varAppender="complete_"

_addToYarnAutoCompletion(){
	echo "export $1=\"${2}\"">>$complitonFile
	source $complitonFile
}

_addToHadoopLs(){
	{
		echo "that_cmd=\"$1\""
		echo "that_cur=\"$2\""
		echo "that_upto=$3"
		echo "hdfs_upto=$4"
		echo "that_temp=\"$5\""
	}>$hadoopLs
}


_fsAdvHandling(){
	options=`echo ${COMP_WORDS[2]}| sed 's/[ \t]*-//'`
	completeListVar="${varAppender}${script}${COMP_WORDS[1]}${options}"
	eval completeList="\$$completeListVar"
	cmdSynVar="${varAppender}${script}${COMP_WORDS[1]}${options}_syn"
	eval cmdSyntax="\$$cmdSynVar"

	# Check if we already parsed this command syntax or not

	if [[ -z $cmdSyntax ]];then
		commandSyntax=`$script ${COMP_WORDS[1]} -usage $options 2>&1`
		echo "$commandSyntax" | grep -q 'Unknown command'
		if [[ $? -eq 0 ]];then
			return 1
		else
			commandSyntax=`echo $commandSyntax | sed 's/\(.*\)-'$options'\(.*\)/\2/'`
		fi
		_addToYarnAutoCompletion ${cmdSynVar} "${commandSyntax}"
	else
		commandSyntax=$cmdSyntax
	fi

	curStartWith=${cur:0:1}
	prevStartWith=${prev:0:1}

	# Check if User is trying to access optional flags

	if  [[ $curStartWith = "-" ]];then
		completeListVar="${varAppender}${script}${COMP_WORDS[1]}${options}"
		eval completeList="\$$completeListVar"
			if [[ -z $completeList ]];then
				temp=`echo $commandSyntax | cut -d '<' -f1 |awk '{gsub(/[\[\]]/, "\n"); print $0}' | sed '/^[ \t]*$/ d'`;
				_addToYarnAutoCompletion ${completeListVar} "${temp}"
			else
				temp=$completeList
			fi
		COMPREPLY=(`compgen -W "${temp}" -- ${cur}`);
		return 0
	else
		# Check if command is expecting hdfs file-system path or local file-system path
		# script currently handling only upto 2 arguments for a command , if more it will return

		[[ $prevStartWith = "-" ]] && temp=2 || temp=3
		temp=`echo $commandSyntax | cut -d '<' -f $temp |awk '{gsub(/[\[\]\> \.]/, ""); print $0}'`;

		if [ ${#temp} -lt 1 ]; then
			# No match
			return 1;
		fi;

		# Handle hdfs and local file-system path completion

		case $temp in
			path | src | dst)

				#Retrieve last hdfs ls output
				source $hadoopLs

				echo "$cur" | grep -q -E '[*?]|\.\.'
				[[ $? -eq 0 ]] && regExUsed="true" || regExUsed="false"

				this_cmd=$(echo "${COMP_WORDS[0]}-${COMP_WORDS[1]}-${COMP_WORDS[2]}" | tr -s "-"|tr "-" "_")
				this_upto=$(echo "$cur" |awk -F '/' '{print NF}')

				# IF user used any regex,alwasys perform a new search
				# as we are not sure of all the changes user made
				# ELSE check if current path is in last ls output

				if 	[[ $that_cmd = $this_cmd ]] && \
					[[ $regExUsed = "false" ]] && \
					[[ ${cur/$that_cur} != $cur ]] && \
					[[ "$cur" = "${that_cur}"* ]] && \
					[[ ${this_upto} -lt ${that_upto} ]];then
					temp=`echo "$that_temp" | grep -E "${cur}." 2>/dev/null`
				else

					# make hdfs ls string in order to retrieve files for next levels also
					# This is required just to make next few hdfs path completions fast and
					# minimize hdfs ls operation as every ls takes ~3-9 seconds

					appender="/*"
					lString=""

					tString=($(for ((i=1; i<=$searchNextLevel; i++));do printf "%s" "\"${appender}${lString}\"" ;printf "\n";lString="${appender}${lString}";done;))

					if [[ ${cur#${cur%?}} = "/" ]];then
						hdfsPathString=$( echo ${tString[@]} |sed 's#"/#"'$cur'*/#g' |sed 's#^#"'$cur'" "'$cur'*" #' | sed 's/"//g')
						extraLevel=2
					else
						hdfsPathString=$( echo ${tString[@]} |sed 's#"/#"'$cur'*/#g' |sed 's#^#"'$cur'*" #' | sed 's/"//g')
						extraLevel=1
					fi

					#disable shell expansaion for * so that it searches files correctly on hdfs
					#after hdfs -ls enable it again

					set -f
					if [[ ! -z $isSnakeBite ]];then
						temp=$($isSnakeBite ls $hdfsPathString 2>/dev/null | grep -vE '^Found ' | awk '{if ($0 ~ /^d/) {print $8"/"} else {print $8}}'|sed '/^[ \t]*$/d'| sort -u)
					else
						temp=$($script ${COMP_WORDS[1]} -ls $hdfsPathString 2>/dev/null | grep -vE '^Found ' | awk '{if ($0 ~ /^d/) {print $8"/"} else {print $8}}'|sed '/^[ \t]*$/d'| sort -u)
					fi
					set +f

					# If last hdfs ls command returned no results for current dir
					# This means its an empty dir,so if a user press another tab
					# a space will added on command prompt as an indication for emptry dir

					if [[ -z $temp ]];then
						if [[ ${cur#${cur%?}} = "/" ]] && [[ $regExUsed = "false" ]];then
							compopt +o nospace -o filenames
							COMPREPLY=("$cur");
							return 0
						else
							# Something else went wrong, we have no idea
							return 1
						fi
					fi

					# just a handler to tell maximum no of / in its output
					# this is used for returning correct buffer from last ls output
					# in further tabs

					that_upto=$(( $(echo "${cur}""/"| sed -e 's#/\.\./#/#g' -e 's#/\.\.##g' -e 's#\.\./##g'|sed 's#/[/]*#/#g'|awk -F '/' '{print NF}') + searchNextLevel + extraLevel ))
					hdfs_upto=$(echo "$temp"| awk -F '/' '{print NF}' | sort -n | tail -1 )

					# IF regex was used then find the common path in all returned results

					if [[ $regExUsed = "true" ]];then
						if [[ $(echo "$temp" | wc -l) -eq 1 ]];then
							cur=$temp
						else
							i=1
							while [[ 1 ]];do
								if [[ $(echo "$temp" | cut -c $i |sort -u |wc -l) -gt 1 ]];then
									break
								fi
								i=$((i + 1))
							done
							cur=$(echo "$temp"| head -1 | cut -c 1-$(($i - 1)))
						fi
					fi

					# Put this ls output to a file so that it can retrieved next time
					_addToHadoopLs "$this_cmd" "$cur" "$that_upto" "$hdfs_upto" "$temp"
				fi

				# Handling to show hdfs files and dirs the same way as bash shows for local file-system on tab
				# reduce the temp buffer output for

				noOfF=`echo $cur | awk -F '/' '{print NF}'`
				[[ $noOfF -ge 1 ]] && noOfF=$noOfF || noOfF=1
				temp=`echo "$temp"| sed 's#/[^/]*#/#'$noOfF'g' | sort -u | sed 's#/[/]*#/#g'| sort -u`

				tReply=(`compgen -W "${temp}" -- ${cur}`)

				localDirs=(`find ${cur}* -maxdepth 0 -type d -follow 2>/dev/null`)
				if [[ ${#localDirs[@]} -ge 1 ]];then
					for ((i=0; i < ${#tReply[@]}; i++))
					do
						for ((j=0; j < ${#localDirs[@]}; j++))
						do
							if [[ ${tReply[$i]} = ${localDirs[$j]}"/" ]];then
								tReply[$i]=${localDirs[$j]}
							fi
						done
					done
				fi

				# Handling to show a space if current dir is empty or its a file

				if [[ ${#tReply[@]} -eq 1 ]] && [[ $this_upto -le $hdfs_upto ]];then
					if [[ ${tReply#${tReply%?}} != "/" ]];then
						compopt +o nospace -o filenames
					else
						compopt -o nospace -o filenames
					fi
				elif [[ ${#tReply[@]} -eq 0 ]] && [[ $this_upto -le $hdfs_upto ]];then
					tReply=$(echo "$that_temp" | grep "$cur" 2>/dev/null)
					if [[ -z $tReply ]];then
						unset tReply
						compopt -o nospace -o filenames
					else
						[[ -d $tReply ]] && compopt +o nospace || compopt +o nospace -o filenames
					fi
				else
					compopt -o nospace -o filenames
				fi
				COMPREPLY=("${tReply[@]}");
				return 0;;

			localsrc | localdst)
				# Local path completion
				compopt -o nospace -o default
				COMPREPLY=();
				return 0;;
			*)
				# Other arguments - no idea
				return 1;;
		esac
	fi
}

_hadoopAutoComplete() {
	local script cur prev temp
	COMPREPLY=()
	cur=${COMP_WORDS[COMP_CWORD]}
	prev=${COMP_WORDS[COMP_CWORD-1]}
	script=${COMP_WORDS[0]}

	case $COMP_CWORD in
		1)
			completeListVar="${varAppender}${script}"
			eval completeList="\$$completeListVar"

			temp=`$script | grep -n "^\s*or"`;

			if [[ -z $completeList ]];then
				temp=`$script | tail -n +3 | awk '/^ /{print}' | cut -d " " -f3 | sed '/^ *$/d'`
				_addToYarnAutoCompletion ${completeListVar} "${temp}"
			else
				temp=$completeList
			fi

			COMPREPLY=(`compgen -W "${temp}" -- ${cur}`);
			return 0
			;;

		2)
			completeListVar="${varAppender}${script}${COMP_WORDS[1]}"
			eval completeList="\$$completeListVar"

			case ${COMP_WORDS[1]} in
				fs|daemonlog)
					if [[ -z $completeList ]];then
						temp=`$script ${COMP_WORDS[1]} 2>&1 | awk '/^[ \t]*\[/ {gsub(/[\[\]]/, ""); print $1}'`;
						_addToYarnAutoCompletion ${completeListVar} "${temp}"
					else
						temp=$completeList
					fi
					;;

				jar)
					compopt -o nospace -o default
					COMPREPLY=();
					return 0
					;;

				distcp)
					if [[ -z $completeList ]];then
						temp=`$script ${COMP_WORDS[1]} 2>&1 | awk '/^[ \t]*\-/ { print $1}'`;
						_addToYarnAutoCompletion ${completeListVar} "${temp}"
					else
						temp=$completeList
					fi
					;;
				*)
					# Other commands - no idea
					return 1;;
			esac

			COMPREPLY=(`compgen -W "${temp}" -- ${cur}`);
			return 0
			;;

		*)
			case ${COMP_WORDS[1]} in
				dfs | fs)
					_fsAdvHandling
					return $?
					;;
				*)
					return 1
					;;
			esac
			;;
	esac;
}


_hdfsAutoComplete() {
	local script cur prev temp
	COMPREPLY=()
	cur=${COMP_WORDS[COMP_CWORD]}
	prev=${COMP_WORDS[COMP_CWORD-1]}
	script=${COMP_WORDS[0]}

	case $COMP_CWORD in
		1)
			completeListVar="${varAppender}${script}"
			eval completeList="\$$completeListVar"

			temp=`$script | grep -n "^\s*or"`;
			if [[ -z $completeList ]];then
				temp=`$script | tail -n +3 | awk '/^ /{print}' | cut -d " " -f3 | sed '/^ *$/d'`
				_addToYarnAutoCompletion ${completeListVar} "${temp}"
			else
				temp=$completeList
			fi

			COMPREPLY=(`compgen -W "${temp}" -- ${cur}`);
			return 0
			;;

		2)
			completeListVar="${varAppender}${script}${COMP_WORDS[1]}"
			eval completeList="\$$completeListVar"

			case ${COMP_WORDS[1]} in
				dfs | dfsadmin | fs | job | pipes | mradmin|getconf)
					if [[ -z $completeList ]];then
						temp=`$script ${COMP_WORDS[1]} 2>&1 | awk '/^[ \t]*\[/ {gsub(/[\[\]]/, ""); print $1}'`;
						_addToYarnAutoCompletion ${completeListVar} "${temp}"
					else
						temp=$completeList
					fi
					;;

				jar)
					compopt -o nospace -o default
					COMPREPLY=();
					return 0
					;;

				namenode | secondarynamenode|journalnode|zkfc)
					if [[ -z $completeList ]];then
						temp=`$script ${COMP_WORDS[1]} --help 2>&1 | grep -i "Usage:" | cut -d '[' -f 2- | awk '{gsub(/[\[\] \t\|]/, " "); print}'`;
						_addToYarnAutoCompletion ${completeListVar} "${temp}"
					else
						temp=$completeList
					fi
					;;

				datanode)
					if [[ -z $completeList ]];then
						temp=`$script ${COMP_WORDS[1]} --help 2>&1 | awk '/Usage:/ {getline; gsub(/[\[\]]/, ""); print}'`;
						_addToYarnAutoCompletion ${completeListVar} "${temp}"
					else
						temp=$completeList
					fi
					;;

				fsck)

					if [[ -z $completeList ]];then
						temp=`$script ${COMP_WORDS[1]} 2>&1 | grep -i "Usage:" | cut -d '>' -f 2 | awk '{gsub(/[\[\]\|]/, ""); print}'`;
						_addToYarnAutoCompletion ${completeListVar} "${temp}"
					else
						temp=$completeList
					fi
					;;

				balancer)

					if [[ -z $completeList ]];then
						temp=`$script ${COMP_WORDS[1]} --help 2>&1 | awk '/^[ \t]*\[/ {gsub(/[\[\]]/, ""); print $1}'`;
						_addToYarnAutoCompletion ${completeListVar} "${temp}"
					else
						temp=$completeList
					fi
					;;

				jmxget)

					if [[ -z $completeList ]];then
						temp=`$script ${COMP_WORDS[1]} --help	2>&1 | awk '/^[ \t]+\-/ { print $1}'`;
						_addToYarnAutoCompletion ${completeListVar} "${temp}"
					else
						temp=$completeList
					fi
					;;

				oiv|oev)

						if [[ -z $completeList ]];then
						temp=`$script ${COMP_WORDS[1]} --help 2>&1 | sed '/Generic options supported are/,$ d' |awk -F '[, ]' '/^\-/ {print $2}'`;
						_addToYarnAutoCompletion ${completeListVar} "${temp}"
					else
						temp=$completeList
					fi
					;;

				fetchdt)

					if [[ -z $completeList ]];then
						temp=`$script ${COMP_WORDS[1]} 2>&1 | awk '/[ \t]*--/ {print $1}'`;
						_addToYarnAutoCompletion ${completeListVar} "${temp}"
					else
						temp=$completeList
					fi
					;;

				*)
					# Other commands - no idea
					return 1
					;;
			esac
			COMPREPLY=(`compgen -W "${temp}" -- ${cur}`);
			return 0
			;;

		*)
			case ${COMP_WORDS[1]} in
				dfs | fs)
					_fsAdvHandling
					return $?
					;;
				*)
					return 1
					;;
			esac
			;;
	esac;
}


_yarnAutoComplete() {
	local script cur prev temp
	COMPREPLY=()
	cur=${COMP_WORDS[COMP_CWORD]}
	prev=${COMP_WORDS[COMP_CWORD-1]}
	script=${COMP_WORDS[0]}

	case $COMP_CWORD in
		1)
			completeListVar="${varAppender}${script}"
			eval completeList="\$$completeListVar"

			temp=`$script | grep -n "^\s*or"`;
			if [[ -z $completeList ]];then
				temp=`$script | tail -n +3 | awk '/^ /{print}' | cut -d " " -f3 | sed '/^ *$/d'`
				_addToYarnAutoCompletion ${completeListVar} "${temp}"
			else
				temp=$completeList
			fi

			COMPREPLY=(`compgen -W "${temp}" -- ${cur}`);
			return 0
			;;

		2)
			completeListVar="${varAppender}${script}${COMP_WORDS[1]}"
			eval completeList="\$$completeListVar"

			case ${COMP_WORDS[1]} in
				rmadmin|application|applicationattempt|container|node)
					if [[ -z $completeList ]];then
						temp=`$script ${COMP_WORDS[1]} 2>&1 | awk '/^[ \t]+\-/ { print $1}'`;
						_addToYarnAutoCompletion ${completeListVar} "${temp}"
					else
						temp=$completeList
					fi
					;;
				daemonlog)
					if [[ -z $completeList ]];then
						temp=`$script ${COMP_WORDS[1]} 2>&1 | awk '/^[ \t]*\[/ {gsub(/[\[\]]/, ""); print $1}'`;
						_addToYarnAutoCompletion ${completeListVar} "${temp}"
					else
						temp=$completeList
					fi
					;;
				logs)
					temp="-applicationId"
					;;
				*)
					# Other commands - no idea
					return 1;;
			esac

			COMPREPLY=(`compgen -W "${temp}" -- ${cur}`);
			return 0
			;;
		*)
			return 1
			;;
	esac;
}

_mapredAutoComplete() {
	local script cur prev temp
	COMPREPLY=()
	cur=${COMP_WORDS[COMP_CWORD]}
	prev=${COMP_WORDS[COMP_CWORD-1]}
	script=${COMP_WORDS[0]}

	case $COMP_CWORD in
		1)
			completeListVar="${varAppender}${script}"
			eval completeList="\$$completeListVar"

			temp=`$script | grep -n "^\s*or"`;
			if [[ -z $completeList ]];then
				temp=`$script | tail -n +3 | awk '/^ /{print}' | cut -d " " -f3 | sed '/^ *$/d'`
				_addToYarnAutoCompletion ${completeListVar} "${temp}"
			else
				temp=$completeList
			fi

			COMPREPLY=(`compgen -W "${temp}" -- ${cur}`);
			return 0
			;;
		2)
			completeListVar="${varAppender}${script}${COMP_WORDS[1]}"
			eval completeList="\$$completeListVar"

			case ${COMP_WORDS[1]} in
				pipes | job | queue|hsadmin)
					if [[ -z $completeList ]];then
						temp=`$script ${COMP_WORDS[1]} 2>&1 | awk '/\s*\[-/ {gsub(/[\[\]\|]/, ""); print $1}'`;
						_addToYarnAutoCompletion ${completeListVar} "${temp}"
					else
						temp=$completeList
					fi
					;;
				*)
					# Other commands - no idea
					return 1;;
			esac

			COMPREPLY=(`compgen -W "${temp}" -- ${cur}`);
			return 0
			;;
		*)
				return 1;;
		esac;
}

complete -F _hadoopAutoComplete hadoop
complete -F _hdfsAutoComplete hdfs
complete -F _yarnAutoComplete yarn
complete -F _mapredAutoComplete mapred

