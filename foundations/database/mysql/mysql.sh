#!/bin/bash
#$0 是脚本本身的名字
#$1 是传递给该shell脚本的第一个参数，即删除容器的判断依据
#$2 是传递给该shell脚本的第二个参数，即镜像容器的判断依据

current_name="${USER}"
image_name="mysql:5.7.25"
image_alias="mysql"
container_exist=$(docker ps -a | grep ${image_name})
sub_image_name=${image_name%:*}
# 准确查找镜像是否已经存在
image_exist=$(docker images --all | grep -w ^$sub_image_name)

function get_os_path() {
    if [ "$(uname)" == "Darwin" ]; then
        path=/Users/${current_name}/data/docker/volumes/${image_alias}
    elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
        path=d:/docker/volumes/${image_alias}
    elif [ "$(expr substr $(uname -s) 1 10)" == "Linux" ]; then
        path=/home/${current_name}/data/docker/volumes/${image_alias}
    fi
}

function check_image() {
    if [[ -n "$2" && -n "$1" ]]; then
        echo "1、删除镜像[${image_name}]，该操作用于环境调试"
        docker stop ${image_alias} && docker rm ${image_alias} && docker rmi ${image_name} && exit 1
    elif [[ -n "$1" ]]; then
        echo "1、镜像已存在[${image_name}]，不执行操作"
    else
        if [ -z "${image_exist}" ]; then
            echo "1、镜像不存在[${image_exist}]，执行命令：docker pull ${image_name}"
            docker pull ${image_name}
        else
            echo "1、镜像已存在[${image_name}]，不需要拉取镜像"
        fi
    fi
}

function create_folder() {
    # 这里的参数（-n）是判断脚本的传递的第一个参数（"$1"）已存在
    if [[ -n "$1" ]]; then # 删除操作跳过此步骤
        return 0
    fi
    # 这里的参数（-d）是判断外挂的容器路径（"${path}"）已存在
    if [ -d "${path}" ]; then
        echo "2、文件夹已存在[${path}]，不执行操作"
    else
        echo "2.1、创建文件夹，执行命令：sudo mkdir -p -v ${path}/{data,logs,conf} "
        echo "2.2、授权文件夹，执行命令：sudo chown -R ${current_name} ${path}/{data,logs,conf} "
        if [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 10)" == "Linux" ]]; then
            sudo mkdir -p -v ${path}/{data,logs,conf} &&
                sudo chown -R ${current_name} ${path}/{data,logs,conf}
        elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
            mkdir -p -v ${path}/{data,logs,conf}
        fi
    fi
}

function check_container() {
    # 这里的参数（-n）是判断脚本的传递的第一个参数（"$1"）已存在
    if [[ -n "$1" ]]; then
        # 这里的参数（-n）是判断容器（"${container_exist}"）已存在
        if [[ -n "${container_exist}" ]]; then
            echo "2、删除容器[${image_alias}]，执行命令：docker stop ${image_alias} && docker rm ${image_alias}"
            docker stop ${image_alias} && docker rm -f ${image_alias}
            echo "3、成功删除容器[${image_alias}]"
        else
            echo "3、容器不存在[${image_alias}]，不执行操作"
        fi
    else
        # 这里的参数（-z）是判断容器是否存在，不存在则执行初始化脚本
        if [[ -z "${container_exist}" ]]; then
            echo "3、检查容器[${image_alias}]不存在，执行命令：docker run -d -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root --name -v ${path}/conf/:/etc/mysql/conf.d/ -v ${path}/data:/var/lib/mysql -v ${path}/logs:/var/log/mysql ${image_alias} ${image_name}"
            docker run -d -p 3306:3306 \
                -d --restart=always \
                --privileged=true -e MYSQL_ROOT_PASSWORD=root \
                -v ${path}/conf/:/etc/mysql/conf.d/ \
                -v ${path}/data:/var/lib/mysql \
                -v ${path}/logs:/var/log/mysql \
                --name ${image_alias} ${image_name}
        else
            echo "3、容器已存在[${image_alias}]，不执行操作"
        fi
    fi
}

# 将配置写到文件中
function create_file() {
    # 这里的参数（-n）是判断脚本的传递的第一个参数（"$1"）已存在
    if [[ -n "$1" ]]; then # 删除操作跳过此步骤
        return 0
    fi

    if [[ -z "${container_exist}" ]]; then
        file_name="${path}/conf/my.cnf"
        if [[ -f ${file_name} ]]; then
            echo "4、文件已存在["${file_name}"]"
        else
            touch ${file_name}
            echo "4、创建文件my.cnf并将配置写到文件中["${file_name}"]"
            cat >${file_name} <<EOF
# Default MySQL server config
[mysqld]
character-set-server = utf8
explicit_defaults_for_timestamp = 1
bulk_insert_buffer_size = 120M
explicit_defaults_for_timestamp = 1

[client]
default-character-set = utf8

[mysqldump]
max_allowed_packet = 1024M
EOF
            cat ${file_name}
        fi
    fi
}

function check_container_status() {
    # 这里的参数（-n）是判断脚本的传递的第一个参数（"$1"）已存在
    if [[ -n "$1" ]]; then # 删除操作跳过此步骤
        return 0
    fi

    echo "5、查看容器状态[${image_alias}]，执行命令：docker inspect --format='{{.State.Status}}' ${image_alias}"
    status=$(docker inspect --format='{{.State.Status}}' ${image_alias})
    if [ "${status}" == "running" ]; then
        echo "6、查看容器状态[${image_alias}]：[${status}]"
    elif [ "${status}" == "exited" ]; then
        echo "6、查看容器状态[${image_alias}]：[${status}]，启动命令：docker start ${image_alias}"
        docker start ${image_alias}
    else
        echo "6、查看容器状态[${image_alias}]：[${status}]，存在异常"
        exit 1 #强制退出，不执行后续步骤
    fi

    echo "7、查看容器详情[${image_alias}]，执行命令：docker ps | grep ${image_alias}"
    docker ps | grep ${image_alias}
}

function delete_folder() {
    # 这里的参数（-n）是判断脚本的传递的第一个参数（"$1"）已存在
    if [[ -n "$1" ]]; then
        if [[ -d "${path}" ]]; then
            echo "4、删除文件夹，执行命令：sudo rm -rf ${path}"
            sudo rm -rf ${path}
            echo "5、成功删除文件夹[${path}]" && exit 1
        else
            echo "3、文件夹不存在[${path}]，不执行操作"
        fi
    fi
}

echo "---------------函数开始执行---------------"
get_os_path
check_image $1 $2
create_folder $1
check_container $1
create_file $1
# delete_folder $1
check_container_status $1

echo "---------------函数执行完毕---------------"
