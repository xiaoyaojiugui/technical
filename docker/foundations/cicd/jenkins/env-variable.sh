#!/bin/bash
#$0 是脚本本身的名字
#$1 是传递给该shell脚本的第一个参数，即删除容器的判断依据
#$2 是传递给该shell脚本的第二个参数，即删除镜像的判断依据

export current_name="${USER}"
export image_name="jenkins/jenkins:latest"
export image_alias="jenkins"
export container_exist=$(docker ps -a | grep $image_name)
export sub_image_name=${image_name%:*}
export image_exist=$(docker images --all | grep -w ^$sub_image_name)
export maven_filename="apache-maven-3.8.6"
export oracle_jdk_filename="jdk-17"
export jenkins_war_filename="jenkins.war"

function get_os_path() {
    if [ "$(uname)" == "Darwin" ]; then
        os_path=/Users/$current_name/data/docker/volumes/$image_alias
        app_software_path=/Users/$current_name/data/docker/apps
    elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
        os_path=d:/docker/volumes/$image_alias
        app_software_path=d:/docker/apps
    elif [ "$(expr substr $(uname -s) 1 10)" == "Linux" ]; then
        os_path=/home/$current_name/data/docker/volumes/$image_alias
        app_software_path=/home/$current_name/data/docker/apps
    fi
}
export os_path
export app_software_path

function get_software_download_path() {
    software_download_path=$(
        cd $(dirname $0)
        pwd
    )/software
}
export software_download_path

get_os_path
get_software_download_path
