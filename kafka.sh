#!/bin/bash
source config.ini


### check users
echo '#!/bin/bash' > userCheck_kafka.sh
echo "$kafka_usr "
echo "### check users" >> userCheck_kafka.sh
echo 'users=$(cat /etc/passwd | grep '$kafka_usr')' >> userCheck_kafka.sh 
echo 'k2vusr=$(echo "$users" | grep -o '$kafka_usr':/bin/bash)' >>  userCheck_kafka.sh
echo 'if [ -z $k2vusr ]; then' >>  userCheck_kafka.sh
echo "    mkdir -p $kafka_path" >>  userCheck_kafka.sh
echo "    useradd $kafka_usr -m -d $kafka_path" >>  userCheck_kafka.sh
echo "    chown -R $kafka_usr:$kafka_usr $kafka_path" >>  userCheck_kafka.sh
echo "fi" >>  userCheck_kafka.sh


while IFS=',' read -ra ADDR; do
    for i in "${ADDR[@]}"; do
        echo -e "\n\n\e[32m user check on server : $i \e[0m"
        chmod +x userCheck_kafka.sh
        scp -i $ssh_key userCheck_kafka.sh $ssh_usr@$i:/tmp
        command="/tmp/userCheck_kafka.sh"
        ssh -i $ssh_key $ssh_usr@$i "$command"
    done
done <<< "$kafka_IP"


zookeeperConnect=''
n=0
while IFS=',' read -ra ADDR; do
    for i in "${ADDR[@]}"; do
        # echo "$i"
        n=$((n+1))
        if [ -z "$zookeeperConnect" ]; then
            zookeeperServer="echo "\"server.$n=$i:2888:3888\"" >> $kafka_path/kafka/zookeeper.properties "
            zookeeperConnect="$i:2181"
            BOOTSTRAP_SERVERS="$i:9093"
        else
            BOOTSTRAP_SERVERS="$BOOTSTRAP_SERVERS,$i:9093"
            zookeeperConnect="$zookeeperConnect,$i:2181"
            zookeeperServer="$zookeeperServer
echo "\"server.$n=$i:2888:3888\"" >> $kafka_path/kafka/zookeeper.properties "
        fi
    done
done <<< "$kafka_IP"

