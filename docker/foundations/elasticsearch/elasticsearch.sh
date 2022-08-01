#!/bin/sh
#$0 是脚本本身的名字
#$1 是传递给该shell脚本的第一个参数，即删除容器的判断依据
#$2 是传递给该shell脚本的第二个参数，即镜像容器的判断依据

image_name="elasticsearch:6.6.0"
image_alias="es"
container_exist=$(docker ps -a | grep $image_name)
sub_image_name=${image_name%:*}
# 准确查找镜像是否已经存在
image_exist=$(docker images --all | grep -w ^$sub_image_name)

if [ -z "$image_exist" ]; then
    echo "检查镜像[${image_exist}]不存在，初始化命令：docker pull ${image_name}"
    docker pull ${image_name}
else
    if [[ -z "$2" ]]; then
        echo "检查镜像[${image_name}]已存在，不需要拉取镜像"
    else
        echo "删除镜像[${image_name}]，该操作用于环境调试"
        docker stop $image_alias && docker rm $image_alias && docker rmi $image_name && exit 1
    fi
fi

# 判断应用是否存在，不存在则执行初始化脚本
if [ -z "$container_exist" ]; then
    echo "检查容器[${image_name}]不存在，初始化命令：docker run -d -p 9200:9200 -p 9300:9300 --name ${image_alias} ${image_name}"
    docker run -d -p 9200:9200 -p 9300:9300 --name ${image_alias} ${image_name}
else
    if [[ -z "$1" ]]; then
        echo "检查容器[${image_name}]已存在，不需要初始化容器"
    else
        echo "删除容器[${image_name}]，该操作用于环境调试"
        docker stop $image_alias && docker rm $image_alias
        echo "删除容器[${image_name}]，删除成功" && exit 1
    fi
fi

echo "查看容器[${image_name}]状态，执行命令：docker inspect $image_alias | jq -r '.[].State.Status'"
status=$(docker inspect $image_alias | jq -r '.[].State.Status')

if [ "$status" == "running" ]; then
    echo "查看容器[${image_name}]状态：[$status]"
elif [ "$status" == "exited" ]; then
    echo "查看容器[${image_name}]状态：[$status]，启动命令：docker start $image_alias"
    docker start $image_alias
else
    echo "查看容器[${image_name}]状态：[$status]，存在异常"
    exit 1 #强制退出，不执行后续步骤
fi

echo "查看容器[${image_name}]详情，执行命令：docker ps | grep ${image_name}"
docker ps | grep $image_name