#!/bin/bash
#$0 是脚本本身的名字
#$1 是传递给该shell脚本的第一个参数，即删除容器的判断依据
#$2 是传递给该shell脚本的第二个参数，即镜像容器的判断依据

basepath=$(
    cd $(dirname $0)
    pwd
)
current_name="${USER}"
image_name="puckel/docker-airflow:latest"
image_alias="airflow"
mysql_image_alias="mysql"
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
    elif [[ -n "$1" ]] && [[ "$1" != "init" ]]; then
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
    if [[ -n "$1" ]] && [[ "$1" != "init" ]]; then # 删除操作跳过此步骤
        return 0
    fi
    # 这里的参数（-d）是判断外挂的容器路径（"${path}"）已存在
    if [ -d "${path}" ]; then
        echo "2、文件夹已存在[${path}]，不执行操作"
    else
        echo "2.1、创建文件夹，执行命令：sudo mkdir -p -v ${path}/{dags,logs,conf} "
        echo "2.2、授权文件夹，执行命令：sudo chown -R ${current_name} ${path}/{dags,logs,conf} "
        if [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 10)" == "Linux" ]]; then
            sudo mkdir -p -v ${path}/{dags,logs,conf} &&
                sudo chown -R ${current_name} ${path}/{dags,logs,conf}
        elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
            mkdir -p -v ${path}/{dags,logs,conf}
        fi
    fi
}

function check_container() {
    # 这里的参数（-n）是判断脚本的传递的第一个参数（"$1"）已存在
    if [[ -n "$1" ]] && [[ "$1" != "init" ]]; then
        # 这里的参数（-n）是判断容器（"${container_exist}"）已存在
        if [[ -n "${container_exist}" ]]; then
            echo "2、删除容器[${image_alias}]，执行命令：docker stop ${image_alias} && docker rm ${image_alias}"
            docker stop ${image_alias} && docker rm -f ${image_alias}
            echo "3、成功删除容器[${image_alias}]"
        else
            echo "2、容器不存在[${image_alias}]，不执行操作"
        fi
    else
        # 这里的参数（-z）是判断容器是否存在，不存在则执行初始化脚本
        if [[ -z "${container_exist}" ]]; then
            echo "3、检查容器[${image_alias}]不存在，执行命令：docker run -p 9090:8080 --privileged=true --name ${image_alias} -d ${image_name}"
            docker run -p 9090:8080 --privileged=true --name ${image_alias} -d ${image_name}
        else
            echo "3、容器已存在[${image_alias}]，不执行操作"
        fi
    fi
}

# 将配置写到文件中
function copy_file() {
    # 这里的参数（-n）是判断脚本的传递的第一个参数（"$1"）已存在
    if [[ -n "$1" ]] && [[ "$1" != "init" ]]; then # 删除操作跳过此步骤
        return 0
    fi

    if [[ -z "${container_exist}" ]]; then
        echo "4.1、拷贝配置文件[airflow.cfg]到本地，执行命令：sudo docker cp $(docker ps -a | grep ${image_alias} | awk '{print $1}'):/usr/local/airflow/airflow.cfg ${path}/conf"
        docker cp $(docker ps -a | grep ${image_alias} | awk '{print $1}'):/usr/local/airflow/airflow.cfg ${path}/conf

        airflow_cfg=${path}/conf/airflow.cfg
        echo "4.2、查看docker中mysql的IP地址，执行命令：docker inspect ${mysql_image_alias} --format='{{.NetworkSettings.IPAddress}}'"
        ip_address=$(docker inspect ${mysql_image_alias} --format='{{.NetworkSettings.IPAddress}}')
        echo "4.3、查看docker中mysql的IP地址：[${ip_address}]"

        #replace_path=${path//\//\\\/}
        echo "4.4、修改配置文件[airflow.cfg]"
        if [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 10)" == "Linux" ]]; then
            sed -i \'\' 's/executor = SequentialExecutor/executor = LocalExecutor/g' ${airflow_cfg}
            sed -i \'\' 's/\# sql_alchemy_conn = sqlite:\/\/\/\/tmp\/airflow.db/sql_alchemy_conn = mysql:\/\/airflow:airflow\'@${ip_address}':3306\/airflow/g' ${airflow_cfg}

            sudo rm -rf "${path}/conf/airflow.cfg\"\""
        elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
            sed -i 's/executor = SequentialExecutor/executor = LocalExecutor/g' ${airflow_cfg}
            sed -i 's/\# sql_alchemy_conn = sqlite:\/\/\/\/tmp\/airflow.db/sql_alchemy_conn = mysql:\/\/airflow:airflow\'@${ip_address}':3306\/airflow/g' ${airflow_cfg}
        fi

        echo "4.5、查看配置文件[airflow.cfg]，修改是否成功"
        cat ${airflow_cfg} | grep 'executor ='
        cat ${airflow_cfg} | grep 'sql_alchemy_conn'

        echo "4.6、拷贝airflow的[example_dags]用例，执行命令：sudo docker cp $(docker ps -a | grep ${image_alias} | awk '{print $1}'):/usr/local/lib/python3.7/site-packages/airflow/example_dags ${path}/dags"
        docker cp $(docker ps -a | grep ${image_alias} | awk '{print $1}'):/usr/local/lib/python3.7/site-packages/airflow/example_dags ${path}/dags
    fi
}

