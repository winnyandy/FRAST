#!/bin/bash

source /home/dic/script/record_device.sh
source /home/dic/script/p_setting.txt
source /home/dic/script/global_setting.txt
source ${SCRIPT_PATH}/function.sh

echo "Load MBR: ${ROOTDEVICE}"
if sudo dd if=${SCRIPT_PATH}/system.mbr of=${ROOTDEVICE};then
	PrintContent "green" "OK" "loaded MBR to ${ROOTDEVICE}!"
else
	PrintContent "red" "FAILED" "failed load MBR to ${ROOTDEVICE}!"
fi

echo "Device: ${ROOTDEVICE}"
print="sudo parted ${ROOTDEVICE} unit MB print"

${print} |awk 'NR>7' |grep -E "primary|extended|logical" ;part=$?

part_num=$(( `${print} |awk 'NR>7' |wc -l` -1 ))
if [ ${part} -eq 0 ]; then
	for (( row=${part_num}; row>0; row-- ))
	do
		#sudo parted ${ROOTDEVICE} rm $(${print} |awk 'NR>7{print $1}' |awk "NR==${row}")
		sudo parted ${ROOTDEVICE} rm $(${print} |awk 'NR>7{print $1}' |awk "NR==${row}")
	done
fi

${print} |grep -i "Partition Table:" |grep "loop"; loop=$?
[ ${loop} -eq 0 ] && sudo parted ${ROOTDEVICE} mklabel msdos yes

FNR=`awk 'END{print NR}' ${SCRIPT_PATH}/disk`
for num in $(seq 1 ${FNR})
do
	Numbar=`awk NR==${num}'{split($1,device,/[=]/);print device[2]}' ${SCRIPT_PATH}/disk`
	Start=`awk NR==${num}'{split($2,device,/[=]/);print device[2]}' ${SCRIPT_PATH}/disk`
	End=`awk NR==${num}'{split($3,device,/[=]/);print device[2]}' ${SCRIPT_PATH}/disk`
	Size=`awk NR==${num}'{split($4,device,/[=]/);print device[2]}' ${SCRIPT_PATH}/disk`
	Type=`awk NR==${num}'{split($5,device,/[=]/);print device[2]}' ${SCRIPT_PATH}/disk`
	Format=`awk NR==${num}'{split($6,device,/[=]/);print device[2]}' ${SCRIPT_PATH}/disk`
	Boot=`awk NR==${num}'{split($7,device,/[=]/);print device[2]}' ${SCRIPT_PATH}/disk`
	
	if [ ${Type} == "extended" ]; then
		sudo parted ${ROOTDEVICE} mkpart ${Type} ${Start} ${End}
		sudo partprobe
	else
		/bin/sh /home/dic/script/create_partition.sh ${ROOTDEVICE} ${Numbar} ${Size} ${Type} ${Format}
		sudo partprobe
		if [ "${Format}" == "ntfs" ];then
			sudo mkfs.${Format} -f ${ROOTDEVICE}${Numbar}
		else
			sudo mkfs.${Format} ${ROOTDEVICE}${Numbar}
		fi
		[ "${Boot}" == "boot" ] && sudo parted ${ROOTDEVICE} set ${Numbar} boot on
	fi
done
