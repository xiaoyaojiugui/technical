#!/bin/bash
#$0 是脚本本身的名字
#$1 是传递给该shell脚本的第一个参数，即删除容器的判断依据
#$2 是传递给该shell脚本的第二个参数，即镜像容器的判断依据

current_name="$USER"
image_name="redis:5.0"
image_alias="redis"
sub_image_name=${image_name%:*}
if [ "$(uname)" == "Darwin" ];then
	path=/Users/${current_name}/data/docker/volumes/${image_alias}
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ];then
	path=d:/docker/volumes/${image_alias}
fi

# 准确查找镜像是否已经存在
image_exist=$(docker images --all | grep -w ^$sub_image_name)
container_exist=$(docker ps -a | grep ${image_name})

function check_image(){
    if [ -z "$image_exist" ]; then
        echo "\n1、检查镜像[${image_exist}]不存在，初始化命令："
        echo "docker pull ${image_name}"
        docker pull ${image_name}
    else
        if [[ -z "$2" ]]; then
            echo "\n1、检查镜像[${image_name}]已存在，不需要拉取镜像"
        else
            echo "\n1、删除镜像[${image_name}]，该操作用于环境调试"
            docker stop ${image_alias} && docker rm ${image_alias} && docker rmi ${image_name} && exit 1
        fi
    fi
}

function check_container(){
    # 判断应用是否存在，不存在则执行初始化脚本
    if [ -z "$container_exist" ]; then
        echo "\n4、检查容器[${image_name}]不存在，初始化命令："
        echo "docker run --restart=always  -d --privileged=true -p 6379:6379 -v ${path}/conf/redis.conf:/etc/redis/redis.conf -v ${path}/data:/data --name ${image_alias} ${image_name} redis-server /etc/redis/redis.conf --appendonly yes"
        docker run --restart=always  -d --privileged=true -p 6379:6379 \
        -v ${path}/conf/redis.conf:/etc/redis/redis.conf -v ${path}/data:/data \
        --name ${image_alias} ${image_name} redis-server /etc/redis/redis.conf --appendonly yes
    else
        if [[ -z "$1" ]]; then
            echo "\n3、检查容器[${image_name}]已存在，不需要初始化容器"
        else
            echo "\n4、删除容器[${image_name}]，该操作用于环境调试"
            docker stop ${image_alias} && docker rm ${image_alias} && delete_images_folder
            echo "\n4.1、删除容器[${image_name}]，删除成功" && exit 1
        fi
    fi
}

function checkt_container_status (){
    echo "\n5、查看容器[${image_name}]状态，执行命令："
    echo "docker inspect --format='{{.State.Status}}' ${image_alias}"
    status=$(docker inspect --format='{{.State.Status}}' ${image_alias})
    if [ "${status}" == "running" ]; then
        echo "\n5.1、查看容器[${image_name}]状态：[${status}]"
    elif [ "${status}" == "exited" ]; then
        echo "\n5.1、查看容器[${image_name}]状态：[${status}]，启动命令："
        echo "docker start ${image_alias}"
        docker start ${image_alias}
    else
        echo "\n5.1、查看容器[${image_name}]状态：[${status}]，存在异常"
        exit 1 #强制退出，不执行后续步骤
    fi

    echo "\n5.2、查看容器[${image_name}]挂载宿主机地址，执行命令："
    echo "docker inspect redis | jq -r '.[].HostConfig.Binds'"
    docker inspect redis | jq -r '.[].HostConfig.Binds'

    echo "\n5.3、查看容器[${image_name}]详情，执行命令："
    echo "docker ps | grep ${image_name}"
    docker ps | grep ${image_name}
}

function mkdir_folder() {
    #这里的-d 参数判断${path}是否存在 
    if [ ! -d ${path} ];then
		echo "\n2、创建文件夹，执行命令："
        echo "sudo mkdir -p -v ${path}/{data,conf} && sudo chown -R $current_name ${path}/{data,conf}" 
		if [ "$(uname)" == "Darwin" ];then
			sudo mkdir -p -v ${path}/{data,conf} && sudo chown -R $current_name ${path}/{data,conf} && download_redis_conf
		elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ];then    
			mkdir -p -v ${path}/{data,conf} 
		fi
    else
        echo "\n2、文件夹["${path}"]已经存在"
    fi
}

function download_redis_conf(){
    echo "\n3.1、从github下载redis.conf，执行命令："
    echo "wget -P ${path}/conf/ https://github.com/xiaoyaojiugui/docker/blob/master/foundations/cache/redis5/redis.conf" 
        wget -P ${path}/conf/ https://github.com/xiaoyaojiugui/docker/blob/master/foundations/cache/redis5/redis.conf
    echo "\n3.2、修改：protected-mode yes = protected-mode no"
        $(sudo sed -i \"\" 's/protected-mode yes/protected-mode no/g' ${path}/conf/redis.conf)
        $(sudo sed -i \"\" 's/\# requirepass foobared/requirepass 123456/g' ${path}/conf/redis.conf)
        $(sudo sed -i \"\" 's/bind 127.0.0.1/\# bind 127.0.0.1/g' ${path}/conf/redis.conf)
    echo "\n3.3、查看更新是否修改成功"
        cat ${path}/conf/redis.conf | grep 'protected-mode '
        cat ${path}/conf/redis.conf | grep 'requirepass 123456'
        cat ${path}/conf/redis.conf | grep 'bind 127.0.0.1'
}

function delete_images_folder() {
    #这里的-d 参数判断$path是否存在 
    if [ -d ${path} ];then
        sudo rm -rf ${path}
        echo "\n3.1、删除文件夹["${path}"]成功"
    fi
}

echo "---------------函数开始执行---------------"
check_image $1 $2
mkdir_folder
check_container $1
checkt_container_status
echo "---------------函数执行完毕---------------"