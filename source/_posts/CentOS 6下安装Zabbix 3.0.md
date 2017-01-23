---
title: CentOS 6下安装Zabbix 3.0
tags:
  - Zabbix
  - Linux
categories: Zabbix
abbrlink: 16723
date: 2016-03-29 09:00:02
updated:
---
### 概述

对于3.0官方只提供CentOS7的RPM包、Ubuntu的DEB包。对于CentOS6默认不提供RPM包，为了方便CentOS6包安装可采用以下两个项目中打好的RPM包。

环境要求

> PHP >= 5.4  (CentOS6默认为5.3.3，需要更新)
> curl >= 7.20 (如需支持SMTP认证，需更新)

为了支持CentOS6，特建立如下项目

> https://github.com/zabbixcn/zabbix3.0-rpm.git
> https://github.com/zabbixcn/curl-rpm

<!-- more -->

### 安装MySQL

MySQL建议使用5.6版本，CentOS6默认为5.1，不建议使用，性能偏低。

#### 安装
```bash
rpm -ivh http://dev.mysql.com/get/mysql-community-release-el6-5.noarch.rpm
yum install mysql-server -y  #此过程会因为网路问题偏慢，请耐心等待  
```

#### 配置
```bash
vim /etc/my.cnf  
[mysqld]
innodb_file_per_table   
```

#### 启动
```bash
service mysqld start  
```

#### 设置ROOT密码
```bash
mysql_secure_installation   

Enter current password for root (enter for none):
Set root password? [Y/n]
Remove anonymous users? [Y/n]
Disallow root login remotely? [Y/n]
Remove test database and access to it? [Y/n]
Reload privilege tables now? [Y/n]   
```

#### 创建zabbix数据库
```bash
mysql -uroot -p
mysql> CREATE DATABASE zabbix CHARACTER SET utf8 COLLATE utf8_bin;
mysql> GRANT ALL PRIVILEGES ON zabbix.* TO zabbix@localhost IDENTIFIED BY 'zabbix';
mysql> show databases;   
+--------------------+     
| Database           |     
+--------------------+     
| information_schema |     
| mysql              |     
| performance_schema |     
| zabbix             |     
+--------------------+
```

### 安装WEB

Zabbix 3.0对PHP的要求最低为5.4，而CentOS6默认为5.3.3，完全不满足要求，故需要利用第三方源将PHP升级到5.4以上。(注意:不支持PHP7)

ssh登录您的CentOS6 x64系统，使用root用户运行以下命令

#### 迁出RPM安装包

```bash
git clone https://github.com/zabbixcn/zabbix3.0-rpm.git
cd  zabbix3.0-rpm/RPMS
yum install zabbix-web-mysql-3.0.0-1.el6.noarch.rpm zabbix-web-3.0.0-1.el6.noarch.rpm
```

#### 升级PHP为5.6版本

安装软件源
```bash
rpm -ivh http://repo.webtatic.com/yum/el6/latest.rpm
```

如已安装PHP 5.3,先卸载

```bash
yum erase php php-mysql php-gd php-imap php-ldap php-odbc php-pear php-xml php-xmlrpc php-mcrypt php-mbstring php-devel php-pecl-memcached php-pecl-memcache  php-common php-pdo php-cli php-fpm libmemcached
```
安装PHP 5.6

```bash
yum install httpd php56w php56w-mysql php56w-gd php56w-imap php56w-ldap php56w-odbc php56w-pear php56w-xml php56w-xmlrpc php56w-mcrypt php56w-mbstring php56w-devel php56w-pecl-memcached  php56w-common php56w-pdo php56w-cli php56w-pecl-memcache php56w-bcmath php56w-fpm
```

修改时区

```bash
sed -i "s@# php_value date.timezone Europe/Riga@php_value date.timezone Asia/Shanghai@g" /etc/httpd/conf.d/zabbix.conf
```

#### 升级CURL

安装 
```bash
git clone https://github.com/zabbixcn/curl-rpm
cd curl-rpm/RPMS 
yum install curl-7.29.0-25.el6.x86_64.rpm  libcurl-7.29.0-25.el6.x86_64.rpm  libcurl-devel-7.29.0-25.el6.x86_64.rpm
```

验证
```bash
curl -V          

curl 7.29.0 (x86_64-redhat-linux-gnu) libcurl/7.29.0 NSS/3.16.1 Basic ECC zlib/1.2.3 libidn/1.18 libssh2/1.4.2
Protocols: dict file ftp ftps gopher http https imap imaps ldap ldaps pop3 pop3s rtsp scp sftp smtp smtps telnet tftp 
Features: AsynchDNS GSS-Negotiate IDN IPv6 Largefile NTLM NTLM_WB SSL libz 
```

### 安装Zabbix-Server

#### 安装

```bash
yum  localinstall  zabbix-server-mysql-3.0.0-1.el6.x86_64.rpm
```

#### 初始化Zabbix数据库

```bash
cd /usr/share/zabbix-server-mysql-3.0.0
zcat create.sql.gz | mysql -uzabbix -pzabbix zabbix
```

#### 配置数据库连接信息

```bash
vi /etc/zabbix/zabbix_server.conf
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=zabbix
```
#### 启动Zabbix-Server

```bash
/etc/init.d/zabbix-server restart
```

如果一切正常，日志会如下:

```bash
tail -n 100 /var/log/zabbix/zabbix_server.log
 28554:20160217:112307.419 Starting Zabbix Server. Zabbix 3.0.0 (revision 58460).
 28554:20160217:112307.419 ****** Enabled features ******
 28554:20160217:112307.419 SNMP monitoring:           YES
 28554:20160217:112307.419 IPMI monitoring:           YES
 28554:20160217:112307.419 Web monitoring:            YES
 28554:20160217:112307.419 VMware monitoring:         YES
 28554:20160217:112307.419 SMTP authentication:       YES
 28554:20160217:112307.419 Jabber notifications:      YES
 28554:20160217:112307.419 Ez Texting notifications:  YES
 28554:20160217:112307.419 ODBC:                      YES
 28554:20160217:112307.419 SSH2 support:              YES
 28554:20160217:112307.419 IPv6 support:              YES
 28554:20160217:112307.419 TLS support:               YES
 28554:20160217:112307.419 ******************************
 28554:20160217:112307.419 using configuration file: /etc/zabbix/zabbix_server.conf
 28554:20160217:112307.428 current database version (mandatory/optional): 03000000/03000000
 28554:20160217:112307.428 required mandatory version: 03000000
 28554:20160217:112307.436 server #0 started [main process]
 28556:20160217:112307.436 server #1 started [configuration syncer #1]
```

### 配置WEB

#### 启动Apache

```bash
/etc/init.d/httpd start
```

#### 访问zabbix web

浏览器访问`http://${IP}/zabbix`，进行配置即可，此处不再详解！
默认用户名/密码:`Admin/zabbix`(区分大小写)

![](http://www.hi-linux.com/img/linux/zabbix3.0.png)

### 安装客户端

```bash
yum install zabbix-agent-3.0.0-1.el6.x86_64.rpm zabbix-sender-3.0.0-1.el6.x86_64.rpm zabbix-get-3.0.0-1.el6.x86_64.rpm
```

### 其它

如果您是CentOS7或Ubuntu，请参考官方文档直接安装
> https://www.zabbix.com/documentation/3.0/manual/installation/install_from_packages

### 参考
> http://itnihao.blog.51cto.com/1741976/1742701