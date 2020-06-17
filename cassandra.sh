#!/bin/bash

source config.ini

INSLATT_DIR=$cassandra_path
ip=null
n=1
ip_seeds=''

cassandra_IP="$cassandra_DC1_IP"
if [[ ! -z "$cassandra_DC2_IP" ]]; then
        cassandra_IP="$cassandra_IP"",$cassandra_DC2_IP"
fi


### check users
echo '#!/bin/bash' > userCheck_cassandra.sh
echo "$cassandra_usr "
echo "### check users" >> userCheck_cassandra.sh
echo 'users=$(cat /etc/passwd | grep '$cassandra_usr')' >> userCheck_cassandra.sh 
echo 'k2vusr=$(echo "$users" | grep -o '$cassandra_usr':/bin/bash)' >>  userCheck_cassandra.sh
echo 'if [ -z $k2vusr ]; then' >>  userCheck_cassandra.sh
echo "    mkdir -p $cassandra_path" >>  userCheck_cassandra.sh
echo "    useradd $cassandra_usr -m -d $cassandra_path" >>  userCheck_cassandra.sh
echo "    chown -R $cassandra_usr:$cassandra_usr $cassandra_path" >>  userCheck_cassandra.sh
echo "fi" >>  userCheck_cassandra.sh

while IFS=',' read -ra ADDR; do
    for i in "${ADDR[@]}"; do
        chmod +x userCheck_cassandra.sh
        scp -i $ssh_key userCheck_cassandra.sh $ssh_usr@$i:/tmp
        command="/tmp/userCheck_cassandra.sh"
        ssh -i $ssh_key $ssh_usr@$i "$command"
    done
done <<< "$cassandra_IP"


function get_seeds {
    if [[ ! -z "$cassandra_DC2_IP" ]]; then 
        IFS=',' read -ra ADDR <<< "$cassandra_DC1_IP"
        for a in "${ADDR[@]}"; do
            echo $a
        done
        ip_seeds="${ADDR[0]}"
        IFS=',' read -ra ADDR <<< "$cassandra_DC2_IP"
        for b in "${ADDR[@]}"; do
            echo $b
        done
        ip_seeds="$ip_seeds,${ADDR[0]}"
    else 
        ip_seeds="$cassandra_seed"
    fi
}
function post_cassandra {
    if [[ ! -z "$cassandra_DC2_IP" ]]; then 
        IFS=',' read -ra ADDR <<< "$cassandra_DC1_IP"
        for a in "${ADDR[@]}"; do
            echo $a
        done
        post_node="${ADDR[0]}"
            
    else 
        post_node="$cassandra_seed"
    fi

    chmod +x post_cassandra.sh
    scp -i $ssh_key post_cassandra.sh $ssh_usr@$post_node:/$cassandra_path
    command="chown -R $cassandra_usr:$cassandra_usr /$cassandra_path/"
    ssh -i $ssh_key $ssh_usr@$i "$command"
    command="sudo -u $cassandra_usr /$cassandra_path/post_cassandra.sh"
    ssh -i $ssh_key $ssh_usr@$post_node "$command"
}
function post_cassandra_all_nodes {
    while IFS=',' read -ra ADDR; do
        for i in "${ADDR[@]}"; do
        scp -i $ssh_key post_cassandra.sh $ssh_usr@$i:/$cassandra_path
        command="chown -R $cassandra_usr:$cassandra_usr /$cassandra_path/"
        ssh -i $ssh_key $ssh_usr@$i "$command"
        command="sudo -u $cassandra_usr /$cassandra_path/post_cassandra.sh"
        ssh -i $ssh_key $ssh_usr@$i "$command"
        done
    done <<< "$cassandra_IP"
}
function get_alters {
    if [[ "$n" == "1" ]]; then
        echo '#!/bin/bash' > post_cassandra.sh
        echo "cd $cassandra_path" >> post_cassandra.sh
        echo "source $cassandra_path/.bash_profile" >> post_cassandra.sh
        NetworkTopologyStrategy="'NetworkTopologyStrategy'"
        class="'class'"
        if [[ ! -z "$cassandra_DC2_IP" ]]; then
            inside="'$DC1_name' : '$cass_RF1', '$DC2_name' : '$cass_RF2'"
        else 
            inside="'$DC1_name' : '$cass_RF1'"           
        fi
        echo '## alter cassandra keyspaces' >> post_cassandra.sh
        echo 'echo "ALTER KEYSPACE system_auth WITH replication = {'$class': '$NetworkTopologyStrategy', '$inside'};" | cqlsh -ucassandra -pcassandra localhost' >> post_cassandra.sh 
        echo 'echo "ALTER KEYSPACE system_schema WITH replication = {'$class': '$NetworkTopologyStrategy', '$inside'}; " | cqlsh -ucassandra -pcassandra localhost' >> post_cassandra.sh 
        echo 'echo "ALTER KEYSPACE system_distributed WITH replication = {'$class': '$NetworkTopologyStrategy', '$inside'} ;" | cqlsh -ucassandra -pcassandra localhost' >> post_cassandra.sh 
        echo 'echo "ALTER KEYSPACE system WITH replication = {'$class': '$NetworkTopologyStrategy', '$inside'} ; " | cqlsh -ucassandra -pcassandra localhost' >> post_cassandra.sh 
        echo 'echo "ALTER KEYSPACE system_traces WITH replication = {'$class': '$NetworkTopologyStrategy', '$inside'} ;" | cqlsh -ucassandra -pcassandra localhost' >> post_cassandra.sh 
        pass="'Q1w2e3r4t5'"
        cmd_body='echo "CREATE ROLE k2admin with SUPERUSER = true AND LOGIN = true and PASSWORD = '$pass';"| cqlsh -ucassandra -pcassandra localhost'
        echo $cmd_body >> post_cassandra.sh
        echo "nodetool -u cassandra -pw cassandra rebuild" >> post_cassandra.sh
        echo "nodetool -u cassandra -pw cassandra repair" >> post_cassandra.sh
    fi
	
	
}

