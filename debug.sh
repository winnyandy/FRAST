#!/bin/bash

source ${SCRIPT_PATH}/function.sh
source ${SCRIPT_PATH}/record_device.sh
source /home/dic/script/p_setting.txt


#Check if this script is executed for server
identity=$1
[ $# -eq 2 ] && ip=$2

if [ "$identity" == "server" ];then

	echo $$ > ${SCRIPT_PATH}/server_debug_process

	/bin/bash ${SCRIPT_PATH}/sql.sh delete

	for ip in $(cat ${SCRIPT_PATH}/activeip_*)
	do
		/bin/bash ${SCRIPT_PATH}/sql.sh insert $ip
	done

	sleep 30	
	while true
	do
		for ip in $(cat ${SCRIPT_PATH}/activeip_*)
		do
			sshpass -p ${PASSWD} ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${ACCOUNT}@${ip} "date"; res=$?;
        		if [ ${res} -eq 0 ];then
				/bin/bash ${SCRIPT_PATH}/sql.sh update $ip root_ping ok
			else
				/bin/bash ${SCRIPT_PATH}/sql.sh update $ip root_ping fail
        		fi
			
			if [ "${ip}" == "${SERVERIP}" ];then
				/bin/bash ${SCRIPT_PATH}/sql.sh update $ip hd_stat ok
			fi
		done
		sleep 5
	done
	
else
	max_piece_num=$(cat ${SCRIPT_PATH}/${PIECE_FILE}|wc -l)
	sleep 30	
	until [[ $max_piece_num -eq $(cat /dev/shm/FRAST/nowNum)+1 ]]
	do

		[ -f ${SCRIPT_PATH}/ip.new ] && ip=$(cat ${SCRIPT_PATH}/ip.new) && PrintContent "red" "CHANGE DEBUG IP" "New ip is ${ip}"

		#Check previous ip is survival
		sshpass -p ${PASSWD} ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${ACCOUNT}@${ip} "date"; res=$?;
	        if [ ${res} -eq 0 ];then
			sshpass -p ${PASSWD} ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${ACCOUNT}@${SERVERIP} \
				"/bin/bash ${SCRIPT_PATH}/sql.sh update $ip nextip_ping ok"; res=$?;
		else
			sshpass -p ${PASSWD} ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${ACCOUNT}@${SERVERIP} \
				"/bin/bash ${SCRIPT_PATH}/sql.sh update $ip nextip_ping fail"; res=$?;
	        fi
			
	
		#Check my HD is health
		if [ -f ${SCRIPT_PATH}/ip.new ];then
			myip=$(cat /dev/shm/FRAST/iplist|grep -wA2 $ip|tail -n1)
		else
			myip=$(cat /dev/shm/FRAST/iplist|grep -wA1 $ip|grep -wv $ip)
		fi


		sudo smartctl -H ${ROOTDEVICE} |grep 'PASSED'; res=$?;
		if [ ${res} -eq 0 ];then
			sshpass -p ${PASSWD} ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${ACCOUNT}@${SERVERIP} \
				"/bin/bash ${SCRIPT_PATH}/sql.sh update $myip hd_stat ok";
	                PrintContent "green" "HD HEALTH" "The hard disk is health now!"
		else
			sshpass -p ${PASSWD} ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${ACCOUNT}@${SERVERIP} \
				"/bin/bash ${SCRIPT_PATH}/sql.sh update $myip hd_stat fail";
	                PrintContent "red" "HD HEALTH" "The hard disk is broke now!"
		fi

		sleep 2
	
		#Check if any status is fail and go another road!
		declare -a getStat
		getStat=($(sshpass -p ${PASSWD} ssh -o StrictHostKeyChecking=no ${ACCOUNT}@${SERVERIP} "/bin/bash ${SCRIPT_PATH}/sql.sh check ${ip};";))
	
		root_ping_status=${getStat[0]}
		nextip_ping_status=${getStat[1]}
		hd_stat_status=${getStat[2]}
		
		if [ "${root_ping_status}" != "ok" -o "${nextip_ping_status}" != "ok" -o "${hd_stat_status}" != "ok" ];then
			echo "this computer is dead!"

			upupip=$(cat /dev/shm/FRAST/iplist |grep -wB1 ${ip}|grep -wv ${ip})
			echo $upupip > ${SCRIPT_PATH}/ip.new

			#kill now running memory.sh if upper ip is dead!
			/bin/bash ${SCRIPT_PATH}/kill.sh memory && PrintContent "lightyellow" "DELETE MEMORY.SH OK" "!"


			PrintContent "yellow" "SLEEP 15 SECOND" "!" && sleep 15 

			#rerun memory.sh again
			getCompressAndlastip=($(cat /dev/shm/FRAST/rescue.data))
			getNowPieceNum=$(cat /dev/shm/FRAST/nowNum)

			#get rescue image number
			rescueNum=$(($getNowPieceNum-3))
			PrintContent "lightyellow" "RESCUE NUM: ${rescueNum}" "!" && echo "${rescueNum}" > /dev/shm/FRAST/rescue.num


			if [ "${hd_stat_status}" != "ok" ];then
				((rescueNum+=1))
			fi

			#get piece file name
			if [ ${getNowPieceNum} -lt 10 ];then
				nowPieceName=${TARGET}_000${rescueNum}
			elif [ ${getNowPieceNum} -lt 100 ];then
				nowPieceName=${TARGET}_00${rescueNum}
			elif [ ${getNowPieceNum} -lt 1000 ];then
				nowPieceName=${TARGET}_0${rescueNum}
			fi
	
			#kill /dev/shm/piece...
			if [ ${getNowPieceNum} -lt 10 ];then
				rm -f /dev/shm/FRAST/${nowPieceName} && PrintContent "lightyellow" "DELETE ${nowPieceName}" "!" && echo "${nowPieceName}" > /dev/shm/FRAST/kill.temp
			elif [ ${getNowPieceNum} -lt 100 ];then
				rm -f /dev/shm/FRAST/${nowPieceName} && PrintContent "lightyellow" "DELETE ${nowPieceName}" "!" && echo "${nowPieceName}" > /dev/shm/FRAST/kill.temp
			elif [ ${getNowPieceNum} -lt 1000 ];then
				rm -f /dev/shm/FRAST/${nowPieceName} && PrintContent "lightyellow" "DELETE ${nowPieceName}" "!" && echo "${nowPieceName}" > /dev/shm/FRAST/kill.temp
			fi


			#touch ok file in this computer
			touch ${FLASH_PATH}/${nowPieceName}.ok && PrintContent "yellow" "TOUCH OK FILE IN MYSELF: ${nowPieceName}.ok" "!" && echo "${nowPieceName}.ok" > /dev/shm/FRAST/touchOK.temp
		

 
			if sshpass -p ${PASSWD} scp -o StrictHostKeyChecking=no ${ACCOUNT}@${SERVERIP}:${BASEDIR}/${PARTITION}/${nowPieceName} /dev/shm/FRAST;then
				PrintContent "purple" "RESCUE download ${nowPieceName} done from ${SERVERIP}!" "."
			fi

			piece_md5=$(cat ${SCRIPT_PATH}/${PIECE_FILE}|grep ${nowPieceName}|cut -d ':' -f2)
			current_md5=$(md5sum /dev/shm/FRAST/${nowPieceName} |awk '{print $1}')
			if [ "${current_md5}" == "${piece_md5}" ];then
			                                                                                                                                                   
			        PrintContent "lightyellow" "RESCUE server memory ${nowPieceName} check md5 is ok" "."
			                                                                                                                                                   
			        #create unlock file
				touch /dev/shm/FRAST/${nowPieceName}.unlock
				PrintContent "lightyellow" "RESCUE created ${nowPieceName}.unlock file finish!" "."
				
				#remote upperip and touch ok file
				if sshpass -p ${PASSWD} ssh -o StrictHostKeyChecking=no  ${ACCOUNT}@${upupip} "touch /dev/shm/FRAST/${nowPieceName}.ok" ;then
					PrintContent "lightyellow" "RESCUE remote ${upupip} and created ${nowPieceName}.ok file finish!" "."
				fi
			fi
		fi
		sleep 5
	done


fi

