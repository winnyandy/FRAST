#!/bin/bash
source /home/dic/script/p_setting.txt
source /home/dic/script/global_setting.txt
source ${SCRIPT_PATH}/function.sh

piece_num=0
upperip=${1}
compression=${2}
is_last_ip=${3}

if [ "${upperip}" == "server" ];then

	#mkdir /dev/shm folder FRAST
	[ ! -d /dev/shm/FRAST ] && mkdir /dev/shm/FRAST && PrintContent "green" "OK" "finish mkdir /dev/shm/FRAST!"
        [ -d /dev/shm/FRAST ] && chmod 777 /dev/shm/FRAST && PrintContent "green" "OK" "finish chmod 777  /dev/shm/FRAST!"	

	#to delete /dev/shm/FRAST folder content
	[ -d /dev/shm/FRAST ] && rm -rf /dev/shm/FRAST/* && PrintContent "green" "OK" "deleted finish /dev/shm/FRAST content!"
	rm -rf /dev/shm/FRAST/finish_* && PrintContent "green" "OK" "deleted finish /dev/shm/finish_* content!"

	#cp piece.txt to script folder
	if cp ${BASEDIR}/${PARTITION}/piece.txt ${SCRIPT_PATH};then
		PrintContent "green" "OK" "success cp piece.txt to script folder!"
	else
		PrintContent "red" "FAILED" "failed cp piece.txt to script folder!"
	fi

	#cp piece.txt(content contains md5sum) to /dev/shm/FRAST
	if cp ${BASEDIR}/${PARTITION}/piece.txt /dev/shm/FRAST;then
		PrintContent "green" "OK" "success cp piece.txt to /dev/shm/FRAST!"
	else
		PrintContent "red" "FAILED" "failed cp piece.txt to /dev/shm/FRAST!"
	fi
	
	#cp p_setting.txt(content contains basic directory location,file name) to /dev/shm/FRAST
	if cp ${SCRIPT_PATH}/p_setting.txt /dev/shm/FRAST;then
		PrintContent "green" "OK" "success cp p_setting.txt to /dev/shm/FRAST!"
	else
		PrintContent "red" "FAILED" "failed cp p_setting.txt to /dev/shm/FRAST!"
	fi

	#cp piece.txt(content contains md5sum) to /dev/shm/FRAST
	if cp ${BASEDIR}/disk /dev/shm/FRAST;then
		PrintContent "green" "OK" "success cp disk to /dev/shm/FRAST!"
	else
		PrintContent "red" "FAILED" "failed cp disk to /dev/shm/FRAST!"
	fi

	#cp MBR to /dev/shm/FRAST
	if cp ${BASEDIR}/system.mbr /dev/shm/FRAST;then
		PrintContent "green" "OK" "success cp mbr to /dev/shm/FRAST!"
	else
		PrintContent "red" "FAILED" "failed cp mbr to /dev/shm/FRAST!"
	fi

	#run preserver.sh
	if /bin/bash ${SCRIPT_PATH}/preserver.sh ${compression};then 
		PrintContent "green" "OK" "success to execute preserver.sh"
	fi


	
else
	CheckInputVariable ${1}

	if sudo chmod 1777 /dev/shm;then
		PrintContent "green" "OK" "success to chmod 1777 /dev/shm"
	fi
	

	if sudo chmod 777 ${SCRIPT_PATH};then
		PrintContent "green" "OK" "success to chmod 777 ${SCRIPT_PATH}"
	fi

	#mkdir /dev/shm folder FRAST
	[ ! -d /dev/shm/FRAST ] && mkdir /dev/shm/FRAST && PrintContent "green" "OK" "finish mkdir /dev/shm/FRAST!"
        [ -d /dev/shm/FRAST ] && chmod 777 /dev/shm/FRAST && PrintContent "green" "OK" "finish chmod 777  /dev/shm/FRAST!"	

	#to delete /dev/shm/FRAST folder content
	[ -d /dev/shm/FRAST ] && rm -rf /dev/shm/FRAST/* && PrintContent "green" "OK" "deleted finish /dev/shm/FRAST content!"


	#download iplist
        if sshpass -p ${PASSWD} scp -o StrictHostKeyChecking=no ${ACCOUNT}@${SERVERIP}:${SCRIPT_PATH}/iplist /dev/shm/FRAST;then
                PrintContent "green" "IPLIST" "download iplist done from server!"
        fi

	#format the partition table
	if sshpass -p ${PASSWD} scp -o StrictHostKeyChecking=no  ${ACCOUNT}@${SERVERIP}:/dev/shm/FRAST/disk /dev/shm/FRAST;then
	        PrintContent "green" "OK" "download disk done from ${upperip}!"
		if [ ! -e ${SCRIPT_PATH}/disk ];then
			#download MBR
			if sshpass -p ${PASSWD} scp -o StrictHostKeyChecking=no  ${ACCOUNT}@${SERVERIP}:/dev/shm/FRAST/system.mbr /dev/shm/FRAST;then
				PrintContent "green" "OK" "download MBR done from ${upperip}!"
				if mv /dev/shm/FRAST/system.mbr ${SCRIPT_PATH}/;then
					PrintContent "green" "OK" "success cp MBR to ${SCRIPT_PATH}"
				fi
			fi
			#run format partition table
			if mv /dev/shm/FRAST/disk ${SCRIPT_PATH}/;then
				PrintContent "green" "OK" "success cp disk to ${SCRIPT_PATH}"
				#delete and create partition table
				if /bin/bash ${SCRIPT_PATH}/mk_partition.sh;then
					PrintContent "green" "OK" "success to create partition table"
				fi
			fi
		fi
	fi

	if sshpass -p ${PASSWD} scp -o StrictHostKeyChecking=no ${ACCOUNT}@${SERVERIP}:/dev/shm/FRAST/${PIECE_FILE} /dev/shm/FRAST;then
	        PrintContent "green" "OK" "download piece.txt done from ${upperip}!"
		if mv /dev/shm/FRAST/${PIECE_FILE} ${SCRIPT_PATH}/;then
			PrintContent "green" "OK" "success cp piece.txt to ${SCRIPT_PATH}"
		fi
	fi

	
	if sshpass -p ${PASSWD} scp -o StrictHostKeyChecking=no ${ACCOUNT}@${SERVERIP}:/dev/shm/FRAST/p_setting.txt /dev/shm/FRAST;then
	        PrintContent "green" "OK" "download p_setting.txt done from ${upperip}!"
		if mv /dev/shm/FRAST/p_setting.txt ${SCRIPT_PATH}/;then
			PrintContent "green" "OK" "success cp p_setting.txt to ${SCRIPT_PATH}"
		fi
	fi


	#make rescue data to /dev/shm/FRAST/rescue.data
	echo "${compression} ${is_last_ip}" > /dev/shm/FRAST/rescue.data

	#source global variable to dic direction
	if [ -z "$(grep 'global_setting.txt' /home/dic/.bashrc)" ];then
		echo "source /home/dic/script/global_setting.txt" >> /home/dic/.bashrc
	fi

	
fi

#get max_piece_num
max_piece_num=$(cat ${SCRIPT_PATH}/${PIECE_FILE}|wc -l)


#get each ip in piece_name array
GetPieceName


while [ ${piece_num} -lt ${max_piece_num} ]
do
	echo "${piece_num}" > /dev/shm/FRAST/nowNum
	
	#temp_command
	PrintContent "purple" "\033[35mNOW PIECE: ${piece_num}\033[0m" "nowNum"
	
	if [ ${piece_num} -ge ${MAXFILE} ];then
		mainrun "StartMemoryScript"
	else

		###open debug model###
                if [ ${piece_num} -eq 0 -a "${upperip}" != "server" ];then
                        #run debug.sh
                        /bin/bash ${SCRIPT_PATH}/debug.sh cleint ${upperip} &
                        PrintContent "green" "OK" "success to execute debug.sh"
                fi
		
		[ "${upperip}" != "server" -a -f ${SCRIPT_PATH}/ip.new ] && upperip=$(cat ${SCRIPT_PATH}/ip.new) && PrintContent "red" "CHANGE IP" "New ip is ${upperip}"

		if /bin/bash ${SCRIPT_PATH}/memory.sh ${upperip} ${piece_num} ${compression} ${is_last_ip};then
			PrintContent "green" "OK" "success to execute memory.sh \033[31m${upperip}\033[0m \033[35mNOW PIECE: ${piece_num}\033[0m"
	        fi	
	fi
	((piece_num+=1))  # equal piece_num=$((piece_num + 1))
done

if [[ $piece_num -eq ${max_piece_num} ]];then
        while [[ $piece_num -le ${max_piece_num}-1+${MAXFILE} ]]
        do
                mainrun
                ((piece_num+=1))
        done
fi
