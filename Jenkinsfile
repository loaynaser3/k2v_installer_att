pipeline {
    agent any
    parameters {
        string(name: 'ssh_usr', description: '# ssh user in slave machines', defaultValue : "root")
        string(name: 'ssh_key', description: '''# Master server ssh_key
        '''  , defaultValue : "/root/.ssh/id_rsa")
        choice (choices: ['local', 'download'], name: 'packageOptions')
        booleanParam(name: 'credentials', description: 'insert only if downloadin need user and pass' , defaultValue : false)
        string(name: 'download_usr', description: '', defaultValue : "")
        string(name: 'download_pass', description: '', defaultValue : "")
        string(name: 'packages_location', description: ' ' , defaultValue : "/opt/apps/")
//         choice (choices: ['y', 'n'], description: '''# kafka message broker y/n
// ''', name: 'KAFKA_MESSAGES_BROKER')
        string(name: 'BOOTSTRAP_SERVERS', description: '''# in case of using existing kafka cluster please provide the BOOTSTRAP_SERVERS
# otherwise leave it blank
# ex :
#     BOOTSTRAP_SERVERS=172.31.25.86:9093,172.31.26.104:9093,172.31.40.112:9093

#### kafka ####''')
        string(name: 'kafka_usr', description: ' ' , defaultValue : "kafka")
        string(name: 'kafka_path', description: ' ' , defaultValue : "/opt/apps/kafka")
        choice (choices: ['1', '2', '3'], name: 'kafka_RF')
        string(name: 'kafka_IP', description: ' ' , defaultValue : "10.0.1.4")
        string(name: 'kafka_download_link', description: 'insert download link only if you dont have the package localy ' , defaultValue : "https://owncloud_bkp.s3.amazonaws.com/adminoc/fabricint/kafka/5.3.0.2/Oracle%20JAVA/k2view_Confluent_5.3.0_Package_01.tar.gz")
        string(name: 'kafka_package', description: '''
        #### cassandra ####''' , defaultValue : "k2view_Confluent_5.3.0_Package_01.tar.gz")

        string(name: 'cassandra_usr', description: ' ' , defaultValue : "cassandra")
        string(name: 'cassandra_path', description: ' ' , defaultValue : "/opt/apps/cassandra")
//         choice (choices: ['y', 'n'], description: '''# multi DCs y/n
//  ''', name: 'cassandra_multi_DC')
        string(name: 'clusterName', description: ' ' , defaultValue : "azure")
        string(name: 'cassandra_seed', description: '''# cassandra_seed is the first node will start
''', defaultValue : "10.0.1.4")
        string(name: 'DC1_name', description: ' ' , defaultValue : "azureDC1")
        string(name: 'cassandra_DC1_IP', description: ' ' , defaultValue : "10.0.1.4,10.0.1.11,10.0.1.5")
        string(name: 'cass_RF1', description: ' ' , defaultValue : "3")
        string(name: 'DC2_name', description: ' ' , defaultValue : "")
        string(name: 'cassandra_DC2_IP', description: ' ' , defaultValue : "")
        string(name: 'cass_RF2', description: ' ' , defaultValue : "")
        string(name: 'cassandra_download_link', description: 'insert download link only if you dont have the package localy ' , defaultValue : "https://owncloud_bkp.s3.amazonaws.com/adminoc/fabricint/cassandra/3.11.4/OpenJDK/k2v_cassandra-3.11.4_vanilla_02.tar.gz")
        string(name: 'cassandra_package',   description: '''
        #### fabric #### ''', defaultValue: "k2v_cassandra-3.11.4_vanilla_02.tar.gz")

        string(name: 'fabric_usr', description: ' ' , defaultValue : "k2view")
        string(name: 'fabric_path', description: ' ' , defaultValue : "/opt/apps/k2view")
        // choice (choices: ['y', 'n'], description: '''# fabric multi DCs y/n ''', name: 'fabric_multi_DC')
        string(name: 'fabric_DC1_IP', description: ' ' , defaultValue : "10.0.1.4,10.0.1.11,10.0.1.5")
        string(name: 'fabric_RF1', description: ' ' , defaultValue : "3")
        string(name: 'fabric_DC2_IP', description: ' ' , defaultValue : "")
        string(name: 'fabric_RF2', description: ' ' , defaultValue : "")
        string(name: 'fabric_download_link', description: 'insert download link only if you dont have the package localy ' , defaultValue : "https://owncloud_bkp.s3.amazonaws.com/adminoc/fabricint/fabric_5.5/5.5.0/fabric_5.5.0_51/k2fabric-server-fabric_5.5.0_51_201912221721.tar.gz")
        string(name: 'fabric_package', description: ' ' , defaultValue : "fabric_6.0.1_24_202002191106.tar.gz")
        choice (choices: ['6.X', '5.X'], name: 'fabric_version')
        booleanParam(name: 'install_fabric', description: ' ' , defaultValue : false)
        booleanParam(name: 'install_cassandra', description: ' ' , defaultValue : false)
        booleanParam(name: 'install_kafka', description: ' ' , defaultValue : false)

    }
    options {
        disableConcurrentBuilds()
    }
    stages {
        stage('prepare config.ini'){
            steps{
                println("inserting configuration")
                script {
                    sh(script : "echo '''############## config.ini ##############\n\n\n############## general ##############\n\n# ssh user in slave machines''' > config.ini", returnStdout: true)
                    sh(script : "echo 'ssh_usr=$params.ssh_usr' >> config.ini", returnStdout: true)
                    // sh(script : "echo '\n# kafka message broker y/n' >> config.ini", returnStdout: true)
                    // sh(script : "echo 'KAFKA_MESSAGES_BROKER=$params.KAFKA_MESSAGES_BROKER' >> config.ini", returnStdout: true)
                    sh(script : "echo '''\n# in case of using existing kafka cluster please provide the BOOTSTRAP_SERVERS\n# otherwise leave it blank\n\n# ex :\n#     BOOTSTRAP_SERVERS=172.31.25.86:9093,172.31.26.104:9093,172.31.40.112:9093''' >> config.ini", returnStdout: true)
                    if ("$params.BOOTSTRAP_SERVERS"?.trim()) {
                        sh(script : "echo 'BOOTSTRAP_SERVERS=$params.BOOTSTRAP_SERVERS' >> config.ini", returnStdout: true)
                    }else {
                        sh(script : "echo '#BOOTSTRAP_SERVERS=' >> config.ini", returnStdout: true)
                    }


                    sh(script : "echo '# Master server ssh_key' >> config.ini", returnStdout: true)
                    sh(script : "echo 'ssh_key=$params.ssh_key' >> config.ini", returnStdout: true)
                    sh(script : "echo 'packages_location=$params.packages_location' >> config.ini", returnStdout: true)

                    sh(script : "echo '\n############## kafka ##############\n' >> config.ini", returnStdout: true)
                    sh(script : "echo 'kafka_usr=$params.kafka_usr' >> config.ini", returnStdout: true)
                    sh(script : "echo 'kafka_RF=$params.kafka_RF' >> config.ini", returnStdout: true)
                    sh(script : "echo 'kafka_IP=$params.kafka_IP' >> config.ini", returnStdout: true)
                    sh(script : "echo 'kafka_package=$params.kafka_package' >> config.ini", returnStdout: true)
                    sh(script : "echo 'kafka_path=$params.kafka_path' >> config.ini", returnStdout: true)

                    sh(script : "echo '\n############## cassandra ##############\n' >> config.ini", returnStdout: true)
                    sh(script : "echo 'cassandra_usr=$params.cassandra_usr' >> config.ini", returnStdout: true)
                    sh(script : "echo '# multi DCs y/n' >> config.ini", returnStdout: true)
                    // sh(script : "echo 'cassandra_multi_DC=$params.cassandra_multi_DC' >> config.ini", returnStdout: true)
                    sh(script : "echo 'DC1_name=$params.DC1_name' >> config.ini", returnStdout: true)
                    sh(script : "echo 'DC2_name=$params.DC2_name' >> config.ini", returnStdout: true)
                    sh(script : "echo '# cassandra_seed is the first node will start' >> config.ini", returnStdout: true)
                    sh(script : "echo 'cassandra_seed=$params.cassandra_seed' >> config.ini", returnStdout: true)
                    sh(script : "echo 'cassandra_DC1_IP=$params.cassandra_DC1_IP' >> config.ini", returnStdout: true)
                    sh(script : "echo 'cassandra_DC2_IP=$params.cassandra_DC2_IP' >> config.ini", returnStdout: true)
                    sh(script : "echo 'clusterName=$params.clusterName' >> config.ini", returnStdout: true)
                    sh(script : "echo 'cass_RF1=$params.cass_RF1' >> config.ini", returnStdout: true)
                    sh(script : "echo 'cass_RF2=$params.cass_RF2' >> config.ini", returnStdout: true)
                    sh(script : "echo 'cassandra_package=$params.cassandra_package' >> config.ini", returnStdout: true)
                    sh(script : "echo 'cassandra_path=$params.cassandra_path' >> config.ini", returnStdout: true)

                    sh(script : "echo '\n############## fabric ##############\n' >> config.ini", returnStdout: true)
                    sh(script : "echo 'fabric_usr=$params.fabric_usr' >> config.ini", returnStdout: true)
                    sh(script : "echo '# fabric multi DCs y/n' >> config.ini", returnStdout: true)
                    // sh(script : "echo 'fabric_multi_DC=$params.fabric_multi_DC' >> config.ini", returnStdout: true)
                    sh(script : "echo 'fabric_DC1_IP=$params.fabric_DC1_IP' >> config.ini", returnStdout: true)
                    sh(script : "echo 'fabric_DC2_IP=$params.fabric_DC2_IP' >> config.ini", returnStdout: true)
                    sh(script : "echo 'fabric_RF1=$params.fabric_RF1' >> config.ini", returnStdout: true)
                    sh(script : "echo 'fabric_RF2=$params.fabric_RF2' >> config.ini", returnStdout: true)
                    sh(script : "echo 'fabric_package=$params.fabric_package' >> config.ini", returnStdout: true)
                    sh(script : "echo 'fabric_path=$params.fabric_path' >> config.ini", returnStdout: true)
                    sh(script : "chmod +x *.sh", returnStdout: true)


                }
            }
        }
        stage('download packages'){
            when {
                    environment name: 'packageOptions', value: 'download'
                }
            steps{
                script {
                    if("$params.credentials" == "true"){
                        if("$params.install_fabric" == "true") sh(script : "curl -u $params.download_usr:$params.download_pass -o $params.packages_location$params.fabric_package $params.fabric_download_link", returnStdout: true)
                        if("$params.install_cassandra" == "true") sh(script : "curl -u $params.download_usr:$params.download_pass -o $params.packages_location$params.cassandra_package $params.cassandra_download_link", returnStdout: true)
                        if("$params.install_kafka" == "true") sh(script : "curl -u $params.download_usr:$params.download_pass -o $params.packages_location$params.kafka_package $params.kafka_download_link", returnStdout: true)
                    }else{
                        if("$params.install_fabric" == "true") sh(script : "curl $params.fabric_download_link -o $params.packages_location$params.fabric_package", returnStdout: true)
                        if("$params.install_cassandra" == "true") sh(script : "curl $params.cassandra_download_link -o $params.packages_location$params.cassandra_package", returnStdout: true)
                        if("$params.install_kafka" == "true") sh(script : "curl $params.kafka_download_link -o $params.packages_location$params.kafka_package", returnStdout: true)
                    }
                }
            }
        }
        stage('install kafka'){
            when{
                 expression { return params.install_kafka }
            }
            steps{
                script {
                    println "################"
                    println "installing kafka on $params.kafka_IP"
                    println "################"
                    sh(script : "./kafka.sh", returnStdout: true)
                    println "################"
                    println "checking if kafka brokers UP"
                    println "################"
                    def list = kafka_IP.trim().split(',')[0]
                    println("testing on node : "  + list)
                    cmd="kafka_check_$list'.sh'"
                    sh "scp -i $params.ssh_key $cmd $params.ssh_usr@$list:/$kafka_path"
                    cmd="$kafka_path/kafka_check_$list'.sh'"
                    sh "ssh -i $params.ssh_key $ssh_usr@$list $cmd"
                }
            }
        }
        stage('install cassandra'){
            when{
                 expression { return params.install_cassandra }
            }
            steps{
                script {
                    println "################"
                    println "installing cassandra"
                    println "it may take a while go grap some coffe"
                    println "################"

                    sh(script : "./cassandra.sh", returnStdout: true)

                   def list = "$params.cassandra_DC1_IP".trim().split(',')[0]
                    println("testing on node : " + list)
                    sh "scp -i $params.ssh_key cassandra_check_*.sh $params.ssh_usr@$list:/$cassandra_path"
                    cmd="$cassandra_path/cassandra_check_*.sh"
                    sh "ssh -i $params.ssh_key $ssh_usr@$list $cmd"
                }
            }
        }
        stage('install fabric'){
            when{
                 expression { return params.install_fabric }
            }
            steps{
                script {
                    println "################"
                    println "installing fabric"
                    println "it may take a while go for a ciggerate"
                    println "################"
                    if ("$params.fabric_version" == "5.X") sh(script : "./fabric.sh", returnStdout: true)
                    if ("$params.fabric_version" == "6.X") sh(script : "./fabric6.sh", returnStdout: true)
                    def list = "$params.fabric_DC1_IP".trim().split(',')[0]
                    println("testing on node : " + list)
                    sh "scp -i $params.ssh_key fabric_check_*.sh $params.ssh_usr@$list:/$fabric_path"
                    cmd="$fabric_path/fabric_check_*.sh"
                    sh "ssh -i $params.ssh_key $ssh_usr@$list $cmd"
                }
            }
        }

    }
}
