#!/bin/bash
#$0 是脚本本身的名字
#$1 是传递给该shell脚本的第一个参数，即删除容器的判断依据
#$2 是传递给该shell脚本的第二个参数，即镜像容器的判断依据

current_name="$USER"
image_name="solace-pubsub-standart"
image_alias="solace"
sub_image_name=${image_name%:*}
if [ "$(uname)" == "Darwin" ];then
	path=/Users/${current_name}/data/docker/volumes/${image_alias}
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ];then
	path=d:/docker/volumes/${image_alias}
fi

# 准确查找镜像是否已经存在
image_exist=$(docker images --all | grep -w ^$sub_image_name)
container_exist=$(docker ps -a | grep $image_name)

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
        echo "3、检查容器[${image_name}]不存在，初始化命令：sudo docker run -d -p 8080:8080 -p 55555:55555 --shm-size=1g --env username_admin_globalaccesslevel=admin --env username_admin_password=admin --name=solace solace/solace-pubsub-standard"
        sudo docker run -d -p 8080:8080 -p 55555:55555 --shm-size=1g \
        --env username_admin_globalaccesslevel=admin --env username_admin_password=admin \
        --name=solace solace/solace-pubsub-standard
    else
        if [[ -z "$1" ]]; then
            echo "3、检查容器[${image_name}]已存在，不需要初始化容器"
        else
            echo "3、删除容器[${image_name}]，该操作用于环境调试"
            docker stop $image_alias && docker rm $image_alias && delete_images_folder
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

echo "---------------函数开始执行---------------"
check_image $1 $2
check_container $1
checkt_container_status
echo "---------------函数执行完毕---------------"