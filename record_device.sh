#!/bin/bash

declare -a DISKDEVICE
DIR='/sys/block'
MINSIZE=60

hd=`echo hd{a..f}`
sd=`echo sd{a..f}`
vd=`echo vd{a..f}`

DISKDEVICE=(${hd} ${sd} ${vd})
ROOTDEVICE=''

for DEV in ${DISKDEVICE[@]}
do
	if [ -d "${DIR}/${DEV}" ]; then
		REMOVABLE=`cat ${DIR}/${DEV}/removable`
		if [ ${REMOVABLE} -eq 0 ]; then
			SIZE=`cat ${DIR}/${DEV}/size`
			ROOTSIZE=$(( ${SIZE}/2**21 ))
			if [ ${ROOTSIZE} -gt ${MINSIZE} ]; then
				ROOTDEVICE=${DEV}
				break;
			fi
		fi
	fi
done

ROOTDEVICE="/dev/${DEV}"	ROOTSIZE="${ROOTSIZE}GB"	DEVX="${DEV}"
echo "ROOTDEVICE=/dev/${DEV}	ROOTSIZE=${ROOTSIZE}" 		DEVX="${DEV}"> /tmp/device
