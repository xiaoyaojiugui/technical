#!/bin/bash
#$0 是脚本本身的名字
#$1 是传递给该shell脚本的第一个参数，即删除容器的判断依据
#$2 是传递给该shell脚本的第二个参数，即镜像容器的判断依据

image_name="alfresco/alfresco-content-repository-community"
image_alias="alfresco"
container_exist=$(docker ps -a | grep $image_name)
sub_image_name=${image_name%:*}
if [ "$(uname)" == "Darwin" ];then
	path=/data/docker/volumes/${image_alias}
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ];then
	path=d:/docker/volumes/${image_alias}
fi
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

function check_container(){
    # 判断应用是否存在，不存在则执行初始化脚本
    if [ -z "$container_exist" ]; then
        echo "3、检查容器[${image_name}]不存在，初始化命令：docker run -d --privileged=true --name ${image_alias} ${image_name}"
		    docker run -d --privileged=true --name ${image_alias} ${image_name}
    else
        if [[ -z "$1" ]]; then
            echo "3、检查容器[${image_name}]已存在，不需要初始化容器"
        else
            echo "3、删除容器[${image_name}]，该操作用于环境调试"
            docker stop $image_alias && docker rm $image_alias
            echo "4、删除容器[${image_name}]，删除成功" && exit 1
        fi
    fi
}

function checkt_container_status (){
    echo "4、查看容器[${image_name}]状态，执行命令：docker inspect --format='{{.State.Status}}' ${image_alias}"
    status=$(docker inspect --format='{{.State.Status}}' ${image_alias})
    if [ "$status" == "running" ]; then
        echo "5、查看容器[${image_name}]状态：[$status]"
    elif [ "$status" == "exited" ]; then
        echo "5、查看容器[${image_name}]状态：[$status]，启动命令：docker start $image_alias"
        docker start $image_alias
    else
        echo "5、查看容器[${image_name}]状态：[$status]，存在异常"
        exit 1 #强制退出，不执行后续步骤
    fi

    echo "6、查看容器[${image_name}]详情，执行命令：docker ps | grep ${image_name}"
    docker ps | grep $image_name
}

function mkdir_folder() {
    #这里的-d 参数判断$path是否存在 
    if [ ! -d $path ];then
		echo "2、创建文件夹，执行命令：sudo mkdir -p -v $path/{data,config} && sudo chown -R $current_name $path/{data,conf}" 
		if [ "$(uname)" == "Darwin" ];then
			sudo mkdir -p -v $path/{data,conf} && sudo chown -R $current_name $path/{data,conf} && write_mysql_config
		elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ];then    
			mkdir -p -v $path/{data,conf} && write_mysql_config
		fi
    else
        echo "2、文件夹["${path}"]已经存在"
    fi
}

# 将MySQL配置，写到my.conf中
function write_mysql_config() {
    file_name="${path}/conf/my.cnf"
    if [ -f $file_name ]; then
        echo "2.1、文件已存在["$file_name"]"
        return 0
    else
        touch $file_name
        echo "2.1、创建文件my.cnf并将配置写到文件中["$file_name"]"
        cat >$file_name <<EOF
# Default MySQL server config
[mysqld]
character-set-server=utf8
explicit_defaults_for_timestamp = 1
[client]
default-character-set=utf8
[mysql]
default-character-set=utf8

# Only allow connections from localhost
bind-address = 127.0.0.1
EOF
        cat $file_name
    fi
    return 0
}


echo "---------------函数开始执行---------------"
check_image $1 $2
check_container $1
checkt_container_status
echo "---------------函数执行完毕---------------"