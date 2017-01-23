---
title: 在Nginx使用Lua扩展功能
tags:
  - Nginx
  - Lua
categories: Nginx
abbrlink: 24
date: 2016-06-28 09:00:00
updated:
toc_number:
---

### 什么是LUA

Lua从一开始就是作为一门方便嵌入(其它应用程序)并可扩展的轻量级脚本语言来设计的，因此她一直遵从着简单、小巧、可移植、快速的原则，官方实现完全采用ANSI C编写，能以C程序库的形式嵌入到宿主程序中。

Lua脚本是一个很轻量级的脚本，也是号称性能最高的脚本，用在很多需要性能的地方，比如：游戏脚本，Nginx，Wireshark的脚本。

<!-- more -->

### 什么是Nginx_Lua_Module

`Nginx_Lua_Module`是由淘宝的工程师清无(王晓哲)和春来(章亦春)所开发的Nginx第三方模块,它能将Lua语言嵌入到Nginx配置中,从而使用Lua就极大增强了Nginx的能力。


### 编译Nginx并加载Lua

#### 安装基础编译环境

```
$ yum -y groupinstall 'Development Tools'
```

#### 下载相关软件源码包

下载当前最新的Nginx、Luajit和Ngx_devel_kit(NDK)，以及Lua-nginx-module源码包

```
$ cd /usr/local/src
$ wget http://nginx.org/download/nginx-1.10.1.tar.gz
$ wget http://luajit.org/download/LuaJIT-2.0.4.tar.gz
$ wget https://github.com/simpl/ngx_devel_kit/archive/v0.3.0.tar.gz
$ wget https://github.com/openresty/lua-nginx-module/archive/v0.10.5.tar.gz
```

#### 创建Nginx运行的普通用户

```
$ useradd -s /sbin/nologin -M nginx
```

#### 安装LuaJIT 

Luajit是Lua即时编译器

```
$ tar zxvf LuaJIT-2.0.4.tar.gz
$ cd LuaJIT-2.0.4
$ make && make install
```

#### 安装Nginx并加载模块

让Nginx支持Lua有两种方法：一是使用Luajit即时编译器，二是使用Lua编译器。推荐使用Luajit，因为效率高。其中Ngx_devel_kit的作用有2个：一是开发用的，二是可以在错误日志中记录Nginx处理阶段信息(rewrite phase,access phase,content phase)，需要将错误日志级别调高，调试时可以设置成Debug。

- 解压Nginx、NDK和Lua-Nginx-Module源码包

```
$ tar zxvf nginx-1.10.1.tar.gz
$ tar zxvf v0.3.0.tar.gz
$ tar zxvf v0.10.5.tar.gz
```

- 安装依赖包

```
$ yum -y install openssl openssl-devel pcre pcre-devel 
```

- 编译安装Nginx

```
$ cd nginx-1.10.1
$ export LUAJIT_LIB=/usr/local/lib
$ export LUAJIT_INC=/usr/local/include/luajit-2.0
$ ./configure --prefix=/usr/local/nginx --user=nginx --group=nginx --with-http_ssl_module --with-http_stub_status_module --with-file-aio --with-http_dav_module --add-module=../ngx_devel_kit-0.3.0/ --add-module=../lua-nginx-module-0.10.5/
$ make && make install
```

- 创建软连接

```
$ ln -s /usr/local/lib/libluajit-5.1.so.2 /lib64/libluajit-5.1.so.2
```

- 如果不创建会出现类似以下错误

```
$ nginx -t
/usr/local/nginx/sbin/nginx: error while loading shared libraries: libluajit-5.1.so.2: cannot open shared object file: No such file or directory
```

#### 测试是否支持LUA


- 修改nginx.conf文件，增加如下配置

```
$ vim /usr/local/nginx/conf/nginx.conf

        location /hello {
        default_type 'text/plain';
        content_by_lua 'ngx.say("hello,lua")';
        }
```


- 配置完成后，类似如下这样

```

    server {
        listen       80;
        server_name  localhost;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        location / {
            root   html;
            index  index.html index.htm;
        }
		
        location /hello {
        default_type 'text/plain';
        content_by_lua 'ngx.say("hello,lua")';
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }


    }
```

- 检查配置

```
$ /usr/local/nginx/sbin/nginx  -t
nginx: the configuration file /usr/local/nginx/conf/nginx.conf syntax is ok
nginx: configuration file /usr/local/nginx/conf/nginx.conf test is successful
```

- 启动Nginx

```
$ /usr/local/nginx/sbin/nginx
```

用浏览器访问`http://IP/hello`，页面输出`hello,lua`表示已正确支持LUA。


### 创建启动脚本


使用命令行直接运行Nginx较为麻烦，因此使用脚本来控制Nginx的启动、关闭、重载更加合理一些。


- 适用于CentOS 6/CentOS 5

