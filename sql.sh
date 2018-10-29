#!/bin/bash
. /home/dic/script/.config

action=$1;shift
ip=$1;shift
columns=$1;shift
stat=$1

if [ "$action" == "select" ];then
	mysql -N -u ${DBUSER} -p${DBPWD} ${DBNAME} <<EOF
	        select ip from ip_status;
EOF

elif [ "$action" == "insert" ];then
	mysql -N -u ${DBUSER} -p${DBPWD} ${DBNAME} <<EOF
		insert into ip_status select max(id)+1,'${ip}','null','null','null' from ip_status;
EOF
elif [ "$action" == "delete" ];then
	mysql -N -u ${DBUSER} -p${DBPWD} ${DBNAME} <<EOF
		delete from ip_status where id>0;
EOF
elif [ "$action" == "update" ];then
	mysql -N -u ${DBUSER} -p${DBPWD} ${DBNAME} <<EOF
		update ip_status set ${columns}='${stat}' where ip='${ip}';
EOF
elif [ "$action" == "check" ];then
	mysql -N -u ${DBUSER} -p${DBPWD} ${DBNAME} <<EOF
	        select root_ping,nextip_ping,hd_stat from ip_status where ip='${ip}';
EOF
fi

