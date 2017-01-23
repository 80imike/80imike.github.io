---
title: CentOS下使用MyTop实时监控MySQL
tags:
  - MyTop
  - MySQL
categories: MySQL
abbrlink: 26991
date: 2016-06-01 09:00:00
updated:
toc_number:
---

MyTop是一个类似Linux下的`top`命令风格的MySQL监控工具，MyTop采用Perl开发。MyTop可以监控MySQL当前的连接用户和正在执行的命令。

MyTop的项目页面为：http://jeremy.zawodny.com/mysql/mytop/

<!-- more -->

### MyTop安装

```
$ yum -y install mytop #epel源
```

### MyTop命令参数

```
$ man mytop

-u / --user <USERNAME>：指定 username，预设是 root
-p / --pass / --password <PASSWORD>：指定password，预设是none
-h / --host <HOSTNAME[:PORT]>：指定 MySQL server的hostname，预设是localhost
-P / --port <PORT>：指定连接 MySQL server的port，预设是3306
-s / --delay <SECONDS>：更新的秒数，预设是5秒
-d / --db / --database <DATABASE>：指定连接的资料库，预设是test
-b / --batch / --batchmode：指定为 batch mode，每次更新不会清除旧的显示结果，会将更新资料显示上最上方，预设是unset
-S / --socket <PATH_TO_SOCKET>：指定使用MySQL socket直接连线，而不使用TCP/IP连线，预设是none(当mytop和MySQL在同一台时才能使用)
--header or -noheader：是否要显示表头，预设是header
--color or --nocolor：是否要使用颜色，预设是color
-i / -idle or -noidle：idle 的thread是否要出现在清单上，预设是idle
```
注意: 因`.mytop`内有MySQL server的密码，请注意档案权限。

### MyTop的使用

- 命令行运行

```
$ mytop -uroot -pmysql -d wordpress -h 127.0.0.1

```

- 通过配置文件运行

MyTop配置文件在`~/.mytop`,也可在`~/.my.cnf`文件中配置用户名和密码。

```
$ vim ~/.mytop

user=root
pass=mysql
host=localhost
db=wordpress
delay=5
port=3306
socket=/var/lib/mysql//mysql.sock
batchmode=0
header=1
color=1
idle=1
```

注意:socket设置和my.cnf里的路径一样，一般MyTop和Mysql在同一台机器。

- MyTop远端监控

若将MyTop装在另一台机器上时，需要设定MySQL Server上的权限才能远端监控

在MySQL Server上新增一个帐号，并给它Process的权限

```
$ mysql -u root -p
mysql> grant process on *.* to <REMOTE_USERNAME>@<REMOTE_IP> identified by '<PASSWORD>';
mysql> flush privileges;
mysql> exit
```

在安装MyTop的机器上，用参数指定或修改配置文件的设定。

参数指定

```
$ mytop -u <REMOTE_USERNAME> -p <PASSWORD> -h <MYSQL_SERVER_IP>
```

修改配置文件

```
$ vim ~/.mytop

user=<REMOTE_USERNAME>
pass=<PASSWORD>
host=<MYSQL_SERVER_IP>
```

- MyTop快捷键

```
s：设定更新时间 
p：暂停画面更新
q：离开
u：只看某个使用者的thread
o：反转排列顺序
```

- 监控画面参数解释

Mytop和Linux下面的top命令展现的结果类似，下面展示了每个线程的当前的状态并且是动态变化。

```
$ mytop -uroot -pmysql -d wordpress -h 127.0.0.1

MySQL on 127.0.0.1 (5.6.29-log)                                                  up 0+05:44:42 [16:51:31]
 Queries: 654.0  qps:    0 Slow:     0.0         Se/In/Up/De(%):    00/00/00/00 
             qps now:    0 Slow qps: 0.0  Threads:    1 (   1/   0) 00/00/00/00 
 Key Efficiency: 100.0%  Bps in/out:   0.8/160.4   Now in/out:   9.7/ 2.0k

      Id      User         Host/IP         DB      Time    Cmd Query or State                                                                                                                                                                                                
       --      ----         -------         --      ----    --- ----------                                                                                                                                                                                                    
        8      root       localhost  wordpress         0  Query show full processlist  

```

- 第一行显示了主机名称，还有至今MySQL的运行时间(以`days hour:minutes:seconds`为格式)。
- 第二、三行的显示了Qps:每秒请求书、Slow:慢查询的数量、Se/In/Up/De(%)：读写比例。
- 第四行的Key Efficiency就是Myisam的键值缓存区使用比例(缓存命中率)，Bps:目前网络进出流量。
- 最下方的区域就是目前链接到数据库的各个线程，你可以按`k`杀死一个线程，或者按`f`了解特定线程的信息。

### 参考文档

http://www.google.com
http://jeremy.zawodny.com/mysql/mytop/mytop.html
http://dwchaoyue.blog.51cto.com/2826417/1636023
http://www.21andy.com/new/20100927/1970.html