while IFS=',' read -ra ADDR; do
    for i in "${ADDR[@]}"; do
        scp -i $ssh_key $packages_location/$cassandra_package $ssh_usr@$i:/$cassandra_path
        command="chown -R $cassandra_usr:$cassandra_usr $cassandra_path/$cassandra_package"
        ssh -i $ssh_key $ssh_usr@$i "$command"
        ssh -i $ssh_key $ssh_usr@$i "tar -zxf $cassandra_path/$cassandra_package -C $cassandra_path/"
        echo '#!/bin/bash' > cassandra_$i.sh
        echo "sed -i "\"s@INSLATT_DIR=.*@INSLATT_DIR=$cassandra_path@\"" $cassandra_path/.bash_profile" >> cassandra_$i.sh
        echo "sed -i "\"s@cd.*@cd $cassandra_path@\"" $cassandra_path/.bash_profile" >> cassandra_$i.sh
        echo "cd $cassandra_path" >> cassandra_$i.sh
        echo "source $cassandra_path/.bash_profile" >> cassandra_$i.sh
        findIP=$(echo $cassandra_DC1_IP | grep -o $i)
        if [[ "$i" == "$findIP" ]]; then
            echo "sed -i 's@dc=.*@dc=$DC1_name@'  $INSLATT_DIR/cassandra/conf/cassandra-rackdc.properties " >> cassandra_$i.sh
        else
            echo "sed -i 's@dc=.*@dc=$DC2_name@'  $INSLATT_DIR/cassandra/conf/cassandra-rackdc.properties " >> cassandra_$i.sh
        fi
        echo "sed -i 's@cluster_name: .*@cluster_name: '$clusterName'@' $INSLATT_DIR/cassandra/conf/cassandra.yaml" >> cassandra_$i.sh
        echo "sed -i 's/seeds:.*/"seeds: \"$cassandra_seed\""/g' $INSLATT_DIR/cassandra/conf/cassandra.yaml" >> cassandra_$i.sh
        echo "sed -i 's/listen_address:.*/"listen_address: $i"/g' $INSLATT_DIR/cassandra/conf/cassandra.yaml" >> cassandra_$i.sh
        echo "sed -i 's/broadcast_rpc_address:.*/"broadcast_rpc_address: $i"/g' $INSLATT_DIR/cassandra/conf/cassandra.yaml" >> cassandra_$i.sh
        echo "sed -i 's@endpoint_snitch:.*@endpoint_snitch: GossipingPropertyFileSnitch@' $INSLATT_DIR/cassandra/conf/cassandra.yaml" >> cassandra_$i.sh
        
        echo "sed -i 's@LOCAL_JMX=.*@LOCAL_JMX='no'@' $INSLATT_DIR/cassandra/conf/cassandra-env.sh" >> cassandra_$i.sh
        echo "sed -i '"s@-Djava.rmi.server.hostname=.*@-Djava.rmi.server.hostname=$i\"@"' $INSLATT_DIR/cassandra/conf/cassandra-env.sh" >> cassandra_$i.sh
        echo "sed -i "\'s@-Dcom.sun.management.jmxremote.password.file=.*@-Dcom.sun.management.jmxremote.password.file=$INSLATT_DIR/cassandra/conf/.jmxremote.password\"@\'" $INSLATT_DIR/cassandra/conf/cassandra-env.sh" >> cassandra_$i.sh

        echo "cassandra" >> cassandra_$i.sh
        get_seeds
        get_alters    
        
        echo "## seeds alter after startup" >> cassandra_$i.sh
        echo "sed -i 's/seeds:.*/"seeds: \"$ip_seeds\""/g' $INSLATT_DIR/cassandra/conf/cassandra.yaml" >> cassandra_$i.sh
        echo -e "\n\n\e[32mwait for cassandra node, 15 sec\e[0m"
        sleep 15
        chmod +x cassandra_$i.sh
        scp -i $ssh_key cassandra_$i.sh $ssh_usr@$i:/$cassandra_path
        command="chown -R $cassandra_usr:$cassandra_usr /$cassandra_path/"
        ssh -i $ssh_key $ssh_usr@$i "$command"
        command="sudo -u $cassandra_usr /$cassandra_path/cassandra_$i.sh"
        ssh -i $ssh_key $ssh_usr@$i "$command"
        
        n=$((n+1))
    done
done <<< "$cassandra_IP"
post_cassandra
# post_cassandra_all_nodes
echo " connect to : $cassandra_seed"
echo "server : $cassandra_seed"
echo '#!/bin/bash' > cassandra_check_$cassandra_seed.sh
echo "cd /$cassandra_path/" >> cassandra_check_$cassandra_seed.sh
echo "source .bash_profile" >> cassandra_check_$cassandra_seed.sh
echo "nodetool -u cassandra -pw cassandra status" >> cassandra_check_$cassandra_seed.sh
chmod +x cassandra_check_$cassandra_seed.sh
scp -i $ssh_key cassandra_check_$cassandra_seed.sh $ssh_usr@$cassandra_seed:/$cassandra_path
command="chown -R cassandra:cassandra $cassandra_path/cassandra_check_$cassandra_seed.sh"
ssh -i $ssh_key $ssh_usr@$cassandra_seed "$command"
command="sudo -u cassandra /$cassandra_path/cassandra_check_$cassandra_seed.sh"
ssh -i $ssh_key $ssh_usr@$cassandra_seed "$command"        
