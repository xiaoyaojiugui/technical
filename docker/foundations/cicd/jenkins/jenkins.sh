#!/bin/bash
#$0 是脚本本身的名字
#$1 是传递给该shell脚本的第一个参数，即删除容器的判断依据
#$2 是传递给该shell脚本的第二个参数，即删除镜像的判断依据

function init_environment_variable() {
    # .[空格]./子脚本，此时，相当于函数中的内联函数(inline)的概念，子脚本中的内容会在此处通通展开，此时相当于在一个shell环境中执行所有的脚本内容，所以，此时父子脚本中任何变量都可以共享（注意定义变量的顺序，在使用前声明）。【一个进程】
    . ./env-variable.sh
}

function check_system_software() {
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$1" ]; then
        echo "1.1、执行容器删除操作，跳过此步骤，检查必要软件"
        return 0
    fi

    # 这里的参数（-d）是判断目录是否存在
    if [ ! -d "$software_path" ]; then
        echo "1.1、检查必要软件不存在，请执行脚本：sh ./download.sh"
        sh ./download.sh
    else
        oracle_jdk_exist=$(find $software_path -name $oracle_jdk_filename)
        maven_exist=$(find $software_path -name $maven_filename)
        jenkins_war_exist=$(find ./software -maxdepth 1 -type f | sed 's@^./@@' | grep $jenkins_war_filename)
        # 这里的参数（-d）是判断目录是否存在
        if [ -d "$oracle_jdk_exist" ] && [ -d "$maven_exist" ] && [ -f "$jenkins_war_exist" ]; then
            echo "1.1、检查必要软件，跳过此步骤，目录已存在[$oracle_jdk_exist]"
            echo "1.2、检查必要软件，跳过此步骤，目录已存在[$maven_exist]"
            echo "1.3、检查必要软件，跳过此步骤，文件已存在[$software_download_path/$jenkins_war_filename]"
            echo ""
        else
            echo "1.1、检查必要软件不存在，请执行脚本：sh ./download.sh"
            sh ./download.sh
        fi
    fi
}

function check_image() {
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$2" ] && [ -n "$1" ]; then
        echo "2.1、执行镜像删除操作，删除镜像[$image_name]，该操作用于环境调试"
        docker stop $image_alias && docker rm $image_alias && docker rmi $image_name && exit 1
    elif [ -n "$1" ]; then
        echo "2.1、执行容器删除操作，跳过此步骤，删除原镜像[$image_name]"
    else
        sub_image_name=${image_name%:*}
        image_exist=$(docker images --all | grep -w ^$sub_image_name)
        if [ -z "$image_exist" ]; then
            echo "2.1、执行创建容器操作，检查镜像[$image_exist]不存在，执行命令：docker pull $image_name"
            docker pull $image_name
        else
            echo "2.1、执行创建容器操作，跳过此步骤，镜像已存在[$image_name]"
        fi
    fi
}

function create_folder() {
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$1" ]; then
        echo "2.2、执行容器删除操作，跳过此步骤，创建目录[$os_path]"
        return 0
    fi
    # 这里的参数（-d）是判断目录是否存在
    if [ -d "$os_path" ]; then
        echo "2.2、执行创建容器操作，跳过此步骤，目录已存在[$os_path]"
    else
        echo "2.2、执行创建容器操作，创建目录并授权，执行命令：sudo mkdir -p -v $os_path/{jenkins-home,conf} && sudo chown -R $current_name $os_path "
        if [ "$(uname)" == "Darwin" ] || [ "$(expr substr $(uname -s) 1 10)" == "Linux" ]; then
            # sudo chmod -R 755 jenkins-home
            sudo mkdir -p -v $os_path/{jenkins-home,conf} && sudo chown -R $current_name $os_path
        elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
            mkdir -p -v $os_path/{jenkins-home,conf}
        fi
    fi
}

