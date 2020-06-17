#!/bin/bash

source config.ini

K2_HOME=$fabric_path
ip=null


fabric_IP="$fabric_DC1_IP"
if [[ ! -z "$fabric_DC2_IP" ]]; then
        fabric_IP="$fabric_IP"",$fabric_DC2_IP"
fi

### check users
echo '#!/bin/bash' > userCheck_fabric.sh
echo "$fabric_usr "
echo "### check users" >> userCheck_fabric.sh
echo 'users=$(cat /etc/passwd | grep '$fabric_usr')' >> userCheck_fabric.sh
echo 'k2vusr=$(echo "$users" | grep -o '$fabric_usr':/bin/bash)' >>  userCheck_fabric.sh
echo 'if [ -z $k2vusr ]; then' >>  userCheck_fabric.sh
echo "    mkdir -p $fabric_path" >>  userCheck_fabric.sh
echo "    useradd $fabric_usr -m -d $fabric_path" >>  userCheck_fabric.sh
echo "    chown -R $fabric_usr:$fabric_usr $fabric_path" >>  userCheck_fabric.sh
echo "fi" >>  userCheck_fabric.sh


while IFS=',' read -ra ADDR; do
    for i in "${ADDR[@]}"; do
        chmod +x userCheck_fabric.sh
        scp -i $ssh_key userCheck_fabric.sh $ssh_usr@$i:/tmp
        command="/tmp/userCheck_fabric.sh"
        ssh -i $ssh_key $ssh_usr@$i "$command"
    done
done <<< "$fabric_IP"

