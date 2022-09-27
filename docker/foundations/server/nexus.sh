#!/bin/bash
#$0 是脚本本身的名字
#$1 是传递给该shell脚本的第一个参数，即删除容器的判断依据
#$2 是传递给该shell脚本的第二个参数，即镜像容器的判断依据

current_name="${USER}"
image_name="sonatype/nexus3"
image_alias="nexus3"
container_exist=$(docker ps -a | grep $image_name)
sub_image_name=${image_name%:*}
# 准确查找镜像是否已经存在
image_exist=$(docker images --all | grep -w ^$sub_image_name)·

function get_os_path() {
    if [ "$(uname)" == "Darwin" ]; then
        os_path=/Users/$current_name/data/docker/volumes/$image_alias
    elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
        os_path=d:/docker/volumes/$image_alias
    elif [ "$(expr substr $(uname -s) 1 10)" == "Linux" ]; then
        os_path=/home/$current_name/data/docker/volumes/$image_alias
    fi
}

function check_image() {
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$2" ] && [ -n "$1" ]; then
        echo "1.1、执行镜像删除操作，删除镜像[$image_name]，该操作用于环境调试"
        docker stop $image_alias && docker rm $image_alias && docker rmi $image_name && exit 1
    elif [ -n "$1" ]; then
        echo "1.1、执行容器删除操作，跳过此步骤，删除原镜像[$image_name]"
    else
        if [ -z "$image_exist" ]; then
            echo "1.1、执行创建容器操作，检查镜像[$image_exist]不存在，执行命令：docker pull $image_name"
            docker pull $image_name
        else
            echo "1.1、执行创建容器操作，跳过此步骤，镜像已存在[$image_name]"
        fi
    fi
}

function create_folder() {
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$1" ]; then
        echo "1.2、执行容器删除操作，跳过此步骤，创建目录[$os_path]"
        return 0
    fi
    # 这里的参数（-d）是判断目录是否存在
    if [ -d "$os_path" ]; then
        echo "1.2、执行创建容器操作，跳过此步骤，目录已存在[$os_path]"
    else
        echo "1.2、执行创建容器操作，创建目录并授权，执行命令：sudo mkdir -p -v $os_path/{nexus-data,logs} && sudo chown -R $current_name $os_path "
        if [ "$(uname)" == "Darwin" ] || [ "$(expr substr $(uname -s) 1 10)" == "Linux" ]; then
            # sudo chmod -R 755 nexus-data
            sudo mkdir -p -v $os_path/{nexus-data,logs} && sudo chown -R $current_name $os_path
        elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
            mkdir -p -v $os_path/{nexus-data,logs}
        fi
    fi
}

function initialize_container_for_the_first_time() {
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$1" ]; then
        echo "1.3、执行容器删除操作，跳过此步骤，第一次初始化容器[$image_alias]"
    else
        # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
        if [ -n "$container_exist" ]; then
            echo "1.3、执行创建容器操作，跳过此步骤，容器已存在[$image_alias]"
        else
            # --restart=always
            echo "1.3、执行创建容器操作，执行命令：docker run -d -p 38081:8081 -p 38082:8082 -p 38083:8083 --platform linux/amd64 --privileged=true -e "INSTALL4J_ADD_VM_PARAMS=-Xms128m -Xmx512m -XX:MaxDirectMemorySize=512m -Djava.util.prefs.userRoot=/nexus-data/javaprefs" -v $os_path/nexus-data:/nexus-data -v /etc/timezone:/etc/timezone:ro --name $image_alias $image_name"
            docker run -d -p 38081:8081 -p 38082:8082 -p 38083:8083 \
                --platform linux/amd64 --privileged=true \
                -e "INSTALL4J_ADD_VM_PARAMS=-Xms128m -Xmx512m -XX:MaxDirectMemorySize=512m -Djava.util.prefs.userRoot=/nexus-data/javaprefs" \
                -v $os_path/nexus-data:/nexus-data \
                -v /etc/timezone:/etc/timezone:ro \
                --name $image_alias $image_name

            # 检验容器是否成功启动，二次赋值
            container_exist=$(docker ps -a | grep $image_name)
        fi
    fi
}

function check_container_status() {
    if [ -n "$1" ]; then
        echo "1.4、执行容器删除操作，跳过此步骤，检查容器状态"
        return 0
    fi
    if [ -n "$container_exist" ]; then
        echo "1.4.1、查看容器状态，执行命令：docker inspect --format='{{.State.Status}}' $image_alias"
        container_status=$(docker inspect --format='{{.State.Status}}' $image_alias)
        if [ "$container_status" == "running" ]; then
            echo "1.4.2、查看容器状态，[$container_status]"
        elif [ "$container_status" == "exited" ]; then
            echo "1.4.2、查看容器状态，[$container_status]，启动命令：docker start $image_alias"
            docker start $image_alias
        else
            echo "1.4.2、查看容器状态，[$container_status]，存在异常"
            exit 1 #强制退出，不执行后续步骤
        fi

        echo "1.4.3、查看容器详情，执行命令：docker ps | grep $image_name"
        docker ps | grep $image_name
    fi
}

function delete_container() {
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$1" ]; then
        # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
        if [ -z "$container_exist" ]; then
            echo "1.5、执行容器删除操作，跳过此步骤，容器已删除[$image_alias]"
        else
            echo "1.5.1、执行容器删除操作，执行命令：docker stop $image_alias && docker rm $image_alias"
            docker stop $image_alias && docker rm -f $image_alias
            echo "1.5.2、执行容器删除操作，成功删除容器[$image_alias]"
        fi
    fi
}

function delete_folder() {
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$1" ]; then
        if [ -d "$os_path" ] && [ "$1" == "delete" ]; then
            echo "1.6.1、执行容器删除操作，删除文件夹，执行命令：sudo rm -rf $os_path"
            sudo rm -rf $os_path
            echo "1.6.2、执行容器删除操作，成功删除文件夹[$os_path]"
        else
            echo "1.6、执行容器删除操作，跳过此步骤，删除文件夹[$os_path]"
        fi
    fi
}

echo "---------------函数开始执行---------------"
get_os_path
check_image $1 $2
create_folder $1
initialize_container_for_the_first_time $1
check_container_status $1
delete_container $1
delete_folder $1
echo "---------------函数执行完毕---------------"
