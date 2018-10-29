#!/bin/bash

if [ $# -eq 0 ];then
        echo "Please input [absolute path] [piece size]"
        exit 0
fi

abpath=${1}
filename=$(echo ${abpath}|awk -F '/' '{print $NF}')
partition=$(echo ${abpath}|awk -F '/' '{print $NF}'|awk -F'.' '{print $1}')
folder=$(echo ${abpath}|sed -e "s/${filename}//g"|sed -e "s/\/$//g")

#start split...
echo "spliting ${filename} pieces ..."
split -b ${2} -d -a 4 ${abpath} ${folder}/${partition}/${filename}_
echo "splited ${filename} pieces !!!"

# please enter your piece folder
piecefilefolder="${folder}/${partition}"
sum=`ls ${piecefilefolder}|wc -l`
result=`ls ${piecefilefolder} |cut -d " " -f1`
i=1


#use md5sum create piece.txt
echo "starting md5sum ..."
for names in ${result}
do
        echo ${i} ${names}
	md5=$(md5sum ${piecefilefolder}/${names}|awk '{print $1}')
        echo "${names}:${md5}" >> ${folder}/${partition}/piece.txt
        i=$(($i+1))
done
echo "started md5sum !!!"
