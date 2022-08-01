#!/bin/bash
#$0 是脚本本身的名字
#$1 是传递给该shell脚本的第一个参数，即删除容器的判断依据
#$2 是传递给该shell脚本的第二个参数，即镜像容器的判断依据

current_name="${USER}"
image_name="jenkins/jenkins:latest"
image_alias="jenkins"
container_exist=$(docker ps -a | grep ${image_name})
sub_image_name=${image_name%:*}
# 准确查找镜像是否已经存在
image_exist=$(docker images --all | grep -w ^$sub_image_name)·

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
        echo "1、执行镜像删除操作，删除镜像[${image_name}]，该操作用于环境调试"
        docker stop ${image_alias} && docker rm ${image_alias} && docker rmi ${image_name} && exit 1
    elif [[ -n "$1" ]]; then
        echo "1、执行容器删除操作，跳过此步骤，删除原镜像[${image_name}]"
    else
        if [ -z "${image_exist}" ]; then
            echo "1、执行创建容器操作，检查镜像[${image_exist}]不存在，执行命令：docker pull ${image_name}"
            docker pull ${image_name}
        else
            echo "1、执行创建容器操作，跳过此步骤，镜像已存在[${image_name}]"
        fi
    fi
}

function create_folder() {
    # 这里的参数（-n）是判断脚本的传递的第一个参数（"$1"）已存在
    if [[ -n "$1" ]]; then
        echo "2、执行容器删除操作，跳过此步骤，创建文件夹[${path}]"
        return 0
    fi
    # 这里的参数（-d）是判断外挂的容器路径（"${path}"）已存在
    if [ -d "${path}" ]; then
        echo "2、执行创建容器操作，跳过此步骤，文件夹已存在[${path}]"
    else
        echo "2.1、执行创建容器操作，创建文件夹，执行命令：sudo mkdir -p -v ${path}/{jenkins-data,logs} "
        echo "2.2、执行创建容器操作，授权文件夹，执行命令：sudo chmod 777 ${current_name} ${path}/{jenkins-data,logs} "
        if [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 10)" == "Linux" ]]; then
            sudo mkdir -p -v ${path}/{jenkins-data,logs} &&
                sudo chmod 777 ${path}/{jenkins-data,logs}
        elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
            mkdir -p -v ${path}/{jenkins-data,logs}
        fi
    fi
}

function initialize_container_for_the_first_time() {
    # 这里的参数（-n）是判断脚本的传递的第一个参数（"$1"）已存在
    if [[ -n "$1" ]]; then
        echo "3、执行容器删除操作，跳过此步骤，第一次初始化容器[${image_alias}]"
    else
        # 这里的参数（-z）是判断容器是否存在，不存在则执行初始化脚本
        if [[ -z "${container_exist}" ]]; then
            echo "3、检查容器[${image_alias}]不存在，执行命令：docker run -d -p 39090:8080 -p 50000:50000 -v ${path}/jenkins-data:/var/jenkins_home --name ${image_alias} ${image_name}"
            docker run -d -p 39090:8080 -p 50000:50000 \
                --privileged=true -v ${path}/jenkins-data:/var/jenkins_home \
                --name ${image_alias} ${image_name}
        else
            echo "3、执行创建容器操作，跳过此步骤，容器已存在[${image_alias}]"
        fi
    fi
}

function sleep_exec_next_method() {
    start_num=1
    end_num=80
    # 这里的参数（-n）是判断脚本的传递的第一个参数（"$1"）已存在
    if [[ -n "$1" ]] || [[ -n "${container_exist}" ]]; then # 删除操作跳过此步骤
        echo "4、执行容器删除操作，跳过此步骤，休眠 ${end_num} 秒钟"
        return 0
    fi

    echo "4.1、执行创建容器操作，休息 ${end_num} 秒后执行其他方法，开始..."
    while ((${start_num} <= ${end_num})); do
        ((start_num++))
        sleep 1
    done
    echo "4.2、执行创建容器操作，休息 ${end_num} 秒后执行其他方法，结束..."
}

