#!/bin/bash
#$0 是脚本本身的名字
#$1 是传递给该shell脚本的第一个参数，即删除容器的判断依据
#$2 是传递给该shell脚本的第二个参数，即镜像容器的判断依据

image_name="postgres:latest"
image_alias="postgresql"
container_exist=$(docker ps -a | grep $image_name)
sub_image_name=${image_name%:*}
path=/data/docker/volumes/${image_alias}
# 准确查找镜像是否已经存在
image_exist=$(docker images --all | grep -w ^$sub_image_name)
current_name="$USER"

function check_image(){
    if [ -z "$image_exist" ]; then
        echo "\n1、检查镜像[${image_exist}]不存在，初始化命令：docker pull ${image_name}"
        docker pull ${image_name}
    else
        if [[ -z "$2" ]]; then
            echo "\n1、检查镜像[${image_name}]已存在，不需要拉取镜像"
        else
            echo "\n1、删除镜像[${image_name}]，该操作用于环境调试"
            docker stop $image_alias && docker rm $image_alias && docker rmi $image_name && exit 1
        fi
    fi
}

function check_container(){
    # 判断应用是否存在，不存在则执行初始化脚本
    if [ -z "$container_exist" ]; then
        mkdir_folder
        echo "\n3、检查容器[${image_name}]不存在，初始化命令：docker run -d -p 5432:5432 -e 'POSTGRES_PASSWORD=postgres' -e 'POSTGRES_DB=postgres' -e 'PGDATA=/var/lib/postgresql/data/pgdata' -v ${path}/data:/var/lib/postgresql/data -v ${path}/log:/var/log --name ${image_alias} ${image_name}"
        docker run -d -p 5432:5432 \
        -e 'POSTGRES_PASSWORD=postgres' \
        -e 'POSTGRES_DB=postgres' \
        -e 'PGDATA=/var/lib/postgresql/data/pgdata' \
        -v ${path}/data:/var/lib/postgresql/data \
        -v ${path}/log:/var/log \
        --name ${image_alias} ${image_name}
    else
        if [[ -z "$1" ]]; then
            echo "\n3、检查容器[${image_name}]已存在，不需要初始化容器"
        else
            echo "\n3、删除容器[${image_name}]，该操作用于环境调试"
            docker stop $image_alias && docker rm $image_alias && delete_images_folder
            echo "\n4、删除容器[${image_name}]，删除成功" && exit 1
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

function mkdir_folder() {
    #这里的-d 参数判断$path是否存在 
    if [ ! -d $path ];then
        echo "\n2、创建文件夹，执行命令：sudo mkdir -p -v $path/{data,log} && sudo chown -R $current_name $path/{data,log}"
        sudo mkdir -p -v $path/{data,log} && sudo chown -R $current_name $path/{data,log} 
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


echo "---------------函数开始执行---------------"
check_image $1 $2
check_container $1
checkt_container_status
echo "---------------函数执行完毕---------------"