n=1
while IFS=',' read -ra ADDR; do
    for i in "${ADDR[@]}"; do
        echo "$i"
        scp -i $ssh_key $packages_location/$kafka_package $ssh_usr@$i:/tmp/
        command="chown -R kafka:kafka /tmp/$kafka_package"
        ssh -i $ssh_key $ssh_usr@$i "$command"
        command="mv /tmp/$kafka_package $kafka_path/"
        ssh -i $ssh_key $ssh_usr@$i "$command"
        ssh -i $ssh_key $ssh_usr@$i "tar -zxf $kafka_path/$kafka_package -C $kafka_path/"
        echo '#!/bin/bash' > kaka$n.sh
        echo "sed -i "\"s@K2_HOME=.*@K2_HOME=$kafka_path@\"" $kafka_path/.bash_profile" >> kaka$n.sh
        echo "cd $kafka_path" >> kaka$n.sh
        echo "source $kafka_path/.bash_profile" >> kaka$n.sh
        echo "sed -i "\"s@advertised.listeners=.*@advertised.listeners=PLAINTEXT:\/\/$i:9093@\"" $kafka_path/kafka/server.properties" >> kaka$n.sh
        echo "sed -i "\"s@advertised.host.name=.*@advertised.host.name=PLAINTEXT:\/\/$i:9093@\"" $kafka_path/kafka/server.properties " >> kaka$n.sh
        echo "sed -i "\"s@listeners=PLAINTEXT:\/\/10.*@listeners=PLAINTEXT:\/\/$i:9093@\"" $kafka_path/kafka/server.properties" >> kaka$n.sh
        echo "sed -i "\"s@zookeeper.connect=.*@zookeeper.connect=$zookeeperConnect@\"" $kafka_path/kafka/server.properties" >> kaka$n.sh
        echo "sed -i "\"s@listeners=PLAINTEXT:\/\/.*@listeners=PLAINTEXT:\/\/$i:9093@\"" $kafka_path/kafka/server.properties" >> kaka$n.sh
        echo "sed -i "\"s@log.dirs=.*@log.dirs=$kafka_path/data@\"" $kafka_path/kafka/server.properties " >> kaka$n.sh
        echo "sed -i 's@broker.id=0@broker.id=$n@'  $kafka_path/kafka/server.properties " >> kaka$n.sh
        echo "sed -i "\"s@dataDir=.*@dataDir=$kafka_path/zk_data@\"" $kafka_path/kafka/zookeeper.properties" >> kaka$n.sh
        echo "echo "\"default.replication.factor=$kafka_RF\"" >> $kafka_path/kafka/server.properties" >> kaka$n.sh
        echo "echo "\"initLimit=3\"" >> $kafka_path/kafka/zookeeper.properties" >> kaka$n.sh
        echo "echo "\"syncLimit=3\"" >> $kafka_path/kafka/zookeeper.properties" >> kaka$n.sh
        echo "echo "$n" > $kafka_path/zk_data/myid" >> kaka$n.sh
        echo "$zookeeperServer " >> kaka$n.sh
        # echo "sed -i "\"s@K2_HOME=.*@K2_HOME=$kafka_path@\"" $kafka_path/.bash_profile" >> kaka$n.sh
        echo "$kafka_path/kafka/bin/zookeeper-server-start -daemon $kafka_path/kafka/zookeeper.properties" >> kaka$n.sh
        echo "sleep 10" >> kaka$n.sh
        # echo "$kafka_path/kafka/bin/kafka-server-start -daemon $kafka_path/kafka/server.properties" >> kaka$n.sh
        
        chmod +x kaka$n.sh
        
        scp -i $ssh_key kaka$n.sh $ssh_usr@$i:/$kafka_path
        command="chown -R kafka:kafka $kafka_path"
        ssh -i $ssh_key $ssh_usr@$i "$command"
        command="sudo -u kafka /$kafka_path/kaka$n.sh"
        ssh -i $ssh_key $ssh_usr@$i "$command"
        n=$((n+1))
    done
done <<< "$kafka_IP"

n=1
while IFS=',' read -ra ADDR; do
    for i in "${ADDR[@]}"; do
        echo '#!/bin/bash' > kaka$n_$n.sh
        echo "cd $kafka_path" >> kaka$n_$n.sh
        echo "source $kafka_path/.bash_profile" >> kaka$n_$n.sh
        echo "$kafka_path/kafka/bin/kafka-server-start -daemon $kafka_path/kafka/server.properties" >> kaka$n_$n.sh
        echo "sleep 10" >> kaka$n_$n.sh
        chmod +x kaka$n_$n.sh
        scp -i $ssh_key kaka$n_$n.sh $ssh_usr@$i:/$kafka_path
        command="chown -R kafka:kafka $kafka_path"
        ssh -i $ssh_key $ssh_usr@$i "$command"
        command="sudo -u kafka /$kafka_path/kaka$n_$n.sh"
        ssh -i $ssh_key $ssh_usr@$i "$command"
        n=$((n+1))
    done
done <<< "$kafka_IP"
sed -i "s@#BOOTSTRAP_SERVERS=.*@BOOTSTRAP_SERVERS=$BOOTSTRAP_SERVERS@" config.ini

while IFS=',' read -ra ADDR; do
    for i in "${ADDR[@]}"; do
        echo '#!/bin/bash' > kafka_check_$i.sh
	echo "cd /$kafka_path/" >> kafka_check_$i.sh
	echo "source .bash_profile" >> kafka_check_$i.sh
	echo "$kafka_path/kafka/bin/zookeeper-shell localhost:2181 <<< 'ls /brokers/ids'" >> kafka_check_$i.sh
        chmod +x kafka_check_$i.sh
        scp -i $ssh_key kafka_check_$i.sh $ssh_usr@$i:/$kafka_path
        command="chown -R kafka:kafka $kafka_path/kafka_check_$i.sh"
        ssh -i $ssh_key $ssh_usr@$i "$command"
        command="sudo -u kafka /$kafka_path/kafka_check_$i.sh"
        ssh -i $ssh_key $ssh_usr@$i "$command"
    done
done <<< "$kafka_IP"

