#!/bin/bash


declare -a piece_name
declare -a piece_md5

function CheckInputVariable() {
	if [ $# -eq 0 ];then
       		PrintContent "red" "FAILED" "Please input ip!"
       		exit 0
	else
		echo "${1}" | egrep -q '^([0-9]{1,3}\.){3}[0-9]{1,3}$';res=$?
		if [[ ${res} -ne 0 ]];then 
			PrintContent "red" "FAILED" "Please input correct ip format !"
			exit 0
		fi
	fi
}

function PrintContent() {
	if [ "${1}" == "red" ];then
		echo -e "[  \033[31m${2}\033[0m  ] ${3}"|sudo tee /dev/tty2
	elif [ "${1}" == "green" ];then
		echo -e "[  \033[32m${2}\033[0m  ] ${3}"|sudo tee /dev/tty2
	elif [ "${1}" == "yellow" ];then
                echo -e "[  \033[33m${2}\033[0m  ] ${3}"|sudo tee /dev/tty2
	elif [ "${1}" == "lightyellow" ];then
                echo -e "[  \033[1;33m${2}\033[0m  ] ${3}"|sudo tee /dev/tty2
	elif [ "${1}" == "blue" ];then
                echo -e "[  \033[36m${2}\033[0m  ] ${3}"|sudo tee /dev/tty2
	elif [ "${1}" == "white" ];then
                echo -e "[  \033[37m${2}\033[0m  ] ${3}"|sudo tee /dev/tty2
	elif [ "${1}" == "purple" ];then
                echo -e "[  \033[35m${2}\033[0m  ] ${3}"|sudo tee /dev/tty2
	elif [ "${1}" == "darkblue" ];then
                echo -e "[  \033[34m${2}\033[0m  ] ${3}"|sudo tee /dev/tty2
	fi
}

function GetFileName() {
	file_name=$(cat ${SCRIPT_PATH}/${PIECE_FILE}|head -n 1|cut -d '_' -f1)
}

function GetPieceName() {
	#get each ip in piece_name array
	for eachline in $(cat ${SCRIPT_PATH}/${PIECE_FILE})
	do
	        piece_name+=($(echo ${eachline}|cut -d ':' -f1)) #print add to piece_name array
	done
}

function GetPieceMD5() {
	#get each ip in piece_name array
	for eachline in $(cat ${SCRIPT_PATH}/${PIECE_FILE})
	do
	        piece_md5+=($(echo ${eachline}|cut -d ':' -f2)) #print add to piece_name array
	done
}

function mainrun() {
ARGS=${1}
if [ ${is_last_ip} == "nolastip" -o "${upperip}" == "server" ];then
	
	#判斷下層完成否 last_ip不用判斷
	until [[ -e "/dev/shm/FRAST/${piece_name[${piece_num}-${MAXFILE}]}.ok" ]]
	do
		if usleep ${SLEEP_SEC};then 
			us=$(awk "BEGIN{printf \"%.2f\n\", ${SLEEP_SEC} / 1000000}")
			PrintContent "yellow" "SLEEP" "not found \033[1;31m${piece_name[${piece_num}-${MAXFILE}]}.ok\033[0m success to sleep ${us}s!"
		fi
	done
	
	PrintContent "green" "OK" "created \033[32m${piece_name[${piece_num}-${MAXFILE}]}.ok\033[0m file"
	
	if [ "${upperip}" == "server" ];then
		PrintContent "white" "NOCHECK" "the server does not need to check hd file"
	fi
fi

if [ ${is_last_ip} == "lastip" -o "${upperip}" != "server" ];then

	if [ ${is_last_ip} == "lastip" ];then
		PrintContent "white" "NOCHECK" "the last ip does not need to check ok file"
	fi
	
	#判斷硬碟完成否 server不用判斷
	until [[ -e "/dev/shm/FRAST/${piece_name[${piece_num}-${MAXFILE}]}.hd" ]]
	do
		if usleep ${SLEEP_SEC};then
			us=$(awk "BEGIN{printf \"%.2f\n\", ${SLEEP_SEC} / 1000000}")
			PrintContent "yellow" "SLEEP" "not found \033[1;31m${piece_name[${piece_num}-${MAXFILE}]}.hd\033[0m success to sleep ${us}s!"
		fi
	done
	PrintContent "green" "OK" "created \033[32m${piece_name[${piece_num}-${MAXFILE}]}.hd\033[0m file"
fi

#刪除在/dev/shm/FRAST該piece的所有相關檔案
if sudo rm -f /dev/shm/FRAST/${piece_name[${piece_num}-${MAXFILE}]}.* &&  sudo rm -f /dev/shm/FRAST/${piece_name[${piece_num}-${MAXFILE}]};then
	PrintContent "blue" "DELETED" "deleted all ${piece_name[${piece_num}-${MAXFILE}]} temp file"
fi

#判斷piece_num是否大於記憶體承受的數量(MAXFILE)
if [[ "${ARGS}" == "StartMemoryScript" ]];then

        [ "${upperip}" != "server" -a -f ${SCRIPT_PATH}/ip.new ] && upperip=$(cat ${SCRIPT_PATH}/ip.new) && PrintContent "red" "CHANGE IP" "New ip is ${upperip}"

	if /bin/bash ${SCRIPT_PATH}/memory.sh ${upperip} ${piece_num} ${compression} ${is_last_ip};then
		if [ "${upperip}" == "server" ];then
			PrintContent "green" "OK" "server finish delete piece and success to execute memory.sh"
		else
			PrintContent "green" "OK" "success to execute memory.sh \033[31m${upperip}\033[0m \033[35mNOW PIECE: ${piece_num}\033[0m"
		fi
	fi
fi
}