function initialize_container_for_the_first_time() {
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$1" ]; then
        echo "2.3、执行容器删除操作，跳过此步骤，第一次初始化容器[$image_alias]"
    else
        # 这里的参数（-z）判断字符串的长度为0时为真(空串) ，不存在则执行初始化脚本
        if [ -z "$container_exist" ]; then
            echo "2.3、执行创建容器操作，执行命令：docker run -d -p 39090:8080 -p 50000:50000 -v $os_path/jenkins-home:/var/jenkins_home --name $image_alias $image_name"
            docker run -d -p 39090:8080 -p 50000:50000 \
                --privileged=true \
                -v $os_path/jenkins-home:/var/jenkins_home \
                --name $image_alias $image_name
            # 检验容器是否成功启动，二次赋值
            container_exist=$(docker ps -a | grep $image_name)
        else
            echo "2.3、执行创建容器操作，跳过此步骤，容器已存在[$image_alias]"
        fi
    fi
}

function sleep_exec_next_method() {
    start_num=1
    end_num=10
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$1" ]; then # 删除操作跳过此步骤
        echo "2.4、执行容器删除操作，跳过此步骤，休眠 $end_num 秒"
        return 0
    fi

    update_center_file=$os_path/jenkins-home/hudson.model.UpdateCenter.xml
    # 这里的参数（-e）是判断文件是否存在
    if [ -e "$update_center_file" ]; then
        echo "2.4、执行创建容器操作，跳过此步骤，休眠 $end_num 秒"
        return 0
    fi

    echo "2.4.1、执行创建容器操作，根据服务器性能调整时间，默认休息 $end_num 秒，--> $(date) <--"
    while (($start_num <= $end_num)); do
        ((start_num++))
        sleep 1
    done
    echo "2.4.2、执行创建容器操作，根据服务器性能调整时间，默认休息 $end_num 秒，--> $(date) <--"
}

function copy_file() {
    # 这里的参数（-z）判断字符串的长度为0时为真(空串)
    if [ -n "$1" ] || [ -z "$container_exist" ]; then # 删除操作跳过此步骤
        echo "2.5、执行容器删除操作，跳过此步骤，修改配置文件"
        return 0
    fi

    update_center=$os_path/jenkins-home/hudson.model.UpdateCenter.xml
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$container_exist" ]; then
        #replace_path=${path//\//\\\/}
        # 这里的参数（-e）是判断文件是否存在
        if [ -e "$update_center" ]; then
            filter_update_center=$(cat $update_center | grep 'tsinghua')
            # 这里的参数（-z）判断字符串的长度为0时为真(空串)
            if [ -z "$filter_update_center" ]; then
                echo "2.5.1、执行创建容器操作，修改配置文件[$update_center]"
                if [ "$(uname)" == "Darwin" ]; then
                    sed -i "" 's/https:\/\/updates.jenkins.io\/update-center.json/https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins\/updates\/update-center.json/g' $update_center
                elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ] || [ "$(expr substr $(uname -s) 1 10)" == "Linux" ]; then
                    sed -i 's/https:\/\/updates.jenkins.io\/update-center.json/https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins\/updates\/update-center.json/g' $update_center
                fi
                echo "2.5.2、执行创建容器操作，查看配置文件，执行命令：cat $update_center | grep 'url'"
                cat $update_center | grep 'url'
            else
                echo "2.5.1、执行创建容器操作，跳过此步骤，文件已修改[$update_center]"
            fi
        fi

        update_default=$os_path/jenkins-home/updates/default.json
        # 这里的参数（-e）是判断文件是否存在
        if [ ! -e "$update_default" ]; then
            echo ""
            echo "2.5.3、执行创建容器操作，修改配置文件[$update_default]"
            if [ "$(uname)" == "Darwin" ]; then
                echo "sed -i \"\" 's/https:\/\/updates.jenkins.io\/download/https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins/g' $update_default && sed -i \"\" 's/https:\/\/www.google.com/https:\/\/www.baidu.com/g' $update_default"
            elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ] || [ "$(expr substr $(uname -s) 1 10)" == "Linux" ]; then
                echo "sed -i 's/https:\/\/updates.jenkins.io\/download/https:\/\/mirrors.tuna.tsinghua.edu.cn\/jenkins/g' $update_default && sed -i 's/https:\/\/www.google.com/https:\/\/www.baidu.com/g' $update_default"
            fi
            echo ""
        fi

        # 这里的参数（-d）是判断目录是否存在
        conf_path=$os_path/conf
        if [ -d "$conf_path" ]; then
            etc_profile=$conf_path/profile
            # 这里的参数（-e）是判断文件是否存在
            if [ -e "$etc_profile" ]; then
                filter_etc_profile=$(cat $etc_profile | grep $oracle_jdk_filename)
                # 这里的参数（-z）判断字符串的长度为0时为真(空串)
                if [ -z "$filter_etc_profile" ]; then
                    echo "2.5.4、执行创建容器操作，配置环境变量[/etc/profile]"
                    write_etc_profile
                else
                    echo "2.5.4、执行创建容器操作，跳过此步骤，文件已修改[$etc_profile]"
                fi
            else
                echo "2.5.5、执行创建容器操作，拷贝配置[/etc/profile]到本地并配置环境变量，执行命令：sudo docker cp \$(docker ps -a | grep $image_alias | awk '{print \$1}'):/etc/profile $conf_path/"
                sudo docker cp $(docker ps -a | grep $image_alias | awk '{print $1}'):/etc/profile $conf_path/
                sudo chmod -R 666 $etc_profile && write_etc_profile && source_etc_profile
            fi
        fi
    fi
}

