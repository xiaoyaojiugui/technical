#!/bin/bash
#$0 是脚本本身的名字
#$1 是传递给该shell脚本的第一个参数，即删除容器的判断依据
#$2 是传递给该shell脚本的第二个参数，即镜像容器的判断依据

function get_basepath() {
    basepath=$(
        cd $(dirname $0)
        pwd
    )
}

function init_environment_variable() {
    # .[空格]./子脚本，此时，相当于函数中的内联函数(inline)的概念，子脚本中的内容会在此处通通展开，此时相当于在一个shell环境中执行所有的脚本内容，所以，此时父子脚本中任何变量都可以共享（注意定义变量的顺序，在使用前声明）。【一个进程】
    . ./env-variable.sh
}

function create_admin_user() {
    # 这里的参数（-n）判断字符串的长度大于0时为真(串非空)
    if [ -n "$container_exist" ]; then
        echo "1、创建数据库用户(admin)并授权，执行命令：docker exec -it $image_alias mysql -uroot -p$password"
        expect $basepath/create-user.exp $image_alias $password
        echo "2、成功创建数据库用户：admin"
    fi
}

echo "---------------函数开始执行---------------"
get_basepath
init_environment_variable
create_admin_user
echo "---------------函数执行完毕---------------"
