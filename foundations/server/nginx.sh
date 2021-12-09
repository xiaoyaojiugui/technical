#!/bin/bash
#$0 是脚本本身的名字
#$1 是传递给该shell脚本的第一个参数，即删除容器的判断依据
#$2 是传递给该shell脚本的第二个参数，即镜像容器的判断依据

current_name="${USER}"
image_name="nginx:1.21"
image_alias="nginx"
container_exist=$(docker ps -a | grep ${image_name})
sub_image_name=${image_name%:*}
# 准确查找镜像是否已经存在
image_exist=$(docker images --all | grep -w ^$sub_image_name)

function get_os_path(){
    if [ "$(uname)" == "Darwin" ];then
        path=/Users/${current_name}/data/docker/volumes/${image_alias}
        elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ];then
        path=d:/docker/volumes/${image_alias}
        elif [ "$(expr substr $(uname -s) 1 10)" == "Linux" ];then
        path=/home/${current_name}/data/docker/volumes/${image_alias}
    fi
}

function check_image(){
    if [[ -n "$2" && -n "$1" ]]; then
        echo "1、删除镜像[${image_name}]，该操作用于环境调试"
        docker stop ${image_alias} && docker rm ${image_alias} && docker rmi ${image_name} && exit 1
        elif [[ -n "$1" ]]; then
        echo "1、镜像[${image_name}]，不执行操作"
    else
        if [ -z "${image_exist}" ]; then
            echo "1、检查镜像[${image_exist}]不存在，执行命令：docker pull ${image_name}"
            docker pull ${image_name}
        else
            echo "1、检查镜像[${image_name}]已存在，不需要拉取镜像"
        fi
    fi
}

function check_container(){
    if [[ -n "$1" ]]; then
        echo "2、删除容器[${image_name}]，执行命令：docker stop ${image_alias} && docker rm ${image_alias}"
        docker stop ${image_alias} && docker rm -f ${image_alias}
        echo "2.1、成功删除容器[${image_name}]"
    else
        # 判断应用是否存在，不存在则执行初始化脚本
        if [ -z "${container_exist}" ]; then
            echo "2、检查容器[${image_name}]不存在，执行命令：docker run -d -p 80:80 -d --name ${image_alias} ${image_name}"
            docker run -d -p 80:80 -d --name ${image_alias} ${image_name}
        fi
    fi
}

function create_foler() {
    if [[ -n "$1" ]]; then
        echo "3、删除文件夹，执行命令：sudo rm -rf ${path}"
        sudo rm -rf ${path}
        echo "3、成功删除文件夹[${path}]" && exit 1
    else
        #这里的-d 参数判断${path}是否存在
        if [[ -d ${path} ]];then
            echo "3、文件夹["${path}"]已经存在"
        else
            echo "3、创建文件夹，执行命令：sudo mkdir -p -v ${path}/{html,log} "
            if [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 10)" == "Linux" ]];then
                sudo mkdir -p -v ${path}/{html,log}
                elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ];then
                mkdir -p -v ${path}/{html,log}
            fi
        fi
    fi
}

# 将配置写到文件中
function create_file() {
    if [[ -n "$1" ]]; then
        echo "4、删除文件[${path}]，不执行操作"
    else
        if [ -z "$container_exist" ]; then
            file_name="${path}/nginx.conf"
            if [[ -f ${file_name} ]]; then
                echo "4、文件已存在["${file_name}"]"
            else
                echo "4、拷贝 nginx.conf 到指定目录[${path}]，执行命令：sudo docker cp $(docker ps -a | grep ${image_alias} |awk '{print $1}'):/etc/nginx/nginx.conf ${path}"
                sudo docker cp $(docker ps -a | grep ${image_alias} |awk '{print $1}'):/etc/nginx/nginx.conf ${path}
            fi
        fi
    fi
    echo "4.1、对目录授权[${path}]"
    current_group=`groups ${current_name} | awk '{print $1}'`
    sudo chown -R ${current_name}:${current_group} ${path}
}

function reset_container(){
    if [[ -n "$1" ]]; then
        echo "5、删除容器[${image_name}]，该操作用于环境调试"
        docker stop ${image_alias} && docker rm ${image_alias}
        echo "5.1、删除容器[${image_name}]，删除成功" && exit 1
    else
        # 判断应用是否存在，不存在则执行初始化脚本
        if [ -z "${container_exist}" ]; then
            echo "5、删除旧容器[${image_name}]创建新容器"
            exe_status=`docker stop ${image_alias} && docker rm -f ${image_alias}`
            if [[ -n "${exe_status}" ]]; then
                echo "5.1、重新初始化容器[${image_name}]，执行命令：docker run -d -p 80:80 -d --restart=always -v ${path}/html:/usr/share/nginx/html -v ${path}/log:/var/log/nginx -v ${path}/nginx.conf:/etc/nginx/nginx.conf --name ${image_alias} ${image_name}"
                docker run -d -p 80:80 -d --restart=always \
                -v ${path}/html:/usr/share/nginx/html \
                -v ${path}/log:/var/log/nginx \
                -v ${path}/nginx.conf:/etc/nginx/nginx.conf \
                --name ${image_alias} ${image_name}
            fi
        fi
    fi
}

function checkt_container_status (){
    echo "6、查看容器[${image_name}]状态，执行命令：docker inspect --format='{{.State.Status}}' ${image_alias}"
    status=$(docker inspect --format='{{.State.Status}}' ${image_alias})
    if [ "${status}" == "running" ]; then
        echo "7、查看容器[${image_name}]状态：[${status}]"
        elif [ "${status}" == "exited" ]; then
        echo "7、查看容器[${image_name}]状态：[${status}]，启动命令：docker start ${image_alias}"
        docker start ${image_alias}
    else
        echo "7、查看容器[${image_name}]状态：[${status}]，存在异常"
        exit 1 #强制退出，不执行后续步骤
    fi
    
    echo "8、查看容器[${image_name}]详情，执行命令：docker ps | grep ${image_name}"
    docker ps | grep ${image_name}
}

echo "---------------函数开始执行---------------"
get_os_path
check_image $1 $2
check_container $1
create_foler $1
create_file
reset_container $1
checkt_container_status
echo "---------------函数执行完毕---------------"