function write_etc_profile() {
    cat >>$os_path/conf/profile <<EOF
    
# 配置maven安装目录，用which mvn查看
export M2_HOME=/usr/local/apps/$maven_filename

# 配置java_home所在的目录，注意这个目录下应该有bin文件夹，bin下应该有java等命令
#设置默认的JDK版本
export JAVA_HOME=/usr/local/apps/$oracle_jdk_filename
# 配置CLASSPATH所在的目录
export CLASSPAHT=.:\$JAVA_HOME/lib/dt.jar:\$JAVA_HOME/lib/tools.jar

# 将环境变量加到PATH变量中
export PATH=\$PATH:\$JAVA_HOME/bin:\$M2_HOME/bin
EOF
}

function source_etc_profile() {
    sudo touch $os_path/conf/.bashrc && sudo chmod -R 666 $os_path/conf/.bashrc
    cat >$os_path/conf/.bashrc <<EOF
# 生效环境变量
source /etc/profile
EOF
}

function delete_container() {
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$1" ]; then
        # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
        if [ -n "$container_exist" ]; then
            echo "2.6、执行容器删除操作，执行命令：docker stop $image_alias && docker rm $image_alias"
            docker stop $image_alias && docker rm -f $image_alias
            echo "2.6、执行容器删除操作，成功删除容器[$image_alias]"
        else
            echo "2.6、执行容器删除操作，跳过此步骤，容器已删除[$image_alias]"
        fi
    fi
}

