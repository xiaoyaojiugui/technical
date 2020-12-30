#!/bin/bash
#$0 是脚本本身的名字
#$1 是传递给该shell脚本的第一个参数，即删除容器的判断依据
#$2 是传递给该shell脚本的第二个参数，即镜像容器的判断依据

image_name="puckel/docker-airflow:latest"
image_alias="airflow"
mysql_image_alias="mysql"
container_exist=$(docker ps -a | grep $image_name)
sub_image_name=${image_name%:*}
path=/data/docker/volumes/${image_alias}
# 准确查找镜像是否已经存在
image_exist=$(docker images --all | grep -w ^$sub_image_name)
current_name="$USER"

function check_image(){
    if [ -z "$image_exist" ]; then
        echo "1、检查镜像[${image_exist}]不存在，初始化命令：docker pull ${image_name}"
        docker pull ${image_name}
    else
        if [[ -z "$2" ]]; then
            echo "1、检查镜像[${image_name}]已存在，不需要拉取镜像"
        else
            echo "1、删除镜像[${image_name}]，该操作用于环境调试"
            docker stop $image_alias && docker rm $image_alias && docker rmi $image_name && exit 1
        fi
    fi
}

function mkdir_images_folder() {
    #这里的-d 参数判断$path是否存在 
    if [ ! -d $path ];then
        echo "\n2、创建文件夹，执行命令：sudo mkdir -p -v $path/{dags,logs} && sudo chown -R $current_name $path/{dags,logs}"
        sudo mkdir -p -v $path/{dags,logs} && sudo chown -R $current_name $path/{dags,logs}
    else
        echo "\n2、文件夹["${path}"]已经存在"
    fi
}

function delete_images_folder() {
    #这里的-d 参数判断$path是否存在 
    if [ -d $path ];then
        sudo rm -rf $path
        echo "\n3.1、删除文件夹["${path}"]成功"
    fi
}

function check_container(){
    # 判断应用是否存在，不存在则执行初始化脚本
    if [ -z "$container_exist" ]; then
        mkdir_images_folder
        echo "\n3、检查容器[${image_name}]不存在，初始化命令：docker run -p 8080:8080 --privileged=true -v /data/docker/volumes/airflow/dags:/usr/local/airflow/dags -v /data/docker/volumes/airflow/logs:/usr/local/airflow/logs --name ${image_alias} -d ${image_name}"
        docker run -p 8080:8080 --privileged=true -v /data/docker/volumes/airflow/dags:/usr/local/airflow/dags -v /data/docker/volumes/airflow/logs:/usr/local/airflow/logs --name ${image_alias} -d ${image_name}
    else
        if [[ -z "$1" ]]; then
            echo "\n3、检查容器[${image_name}]已存在，不需要初始化容器"
        else
            echo "\n3、删除容器[${image_name}]，该操作用于环境调试"
            docker stop $image_alias && docker rm $image_alias && delete_images_folder
            echo "\n3.2、删除容器[${image_name}]成功" && exit 1
        fi
    fi
}

function checkt_container_status (){
    echo "\n4、查看容器[${image_name}]状态，执行命令：docker inspect $image_alias | jq -r '.[].State.Status'"
    status=$(docker inspect $image_alias | jq -r '.[].State.Status')

    if [ "$status" == "running" ]; then
        echo "\n5、查看容器[${image_name}]状态：[$status]"
    elif [ "$status" == "exited" ]; then
        echo "\n5、查看容器[${image_name}]状态：[$status]，启动命令：docker start $image_alias"
        docker start $image_alias
    else
        echo "\n5、查看容器[${image_name}]状态：[$status]，存在异常"
        exit 1 #强制退出，不执行后续步骤
    fi

    echo "\n6、查看容器[${image_name}]详情，执行命令：docker ps | grep ${image_name}"
    docker ps | grep $image_name
}


# 将配置文件写到指定的文件中
function write_config() {
    if [ -z "$container_exist" ]; then
        echo "\n7、拷贝airflow.cfg到指定目录[$path]，执行命令：sudo docker cp $(docker ps -a | grep $image_alias |awk '{print $1}'):/usr/local/airflow/airflow.cfg $path"
        sudo docker cp $(docker ps -a | grep $image_alias |awk '{print $1}'):/usr/local/airflow/airflow.cfg $path
        
        echo "\n8、查看docker中mysql的IP地址，执行命令：docker inspect mysql --format='{{.NetworkSettings.IPAddress}}'"
        ipAddress=$(docker inspect mysql --format='{{.NetworkSettings.IPAddress}}')
        echo "\n8.1、查看docker中mysql的IP地址：[$ipAddress]"
        
        echo "\n9、修改airflow.cfg配置中的executor和sql_alchemy_conn"
        $(sudo sed -i \"\" 's/executor = SequentialExecutor/executor = LocalExecutor/g' $path/airflow.cfg)
        $(sudo sed -i \"\" 's/\# sql_alchemy_conn = sqlite:\/\/\/\/tmp\/airflow.db/sql_alchemy_conn = mysql:\/\/airflow:airflow\'@$ipAddress':3306\/airflow/g' $path/airflow.cfg)

        echo "\n10、查看airflow的airflow.cfg配置是否修改成功"
        cat /data/docker/volumes/airflow/airflow.cfg | grep 'executor ='
        cat /data/docker/volumes/airflow/airflow.cfg | grep 'sql_alchemy_conn'
    fi
}

function reset_container(){
    # 判断应用是否存在，不存在则执行初始化脚本
    if [ -z "$container_exist" ]; then
        write_config
        echo "\n11、删除容器[${image_name}]，该操作用于环境调试"
        docker stop $image_alias && docker rm $image_alias
        echo "\n12、重新初始化容器[${image_name}]，初始化命令：docker run -p 8080:8080 --privileged=true -v /data/docker/volumes/airflow/airflow.cfg:/usr/local/airflow/airflow.cfg -v /data/docker/volumes/airflow/dags:/usr/local/airflow/dags -v /data/docker/volumes/airflow/logs:/usr/local/airflow/logs --name ${image_alias} -d ${image_name}"
        docker run -p 8080:8080 --privileged=true -v /data/docker/volumes/airflow/airflow.cfg:/usr/local/airflow/airflow.cfg -v /data/docker/volumes/airflow/dags:/usr/local/airflow/dags -v /data/docker/volumes/airflow/logs:/usr/local/airflow/logs --name ${image_alias} -d ${image_name}
        echo "\n13、查看容器[${image_name}]挂载宿主机地址，执行命令：docker inspect airflow | jq -r '.[].HostConfig.Binds'"
        docker inspect airflow | jq -r '.[].HostConfig.Binds'
        echo "\n14、查看容器[${image_name}]详情，执行命令：docker ps | grep ${image_name}"
        docker ps | grep $image_name
    fi
}

echo "---------------函数开始执行---------------"
check_image $1 $2
check_container $1
checkt_container_status
reset_container
echo "---------------函数执行完毕---------------"

