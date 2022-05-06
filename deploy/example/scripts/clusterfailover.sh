#!/bin/bash
REDISIP=$1
REDISPORT=$2
USER=`whoami`
RDPASSWORD=`cat /data/redis_password`

function redisClusterNodes
{
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
rm -f /tmp/redis_clusternodes.sh
}


function currentMasterSlaveDisplay
{
redisClusterNodes
myip=`cat /tmp/redis_cluster_nodes.txt |grep  myself|awk '{print $2}'| awk -F':' '{print $1}'`
myid=`cat /tmp/redis_cluster_nodes.txt |grep  myself|awk '{print $1}'`
isslave=`cat /tmp/redis_cluster_nodes.txt |grep  myself|grep slave|wc -l`

if [ ${isslave} -eq 1 ] ; then
        masterid=`cat /tmp/redis_cluster_nodes.txt |grep  myself|awk '{print $4}'`
        masterip=`cat /tmp/redis_cluster_nodes.txt |grep master|grep ${masterid}|awk '{print $2}'| awk -F':' '{print $1}'`
        echo "current node master-slave is:**** ${masterip} 6379 master ===> ${myip} 6379 slave ****"
else     
        slavenodes=`cat /tmp/redis_cluster_nodes.txt|grep -v myself|grep ${myid}|wc -l`

        if [ ${slavenodes} -eq 0 ] ; then 
        echo "current nodes master-slave is:**** ${myip} 6379 master ===> no ###"
        elif [ ${slavenodes} -eq 1 ] ; then
           slaveip=`cat /tmp/redis_cluster_nodes.txt|grep -v myself|grep ${myid}|awk '{print $2}'| awk -F':' '{print $1}'`
           echo "current nodes master-slave is:**** ${myip} 6379 master ===> ${slaveip} 6379 slave###"
        else 
           slaveips=($(cat /tmp/redis_cluster_nodes.txt|grep -v myself|grep ${myid}|awk '{print $2}'| awk -F':' '{print $1}'))
           for i in `seq ${#slaveips[@]}`
           do
             slaveip=${slaveips[$i-1]}
             echo "current nodes master-slave is:**** ${myip} 6379 master ===> ${slaveip} 6379 slave###"
           done
        fi
fi
rm -f /tmp/redis_cluster_nodes.txt
}

#currentMasterSlaveDisplay

function cluserFailOver
{
redisClusterNodes

myip=`cat /tmp/redis_cluster_nodes.txt |grep  myself|grep -v fail|awk '{print $2}'| awk -F':' '{print $1}'`
myid=`cat /tmp/redis_cluster_nodes.txt |grep  myself|grep -v fail|awk '{print $1}'`
isslave=`cat /tmp/redis_cluster_nodes.txt |grep  myself|grep slave|wc -l`

if [ ${isslave} -eq 1 ] ; then
	masterid=`cat /tmp/redis_cluster_nodes.txt |grep  myself|grep -v fail|awk '{print $4}'`
	masterip=`cat /tmp/redis_cluster_nodes.txt |grep master|grep -v fail|grep ${masterid}|awk '{print $2}'| awk -F':' '{print $1}'`
	echo "before failover:: current node master-slave is:**** ${masterip} 6379 master ===> ${myip} 6379 slave ****"

	echo "redis-cli -c <<EOF" >/tmp/redis_clusterFailover.sh 
	if [ ${RDPASSWORD}"a" != "a" ];then 
		echo "auth ${RDPASSWORD}">>/tmp/redis_clusterFailover.sh
	fi
	echo "cluster failover">>/tmp/redis_clusterFailover.sh
	echo "exit">>/tmp/redis_clusterFailover.sh
	echo "EOF">>/tmp/redis_clusterFailover.sh
	if [ "${USER}" == "root" ];then
		chown redis:redis  /tmp/redis_clusterFailover.sh
		sh /tmp/redis_clusterFailover.sh
		#su - redis -c 'sh /tmp/redis_clusterFailover.sh'
	elif [ "${USER}" == "redis" ];then
		sh /tmp/redis_clusterFailover.sh
	else 
		echo "only root or redis user can execute it,please change user to execute this command";
		exit;
	fi
        echo "after failover::current node master-slave is:**** ${myip}  6379 master ===> ${masterip} 6379 slave ****"
else     
	#current master node it have no slave, it cannot failover to it
	slavenodes=`cat /tmp/redis_cluster_nodes.txt|grep -v myself|grep ${myid}|grep -v fail|wc -l`

	if [ ${slavenodes} -eq 0 ] ; then 
		echo "current node is master ,it have no normal slave ,it cannot failover!!!!"
		exit;
	#current node is master and it have one slave to failover it 
	elif [ ${slavenodes} -eq 1 ] ; then
		slaveip=`cat /tmp/redis_cluster_nodes.txt|grep -v myself|grep ${myid}|awk '{print $2}'| awk -F':' '{print $1}'`
		echo "before failover:: current node master-slave is:**** ${myip} 6379 master ===> ${slaveip} 6379 slave ****"
		echo "redis-cli -h ${slaveip} -p 6379 -c <<EOF" >/tmp/redis_clusterFailover.sh 
		if [ ${RDPASSWORD}"a" != "a" ];then 
			echo "auth ${RDPASSWORD}">>/tmp/redis_clusterFailover.sh
		fi
		echo "cluster failover">>/tmp/redis_clusterFailover.sh
		echo "exit">>/tmp/redis_clusterFailover.sh
		echo "EOF">>/tmp/redis_clusterFailover.sh
		if [ "${USER}" == "root" ];then
			chown redis:redis  /tmp/redis_clusterFailover.sh
			sh /tmp/redis_clusterFailover.sh
			#su - redis -c 'sh /tmp/redis_clusterFailover.sh'
		elif [ "${USER}" == "redis" ];then
			sh /tmp/redis_clusterFailover.sh
		else 
			echo "only root or redis user can execute it,please change user to execute this command";
			exit;
		fi
        
		echo "after failover:: current node master-slave is:**** ${slaveip} 6379 master ===> ${myip} 6379 slave ****"

	else 
		slaveips=($(cat /tmp/redis_cluster_nodes.txt|grep -v myself|grep ${myid}|awk '{print $2}'| awk -F':' '{print $1}'))
		for i in `seq ${#slaveips[@]}`
		do
			slaveip=${slaveips[$i-1]}
			echo "current node master-slave is:**** ${myip} 6379 master ===> ${slaveip} 6379 slave###"
			#echo "current node have more than one slaves please login slave nodes execute failover command"
			#exit;
		done
                echo "current node have more than one slaves please login slave nodes execute failover command"
    fi
fi
rm -f /tmp/redis_clusterFailover.sh
rm -f /tmp/redis_cluster_nodes.txt
}

cluserFailOver