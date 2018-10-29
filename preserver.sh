#!/bin/bash

source /home/dic/script/p_setting.txt #modify
source ${SCRIPT_PATH}/function.sh

compression=$1
terminal=/dev/shm/output.log
#terminal=/dev/tty3

#check each piece file is exist
if [ ! -e ${BASEDIR}/${PIECE_FILE_SERVER} ]; then
	echo -e "[  \033[31mFAILED\033[0m  ] ${BASEDIR}/${PIECE_FILE_SERVER} does not exists! "
	exit 0
else
	echo -e "[  \033[32mOK\033[0m  ] ${BASEDIR}/${PIECE_FILE_SERVER} file is found! "
	num=$(ls ${BASEDIR}/${PARTITION}|wc -l)
	count=0
	while [ ${count} -lt $((${num}-1)) ]
	do
		if [ ${count} -lt 10 ];then
			if [ ! -f ${BASEDIR}/${PARTITION}/${PIECE_FILE_SERVER}_000${count} ];then 
				echo "${BASEDIR}/${PARTITION}/${PIECE_FILE_SERVER}_000${count} is not exists!! "
				exit 0
			fi
        	elif [ ${count} -lt 100 ];then
			if [ ! -f ${BASEDIR}/${PARTITION}/${PIECE_FILE_SERVER}_00${count} ];then 
				echo "${BASEDIR}/${PARTITION}/${PIECE_FILE_SERVER}_00${count} is not exists!! "
				exit 0
			fi
        	elif [ ${count} -lt 1000 ];then
			if [ ! -f ${BASEDIR}/${PARTITION}/${PIECE_FILE_SERVER}_0${count} ];then 
				echo "${BASEDIR}/${PARTITION}/${PIECE_FILE_SERVER}_0${count} is not exists!! "
				exit 0
			fi
        	else
			if [ ! -f ${BASEDIR}/${PARTITION}/${PIECE_FILE_SERVER}_${count} ];then 
				echo "${BASEDIR}/${PARTITION}/${PIECE_FILE_SERVER}_${count} is not exists!! "
				exit 0
			fi
        	fi
		count=$((count + 1))
	done
	echo -e "[  \033[32mOK\033[0m  ] each piece file is found! "
	
	

	#client ip map
	if [ ! -e ${SCRIPT_PATH}/all ];then
		echo -e "[  \033[31mFAILED\033[0m  ] ${SCRIPT_PATH}/all is not exists!"
		exit 0
	else
		echo -e "[  \033[32mOK\033[0m  ] finish client ip map "
		
		if rm -rf ${SCRIPT_PATH}/${CLIENTMAPFILE};then
			echo -e "[  \033[32mOK\033[0m  ] finish remove old iplist "
		fi
	
		if rm -rf ${SCRIPT_PATH}/activeip_*;then
			echo -e "[  \033[32mOK\033[0m  ] finish remove old activeip "
		fi

		.  ${SCRIPT_PATH}/sortip.sh

		sleep 1

		#run debug.sh
		/bin/bash ${SCRIPT_PATH}/debug.sh server &
		PrintContent "green" "OK" "success to execute debug.sh"


		declare -a eachIP
		eachIP=($(cat ${SCRIPT_PATH}/${CLIENTMAPFILE}))
		last_ip=$(cat ${SCRIPT_PATH}/${CLIENTMAPFILE}|tail -n 1)

		sleep 1

		#start client download.sh
		for ip in $(seq 0 $((${#eachIP[@]}-1)) )
		do
			if [ "${eachIP[$ip]}" == "${last_ip}"  ];then
				sshpass -p ${PASSWD} ssh -v -o StrictHostKeyChecking=no -o ConnectionAttempts=3 -f ${ACCOUNT}@${eachIP[$ip]} "echo 'ok' > /dev/shm/sshOK;/bin/bash /home/dic/script/main.sh ${eachIP[$ip-1]} ${compression} lastip" &>> ${terminal}
				echo "last_ip: "${eachIP[$ip]}

			elif [ "${eachIP[$ip]}" != "${SERVERIP}" ];then
				sshpass -p ${PASSWD} ssh -v -o StrictHostKeyChecking=no -o ConnectionAttempts=3  -f ${ACCOUNT}@${eachIP[$ip]} "echo 'ok' > /dev/shm/sshOK;/bin/bash /home/dic/script/main.sh ${eachIP[$ip-1]} ${compression} nolastip" &>> ${terminal}
				echo ${eachIP[$ip]}

			else
				echo "you are server"
			fi
			sleep 2
		done
		echo -e "[  \033[32mOK\033[0m  ] finish to start client script "

	fi
fi
