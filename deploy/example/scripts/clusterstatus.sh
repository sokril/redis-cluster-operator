#!/bin/bash
REDISIP=$1
REDISPORT=$2
TEMPSHELL=/tmp/redis_temp_`date +'%Y%m%d%M'`.sh
TEMPRESULT=/tmp/redis_temp_result_`date +'%Y%m%d%M'`.txt
RDPASSWORD=`cat /data/redis_password`
USER=`whoami`

echo "redis-cli -h $REDISIP -p ${REDISPORT} <<EOF >${TEMPRESULT} " >${TEMPSHELL}
echo "auth ${RDPASSWORD}">>${TEMPSHELL}
echo "cluster info">>${TEMPSHELL}
echo "cluster nodes">>${TEMPSHELL}
echo "exit">>${TEMPSHELL}
echo "EOF">>${TEMPSHELL}
sh /tmp/redistest.sh &>/tmp/redistest.out


if [ "${USER}" == "root" ];then
        chown redis:redis  ${TEMPSHELL}
        sh ${TEMPSHELL}
        #su - redis -c "sh ${TEMPSHELL}"
elif [ "${USER}" == "redis" ];then
        sh ${TEMPSHELL}
else 
         echo "only root or redis user can execute it,please change user to execute this command";
         exit;
fi

sed -i '1d' ${TEMPRESULT}
rm -f ${TEMPSHELL}

clsstatus=`cat ${TEMPRESULT}|grep cluster_state|awk -F':' '{print $2}'|grep ^ok|wc -l`
failnodes=`cat ${TEMPRESULT}|grep -v cluster|grep fail|wc -l`

function clusterCheck
{

m_id=($(cat ${TEMPRESULT}|grep -v cluster|grep -v fail|grep master|awk '{print $1}'))
m_node=($(cat ${TEMPRESULT}|grep -v cluster|grep -v fail|grep master|awk '{print $2}'| awk -F'@' '{print $1}'))
failNodes=($(cat ${TEMPRESULT}|grep -v cluster|grep fail|awk '{print $2}'| awk -F'@' '{print $1}'))
echo " "
echo "************************  redis cluster nodes status: normal  *****************************"
for i in `seq ${#m_id[@]}`
do
  ID=${m_id[$i-1]}
  s_nodes=($(cat ${TEMPRESULT}|grep -v cluster|grep -v fail|grep -v master|grep -w ${ID}|awk '{print $2}'| awk -F'@' '{print $1}'))
  s_num=${#s_nodes[@]}
  
  if [ ${s_num} -eq 1 ]; then
    echo " "
    echo "  master node:  ${m_node[$i-1]} ok  ---------->  slave node:  ${s_nodes[0]}   ok           "
  elif [ ${s_num} -eq 0 ]; then
    echo " "
    echo "  master node:  ${m_node[$i-1]} ok  ---------->  slave node:   no slaves                   "
  else
    for j in `seq ${#s_nodes[@]}`
    do 
       echo " "
       echo "  master node:  ${m_node[$i-1]} ok  ---------->  slave node:  ${s_nodes[$j-1]}   ok      "
    done
  fi
done
echo " "
echo "*******************************************************************************************"

failnodes=`cat ${TEMPRESULT}|grep -v cluster|grep fail|wc -l`

if [ ${clsstatus} -eq 1 ]; then
   if [ ${failnodes} -eq 0 ]; then
     echo " "
     #echo "*******************************************************************************************"
     echo "************ very good! redis cluster status is ok  and all nodes is ok *******************"
     echo " "
   else
     echo " "
     echo "+++++ a little regret redis cluster status is ok  but exists nodes fail please check  +++++"
     echo " "
     failNodes=($(cat ${TEMPRESULT}|grep -v cluster|grep fail|awk '{print $2}'| awk -F'@' '{print $1}'))
     echo "****************  redis cluster nodes status: abnormal ************************************"
     for i in `seq ${#failNodes[@]}`
     do
       echo " "
       echo "  redis cluster nodes:  ${failNodes[$i-1]}  is fail  "
     done
     echo " "
     echo "*******************************************************************************************"
   fi
else
  echo "**************************   redis cluster status is fail  ********************************"
  echo " "
  echo " very very very bad !!! redis cluster status is fail,please check   "
  echo " "
  echo "*******************************************************************************************"
fi

}

clusterCheck

rm -f /tmp/redis_temp_result*.txt