function copy_file() {
    # 这里的参数（-n）是判断脚本的传递的第一个参数（"$1"）已存在
    config=${path}/jenkins-data/hudson.model.UpdateCenter.xml
    if [[ -n "$1" ]] && [[ "$1" != "init" ]]; then # 删除操作跳过此步骤
        echo "5、执行容器删除操作，跳过此步骤，复制文件[${config}]"
        return 0
    fi

    if [[ -z "${container_exist}" ]]; then
        #replace_path=${path//\//\\\/}
        echo "5.1、执行创建容器操作，修改配置文件[${config}]"
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i \'\' 's/https:\/\/updates.jenkins.io\/update-center.json/https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins\/updates\/update-center.json/g' ${config}
        elif [[ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]] || [[ "$(expr substr $(uname -s) 1 10)" == "Linux" ]]; then
            sed -i 's/https:\/\/updates.jenkins.io\/update-center.json/https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins\/updates\/update-center.json/g' ${config}
        fi
        echo "5.2、执行创建容器操作，查看配置文件，执行命令：cat ${config} | grep 'url'"
        cat ${config} | grep 'url'
    fi
}

function delete_container() {
    # 这里的参数（-n）是判断脚本的传递的第一个参数（"$1"）已存在
    if [[ -n "$1" ]]; then
        # 这里的参数（-n）是判断容器（"${container_exist}"）已存在
        if [[ -n "${container_exist}" ]]; then
            echo "6.1、执行容器删除操作，执行命令：docker stop ${image_alias} && docker rm ${image_alias}"
            docker stop ${image_alias} && docker rm -f ${image_alias}
            echo "6.2、执行容器删除操作，成功删除容器[${image_alias}]"
        else
            echo "6、执行容器删除操作，跳过此步骤，容器已删除[${image_alias}]"
        fi
    fi
}

function initialize_container_for_the_last_time() {
    if [[ -n "$1" ]]; then
        echo "7、执行容器删除操作，跳过此步骤，第二次初始化容器[${image_alias}]"
        return 0
    fi
    # 判断应用是否存在，不存在则执行初始化脚本
    if [[ -z "${container_exist}" ]]; then
        exe_status=$(docker stop ${image_alias} && docker rm -f ${image_alias})
        if [[ -n "${exe_status}" ]]; then
            echo "5、执行重建容器操作，其容器为[${image_name}]，执行命令：docker run -d -p 39090:8080 -p 50000:50000 --restart=always -v ${path}/jenkins-data:/var/jenkins_home --name ${image_alias} ${image_name}"
            docker run -d -p 39090:8080 -p 50000:50000 \
                --privileged=true \
                -v ${path}/jenkins-data:/var/jenkins_home \
                --name ${image_alias} ${image_name}
        fi
    fi
}

function check_container_status() {
    if [[ -n "$1" ]]; then
        echo "8、执行容器删除操作，跳过此步骤，检查容器状态"
        return 0
    fi
    if [[ -n "${container_exist}" ]]; then
        echo "5.1、查看容器状态[${image_name}]，执行命令：docker inspect --format='{{.State.Status}}' ${image_alias}"
        status=$(docker inspect --format='{{.State.Status}}' ${image_alias})
        if [ "${status}" == "running" ]; then
            echo "5.2、查看容器状态[${image_name}]：[${status}]"
        elif [ "${status}" == "exited" ]; then
            echo "5.2、查看容器状态[${image_name}]：[${status}]，启动命令：docker start ${image_alias}"
            docker start ${image_alias}
        else
            echo "5.2、查看容器状态[${image_name}]：[${status}]，存在异常"
            exit 1 #强制退出，不执行后续步骤
        fi

        echo "5.3、查看容器详情[${image_name}]，执行命令：docker ps | grep ${image_name}"
        docker ps | grep ${image_name}
    fi
}

function delete_folder() {
    # 这里的参数（-n）是判断脚本的传递的第一个参数（"$1"）已存在
    if [[ -n "$1" ]]; then
        if [[ -d "${path}" ]]; then
            echo "9.1、执行容器删除操作，删除文件夹，执行命令：sudo rm -rf ${path}"
            sudo rm -rf ${path}
            echo "9.2、执行容器删除操作，成功删除文件夹[${path}]" && exit 1
        else
            echo "9、执行容器删除操作，跳过此步骤，删除文件夹[${path}]"
        fi
    fi
}

function manual_replace_mirrors(){
    sed -i 's/https:\/\/updates.jenkins.io\/download/https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins/g' default.json && sed -i 's/http:\/\/www.google.com/https:\/\/www.baidu.com/g' default.json
}

echo "---------------函数开始执行---------------"
get_os_path
check_image $1 $2
create_folder $1
initialize_container_for_the_first_time $1
sleep_exec_next_method $1
copy_file $1
delete_container $1
initialize_container_for_the_last_time $1
check_container_status $1
delete_folder $1
echo "---------------函数执行完毕---------------"
