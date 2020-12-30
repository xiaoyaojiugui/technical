#!/bin/bash
#$0 是脚本本身的名字
#$1 是传递给该shell脚本的第一个参数，即删除容器的判断依据
#$2 是传递给该shell脚本的第二个参数，即镜像容器的判断依据

image_name="microsoft/mssql-server-linux:2017-latest"
image_alias="mssql"
container_exist=$(docker ps -a | grep $image_name)
sub_image_name=${image_name%:*}
path=/data/docker/volumes/${image_alias}
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
        mkdir_mssql_folder
        echo "3、检查容器[${image_name}]不存在，初始化命令：docker run -p 3306:3306 --privileged=true -e MYSQL_ROOT_PASSWORD=root -v=/data/docker/volumes/mssql/data/:/var/opt/mssql/data/ -v=/data/docker/volumes/mssql/log:/var/opt/mssql/log/ --name ${image_alias} -d ${image_name}"
        # 其中ACCEPT_EULA=Y的意思是同意许可协议，必选；
        # MSSQL_SA_PASSWORD为密码，要求是最少8位的强密码，要有大写字母，小写字母，数字以及特殊符号，不然会有一个大坑（docker启动sqlserver容器后过几秒就停止了）；
        docker run -p 1433:1433 -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=1qaz@WSX' --name ${image_alias} -d ${image_name}
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
    echo "4、查看容器[${image_name}]状态，执行命令：docker inspect $image_alias | jq -r '.[].State.Status'"
    status=$(docker inspect $image_alias | jq -r '.[].State.Status')

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

function mkdir_mssql_folder() {
    #这里的-d 参数判断$path是否存在 
    if [ ! -d $path ];then
        echo "2、创建文件夹，执行命令：sudo mkdir -p -v $path/{data,log} && sudo chown -R $current_name $path/{data,log}"
        sudo mkdir -p -v $path/{data,log} && sudo chown -R $current_name $path/{data,log} 
    else
        echo "2、文件夹["${path}"]已经存在"
    fi
}

function end_execution(){
    # 登入容器
        docker exec -it mssql /bin/bash
    # 连接到sqlcmd
        /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P '1qaz@WSX'
    # 执行SQL语句创建数据库
        CREATE DATABASE InsightImport
        select name from sys.databases
        go
}

echo "---------------函数开始执行---------------"
check_image $1 $2
check_container $1
checkt_container_status
echo "---------------函数执行完毕---------------"