function reset_container() {
    # 这里的参数（-n）是判断脚本的传递的第一个参数（"$1"）已存在
    if [[ -n "$1" ]] && [[ "$1" != "init" ]]; then # 删除操作跳过此步骤
        return 0
    fi
    # 判断应用是否存在，不存在则执行初始化脚本
    if [[ -z "$container_exist" ]]; then
        copy_file $1

        echo "5.1、删除容器中....[${image_alias}]"
        docker stop ${image_alias} && docker rm ${image_alias}
        echo "5.2、成功删除容器[${image_alias}]"

        echo "6、重新初始化容器[${image_alias}]，初始化命令：docker run -p 9090:8080 --privileged=true -v ${path}/conf/airflow.cfg:/usr/local/airflow/airflow.cfg -v ${path}/dags:/usr/local/airflow/dags -v ${path}/logs:/usr/local/airflow/logs --name ${image_alias} -d ${image_name}"
        docker run -p 9090:8080 --privileged=true \
            -v ${path}/conf/airflow.cfg:/usr/local/airflow/airflow.cfg \
            -v ${path}/dags:/usr/local/airflow/dags \
            -v ${path}/logs:/usr/local/airflow/logs \
            --name ${image_alias} -d ${image_name}
    fi
}

function checkt_container_status() {
    # 这里的参数（-n）是判断脚本的传递的第一个参数（"$1"）已存在
    if [[ -n "$1" ]] && [[ "$1" != "init" ]]; then # 删除操作跳过此步骤
        return 0
    fi

    echo "7、查看容器状态[${image_alias}]，执行命令：docker inspect --format='{{.State.Status}}' ${image_alias}"
    status=$(docker inspect --format='{{.State.Status}}' ${image_alias})
    if [ "${status}" == "running" ]; then
        echo "8、查看容器状态[${image_alias}]：[${status}]"
    elif [ "${status}" == "exited" ]; then
        echo "8、查看容器状态[${image_alias}]：[${status}]，启动命令：docker start ${image_alias}"
        docker start ${image_alias}
    else
        echo "8、查看容器状态[${image_alias}]：[${status}]，存在异常"
        exit 1 #强制退出，不执行后续步骤
    fi

    echo "10、查看容器详情[${image_alias}]，执行命令：docker ps | grep ${image_alias}"
    docker ps | grep ${image_alias}
}

function delete_folder() {
    # 这里的参数（-n）是判断脚本的传递的第一个参数（"$1"）已存在
    if [[ -n "$1" ]] && [[ "$1" != "init" ]]; then
        if [[ -d "${path}" ]]; then
            echo "4、删除文件夹，执行命令：sudo rm -rf ${path}"
            if [[ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 10)" == "Linux" ]]; then
                sudo rm -rf ${path}
            elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
                rm -rf ${path}
            fi
            echo "5、成功删除文件夹[${path}]" && exit 1
        else
            echo "3、文件夹不存在[${path}]，不执行操作"
        fi
    fi
}

function create_airflow_database() {
    # 删除授权（常用操作指令可不执行）
    # DROP USER 'airflow'@'$ip_address';
    # 这里的参数（-n）是判断脚本的传递的第一个参数（"$1"）已存在
    if [[ -n "$1" ]] && [[ "$1" == "init" ]]; then # 删除操作跳过此步骤
        ip_address=$(docker inspect ${mysql_image_alias} --format='{{.NetworkSettings.IPAddress}}')
        echo "11、创建 airflow 数据库，并授权docker中mysql的IP地址：${ip_address%.*}.%"
        expect ${basepath}/airflow-create-db.exp "${ip_address%.*}.%" ${mysql_image_alias}
        echo "12、第一次初始化 airflow 数据库，执行时会百分百会失败，为了获取：AIRFLOW__CORE__FERNET_KEY"
        docker exec -it ${image_alias} airflow initdb

        airflow_key=$(docker exec -it ${image_alias} python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())')
        echo "13、第二次初始化 airflow 数据库"
        expect ${basepath}/airflow-init-db.exp ${image_alias} ${airflow_key}
    fi
}

echo "---------------函数开始执行---------------"
get_os_path
check_image $1 $2
create_folder $1
check_container $1
reset_container $1
delete_folder $1
checkt_container_status $1
create_airflow_database $1

echo "---------------函数执行完毕---------------"
