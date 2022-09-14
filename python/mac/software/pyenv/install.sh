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
tty_universal() { tty_escape "0;$1"; } #正常显示
tty_mkbold() { tty_escape "1;$1"; }    #设置高亮
tty_underline="$(tty_escape "4;39")"   #下划线
tty_blue="$(tty_universal 34)"         #蓝色
tty_red="$(tty_universal 31)"          #红色
tty_green="$(tty_universal 32)"        #绿色
tty_yellow="$(tty_universal 33)"       #黄色
tty_bold="$(tty_universal 39)"         #加黑
tty_cyan="$(tty_universal 36)"         #青色
tty_reset="$(tty_escape 0)"            #去除颜色

current_name="$USER"
pyenv_name="pyenv"
python_name="python"

function get_os_path() {
    if [ "$(uname)" == "Darwin" ]; then
        root_path=/Users/$current_name
    elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
        root_path=d:
    elif [ "$(expr substr $(uname -s) 1 10)" == "Linux" ]; then
        root_path=/home/$current_name
    fi
}

function get_current_path() {
    base_path=$(
        cd $(dirname $0)
        pwd
    )

    # 拷贝文件到指定目录
    cd $base_path
    echo "1、安装${tty_blue}Python${tty_reset}版本管理工具，待执行脚本路径["$base_path"]"
}

function install_pyenv_app() {
    if [[ -n "$1" ]]; then
        echo "2、检查应用[$pyenv_name]，跳过此步骤"
        return 0
    fi

    application_version=$(pyenv --version)
    if [ $? -ne 0 ]; then
        echo "2、检查应用[$pyenv_name]，${tty_red}应用不存在${tty_reset}，执行命令：brew install $pyenv_name"
        brew install $pyenv_name
    else
        echo "2、检查应用[$pyenv_name]，${tty_green}应用已安装${tty_reset}"
    fi
    echo "3、检查应用[$pyenv_name]版本，执行命令：pyenv --version"
    pyenv --version
}

function install_python_app() {
    if [[ -n "$1" ]]; then
        return 0
    fi

    python_version=$root_path/.pyenv/shims/python3
    if [ ! -e "${python_version}" ]; then
        echo "4.1、检查应用[$python_name]，${tty_red}应用不存在${tty_reset}"
        pyenv install --list | grep -v -E 'stackless|pyston|pypy|aminiforge|mini|jython|ironpython|graalpython|anaconda|micro|mamba|activepython|nogil|dev'
        echo "4.2、检查应用[$python_name]，请从上述列表中选择合适的版本，并在终端输入..."
        read input_version
        echo "4.3、检查应用[$python_name]，您已选择的版本${tty_red}[$python_name=$input_version]${tty_reset} --> 应用开始安装"
        # pyenv install $input_version
        echo "4.3、检查应用[$python_name]， 设置全局版本，执行命令：pyenv global $input_version"
        pyenv global $input_version
    else
        echo "4、检查应用[$python_name]，${tty_green}应用已安装${tty_reset}"
        #pyenv uninstall 3.10.0
    fi
    echo "5、检查应用[$python_name]版本，执行命令：$python_version --version"
    $python_version --version
}

function write_bash_profile() {
    bash_profile=$root_path/.bash_profile
    result=$(cat $bash_profile | grep -n 'export PYTHON_HOME=' | awk '{print $1}')
    echo "$result"
    sed -i '27d' $bash_profile
}

function uninstall_python_app() {
    if [[ -n "$1" ]] && [[ "$1" == "uninstall" ]]; then
        python_version=$(python --version)
        split_version=${python_version##* }
        echo "删除应用[$python_name]，执行命令：pyenv uninstall $split_version"
        pyenv uninstall $split_version
    fi
}

get_os_path
get_current_path
install_pyenv_app $1
install_python_app $1
write_bash_profile
uninstall_python_app $1
