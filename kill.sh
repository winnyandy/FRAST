#!/bin/bash

source ${SCRIPT_PATH}/function.sh

nu=${1}
if [ "$nu" == "5" ];then
	pro=($(ps aux|grep -e main.sh -e memory.sh -e hd.sh -e tail|grep -v grep|cut -d ' ' -f7))
elif [ "$nu" == "4" ];then
	pro=($(ps aux|grep -e main.sh -e memory.sh -e hd.sh -e tail|grep -v grep|cut -d ' ' -f8))
elif [ "$nu" == "3" ];then
	pro=($(ps aux|grep -e main.sh -e memory.sh -e hd.sh -e tail|grep -v grep|cut -d ' ' -f9))
elif [ "$nu" == "debugServer" ];then
	pro=$(cat /home/dic/script/server_debug_process)
	[ "${pro}" != "" ] && echo "sudo kill -9 ${pro}" && sudo kill -9 ${pro}
	exit 0
elif [ "$nu" == "debugClient" ];then
	pro=$(ps aux|grep debug.sh|grep -v 'bash -c'|grep -v 'grep'|awk '{print $2}')
	[ "$pro" != "" ] && echo "kill client debug => sudo kill -9 ${pro}" && sudo kill -9 ${pro}
	exit 0
elif [ "$nu" == "memory" ];then
	val=$(ps aux|grep memory.sh|grep -v 'color'|grep -v 'grep'|awk '{print $2}')
	[ ! -z "$val" ] && kill $val && PrintContent "red" "KILLED MEMORY" "killed $val" || PrintContent "red" "NO RUN MEMORY" "Not found memory.sh is running..."	
	exit 0
elif [ "$nu" == "0" ];then
	ps aux|grep -e main.sh -e memory.sh -e hd.sh -e tail|grep -v grep|cut -d ' ' -f8
	exit 0
fi
for i in $(seq 0 ${#pro[@]-1})
do
	if [ "${pro[${i}]}" == "" ];then
		continue;
	else
		echo 	"kill  ${pro[${i}]}"
 	 	kill  ${pro[${i}]}
	fi
done
