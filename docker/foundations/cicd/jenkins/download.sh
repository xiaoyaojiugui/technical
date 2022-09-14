#!/bin/bash
#$0 是脚本本身的名字
#$1 是传递给该shell脚本的第一个参数，即删除容器的判断依据
#$2 是传递给该shell脚本的第二个参数，即删除镜像的判断依据

function init_environment_variable() {
    . ./env-variable.sh
}

function create_folder() {
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$1" ]; then
        echo "1.1.1、检查目标目录，跳过此步骤，创建文件夹[$app_software_path]"
        return 0
    fi
    # 这里的参数（-d）是判断目录是否存在
    if [ -d "$app_software_path" ]; then
        echo "1.1.1、检查目标目录，跳过此步骤，文件夹已存在[$app_software_path]"
    else
        echo "1.1.1、检查目标目录，创建文件夹并授权，执行命令：sudo mkdir -p -v $app_software_path && sudo chown -R $current_name $app_software_path"
        if [ "$(uname)" == "Darwin" || "$(expr substr $(uname -s) 1 10)" == "Linux" ]; then
            sudo mkdir -p -v $app_software_path && sudo chown -R $current_name $app_software_path
        elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
            mkdir -p -v $app_software_path
        fi
    fi
    echo ""
}

function download_maven() {
    maven_version=${maven_filename##*-}
    maven_download_url="https://dlcdn.apache.org/maven/maven-3/$maven_version/binaries/$maven_filename-bin.tar.gz"
    maven_filename_compress=${maven_download_url##*/}
    maven_compress=$software_download_path/$maven_filename_compress
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$1" ]; then
        sudo rm -rf $software_download_path/$maven_filename && sudo rm -rf $app_software_path/$maven_filename #&& rm -rf $maven_filename_compress
        echo "1.2.1、成功删除Maven软件！"
        if [ "$1" == "delete" ]; then
            sudo rm -rf $maven_compress
        fi
        return 0
    fi

    echo "1.2.1、检查Maven软件，其文件名[$maven_filename]，压缩包名[$maven_filename_compress]"
    maven_exist=$(find $app_software_path -name $maven_filename)
    # 这里的参数（-d）是判断目录是否存在
    if [ -d "$maven_exist" ]; then
        echo "1.2.2、检查Maven软件，跳过此步骤，文件已存在[$maven_exist]"
    else
        maven_compress_exist=$(find ./software -name $maven_filename_compress)
        # 这里的参数（-f）判断是否为文件
        if [ -f "$maven_compress_exist" ]; then
            echo "1.2.2、检查Maven软件，解压压缩包，执行命令：tar -zxf $maven_compress -C $software_download_path"
            tar -zxf $maven_compress -C $software_download_path
        else
            echo "1.2.2、检查Maven软件，压缩包不存在，执行命令：wget -P $software_download_path $maven_download_url && tar -zxf $maven_compress -C $software_download_path"
            wget -P $software_download_path $maven_download_url && tar -zxf $maven_compress -C $software_download_path
        fi

        maven_filter_name=$(find ./software -maxdepth 1 -type d | sed 's@^./@@' | grep $maven_filename)
        if [ -n "$maven_filter_name" ]; then
            echo "1.2.3、检查Maven软件，拷贝到指定目录，执行命令：sudo cp -r $software_download_path/$maven_filename $app_software_path && sudo chown -R $current_name $app_software_path"
            sudo cp -r $software_download_path/$maven_filename $app_software_path && sudo chown -R $current_name $app_software_path
        fi
    fi
    echo ""
}

function get_oracle_jdk_url() {
    if [ "$(uname)" == "Darwin" ]; then
        oracle_jdk_url_exist=$(uname -a | grep 'arm64')
        if [ -n "$oracle_jdk_url_exist" ]; then
            # Arm 64 Compressed Archive
            oracle_jdk_url=https://download.oracle.com/java/17/latest/jdk-17_macos-aarch64_bin.tar.gz
        else
            # x64 Compressed Archive
            oracle_jdk_url=https://download.oracle.com/java/17/latest/jdk-17_macos-x64_bin.tar.gz
        fi
    elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
        # x64 Installer
        oracle_jdk_url=https://download.oracle.com/java/17/latest/jdk-17_windows-x64_bin.exe
    elif [ "$(expr substr $(uname -s) 1 10)" == "Linux" ]; then
        oracle_jdk_url_exist=$(uname -a | grep 'arm64')
        if [ -n "$oracle_jdk_url_exist" ]; then
            # Arm 64 Compressed Archive
            oracle_jdk_url=https://download.oracle.com/java/17/latest/jdk-17_linux-aarch64_bin.tar.gz
        else
            # x64 Compressed Archive
            oracle_jdk_url=https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.tar.gz
        fi
    fi
}

function download_oracle_jdk() {
    # ##*/ 表示从左边开始删除最后（最右边）一个 / 号及左边的所有字符
    oracle_jdk_compress_filename=${oracle_jdk_url##*/}
    oracle_jdk_compress=$software_download_path/$oracle_jdk_compress_filename
    oracle_jdk_rename=$software_download_path/$oracle_jdk_filename
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$1" ]; then
        sudo rm -rf $oracle_jdk_rename && sudo rm -rf $app_software_path/$oracle_jdk_filename
        echo "1.3.1、成功删除JDK软件!"
        if [ "$1" == "delete" ]; then
            sudo rm -rf $oracle_jdk_compress
        fi
        return 0
    fi

    echo "1.3.1、检查JDK软件，其文件名[$oracle_jdk_filename]，压缩包[$oracle_jdk_compress_filename]"
    oracle_jdk_exist=$(find $app_software_path -name $oracle_jdk_filename)
    # 这里的参数（-d）是判断目录是否存在
    if [ -d "$oracle_jdk_exist" ]; then
        echo "1.3.2、检查JDK软件，跳过此步骤，文件已存在[$oracle_jdk_exist]"
    else
        oracle_jdk_compress_exist=$(find ./software -name $oracle_jdk_compress_filename)
        # 这里的参数（-f）判断是否为文件
        if [ -f "$oracle_jdk_compress_exist" ]; then
            echo "1.3.2、检查JDK软件，解压压缩包，执行命令：tar -zxf $oracle_jdk_compress -C $software_download_path"
            tar -zxf $oracle_jdk_compress -C $software_download_path
        else
            echo "1.3.2、检查JDK软件，压缩包不存在，执行命令：wget -P $software_download_path $oracle_jdk_url && tar -zxf $oracle_jdk_compress -C $software_download_path"
            wget -P $software_download_path $oracle_jdk_url && tar -zxf $oracle_jdk_compress -C $software_download_path
        fi

        oracle_jdk_filter_name=$(find ./software -maxdepth 1 -type d | sed 's@^./@@' | grep $oracle_jdk_filename)
        if [ -n "$oracle_jdk_filter_name" ]; then
            echo "1.3.3、检查JDK软件，重命名文件，执行命令：sudo mv $oracle_jdk_filter_name $oracle_jdk_rename"
            sudo mv $oracle_jdk_filter_name $oracle_jdk_rename

            echo "1.3.4、检查JDK软件，拷贝到指定目录，执行命令：sudo cp -r $oracle_jdk_rename $app_software_path && sudo chown -R $current_name $app_software_path"
            sudo cp -r $oracle_jdk_rename $app_software_path && sudo chown -R $current_name $app_software_path
        fi
    fi
    echo ""
}

function download_apache_jenkins_war() {
    jenkins_war_compress="jenkins.war"
    jenkins_war_filename="jenkins"
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$1" ]; then
        if [ "$1" == "delete" ]; then
            sudo rm -rf $software_download_path/$jenkins_war_compress
        fi
        echo "1.4.1、成功删除Jenkins软件!"
        return 0
    fi

    echo "1.4.1、检查Jenkins软件，压缩包[$jenkins_war_compress]"
    jenkins_war_exist=$(find ./software -maxdepth 1 -type f | sed 's@^./@@' | grep $jenkins_war_filename)
    # 这里的参数（-f）判断是否为文件
    if [ -f "$jenkins_war_exist" ]; then
        echo "1.4.2、检查Jenkins软件，跳过此步骤，文件已存在[$jenkins_war_exist]"
    else
        echo "1.4.2、检查Jenkins软件，压缩包不存在，执行命令：wget http://mirrors.jenkins.io/war/latest/jenkins.war"
        wget -P $software_download_path http://mirrors.jenkins.io/war/latest/jenkins.war
    fi
    echo ""
}

function view_software() {
    echo ""
    echo "2.1.1、查看目标目录内容，执行命令：ls $app_software_path"
    ls $app_software_path
    echo "2.1.2、查看目标目录内容，执行命令：ls $software_download_path"
    ls $software_download_path
}

echo ""
echo "---------------下载必要软件，开始执行---------------"
init_environment_variable
create_folder
download_maven $1
get_oracle_jdk_url $1
download_oracle_jdk $1
download_apache_jenkins_war $1
view_software
echo "---------------下载必要软件，执行完毕---------------"
echo ""
