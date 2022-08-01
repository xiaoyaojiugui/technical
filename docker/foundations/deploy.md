[toc]

# 1. Docker实战
## 1.1. Elasticsearch实战
### 1.1.1. Elasticsearch部署及使用
#### 1.1.1.1. 拉取docker镜像
```
docker pull elasticsearch:6.6.0
```
#### 1.1.1.2. 创建docker容器 
```
docker run -d -p 9200:9200 -p 9300:9300 --name es elasticsearch:6.6.0
-d：交互运行容器，让容器以守护态（daemonized）形式在后台运行
-p：端口映射，此处映射主机9200端口到容器es的9200端口
-p：指定端口
--name：给新创建的容器命名即容器别名，如：es
elasticsearch:6.6.0：最后一个参数指的是镜像名字，也可以指定版本标记。
```
#### 1.1.1.3. 进入docker容器
```
docker exec -it es /bin/bash
-d：分离模式，在后台运行
-i：交互模式，即使没有附加也保持STDIN 打开
-t：分配一个伪终端
/bin/bash：运行命令 bash shell
```

#### 1.1.1.4. docker一键初始化脚本

> [elasticsearch.sh](https://github.com/xiaoyaojiugui/leisure-docker/blob/master/foundations/elasticsearch/elasticsearch.sh)

-----
### 1.1.2. Elasticsearch-head部署及使用
#### 1.1.2.1. 拉取docker镜像
```
docker pull mobz/elasticsearch-head:5
```
#### 1.1.2.2. 创建docker容器 
```
docker run -d -p 9100:9100 --name es_admin mobz/elasticsearch-head:5
-d：交互运行容器，让容器以守护态（daemonized）形式在后台运行
-p：端口映射，此处映射主机9100端口到容器es_admin的9100端口
--name：给新创建的容器命名即容器别名，如：es_admin
mobz/elasticsearch-head:5：最后一个参数指的是镜像名字，也可以指定版本标记。
```
#### 1.1.2.3. 进入docker容器
```
docker exec -it es-admin /bin/bash
-d：分离模式，在后台运行
-i：交互模式，即使没有附加也保持STDIN 打开
-t：分配一个伪终端
/bin/bash：运行命令 bash shell
```

#### 1.1.2.4. docker一键初始化脚本

> [elasticsearch-head.sh](https://github.com/xiaoyaojiugui/leisure-docker/blob/master/foundations/elasticsearch/elasticsearch-head.sh)

#### 1.1.2.5. 本地应用控制台
> http://localhost:9100

-----
### 1.1.3. nexus3部署及使用
#### 1.1.3.1. 拉取docker镜像
```
docker pull sonatype/nexus
```
#### 1.1.3.2. 创建docker容器 
```
docker run -d -p 8081:8081 -p 8082:8082 -p 8083:8083 --name nexus3 --restart=always -v /data/docker/volumes/nexus:/nexus-data sonatype/nexus3
-v：/data/docker/volumes/nexus:/nexus-data 将数据挂载到宿主机
-p：表示绑定端口，前面的端口表示宿主机端口，后面的表示容器端口
  8081：nexus网页端 
  8082：docker(hosted)私有仓库，可以pull和push（后面实现docker的时候会详细说明）
  8083：docker(proxy)代理远程仓库，只能pull（后面实现docker的时候会详细说明）
-d：交互运行容器，让容器以守护态（daemonized）形式在后台运行
--name：给新创建的容器命名即容器别名，如：nexus
--restart=always：这个指定docker重启启动容器，当服务器或者docker进程重启之后，nexus容器会在docker守护进程启动后由docker守护进程启动容器
sonatype/nexus3：最后一个参数指的是镜像名字，也可以指定版本标记。
```
#### 1.1.3.3. 进入docker容器
```
docker exec -it nexus3 /bin/bash
-d：分离模式，在后台运行
-i：交互模式，即使没有附加也保持STDIN 打开
-t：分配一个伪终端
/bin/bash：运行命令 bash shell
```

#### 1.1.3.4. docker一键初始化脚本

> [nexus.sh](https://github.com/xiaoyaojiugui/leisure-docker/blob/master/foundations/nexus.sh)

#### 1.1.3.5. 检查nexus3运行情况
> curl -u admin:admin123 http://localhost:8081/service/metrics/ping