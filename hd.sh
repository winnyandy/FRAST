#!/bin/bash
source /home/dic/script/p_setting.txt
source ${SCRIPT_PATH}/function.sh
source ${SCRIPT_PATH}/record_device.sh

piece_num=0

#get each ip in piece_name array
GetPieceName

#get each MD5 in piece_md5 array
GetPieceMD5

#get now file name
GetFileName

#get max_piece_num
max_piece_num=$(cat ${SCRIPT_PATH}/${PIECE_FILE}|wc -l)

compression=${1}


if [ ${piece_num} -eq 0 ];then
	[ ! -e /dev/shm/FRAST/fifo ] && mkfifo /dev/shm/FRAST/fifo
	if [ "${compression}" == "no" ];then
		tail -f  -n+1 /dev/shm/FRAST/fifo | sudo partclone.restore -s - -o ${ROOTDEVICE}${PARTITION:3} &
	elif [ "${compression}" == "yes" ];then
		tail -f  -n+1 /dev/shm/FRAST/fifo |gunzip -c| sudo partclone.restore -s - -o ${ROOTDEVICE}${PARTITION:3} &
	fi
fi

while [ ${piece_num} -le ${max_piece_num} ]
do
	if [ ${piece_num} -lt ${max_piece_num} ];then
		echo "${piece_num}" > /dev/shm/FRAST/hd_Num
		#直到遠端下載piece檔案結束後判斷unlock是否已建立
		until [ -e /dev/shm/FRAST/${piece_name[${piece_num}]}.unlock ]
		do
			us=$(awk "BEGIN{printf \"%.2f\n\", ${SLEEP_SEC} / 1000000}")
			PrintContent "yellow" "SLEEP" "wait ${us}s for ${piece_name[${piece_num}]}.unlock!"
			usleep  ${SLEEP_SEC}
		done
	fi
	PrintContent "purple" "HD" "start to cat file \033[35m${piece_name[${piece_num}]}\033[0m!"


	if [ ${piece_num} -eq $((${max_piece_num})) ];then
		killall tail
		rm -f /dev/shm/FRAST/fifo

	else
		if cat /dev/shm/FRAST/${piece_name[${piece_num}]} >> /dev/shm/FRAST/fifo;then
			PrintContent "purple" "HD" "finish to cat file \033[35m${piece_name[${piece_num}]}\033[0m!"
			#create unlock file
			touch /dev/shm/FRAST/${piece_name[${piece_num}]}.hd
			PrintContent "green" "OK" "created ${piece_name[${piece_num}]}.hd file finish!"
		fi
	fi
	
        ((piece_num+=1))  # equal piece_num=$((piece_num + 1))
done
