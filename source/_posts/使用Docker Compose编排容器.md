---
category: docker
title: 使用 Docker Compose 编排容器集群
date: 2017-02-22 09:00:00
tags: [linux, docker]
updated:
toc_number: false
---

Docker Compose是Docker的一种编排服务，是一个用于在Docker上定义并运行复杂应用的工具，可以让用户在集群中部署分布式应用。通过Compose，用户可以很容易地用一个配置文件定义一个多容器的应用，然后使用一条指令安装这个应用的所有依赖，完成构建。Docker Compose解决了容器与容器之间如何管理编排的问题。

Compose是用于定义和运行复杂Docker应用的工具。你可以在一个文件中定义一个多容器的应用，然后使用一条命令来启动你的应用，然后所有相关的操作都会被自动完成。

<!-- more -->

**Docker Compose 工作原理图**

![](http://www.hi-linux.com/img/linux/docker-compose.png)

### 安装Docker Compose

Docker Compose 1.7.1

> 如Docker Compose文件格式为2.0，Docker Engine版本必须大于1.10.0
> 如Docker Compose文件格式为1.0，Docker Engine版本必须大于1.9.1

#### 安装Docker

这里使用的是阿里云镜像安装，速度比官方的快一些。

```bash
$ curl -sSL http://acs-public-mirror.oss-cn-hangzhou.aliyuncs.com/docker-engine/internet | sh -
```

- 方法一

通过pip安装(推荐)

```bash
Note: pip version 6.0 or greater is required
$ pip install -U docker-compose
```

验证安装成功

```bash
$ pip list|grep compose
docker-compose (1.5.2)
```

- 方法二

直接使用二进制文件

```bash
$ curl -L https://github.com/docker/compose/releases/download/1.7.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
$ chmod +x /usr/local/bin/docker-compose
```

你可以通过修改URL中的版本，可以自定义您的需要的版本。

Docker Compose存放在GitHub，国内访问比较慢。你可以也通过执行下面的命令，使用国内镜像安装Docker Compose。

```bash
$ curl -L https://get.daocloud.io/docker/compose/releases/download/1.7.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
$ chmod +x /usr/local/bin/docker-compose
```

验证安装成功

```bash
$ docker-compose --version
```

#### 添加SHELL的TAB补全

- Bash

**安装bash-completion**

Debian/Ubuntu

```bash
$ apt-get install bash-completion
```

Centos

```
$ yum install bash-completion
```

MAC

```bash
$ brew install bash-completion
```

**下载docker-compose脚本**

```bash
$ curl -L https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/bash/docker-compose > /etc/bash_completion.d/docker-compose
```

重新登陆后就生效了

- ZSH

下载脚本

```bash
$ mkdir -p ~/.zsh/completion
$ curl -L https://raw.githubusercontent.com/docker/compose/$(docker-compose version --short)/contrib/completion/zsh/_docker-compose > ~/.zsh/completion/_docker-compose
```

编辑zshrc

```bash
$ vim ~/.zshrc

fpath=(~/.zsh/completion $fpath)
autoload -Uz compinit && compinit -i
```

- Oh My ZSH

```bash
$ vim ~/.zshrc

plugins+=(docker-compose)
```

- 重新加载SHELL

```bash
$ exec $SHELL -l
```

#### 卸载Docker

- 通过二进制文件

```bash
$ rm /usr/local/bin/docker-compose
```

- 通过pip安装

```bash
$ pip uninstall docker-compose
```

### 使用Docker Compose

#### Docker-Compose常用命令

查看docker-compose的用法

```bash
$ docker-compose

Define and run multi-container applications with Docker.

Usage:
  docker-compose [-f <arg>...] [options] [COMMAND] [ARGS...]
  docker-compose -h|--help

Options:
  -f, --file FILE             Specify an alternate compose file (default: docker-compose.yml)
  -p, --project-name NAME     Specify an alternate project name (default: directory name)
  --verbose                   Show more output
  -v, --version               Print version and exit
  -H, --host HOST             Daemon socket to connect to

  --tls                       Use TLS; implied by --tlsverify
  --tlscacert CA_PATH         Trust certs signed only by this CA
  --tlscert CLIENT_CERT_PATH  Path to TLS certificate file
  --tlskey TLS_KEY_PATH       Path to TLS key file
  --tlsverify                 Use TLS and verify the remote
  --skip-hostname-check       Don't check the daemon's hostname against the name specified
                              in the client certificate (for example if your docker host
                              is an IP address)

Commands:
  build              Build or rebuild services
  config             Validate and view the compose file
  create             Create services
  down               Stop and remove containers, networks, images, and volumes
  events             Receive real time events from containers
  exec               Execute a command in a running container
  help               Get help on a command
  kill               Kill containers
  logs               View output from containers
  pause              Pause services
  port               Print the public port for a port binding
  ps                 List containers
  pull               Pulls service images
  restart            Restart services
  rm                 Remove stopped containers
  run                Run a one-off command
  scale              Set number of containers for a service
  start              Start services
  stop               Stop services
  unpause            Unpause services
  up                 Create and start containers
  version            Show the Docker-Compose version information
```

#### Docker-Compose命令说明

大部分命令都可以运行在一个或多个服务上。如果没有特别的说明，命令则应用在项目所有的服务上。

执行`docker-compose [COMMAND] --help`查看具体某个命令的使用说明。

**基本的使用格式**

```bash
docker-compose [options] [COMMAND] [ARGS...]
```

**常用选项**

```bash
-f, --file FILE           指定启动模版文件(一个非docker-compose.yml命名的yaml文件,默认为docker-compose.yml)
-p, --project-name NAME   指定一个替代项目名称 (默认是directory名)
-d 以daemon的方式启动容器
--x-networking            (EXPERIMENTAL) 使用新的网络功能
--x-network-driver DRIVER (EXPERIMENTAL) 指定网络驱动程序，桥 (default: "bridge").
--verbose：输出详细信息
--version 打印版本并退出。
```

**常用命令**


- build

构建或重新构建服务。
服务一旦构建后，将会带上一个标记名，例如 web_db。
可以随时在项目目录下运行 docker-compose build 来重新构建服务。

- help

获得一个命令的帮助。

- kill

通过发送SIGKILL信号来强制停止服务容器。支持通过参数来指定发送的信号，例如 `docker-compose kill -s SIGINT`

- logs

查看服务的输出。

- port

打印绑定的公共端口。

- ps

输出运行的容器列表。

- pull

拉取服务镜像。

- rm

删除停止的服务容器。

- run

在一个服务上执行一个命令。例如：`docker-compose run ubuntu ping docker.com`将会启动一个ubuntu 服务，执行 `ping docker.com` 命令。

默认情况下，所有关联的服务将会自动被启动，除非这些服务已经在运行中。该命令类似启动容器后运行指定的命令，相关卷、链接等等都将会按照期望创建。

如果不希望自动启动关联的容器，可以使用 `--no-deps` 选项，例如 `docker-compose run --no-deps web python manage.py shell` 将不会启动 web 容器所关联的其它容器。

- scale

设置同一个服务运行的容器个数。

通过 service=num 的参数来设置数量。例如：`docker-compose scale web=2 worker=3`

- start

启动一个已经存在的服务容器。

- stop

停止一个已经运行的容器，但不删除它。通过 `docker-compose start`可以再次启动这些容器。

- restart

重启服务容器

- up

构建，（重新）创建，启动，链接一个服务相关的容器。链接的服务都将会启动，除非他们已经运行。

默认情况， `docker-compose up` 将会整合所有容器的输出，并且退出时，所有容器将会停止。如果使用 `docker-compose up -d` ，将会在后台启动并运行所有的容器。

默认情况，如果该服务的容器已经存在， `docker-compose up` 将会停止并尝试重新创建他们（保持使用 `volumes-from` 挂载的卷），以保证 `docker-compose.yml` 的修改生效。如果你不想容器被停止并重新创建，可以使用 `docker-compose up --no-recreate`。如果需要的话，这样将会启动已经停止的容器。

- pause              

暂停容器服务

- version

显示Docker-Compose版本信息

- 环境变量

环境变量可以用来配置Compose的行为。

以DOCKER_开头的变量和用来配置 Docker 命令行客户端的使用一样。

COMPOSE_PROJECT_NAME

设置通过Compose启动的每一个容器前添加的项目名称，默认是当前工作目录的名字。

COMPOSE_FILE

设置要使用的 `docker-compose.yml` 的路径。默认路径是当前工作目录。

DOCKER_HOST

设置Docker daemon的地址。默认使用`unix:///var/run/docker.sock`，与Docker客户端采用的默认值一致。

DOCKER_TLS_VERIFY

如果设置不为空，则与 Docker daemon 交互通过 TLS 进行。

DOCKER_CERT_PATH

配置TLS通信所需要的验证(ca.pem、cert.pem 和 key.pem)文件的路径，默认是 `~/.docker` 。

**docker-compose命令对比**

- image vs build

image：如果镜像在本地不存在，Compose 将会尝试拉去这个镜像。

build：指定 `Dockerfile` 所在文件夹的路径。 Compose 将会利用它自动构建这个镜像，然后使用这个镜像。

- links vs external_links

links：链接到其它服务中的容器。使用服务名称（同时作为别名）或服务名称：服务别名 （SERVICE:ALIAS） 格式都可以。使用的别名将会自动在服务容器中的 /etc/hosts 里创建。

external_links：链接到 docker-compose.yml 外部的容器，甚至 并非 Compose 管理的容器。

- ports vs expose

ports

暴露端口信息。使用：宿主：容器 （HOST:CONTAINER）格式或者仅仅指定容器的端口（宿主将会随机选择端口）都可以。

当使用 HOST:CONTAINER 格式来映射端口时，如果你使用的容器端口小于 60 你可能会得到错误得结果，因为 YAML 将会解析 xx:yy 这种数字格式为 60 进制。所以建议采用字符串格式。

expose

暴露端口，但不映射到宿主机，只被连接的服务访问。

- volumes vs volumes_from

volumes

卷挂载路径设置。可以设置宿主机路径 （HOST:CONTAINER） 或加上访问模式 （HOST:CONTAINER:ro）。ro就是readonly的意思，只读模式。

volumes_from

从另一个服务或容器挂载它的所有卷。

#### Docker-Compose YAML语法使用说明

默认的模板文件是 `docker-compose.yml`，其中定义的每个服务都必须通过image指令指定镜像或build指令(需要 Dockerfile)来自动构建。其它大部分指令都跟docker run中的类似。

如果使用build指令，在Dockerfile中设置的选项(例如：CMD, EXPOSE, VOLUME, ENV 等) 将会自动被获取，无需在docker-compose.yml中再次设置。

- build

这个是创建docker镜像时的选项，通过本地的dockerfile来创建，而不是通过image id来pull。
其中build还有一些小选项。

```
build:
  context: ./webapp
  dockerfile: Dockerfile-alternate
  args:
    - buildno=1
    - user=someuser
```

context上下文是docker build中很重要的一个概念。构建镜像必须指定context。context是 docker build 命令的工作目录。默认情况下，如果不额外指定 Dockerfile 的话，会将 Context 下的名为 Dockerfile 的文件作为 Dockerfile。

dockerfile选项是值得备选的dockerfile。args是一些提供的参数。



- image: 生成镜像的ID

指定为镜像名称或镜像 ID。如果镜像在本地不存在，Compose 将会尝试拉去这个镜像。

例如：

```bash
image: ubuntu
image: orchardup/postgresql
image: a4bc65fd
```

- links

链接到其它服务中的容器,使一个容器可以主动的去和另外一个容器通讯。使用服务名称（同时作为别名）或服务名称：服务别名 （SERVICE:ALIAS） 格式都可以。


```bash
links:
 - db
 - db:database
 - redis
```

使用的别名将会自动在服务容器中的 /etc/hosts 里创建。例如：

```
172.17.2.186  db
172.17.2.186  database
172.17.2.187  redis
```

相应的环境变量也将被创建。

- external_links

链接到 docker-compose.yml 外部的容器，甚至 并非 Compose 管理的容器。参数格式跟 links 类似。

```
external_links:
 - redis_1
 - project_db_1:mysql
 - project_db_1:postgresql
```

- expose

这个是给link用的，将一些端口暴露给link到这个container上的containers。暴露端口，但不映射到宿主机，只被连接的服务访问。

```
expose:
    - "3000"
    - "8000"
```

- ports

暴露端口信息,这个是将端口和本机端口映射的选项，写法如下，其实跟`docker -p`一样。使用宿主：容器 （HOST:CONTAINER）格式或者仅仅指定容器的端口（宿主将会随机选择端口）都可以。

```
ports:
    - "3000"
    - "3000-3005"
    - "8000:8000"
    - "9090-9091:8080-8081"
    - "49100:22"
    - "127.0.0.1:8001:8001"
    - "127.0.0.1:5000-5010:5000-5010"
```

注：当使用 HOST:CONTAINER 格式来映射端口时，如果你使用的容器端口小于 60 你可能会得到错误得结果，因为 YAML 将会解析 xx:yy 这种数字格式为 60 进制。所以建议采用字符串格式。


- environment:

设置环境变量。你可以使用数组或字典两种格式。

只给定名称的变量会自动获取它在 Compose 主机上的值，可以用来防止泄露不必要的数据。

```
environment:
  RACK_ENV: development
  SESSION_SECRET:

environment:
  - RACK_ENV=development
  - SESSION_SECRET
```

- env_file

从文件中获取环境变量，可以为单独的文件路径或列表。

如果通过 `docker-compose -f FILE` 指定了模板文件，则 env_file 中路径会基于模板文件路径。

如果有变量名称与 environment 指令冲突，则以后者为准。

```
env_file: .env

env_file:
  - ./common.env
  - ./apps/web.env
  - /opt/secrets.env
```

环境变量文件中每一行必须符合格式，支持 # 开头的注释行。

```
# common.env: Set Rails/Rack environment
RACK_ENV=development
```

- volumes

将本机的文件夹挂载到container中，这一点在使用zmq的ipc通讯方式时用到了。

```
volumes:
     # Just specify a path and let the Engine create a volume
        - /var/lib/mysql

    # Specify an absolute path mapping
        - /opt/data:/var/lib/mysql

    # Path on the host, relative to the Compose file
        - ./cache:/tmp/cache

      # User-relative path
        - ~/configs:/etc/configs/:ro

     # Named volume
        - datavolume:/var/lib/mysql
```


卷挂载路径设置。可以设置宿主机路径 （HOST:CONTAINER） 或加上访问模式 （HOST:CONTAINER:ro）。

```
volumes:
 - /var/lib/mysql
 - cache/:/tmp/cache
 - ~/configs:/etc/configs/:ro
```

- volumes_from

从另一个服务或容器挂载它的所有卷。

```
volumes_from:
 - service_name
 - container_name
```

- extends

基于已有的服务进行扩展。例如我们已经有了一个webapp服务，模板文件为 common.yml。

```
# common.yml
webapp:
  build: ./webapp
  environment:
    - DEBUG=false
    - SEND_EMAILS=false
```

编写一个新的 development.yml 文件，使用 common.yml 中的 webapp 服务进行扩展。

```
# development.yml
web:
  extends:
    file: common.yml
    service: webapp
  ports:
    - "8000:8000"
  links:
    - db
  environment:
    - DEBUG=true
db:
  image: postgres
```

后者会自动继承 common.yml 中的 webapp 服务及相关环节变量。

- net

设置网络模式。使用和 docker client 的 –net 参数一样的值。

```
net: "bridge"
net: "none"
net: "container:[name or id]"
net: "host"
```

- pid

跟主机系统共享进程命名空间。打开该选项的容器可以相互通过进程 ID 来访问和操作。

```
pid: "host"
```

- dns

配置 DNS 服务器。可以是一个值，也可以是一个列表。

```
dns: 8.8.8.8
dns:
  - 8.8.8.8
  - 9.9.9.9
```
- cap_add, cap_drop

添加或放弃容器的 Linux 能力（Capabiliity）。

```
cap_add:
  - ALL

cap_drop:
  - NET_ADMIN
  - SYS_ADMIN
```

- dns_search

配置 DNS 搜索域。可以是一个值，也可以是一个列表。

```
dns_search: example.com
dns_search:
  - domain1.example.com
  - domain2.example.com
```

- command

覆盖容器启动后默认执行的命令。

```
command: bundle exec thin -p 3000
```

- 其它选项

working_dir, entrypoint, user, hostname, domainname, mem_limit, privileged, restart, stdin_open, tty, cpu_sharesv 这些都是和 docker run 支持的选项类似。

```
cpu_shares: 73
working_dir: /code
entrypoint: /code/entrypoint.sh
user: postgresql
hostname: foo
domainname: foo.com
mem_limit: 1000000000
privileged: true
restart: always
stdin_open: true
tty: true
```

### Docker-Compose使用实例

创建一个Wordpress应用,首先建立一个应用的目录

```bash
$ mkdir wordpress
$ cd wordpress
```

创建 docker-compose.yml

```bash
$ vim docker-compose.yml

version: '2'
services:
  db:
    image: mysql:5.7
    volumes:
      - "./data/db:/var/lib/mysql"
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: wordpress
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: wordpress

  wordpress:
    depends_on:
      - db
    image: wordpress:latest
    links:
      - db
    ports:
      - "8000:80"
    restart: always
    environment:
      WORDPRESS_DB_HOST: db:3306
      WORDPRESS_DB_PASSWORD: wordpress
```

MySQL的数据目录挂载到当前目录下，./.data/db不存在时会自动创建。

启动应用

```bash
$ docker-compose up -d

Starting wordpress_db_1
Starting wordpress_wordpress_1
```

确认启动成功

```Bash
$ docker-compose ps

675777c33fdb        wordpress:latest    "docker-entrypoint.sh"   About an hour ago   Up About a minute                     0.0.0.0:8000->80/tcp   wordpress_wordpress_1
6edfe3786798        mysql:5.7           "docker-entrypoint.sh"   About an hour ago   Up About a minute                     3306/tcp               wordpress_db_1
```

访问应用

http://localhost:8000/

初始化设置后，就可以看到Wordpress的页面

![](http://www.hi-linux.com/img/linux/wordpress.png)

**其它**

Docker Compose UI，一个可在网页上的直观的进行Docker Compose操作的项目。

项目地址：https://github.com/francescou/docker-compose-ui


### 参考文档

http://www.google.com
https://docs.docker.com/compose/compose-file/
https://coding.net/u/twang2218/p/docker-lnmp/git
http://www.cnblogs.com/ee900222/p/docker_5.html
