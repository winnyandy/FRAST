#!/bin/bash
source /home/dic/script/global_setting.txt
source ${SCRIPT_PATH}/function.sh

declare -a abpath
declare -a filename
declare -a basedir
declare -a partition
count=0

if [ $# -eq 0 ];then
        echo "Please input [compression] [file absolute path] ....."
        exit 0
elif [ $# -gt 0 ];then
	compression=$1
	shift
fi

#get p_setting variable
while [ $# -gt 0 ]
do
	abpath[$count]=${1}
	filename[$count]=$(echo ${abpath[$count]}|awk -F '/' '{print $NF}')
	basedir[$count]=$(echo ${abpath[$count]}|sed -e "s/${filename[$count]}//g"|sed -e "s/\/$//g")
	partition[$count]=$(echo ${abpath[$count]}|awk -F '/' '{print $NF}'|awk -F'.' '{print $1}')
	((count+=1));
	shift;
done

for num in $( seq 0 $((${#filename[@]}-1)) )
do

	#if pieces folder is not exists, mkdir pieces
	if [ ! -d "${basedir[$num]}/${partition[$num]}" ];then
		mkdir ${basedir[$num]}/${partition[$num]} 
		PrintContent "green" "OK" "finish mkdir ${basedir[$num]}/${partition[$num]}"

		#run PreSplitPiece.sh , default piece size is 200M
		if /bin/bash ${SCRIPT_PATH}/PreSplitPiece.sh ${abpath[$num]} 200M;then
			PrintContent "green" "OK" "start to split piece"
		fi
	else
		PrintContent "darkblue" "EXISTS" "exists folder ${basedir[$num]}/${partition[$num]}"
	fi


	#delete each partition information(p_setting.txt)
	if rm -rf p_setting.txt;then
		PrintContent "green" "OK" "finish delete p_setting.txt"
	fi

	#write new partition information(p_setting.txt)
	echo "BASEDIR='${basedir[${num}]}'" >> p_setting.txt
	echo "PIECE_FILE_SERVER='${filename[${num}]}'" >> p_setting.txt
	echo "TARGET='${filename[${num}]}'" >> p_setting.txt
	echo "PARTITION='${partition[${num}]}'" >> p_setting.txt


	#run server main
	if [ $num -eq 0 ];then 
		rm -rf /dev/shm/finish*
		rm -rf ${SCRIPT_PATH}/server_debug_process
		#run main.sh
                if /bin/bash ${SCRIPT_PATH}/main.sh server ${compression} nolastip;then
                        PrintContent "green" "OK" "finish to run main.sh"
                fi
	elif [ $num -gt 0 ];then

		if [ -f ${SCRIPT_PATH}/server_debug_process ];then
			/bin/bash ${SCRIPT_PATH}/kill.sh debugServer
			PrintContent "green" "OK" "delete server debug.sh"
		fi

		until [ -e /dev/shm/finish_memory_${filename[$(($num-1))]} ]
		do 
			us=$(awk "BEGIN{printf \"%.2f\n\", ${SLEEP_SEC} / 1000000}")
                        PrintContent "yellow" "SLEEP" "wait ${us}s for /dev/shm/finish_memory_${filename[$(($num-1))]}!"
                        usleep  ${SLEEP_SEC}
		done

		#run main.sh
		if /bin/bash ${SCRIPT_PATH}/main.sh server ${compression} nolastip;then
			PrintContent "green" "OK" "finish to run main.sh"
		fi
	fi
done
