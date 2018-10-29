#!/bin/bash
source ${SCRIPT_PATH}/function.sh

allIP=($(cat ${SCRIPT_PATH}/all))
getRouterMaxNum=$(cat ${SCRIPT_PATH}/all|cut -d '|' -f2|sort -r|uniq|head -n1)

#get switch number and sort them
for route in $(seq 1 ${getRouterMaxNum})
do
	for num in $(seq 0 $((${#allIP[@]}-1)) )
	do
		getroute=$(echo ${allIP[$num]}|cut -d '|' -f2)
		ip=$(echo ${allIP[$num]}|cut -d '|' -f1)
		if [ ${getroute} -eq ${route} ];then
			sshpass -p ${PASSWD} ssh -o StrictHostKeyChecking=no ${ACCOUNT}@${ip} "date"; res=$?;
			if [ ${res} -eq 0 ];then
				echo ${ip} >> activeip_${route}
			fi
		fi
	done
done

sudo chown dic: ${SCRIPT_PATH} -R
declare -a activeIP
for route in $(seq 1 ${getRouterMaxNum})
do
	activeIP=($(cat ${SCRIPT_PATH}/activeip_${route}))
	for ip in $(seq 0 $((${#activeIP[@]}-1)) )
	do
	        #transfer active_ip
	        if sshpass -p ${PASSWD} scp -o StrictHostKeyChecking=no  ${SCRIPT_PATH}/activeip_${route} ${ACCOUNT}@${activeIP[$ip]}:${SCRIPT_PATH}/;then
	                PrintContent "green" "OK" "transfer activeip to ${activeIP[$ip]}!"
	        fi
	        if [ "${activeIP[$ip]}" != "${SERVERIP}" ];then
	                sshpass -p ${PASSWD} ssh -o StrictHostKeyChecking=no ${ACCOUNT}@${activeIP[$ip]} "/bin/bash /home/dic/script/rtt.sh ${route}" sudo &> /dev/tty3
	        else
	                /bin/bash /home/dic/script/rtt.sh ${route}
	        fi
	        usleep 500000
	done
	activeIP=""
done
#sort ip
getRouterMaxNum=$(cat ${SCRIPT_PATH}/all|cut -d '|' -f2|sort -r|uniq|head -n1)
for route in $(seq 1 ${getRouterMaxNum})
do
	if [ -e ${SCRIPT_PATH}/iplist ];then
		last_ip=$(cat ${SCRIPT_PATH}/iplist |tail -n1)
		sshpass -p ${PASSWD} scp -o StrictHostKeyChecking=no  ${SCRIPT_PATH}/activeip_${route} ${ACCOUNT}@${last_ip}:${SCRIPT_PATH}/
		sshpass -p ${PASSWD} ssh -o StrictHostKeyChecking=no ${ACCOUNT}@${last_ip} "/bin/bash /home/dic/script/rtt.sh ${route}"  &> /dev/tty3
		getIP=$(sshpass -p ${PASSWD} ssh -o StrictHostKeyChecking=no ${ACCOUNT}@${last_ip} "val=\$(cat /home/dic/script/rtt|cut -d ' ' -f1|head -n1);echo \$val;")
		echo $getIP >> ${SCRIPT_PATH}/iplist
	fi
	
	declare -a eachIP
	declare -a sortIP
	eachIP=($(cat ${SCRIPT_PATH}/activeip_${route}))
	for num in $(seq 0 $((${#eachIP[@]}-2)) )
	do
		if [ $num -eq 0 -a ! -e ${SCRIPT_PATH}/iplist ];then 
			echo "${SERVERIP}" >> ${SCRIPT_PATH}/iplist
			echo $(cat ${SCRIPT_PATH}/rtt|awk 'NR==1{print $1}') >> ${SCRIPT_PATH}/iplist
		else	
			for ip in $(cat ${SCRIPT_PATH}/iplist)
			do
				OPT=$OPT"|grep -wv ${ip}"
			done
			nowIP=$(cat ${SCRIPT_PATH}/iplist|tail -n1)
			getIP=$(sshpass -p ${PASSWD} ssh -o StrictHostKeyChecking=no ${ACCOUNT}@${nowIP} "val=\$(cat /home/dic/script/rtt|cut -d ' ' -f1 ${OPT}|head -n1);echo \$val;")
			echo $getIP >> ${SCRIPT_PATH}/iplist
			OPT=""
		fi
	done
done