[Nginx Wiki](https://www.nginx.com/resources/wiki/start/topics/examples/redhatnginxinit/)网站已经有这个脚本(CentOS)，拿来稍做修改即可使用。

```
$ vim /etc/init.d/nginx

#!/bin/sh
#
# nginx - this script starts and stops the nginx daemon
#
# chkconfig:   - 85 15
# description:  NGINX is an HTTP(S) server, HTTP(S) reverse \
#               proxy and IMAP/POP3 proxy server
# processname: nginx
# config:      /usr/local/nginx/conf/nginx.conf
# config:      /etc/sysconfig/nginx
# pidfile:     /var/run/nginx.pid

# Source function library.
. /etc/rc.d/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

# Check that networking is up.
[ "$NETWORKING" = "no" ] && exit 0

nginx="/usr/local/nginx/sbin/nginx"
prog=$(basename $nginx)

NGINX_CONF_FILE="/usr/local/nginx/conf/nginx.conf"

[ -f /etc/sysconfig/nginx ] && . /etc/sysconfig/nginx

lockfile=/var/lock/subsys/nginx

make_dirs() {
   # make required directories
   user=`$nginx -V 2>&1 | grep "configure arguments:" | sed 's/[^*]*--user=\([^ ]*\).*/\1/g' -`
   if [ -z "`grep $user /etc/passwd`" ]; then
       useradd -M -s /bin/nologin $user
   fi
   options=`$nginx -V 2>&1 | grep 'configure arguments:'`
   for opt in $options; do
       if [ `echo $opt | grep '.*-temp-path'` ]; then
           value=`echo $opt | cut -d "=" -f 2`
           if [ ! -d "$value" ]; then
               # echo "creating" $value
               mkdir -p $value && chown -R $user $value
           fi
       fi
   done
}

start() {
    [ -x $nginx ] || exit 5
    [ -f $NGINX_CONF_FILE ] || exit 6
    make_dirs
    echo -n $"Starting $prog: "
    daemon $nginx -c $NGINX_CONF_FILE
    retval=$?
    echo
    [ $retval -eq 0 ] && touch $lockfile
    return $retval
}

stop() {
    echo -n $"Stopping $prog: "
    killproc $prog -QUIT
    retval=$?
    echo
    [ $retval -eq 0 ] && rm -f $lockfile
    return $retval
}

restart() {
    configtest || return $?
    stop
    sleep 1
    start
}

reload() {
    configtest || return $?
    echo -n $"Reloading $prog: "
    killproc $nginx -HUP
    RETVAL=$?
    echo
}

force_reload() {
    restart
}

configtest() {
  $nginx -t -c $NGINX_CONF_FILE
}

rh_status() {
    status $prog
}

rh_status_q() {
    rh_status >/dev/null 2>&1
}

case "$1" in
    start)
        rh_status_q && exit 0
        $1
        ;;
    stop)
        rh_status_q || exit 0
        $1
        ;;
    restart|configtest)
        $1
        ;;
    reload)
        rh_status_q || exit 7
        $1
        ;;
    force-reload)
        force_reload
        ;;
    status)
        rh_status
        ;;
    condrestart|try-restart)
        rh_status_q || exit 0
            ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart|condrestart|try-restart|reload|force-reload|configtest}"
        exit 2
esac
```

**增加执行权限**

```
$ chmod +x /etc/init.d/nginx
```

**使用下面的指令来控制Nginx**

```
# 启动Nginx
$ /etc/init.d/nginx start

# 重启Nginx
$ /etc/init.d/nginx restart

# 停止Nginx
$ /etc/init.d/nginx stop

# 重新加载Nginx配置文件
$ /etc/init.d/nginx reload
```

- 适用于Centos 7 

由于Centos 7采用了Systemd管理服务进程，故管理的方法与Centos 6之前不太一样。

```
$ vim /usr/lib/systemd/system/nginx.service

# 输入下面内容，并保存。

[Unit]
Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
After=network.target remote-fs.target nss-lookup.target
  
[Service]
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t -c /usr/local/nginx/conf/nginx.conf
ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true
  
[Install]
WantedBy=multi-user.target
```

**注意下面参数的路径，根据实际情况修改。** 

```
PIDFile=/usr/local/nginx/logs/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t -c /usr/local/nginx/conf/nginx.conf
ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
```

**修改权限**

```
$ chmod +x /usr/lib/systemd/system/nginx.service
```

**使用下面的指令来控制Nginx**

```
# 启动Nginx
$ systemctl start nginx.service

# 重启Nginx
$ systemctl restart nginx.service

# 停止Nginx
$ systemctl stop nginx.service

# 重新加载Nginx配置文件
$ systemctl reload nginx.service

# 开机运行Nginx
$ systemctl enable nginx.service

# 取消开机运行Nginx
$ systemctl disable nginx.service 

# 查询Nginx是否开机启动
$ systemctl is-enabled nginx.service

# 查询Nginx运行状态
$ systemctl status nginx.service

# 显示Nginx日志
$ journalctl -f -u nginx.service

# 显示启动失败的服务
$ systemctl --failed 
```

### 参考文档

http://www.google.com
http://my.oschina.net/liucao/blog/470344