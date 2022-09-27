#!/bin/bash
#$0 是脚本本身的名字
#$1 是传递给该shell脚本的第一个参数，即删除容器的判断依据
#$2 是传递给该shell脚本的第二个参数，即删除镜像的判断依据

# 字符串染色程序
if [[ -t 1 ]]; then
    tty_escape() { printf "\033[%sm" "$1"; }
else
    tty_escape() { :; }
fi
tty_universal() { tty_escape "0;$1"; }      #正常显示
tty_mkbold() { tty_escape "1;$1"; }         #设置高亮
export tty_underline="$(tty_escape "4;39")" #下划线
export tty_blue="$(tty_universal 34)"       #蓝色
export tty_red="$(tty_universal 31)"        #红色
export tty_green="$(tty_universal 32)"      #绿色
export tty_yellow="$(tty_universal 33)"     #黄色
export tty_bold="$(tty_universal 39)"       #加黑
export tty_cyan="$(tty_universal 36)"       #青色
export tty_reset="$(tty_escape 0)"          #去除颜色

export current_name="${USER}"
export password="root123456"

function init_database_version() {
    #选择一个 mysql 版本
    echo "1.1、请选择要安装的 MySQL 版本，例如：MySQL8，输入“1” 回车。${tty_green}
1、MySQL8 (Mac with Apple chip or Intel chip)
2、MySQL8 (Linux)
3、MySQL5 (通用)"
    echo "${tty_blue}请输入序号: "
    read MY_DOWN_NUM
    echo "${tty_reset}"
    case $MY_DOWN_NUM in
    "1")
        echo "1.2、你选择了安装：MySQL8 (Mac with Apple chip or Intel chip)"
        export image_alias="mysql8"
        export image_name="mysql/mysql-server:latest"
        export mysql_port="33306"
        ;;
    "2")
        echo "1.2、你选择了安装：MySQL8 (Linux)"
        export image_alias="mysql8"
        export image_name="haakco/mysql80:20220219"
        export mysql_port="33306"
        ;;
    "3")
        echo "1.2、你选择了安装：MySQL5"
        export image_alias="mysql5"
        export image_name="mysql:5.7.25"
        export mysql_port="3306"
        ;;
    *)
        echo "${tty_red}1.2、输入有误，请重新输入${tty_reset}"
        exit
        ;;
    esac
}

function get_os_path() {
    if [ "$(uname)" == "Darwin" ]; then
        os_path=/Users/$current_name/data/docker/volumes/$image_alias
    elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
        os_path=d:/docker/volumes/$image_alias
    elif [ "$(expr substr $(uname -s) 1 10)" == "Linux" ]; then
        os_path=/home/$current_name/data/docker/volumes/$image_alias
    fi
    export os_path

}

function get_container_exist() {
    export container_exist=$(docker ps -a | grep $image_name)
}

function init_env_variable() {
    echo "1.3、初始化 MySQL 环境变量${tty_green}"
    echo "image_alias=$image_alias"
    echo "image_name=$image_name"
    echo "mysql_port=$mysql_port"
    echo "os_path=$os_path"
    echo "password=$password"
    echo "${tty_reset}"
}

echo ""
echo "---------------环境变量初始化开始---------------"
init_database_version
get_os_path
get_container_exist
init_env_variable
echo "---------------环境变量初始化完毕---------------"
echo ""
