---
category: Nginx
title: Nginx Unit 入门教程
date: 2018-05-30 09:00:00
tags: [Linux, Nginx]
abbrlink:
updated:
toc_number: false
---

在「[Nginx 发布支持动态配置的开源 Web 服务器 Nginx Unit](https://mp.weixin.qq.com/s?__biz=MzI3MTI2NzkxMA==&mid=2247485889&idx=1&sn=59e2b7a643db49d36471521bc86615e4&chksm=eac528e8ddb2a1fe469a1474ca48fe896c3a5cd2dc192c91b7e2a97bbdde6b4475fa059060e2#rd)」 一文中我们对 Nginx Unit 的基本特性做了一个介绍。

今天我们用一个典型的 PHP 应用 WordPress 为例，来介绍下如何在 Nginx Unit 下部署一个应用。

### 架构概述

WordPress 是一个相当标准的三层 Web 应用程序，它包括必须由 PHP 处理器执行的 PHP 脚本以及必须由 Web 服务器交付的静态文件。下图为一个简单的 WordPress 应用程序的架构：

![](https://www.hi-linux.com/img/linux/nginx-unit-wp-01.png)

<!-- more -->

本文系统基础环境以 Ubuntu 16.04 为例，如果你使用的是其它发行版本也基本类似，这里就不展开讲解了。

### 安装 MySQL

WordPress 安装的关键要素之一就是存储用户帐户和站点数据的数据库，这里我们使用 MySQL 。

- 安装和配置 MySQL

```
$ sudo apt-get install mysql-server
```

输入新的 MySQL 的 root 用户的密码：

![](https://www.hi-linux.com/img/linux/nginx-unit-wp-02.png)

- 运行 MySQL 配置工具

如果你要对 MySQL 进行更细致的配置，可以使用 `mysql_secure_installation` 工具进行：

```
$ sudo mysql_secure_installation
VALIDATE PASSWORD PLUGIN can be used to test passwords and improve security. It
checks the strength of password and allows the users to set only those passwords
which are secure enough. Would you like to setup VALIDATE PASSWORD plugin?

Press y|Y for Yes, any other key for No:

Using existing password for root.
Change the password for root ? ((Press y|Y for Yes, any other key for No) :

By default, a MySQL installation has an anonymous user, allowing anyone to log
into MySQL without having to have a user account created for them. This is
intended only for testing, and to make the installation go a bit smoother.
You should remove them before moving into a production environment.

Remove anonymous users? (Press y|Y for Yes, any other key for No) :

Normally, root should only be allowed to connect from 'localhost'. This ensures
that someone cannot guess at the root password from the network.

Disallow root login remotely? (Press y|Y for Yes, any other key for No) :

By default, MySQL comes with a database named 'test' that anyone can access. This
is also intended only for testing, and should be removed before moving into a
production environment.

Remove test database and access to it? (Press y|Y for Yes, any other key for No) :

Reloading the privilege tables will ensure that all changes made so far will take
effect immediately.

Reload privilege tables now? (Press y|Y for Yes, any other key for No) :

All done!
```

- 使用 MySQL 的 root 帐户登录

```
# 密码为上面你安装时设置的值
$ sudo mysql -u root -p
```

- 创建一个名为 wordpress 的数据库和用于连接 wordpress 的数据库的用户

```
mysql> CREATE DATABASE wordpress;
mysql> CREATE USER wordpress@localhost IDENTIFIED BY '000000';
mysql> GRANT ALL PRIVILEGES ON wordpress.* TO wordpress@localhost;
mysql> FLUSH PRIVILEGES;
mysql> Exit;
```
> 这里创建的用于连接数据的用户名为：wordpress，密码为：000000

### 安装 WordPress

- 安装 WordPress

我们这里计划把 WordPress 安装到 `/var/www/` 目录下，WordPress 为 PHP 应用，开箱即用。

```
$ cd /var/www/
$ sudo wget http://wordpress.org/latest.tar.gz
$ sudo tar xzvf latest.tar.gz
```

- 配置 WordPress

生成一份 WordPress 的配置文件：

```
$ cd /var/www/wordpress
$ sudo cp wp-config-sample.php wp-config.php
```

为了加强安全性，使用 WordPress 的 salt 函数来随机生成新的密钥：

```
$ curl -s https://api.wordpress.org/secret-key/1.1/salt/
define('AUTH_KEY',         '=wL.},W*rMaA1Pwv!+_qV:4kH.0DLt4XHBYO/$$faan6SdW9f@)-vcol^L@NNgtQ');
define('SECURE_AUTH_KEY',  '`7$#{>c, /-#{iM_[C[/6{zf1TBOL`DZw/.T)A74&[>3G8z#ls1//SN.vf]=L3<o');
define('LOGGED_IN_KEY',    '%)bNF#NIM@Z&W5vosd<!>n]Ja;|I5+Xd!XgizvND|u!^nKmwG:}GPL&//yE4;tRw');
define('NONCE_KEY',        '+:O%5A=Y-K}&4]}g(.1+5)eQ_hVys3~/cj?9SRf_0;mq&@-=gs<x@XGhzV39uDs9');
define('AUTH_SALT',        '3]5-)?dDY%VtL((|83GAN H3glV,}#M=q<31qPnYG`H- azd|iEEIb[qzscHm?=7');
define('SECURE_AUTH_SALT', '(W8i U(:YpP{+m.)qsG|~vOle)_-:0Nb#(!82xxzB!W/Nw3]L4,i].0q_+4jWFi-');
define('LOGGED_IN_SALT',   'T+fp7X.IcPgSEcZZAbVC}q!~QvLg7S0b-L=+[+.9>f?;2S%*Wt|3aS[-g-i|{.RQ');
define('NONCE_SALT',       '|k~[:t^Mq+]+2c/ux4*.1I6AZJyeM-.G%x!~@oesVRQ9@|/3wn2k+y3%;R24B -4');
```

编辑配置文件，修改数据库连接信息和安全密钥：

```
$ sudo vim wp-config.php

# 修改连接数据库的名称、用户名和密码

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define('DB_NAME', 'wordpress');

/** MySQL database username */
define('DB_USER', 'wordpress');

/** MySQL database password */
define('DB_PASSWORD', '000000');

# 修改以下内容为之前产生安全密钥

define('AUTH_KEY',         '=wL.},W*rMaA1Pwv!+_qV:4kH.0DLt4XHBYO/$$faan6SdW9f@)-vcol^L@NNgtQ');
define('SECURE_AUTH_KEY',  '`7$#{>c, /-#{iM_[C[/6{zf1TBOL`DZw/.T)A74&[>3G8z#ls1//SN.vf]=L3<o');
define('LOGGED_IN_KEY',    '%)bNF#NIM@Z&W5vosd<!>n]Ja;|I5+Xd!XgizvND|u!^nKmwG:}GPL&//yE4;tRw');
define('NONCE_KEY',        '+:O%5A=Y-K}&4]}g(.1+5)eQ_hVys3~/cj?9SRf_0;mq&@-=gs<x@XGhzV39uDs9');
define('AUTH_SALT',        '3]5-)?dDY%VtL((|83GAN H3glV,}#M=q<31qPnYG`H- azd|iEEIb[qzscHm?=7');
define('SECURE_AUTH_SALT', '(W8i U(:YpP{+m.)qsG|~vOle)_-:0Nb#(!82xxzB!W/Nw3]L4,i].0q_+4jWFi-');
define('LOGGED_IN_SALT',   'T+fp7X.IcPgSEcZZAbVC}q!~QvLg7S0b-L=+[+.9>f?;2S%*Wt|3aS[-g-i|{.RQ');
define('NONCE_SALT',       '|k~[:t^Mq+]+2c/ux4*.1I6AZJyeM-.G%x!~@oesVRQ9@|/3wn2k+y3%;R24B -4');
```

修改 WordPress 的文件及目录权限：

```
$ sudo chown -R www-data:www-data /var/www/wordpress
$ sudo find /var/www/wordpress -type d -exec chmod g+s {} \;
$ sudo chmod g+w /var/www/wordpress/wp-content
$ sudo chmod -R g+w /var/www/wordpress/wp-content/themes
$ sudo chmod -R g+w /var/www/wordpress/wp-content/plugins
```

> 这里使用的是 www-data 用户，这个用户是要在后面配置到 Nginx Unit 的应用配置文件里的 。

### 安装 PHP

安装 WordPress 需要的 PHP 环境和相关 PHP 扩展，这里我们安装比较新的 PHP 7.0 版本：

```
$ sudo apt-get install -y php7.0 php7.0-common php7.0-mbstring php7.0-gd php7.0-intl php7.0-xml php7.0-mysql php7.0-mcrypt
```

### 安装 Nginx Unit

Nginx Unit 支持多种安装方式，这里我们通过预编译包来安装。

```
# 导入验证 Nginx 仓库的签名密钥
$ sudo curl -C - https://nginx.org/keys/nginx_signing.key | sudo apt-key add -

# 增加 Nginx Unit 仓库源
$ sudo cat >> /etc/apt/sources.list.d/nginx-unit.list << EOF
deb https://packages.nginx.org/unit/ubuntu/ $(lsb_release -sc) unit
deb-src https://packages.nginx.org/unit/ubuntu/ $(lsb_release -sc) unit
EOF

# 安装 Nginx Unit
$ sudo apt-get update
$ sudo apt-get install unit
```

安装 Nginx Unit 的扩展模块

```
$ sudo apt-get install unit-php
```

> 这里只安装了 PHP 模块，Nginx Unit 支持的模块还有很多，比如：unit-python2.7、 unit-python3.5、 unit-go、 unit-perl、 unit-ruby等。

验证 Nginx Unit 和 PHP 是否正常工作

```
$ sudo service unit restart
$ sudo service unit loadconfig /usr/share/doc/unit-php/examples/unit.config
$ curl http://localhost:8300/
```

> 如果出现 phpinfo 页面的原始 HTML 代码，则表示 Nginx Unit 安装正确。

### 配置 Nginx Unit

为 WordPress 创建一个 Nginx Unit 的应用配置文件，该应用配置文件仅用作 Nginx Unit 动态加载用。

此配置文件会创建两个 Nginx Unit 应用程序，每一个应用程序对应一个 URL 方案，两个 URL 分别对应的是 WordPress Web 页面和 WordPress 的后台管理面板。

```
$ sudo vim /var/www/wordpress/wordpress.config

{
    "listeners": {
        "127.0.0.1:8090": {
            "application": "script_index_php"
        },
        "127.0.0.1:8091": {
            "application": "direct_php"
        }
    },

    "applications": {
        "script_index_php": {
            "type": "php",
            "processes": {
                "max": 20,
                "spare": 5
            },
            "user": "www-data",
            "group": "www-data",
            "root": "/var/www/wordpress",
            "script": "index.php"
        },
        "direct_php": {
            "type": "php",
            "processes": {
                "max": 5,
                "spare": 0
            },
            "user": "www-data",
            "group": "www-data",
            "root": "/var/www/wordpress",
            "index": "index.php"
        }
    }
}
```

通过 curl 向 Nginx Unit 提交配置文件

```
$ curl -X PUT -d @/var/www/wordpress/wordpress.config --unix-socket /run/control.unit.sock http://localhost/config
{
	"success": "Reconfiguration done."
}
```

这里只介绍了最基本的 API 用法，实际上基于 Nginx Unit API 可以完成很多工作，具体参考 [NGINX Unit 官方文档](https://unit.nginx.org/configuration/)。 

### 通过 Nginx 整合 Nginx Unit

把 Nginx 和 Nginx Unit 整合到一起，可以实现动静分离。让 Nginx 处理所有的静态资源请求，而与 PHP 相关的动态请求都转由 Nginx Unit 来处理。

- 安装 Nginx

```
# 导入验证 Nginx 仓库的签名密钥
$ sudo curl -C - https://nginx.org/keys/nginx_signing.key | sudo apt-key add -

# 增加 Nginx 仓库源
$ sudo cat >> /etc/apt/sources.list.d/nginx.list << EOF
deb https://nginx.org/packages/mainline/ubuntu/ $(lsb_release -sc) nginx
deb-src https://nginx.org/packages/mainline/ubuntu/ $(lsb_release -sc) nginx
EOF

# 安装 Nginx
$ sudo apt-get update
$ sudo apt-get install nginx
```

验证 Nginx 是否正常工作

```
$ sudo service nginx restart
$ curl http://localhost
```

> 如果出现 Nginx 默认页面的原始 HTML 代码，则表示 Nginx 安装正确。

- 配置 Nginx

首先对默认配置文件做一个备份：

```
$ cd /etc/nginx/conf.d/
$ sudo mv default.conf default.conf.bak
```

其次建立一个新的默认配置文件：

```
$ sudo vim /etc/nginx/conf.d/default.conf

upstream index_php_upstream {
    server 127.0.0.1:8090; # NGINX Unit backend address for index.php with
                           # 'script' parameter
}

upstream direct_php_upstream {
    server 127.0.0.1:8091; # NGINX Unit backend address for generic PHP file handling
}

server {
    listen      80;
    server_name localhost;
    root        /var/www/wordpress/;

    location / {
        try_files $uri @index_php;
    }

    location @index_php {
        proxy_pass       http://index_php_upstream;
        proxy_set_header Host $host;
    }

    location /wp-admin {
        index index.php;
    }

    location ~* \.php$ {
        try_files        $uri =404;
        proxy_pass       http://direct_php_upstream;
        proxy_set_header Host $host;
    }
}
```

最后验证并加载配置文件：

```
$ sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

$ sudo nginx -s reload
```

如果一切正常，在浏览器中访问主机 IP 就会出现 WordPress 的安装页面。

![](https://www.hi-linux.com/img/linux/nginx-unit-wp-03.png)

### 参考文档

https://www.google.com
http://t.cn/R3k71cq
http://t.cn/R3kLoXD