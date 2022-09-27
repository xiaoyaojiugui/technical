#!/bin/bash
#$0 是脚本本身的名字
#$1 是传递给该shell脚本的第一个参数，即删除容器的判断依据
#$2 是传递给该shell脚本的第二个参数，即镜像容器的判断依据

function init_environment_variable() {
    # .[空格]./子脚本，此时，相当于函数中的内联函数(inline)的概念，子脚本中的内容会在此处通通展开，此时相当于在一个shell环境中执行所有的脚本内容，所以，此时父子脚本中任何变量都可以共享（注意定义变量的顺序，在使用前声明）。【一个进程】
    . ./env-variable.sh
}

function check_image() {
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$2" ] && [ -n "$1" ]; then
        echo "1.1、执行镜像删除操作，删除镜像[$image_name]，该操作用于环境调试"
        docker stop $image_alias && docker rm $image_alias && docker rmi $image_name && exit 1
    elif [ -n "$1" ]; then
        echo "1.1、执行容器删除操作，跳过此步骤，删除原镜像[$image_name]"
    else
        sub_image_name=${image_name%:*}
        # 准确查找镜像是否已经存在
        image_exist=$(docker images --all | grep -w ^$sub_image_name)
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
        echo "1.2、执行创建容器操作，创建目录并授权，执行命令：sudo mkdir -p -v $os_path/{data,logs,conf} && sudo chown -R $current_name $os_path "
        if [ "$(uname)" == "Darwin" ] || [ "$(expr substr $(uname -s) 1 10)" == "Linux" ]; then
            # sudo chmod -R 755 nexus-data
            sudo mkdir -p -v $os_path/{data,logs,conf} && sudo chown -R $current_name $os_path
        elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
            mkdir -p -v $os_path/{data,logs,conf}
        fi
    fi
}

# 将配置写到文件中
function create_file() {
    # 这里的参数（-n）是判断脚本的传递的第一个参数（"$1"）已存在
    if [ -n "$1" ]; then # 删除操作跳过此步骤
        echo "1.3、执行容器删除操作，跳过此步骤，创建文件[my.conf]"
        return 0
    fi

    if [ -z "$container_exist" ]; then
        file_name="$os_path/conf/my.cnf"
        if [ -f $file_name ]; then
            echo "1.3、执行创建容器操作，文件已存在["$file_name"]"
        else
            touch $file_name
            echo "1.3、执行创建容器操作，创建文件my.cnf并将配置写到文件中["$file_name"]"
            cat >$file_name <<EOF
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
            cat $file_name
        fi
    fi
}

function initialize_container_for_the_first_time() {
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$1" ]; then
        echo "1.4、执行容器删除操作，跳过此步骤，第一次初始化容器[$image_alias]"
    else
        # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
        if [ -n "$container_exist" ]; then
            echo "1.4、执行创建容器操作，跳过此步骤，容器已存在[$image_alias]"
        else
            # --restart=always
            echo "1.4、执行创建容器操作，执行命令：docker run -d -p $mysql_port:3306 -d --restart=always --privileged=true -e MYSQL_ROOT_PASSWORD=$password -v $os_path/conf/:/etc/mysql/conf.d/ -v $os_path/data:/var/lib/mysql -v $os_path/logs:/var/log/mysql --name $image_alias $image_name"
            docker run -d -p $mysql_port:3306 -d --restart=always --privileged=true -e MYSQL_ROOT_PASSWORD=$password \
                -v $os_path/conf/:/etc/mysql/conf.d/ \
                -v $os_path/data:/var/lib/mysql \
                -v $os_path/logs:/var/log/mysql \
                --name $image_alias $image_name

            # -v /etc/localtime:/etc/localtime \
            # 检验容器是否成功启动，二次赋值
            container_exist=$(docker ps -a | grep $image_name)
        fi
    fi
}

function check_container_status() {
    if [ -n "$1" ]; then
        echo "1.5、执行容器删除操作，跳过此步骤，检查容器状态"
        return 0
    fi
    if [ -n "$container_exist" ]; then
        echo "1.5.1、查看容器状态，执行命令：docker inspect --format='{{.State.Status}}' $image_alias"
        container_status=$(docker inspect --format='{{.State.Status}}' $image_alias)
        if [ "$container_status" == "running" ]; then
            echo "1.5.2、查看容器状态，[$container_status]"
        elif [ "$container_status" == "exited" ]; then
            echo "1.5.2、查看容器状态，[$container_status]，启动命令：docker start $image_alias"
            docker start $image_alias
        else
            echo "1.5.2、查看容器状态，[$container_status]，存在异常"
            exit 1 #强制退出，不执行后续步骤
        fi

        echo "1.5.3、查看容器详情，执行命令：docker ps | grep $image_name"
        docker ps | grep $image_name
    fi
}

function delete_container() {
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$1" ]; then
        # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
        if [ -z "$container_exist" ]; then
            echo "1.6、执行容器删除操作，跳过此步骤，容器已删除[$image_alias]"
        else
            echo "1.6.1、执行容器删除操作，执行命令：docker stop $image_alias && docker rm $image_alias"
            docker stop $image_alias && docker rm -f $image_alias
            echo "1.6.2、执行容器删除操作，成功删除容器[$image_alias]"
        fi
    fi
}

function delete_folder() {
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$1" ]; then
        if [ -d "$os_path" ] && [ "$1" == "delete" ]; then
            echo "1.7.1、执行容器删除操作，删除文件夹，执行命令：sudo rm -rf $os_path"
            sudo rm -rf $os_path
            echo "1.7.2、执行容器删除操作，成功删除文件夹[$os_path]"
        else
            echo "1.7、执行容器删除操作，跳过此步骤，删除文件夹[$os_path]"
        fi
    fi
}


function after_excute() {
    if [ -n "$1" ]; then
        return 0
    fi
    echo ""
    echo "2.1、其他待执行命令，登录容器其命令为：docker exec -it $image_alias mysql -uroot -proot"
    # find . -name \* -type f -print | xargs grep "mysql"
}

echo "---------------函数开始执行---------------"
init_environment_variable
check_image $1 $2
create_folder $1
create_file $1
initialize_container_for_the_first_time $1
check_container_status $1
delete_container $1
delete_folder $1
after_excute $1
echo "---------------函数执行完毕---------------"
