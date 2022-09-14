#!/bin/bash
#$0 是脚本本身的名字
#$1 是传递给该shell脚本的第一个参数，即删除容器的判断依据
#$2 是传递给该shell脚本的第二个参数，即删除镜像的判断依据

function init_environment_variable() {
  # .[空格]./子脚本，此时，相当于函数中的内联函数(inline)的概念，子脚本中的内容会在此处通通展开，此时相当于在一个shell环境中执行所有的脚本内容，所以，此时父子脚本中任何变量都可以共享（注意定义变量的顺序，在使用前声明）。【一个进程】
  . ./env-variable.sh
}

function init_jdk_setting() {
  # 这里的参数（-n）判断字符串长度大于0时为真(串非空)
  if [ -n "$container_exist" ]; then
    update_jdk_setting=$os_path/jenkins-home/config.xml
    # 这里的参数（-e）是判断文件是否存在
    if [ -e "$update_jdk_setting" ]; then
      filter_update_jdk=$(cat $update_jdk_setting | grep $oracle_jdk_filename)
      # 这里的参数（-z）判断字符串的长度为0时为真(空串)
      if [ -n "$filter_update_jdk" ]; then
        echo "1.1、全局工具配置，跳过此步骤，文件已修改[$update_jdk_setting]"
        echo "$filter_update_jdk"
        return 0
      fi

      echo "1.1.1、全局工具配置，修改配置文件[$update_jdk_setting]"
      if [ "$(uname)" == "Darwin" ]; then
        sed -i "" 's/<jdks\/>/<jdks> \
    <jdk> \
      <name>jdk-17<\/name> \
      <home>\/usr\/local\/apps\/jdk-17<\/home> \
      <properties\/> \
    <\/jdk> \
  <\/jdks>/g' $update_jdk_setting
      elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ] || [ "$(expr substr $(uname -s) 1 10)" == "Linux" ]; then
        sed -i 's/<jdks\/>/<jdks> \
    <jdk> \
      <name>jdk-17<\/name> \
      <home>\/usr\/local\/apps\/jdk-17<\/home> \
      <properties\/> \
    <\/jdk> \
  <\/jdks>/g' $update_jdk_setting
      fi
      echo "1.1.2、全局工具配置，查看配置文件，执行命令：cat $update_jdk_setting | grep '$oracle_jdk_filename'"
      cat $update_jdk_setting | grep $oracle_jdk_filename
    fi
  fi
}

function init_maven_setting() {
  # 这里的参数（-n）判断字符串长度大于0时为真(串非空)
  if [ -n "$container_exist" ]; then
    update_maven_config=$os_path/jenkins-home/hudson.tasks.Maven.xml
    # 这里的参数（-e）是判断文件是否存在
    if [ -e "$update_maven_config" ]; then
      filter_update_maven=$(cat $update_maven_config | grep $maven_filename)
      # 这里的参数（-n）判断字符串长度大于0时为真(串非空)
      if [ -n "$filter_update_maven" ]; then
        echo "1.2、全局工具配置，跳过此步骤，文件已修改[$update_maven_config]"
        echo "$filter_update_maven"
      else
        echo "1.2.1、全局工具配置，修改配置文件[$update_maven_config]"
        write_maven_setting
        echo "1.1.2、全局工具配置，查看配置文件，执行命令：cat $update_maven_config | grep '$maven_filename'"
        cat $update_maven_config | grep $maven_filename
      fi
    else
      echo "1.2.1、全局工具配置，创建文件并更新内容，执行命令：sudo touch $update_maven_config && sudo chmod -R 666 $update_maven_config"
      sudo touch $update_maven_config && sudo chmod -R 666 $update_maven_config && write_maven_setting
    fi
  fi
}

function write_maven_setting() {
  cat >$os_path/jenkins-home/hudson.tasks.Maven.xml <<EOF
<?xml version='1.1' encoding='UTF-8'?>
<hudson.tasks.Maven_-DescriptorImpl>
  <installations>
    <hudson.tasks.Maven_-MavenInstallation>
      <name>apache-maven-3.8.6</name>
      <home>/usr/local/apps/apache-maven-3.8.6</home>
      <properties/>
    </hudson.tasks.Maven_-MavenInstallation>
  </installations>
</hudson.tasks.Maven_-DescriptorImpl>

EOF
}

echo "---------------函数开始执行---------------"
init_environment_variable
init_jdk_setting
init_maven_setting
echo "---------------函数执行完毕---------------"
