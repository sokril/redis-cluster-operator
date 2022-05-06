#!/bin/bash
REDISIP=$1
REDISPORT=$2
USER=`whoami`
RDPASSWORD=`cat /data/redis_password`

echo "redis-cli -h $REDISIP -p $REDISPORT  <<EOF >/tmp/redis_cluster_nodes.txt" >/tmp/redis_clusternodes.sh

if [ ${RDPASSWORD}"a" != "a" ];then 
	echo "auth ${RDPASSWORD}">>/tmp/redis_clusternodes.sh
fi

echo "cluster nodes">>/tmp/redis_clusternodes.sh
echo "exit">>/tmp/redis_clusternodes.sh
echo "EOF">>/tmp/redis_clusternodes.sh

if [ "${USER}" == "root" ];then
	chown redis:redis  /tmp/redis_clusternodes.sh
	sh /tmp/redis_clusternodes.sh
	#su - redis -c 'sh /tmp/redis_clusternodes.sh'
elif [ "${USER}" == "redis" ];then
	sh /tmp/redis_clusternodes.sh
else 
	 echo "only root or redis user can execute it,please change user to execute this command";
	 exit;
fi
sed -i '1d' /tmp/redis_cluster_nodes.txt
cat /tmp/redis_cluster_nodes.txt
rm -f /tmp/redis_cluster_nodes.txt
rm -f /tmp/redis_clusternodes.sh
