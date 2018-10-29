#!/bin/bash
source /home/dic/script/p_setting.txt
source ${SCRIPT_PATH}/function.sh


upperip=${1}

piece_num=${2}

compression=${3}

is_last_ip=${4}

#get each ip in piece_name array
GetPieceName

#get each MD5 in piece_md5 array
GetPieceMD5

#get now file name
GetFileName

max_piece_num=$(cat ${SCRIPT_PATH}/${PIECE_FILE}|wc -l)

if [ "${upperip}" == "server" ];then
	while true
	do	
		cp ${BASEDIR}/${PARTITION}/${piece_name[${piece_num}]} /dev/shm/FRAST/${piece_name[${piece_num}]}
		current_md5=$(md5sum /dev/shm/FRAST/${piece_name[${piece_num}]} |awk '{print $1}')

		if [ "${current_md5}" == "${piece_md5[${piece_num}]}" ];then
			PrintContent "green" "OK" "server memory ${piece_name[${piece_num}]} check md5 is ok"
			touch /dev/shm/FRAST/${piece_name[${piece_num}]}.unlock
			exit 0
		fi
	done
else
	CheckInputVariable ${1}
	while true
	do
		sshpass -p ${PASSWD} ssh -o StrictHostKeyChecking=no ${ACCOUNT}@${upperip} "[ -e /dev/shm/FRAST/${piece_name[${piece_num}]}.unlock ]" ; res=$?;
		
		if [ ${res} -eq 0 ];then
			while true
		        do
				if sshpass -p ${PASSWD} scp -o StrictHostKeyChecking=no ${ACCOUNT}@${upperip}:/dev/shm/FRAST/${piece_name[${piece_num}]} /dev/shm/FRAST;then
					PrintContent "green" "OK" "download piece done from ${upperip}!"
				fi
		                current_md5=$(md5sum /dev/shm/FRAST/${piece_name[${piece_num}]} |awk '{print $1}')
		                if [ "${current_md5}" == "${piece_md5[${piece_num}]}" ];then

		                        PrintContent "green" "OK" "server memory ${piece_name[${piece_num}]} check md5 is ok"


					echo "${piece_num}" > /dev/shm/FRAST/mem_Num

		                        #create unlock file
					touch /dev/shm/FRAST/${piece_name[${piece_num}]}.unlock
					PrintContent "green" "OK" "created ${piece_name[${piece_num}]}.unlock file finish!"
					
					#remote upperip and touch ok file
					if sshpass -p ${PASSWD} ssh -o StrictHostKeyChecking=no  ${ACCOUNT}@${upperip} "touch /dev/shm/FRAST/${piece_name[${piece_num}]}.ok" ;then
						PrintContent "green" "OK" "remote ${upperip} and created ${piece_name[${piece_num}]}.ok file finish!"
					fi
					
					if [ ${piece_num} -eq 0 ];then
						/bin/bash ${SCRIPT_PATH}/hd.sh ${compression} &
					elif [ ${piece_num} -eq $((${max_piece_num}-1)) -a "${is_last_ip}" == "lastip" ];then
						if sshpass -p ${PASSWD} ssh -o StrictHostKeyChecking=no  ${ACCOUNT}@${SERVERIP} "touch /dev/shm/finish_memory_${file_name}" ;then
                                                	PrintContent "green" "OK" "remote ${SERVERIP} and created /dev/shm/finish_memory_${file_name} file finish!"
                                        	fi

						if sshpass -p ${PASSWD} ssh -o StrictHostKeyChecking=no  ${ACCOUNT}@${SERVERIP} "sudo /bin/bash ${SCRIPT_PATH}/kill.sh debugServer" ;then
                                                	PrintContent "green" "OK" "remote ${SERVERIP} and sh kill.sh finish!"
                                        	fi
					fi
					
					break
		                fi
			done
			break
		else
			PrintContent "red" "FAILED" "${upperip} is not have ${piece_name[${piece_num}]}.unlock file on /dev/shm/FRAST"
			us=$(awk "BEGIN{printf \"%.2f\n\", ${SLEEP_SEC} / 1000000}")
			PrintContent "yellow" "SLEEP" "wait ${us}s before reconnecting once!"
			usleep ${SLEEP_SEC}
		fi
	done
fi



