#!/bin/bash

ROOTDEVICE=$1
Numbar=$2
Size=$3
Type=$4
Format=$5

if [ ${Format} == "ntfs" ]; then

sudo fdisk ${ROOTDEVICE} << EOF
n
${Type}
${Numbar}

+${Size}
t
${Numbar}
7
w
EOF

else

sudo fdisk ${ROOTDEVICE} << EOF
n
${Type}
${Numbar}

+${Size}
t
${Numbar}
83
w
EOF

fi

sudo partprobe