function initialize_container_for_the_last_time() {
    if [ -n "$1" ]; then
        echo "2.7、执行容器删除操作，跳过此步骤，第二次初始化容器[$image_alias]"
        return 0
    fi
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    # 这里的参数（-z）判断字符串的长度为0时为真(空串)
    create_container_success=$(docker inspect --format='{{.HostConfig.Binds}}' $image_alias | grep $maven_filename)
    if [ -n "$container_exist" ] && [ -z "$create_container_success" ]; then
        container_stop_status=$(docker stop $image_alias && docker rm -f $image_alias)
        if [ -n "$container_stop_status" ]; then
            echo "2.6.1、执行重建容器操作，其容器为[$image_name]，执行命令： docker run -d -p 39090:8080 -p 50000:50000 --privileged=true -v $(which docker):/usr/bin/docker -v /var/run/docker.sock:/var/run/docker.sock -v $os_path/jenkins-home:/var/jenkins_home -v $os_path/conf/profile:/etc/profile -v $os_path/conf/.bashrc:/root/.bashrc -v $software_path/$maven_filename:/usr/local/apps/$maven_filename -v $software_path/$oracle_jdk_filename:/usr/local/apps/$oracle_jdk_filename --name $image_alias $image_name"
            docker run -d -p 39090:8080 -p 50000:50000 \
                --privileged=true \
                -v $(which docker):/usr/bin/docker \
                -v /var/run/docker.sock:/var/run/docker.sock \
                -v $os_path/jenkins-home:/var/jenkins_home \
                -v $os_path/conf/profile:/etc/profile \
                -v $os_path/conf/.bashrc:/root/.bashrc \
                -v $software_path/$maven_filename:/usr/local/apps/$maven_filename \
                -v $software_path/$oracle_jdk_filename:/usr/local/apps/$oracle_jdk_filename \
                --name $image_alias $image_name
        fi

        jenkins_war_exist=$(find ./software -maxdepth 1 -type f | sed 's@^./@@' | grep $jenkins_war_filename)
        # 这里的参数（-f）判断是否为文件
        if [ -f "$jenkins_war_exist" ]; then
            echo "2.6.2、复制Jenkins的最新war包到指定目录，执行命令：docker cp ./software/jenkins.war \$(docker ps -a | grep $image_alias | awk '{print \$1}'):/usr/share/jenkins/jenkins.war"
            docker cp ./software/jenkins.war $(docker ps -a | grep $image_alias | awk '{print $1}'):/usr/share/jenkins/jenkins.war
        fi
    fi
}

function check_container_status() {
    if [ -n "$1" ]; then
        echo "2.8、执行容器删除操作，跳过此步骤，检查容器状态"
        return 0
    fi
    if [ -n "$container_exist" ]; then
        echo "2.7.1、查看容器状态，执行命令：docker inspect --format='{{.State.Status}}' $image_alias"
        container_status=$(docker inspect --format='{{.State.Status}}' $image_alias)
        if [ "$container_status" == "running" ]; then
            echo "2.7.2、查看容器状态，[$container_status]"
        elif [ "$container_status" == "exited" ]; then
            echo "2.7.2、查看容器状态，[$container_status]，启动命令：docker start $image_alias"
            docker start $image_alias
        else
            echo "2.7.2、查看容器状态，[$container_status]，存在异常"
            exit 1 #强制退出，不执行后续步骤
        fi

        echo "2.7.3、查看容器详情，执行命令：docker ps | grep $image_name"
        docker ps | grep $image_name
    fi
}

function delete_folder() {
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$1" ]; then
        if [ -d "$os_path" ] && [ "$1" == "delete" ]; then
            echo "2.9.1、执行容器删除操作，删除文件夹，执行命令：sudo rm -rf $os_path"
            sudo rm -rf $os_path
            echo "2.9.2、执行容器删除操作，成功删除文件夹[$os_path]"
        else
            echo "2.9、执行容器删除操作，跳过此步骤，删除文件夹[$os_path]"
        fi
    fi
}

function after_excute() {
    if [ -n "$1" ]; then
        return 0
    fi
    echo ""
    echo "3.1、其他待执行命令，登录容器其命令为：docker exec -it -u root $image_alias /bin/bash"
    echo "3.2、其他待执行命令，复制最新war包其命令为：docker cp ./jenkins.war \$(docker ps -a | grep $image_alias | awk '{print \$1}'):/usr/share/jenkins/jenkins.war"
    # find . -name \* -type f -print | xargs grep "jdk-17"
}

echo "---------------函数开始执行---------------"
init_environment_variable
check_system_software $1
check_image $1 $2
create_folder $1
initialize_container_for_the_first_time $1
sleep_exec_next_method $1
copy_file $1
delete_container $1
initialize_container_for_the_last_time $1
check_container_status $1
# delete_folder $1
after_excute $1
echo "---------------函数执行完毕---------------"
