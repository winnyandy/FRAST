#!/bin/sh
NUM=${1}
for ip in $(cat ${SCRIPT_PATH}/activeip_${NUM})
do
	if [ "$ip" == "$SERVERIP" ];then
		continue;
	fi
	ping1=$(ping $ip -W 1 -c 1 | grep 'rtt' | awk -F'/' '{print $5}')
	ping2=$(ping $ip -W 1 -c 1 | grep 'rtt' | awk -F'/' '{print $5}')
	ping3=$(ping $ip -W 1 -c 1 | grep 'rtt' | awk -F'/' '{print $5}')
	#ping3=$(ping $ip -W 1 -c 1 | grep 'rtt' | awk -F'/' '{printf ("%0.2f\n",$5)}')
	
	ping_sum=$(printf "%0.3f" `echo "($ping1+$ping2+$ping3)"|bc`)
	ping_avg=$(printf "%0.3f" `echo "scale=3;$ping_sum/3"|bc`)
#	echo $ping1+$ping2+$ping3
	echo "$ip $ping_avg" >> ${SCRIPT_PATH}/rtt.default
done

sort -n -k 2  ${SCRIPT_PATH}/rtt.default > ${SCRIPT_PATH}/rtt
rm -f ${SCRIPT_PATH}/rtt.default