n=1
while IFS=',' read -ra ADDR; do
    for i in "${ADDR[@]}"; do
        echo "$i"
        scp -i $ssh_key $packages_location/$fabric_package $ssh_usr@$i:/$fabric_path
        command="chown -R $fabric_usr:$fabric_usr $fabric_path/$fabric_package"
        echo $command
        ssh -i $ssh_key $ssh_usr@$i "$command"
        ssh -i $ssh_key $ssh_usr@$i "tar -zxf $fabric_path/$fabric_package -C $fabric_path/"
        echo '#!/bin/bash' > fabric_$i.sh
        echo "sed -i "\"s@K2_HOME=.*@K2_HOME=$fabric_path@\"" $fabric_path/.bash_profile" >> fabric_$i.sh
        echo "cd $fabric_path" >> fabric_$i.sh
        echo "source $fabric_path/.bash_profile" >> fabric_$i.sh
        command="cp -r $K2_HOME/fabric/config.template $K2_HOME/config"
        ssh -i $ssh_key $ssh_usr@$i "$command"
        echo 'sed -i "s@#CASSANDRA_CONSISTENCY_LEVEL=.*@CASSANDRA_CONSISTENCY_LEVEL=LOCAL_ONE@"   $K2_HOME/config/config.ini' >> fabric_$i.sh
        echo "sed -i "\"s@#USER=cassandra@USER=k2admin@\"" $K2_HOME/config/config.ini" >> fabric_$i.sh
        echo "sed -i "\"s@#PASSWORD=@PASSWORD=Q1w2e3r4t5@\"" $K2_HOME/config/config.ini" >> fabric_$i.sh
        NetworkTopologyStrategy="'NetworkTopologyStrategy'"
        class="'class'"
        if [[ ! -z "$cassandra_DC2_IP" ]]; then
            inside="'$DC1_name' : $fabric_RF1, '$DC2_name' : $fabric_RF2"
            echo "sed -i \"s@#REPLICATION_OPTIONS=.*@REPLICATION_OPTIONS={ $class : $NetworkTopologyStrategy, $inside }@\"   $K2_HOME/config/config.ini" >> fabric_$i.sh
            echo "sed -i \"s@#AUTH_REPLICATION_OPTIONS=.*@AUTH_REPLICATION_OPTIONS={ $class : $NetworkTopologyStrategy, $inside }@\"   $K2_HOME/config/config.ini" >> fabric_$i.sh
            ip=$(echo $fabric_DC1_IP | grep -o $i)
            if [[ ! -z "$ip" ]]; then
                echo "sed -i s/#HOSTS=.*/"HOSTS=$cassandra_DC1_IP"/g $K2_HOME/config/config.ini" >> fabric_$i.sh
            else
                echo "sed -i s/#HOSTS=.*/"HOSTS=$cassandra_DC2_IP"/g $K2_HOME/config/config.ini" >> fabric_$i.sh
            fi
            # if [[ "$ip" == "$i" ]]; then
            #     cassandra_seed="$cassandra_DC1_IP"
            #     echo "sed -i s/#HOSTS=.*/"HOSTS=$cassandra_seed"/g $K2_HOME/config/config.ini" >> fabric_$i.sh
            # else
            #     cassandra_seed="$cassandra_DC2_IP"
            #     echo "sed -i s/#HOSTS=.*/"HOSTS=$cassandra_seed"/g $K2_HOME/config/config.ini" >> fabric_$i.sh
            # fi
        else
            inside="'$DC1_name' : $fabric_RF1"
            echo "sed -i s/#HOSTS=.*/"HOSTS=$cassandra_DC1_IP"/g $K2_HOME/config/config.ini" >> fabric_$i.sh
            echo "sed -i \"s@#REPLICATION_OPTIONS=.*@REPLICATION_OPTIONS={ $class : $NetworkTopologyStrategy, $inside }@\"   $K2_HOME/config/config.ini" >> fabric_$i.sh
            echo "sed -i \"s@#AUTH_REPLICATION_OPTIONS=.*@AUTH_REPLICATION_OPTIONS={ $class : $NetworkTopologyStrategy, $inside }@\"   $K2_HOME/config/config.ini" >> fabric_$i.sh

        fi

        echo 'sed -i "s@#USER=cassandra@USER=cassandra@" $K2_HOME/config/config.ini' >> fabric_$i.sh
        # if  [[ "$fabric_nodes" != "1" ]]; then
	if [[ ! -z "$BOOTSTRAP_SERVERS" ]]; then
            echo 'sed -i "s@#MESSAGES_BROKER_TYPE=.*@MESSAGES_BROKER_TYPE=KAFKA@" $K2_HOME/config/config.ini' >> fabric_$i.sh
            echo "sed -i 's@#BOOTSTRAP_SERVERS=.*@BOOTSTRAP_SERVERS=$BOOTSTRAP_SERVERS@' $K2_HOME/config/config.ini" >> fabric_$i.sh
        else
            echo 'sed -i "s@#MESSAGES_BROKER_TYPE=.*@MESSAGES_BROKER_TYPE=MEMORY@" $K2_HOME/config/config.ini' >> fabric_$i.sh
        fi
        echo "k2fabric start" >> fabric_$i.sh
        chmod +x fabric_$i.sh
        scp -i $ssh_key fabric_$i.sh $ssh_usr@$i:/$fabric_path
        command="chown -R $fabric_usr:$fabric_usr /$fabric_path/"
        ssh -i $ssh_key $ssh_usr@$i "$command"
        command="sudo -u $fabric_usr /$fabric_path/fabric_$i.sh"
        ssh -i $ssh_key $ssh_usr@$i "$command"
        sleep 10
        n=$((n+1))
    done
done <<< "$fabric_IP"

while IFS=',' read -ra ADDR; do
    for i in "${ADDR[@]}"; do
	echo "$i"
    done
done <<< "$fabric_IP"

        echo "server : $i"
        echo '#!/bin/bash' > fabric_check_$i.sh
        echo "cd /$fabric_path/" >> fabric_check_$i.sh
        echo "source .bash_profile" >> fabric_check_$i.sh
        echo "echo 'clusterstatus;' | fabric" >> fabric_check_$i.sh
        chmod +x fabric_check_$i.sh
        scp -i $ssh_key fabric_check_$i.sh $ssh_usr@$i:/$fabric_path
        command="chown -R k2view:k2view $fabric_path/fabric_check_$i.sh"
        ssh -i $ssh_key $ssh_usr@$i "$command"
        command="sudo -u k2view /$fabric_path/fabric_check_$i.sh"
        ssh -i $ssh_key $ssh_usr@$i "$command"
