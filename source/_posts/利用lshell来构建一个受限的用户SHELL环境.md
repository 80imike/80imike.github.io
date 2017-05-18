---
title: 利用lshell来构建一个受限的用户SHELL环境
tags:
  - SHELL
  - Linux
categories: SHELL
abbrlink: 6397
date: 2016-05-20 09:00:00
updated:
toc_number:
---

有些特殊情况下需要实现将系统内普通用户限定在指定目录下,并且只能使用系统管理员设定的命令。lshell就是实现这样功能的一个神器。

lshell提供了一个针对每个用户可配置的限制性shell，lshell的配置文件非常的简单，可以和`ssh`的`authorized_keys`或者`/etc/shell`、`/etc/passwd`耦合使用，lshell可以很容易的严格限制用户可以访问哪些命令。

项目地址: https://github.com/ghantoos/lshell

<!-- more -->

### lshell安装

RHEL、CentOS

```
$ yum install lshell #EPEL源
```

Debian、Ubuntu

```
$ apt-get install lshell
```

### lshell使用

- lshell语法格式

```
$ lshell --help
Usage: lshell [OPTIONS]
  --config <file> : Config file location (default /etc/lshell.conf)  #指定配置文件
  --log    <dir>  : Log files directory                              #指定日志目录
  -h, --help      : Show this help message                           #显示帮助信息
  --version       : Show version                                     #显示版本信息
```

- lshell配置

Linux下配置文件为`/etc/lshell.conf`

```
# lshell.py configuration file
#
# $Id: lshell.conf,v 1.27 2010/10/18 19:05:17 ghantoos Exp $

[global]
##  log directory (default /var/log/lshell/ )
logpath         : /var/log/lshell/
##  set log level to 0, 1, 2, 3 or 4  (0: no logs, 1: least verbose,
##                                                 4: log all commands)
loglevel        : 2
##  configure log file name (default is %u i.e. username.log)
#logfilename     : %y%m%d-%u
#logfilename     : syslog

##  in case you are using syslog, you can choose your logname
#syslogname      : myapp

[default]
##  a list of the allowed commands or 'all' to allow all commands in user's PATH
allowed         : ['ls','echo','cd','ll']

##  a list of forbidden character or commands
forbidden       : [';', '&', '|','`','>','<', '$(', '${']

##  a list of allowed command to use with sudo(8)
#sudo_commands   : ['ls', 'more']

##  number of warnings when user enters a forbidden value before getting 
##  exited from lshell, set to -1 to disable.
warning_counter : 2

##  command aliases list (similar to bash’s alias directive)
aliases         : {'ll':'ls -l', 'vi':'vim'}

##  introduction text to print (when entering lshell)
#intro           : "== My personal intro ==\nWelcome to lshell\nType '?' or 'help' to get the list of allowed commands"

##  configure your promt using %u or %h (default: username)
#prompt          : "%u@%h"

##  a value in seconds for the session timer
#timer           : 5

##  list of path to restrict the user "geographicaly"
#path            : ['/home/bla/','/etc']

##  set the home folder of your user. If not specified the home_path is set to 
##  the $HOME environment variable
#home_path       : '/home/bla/'

##  update the environment variable $PATH of the user
#env_path        : ':/usr/local/bin:/usr/sbin'

##  add environment variables
#env_vars        : {'foo':1, 'bar':'helloworld'}

##  allow or forbid the use of scp (set to 1 or 0)
#scp             : 1

## forbid scp upload
#scp_upload       : 0

## forbid scp download
#scp_download     : 0

##  allow of forbid the use of sftp (set to 1 or 0)
#sftp            : 1

##  list of command allowed to execute over ssh (e.g. rsync, rdiff-backup, etc.)
#overssh         : ['ls', 'rsync']

##  logging strictness. If set to 1, any unknown command is considered as 
##  forbidden, and user's warning counter is decreased. If set to 0, command is
##  considered as unknown, and user is only warned (i.e. *** unknown synthax)
#strict          : 1

##  force files sent through scp to a specific directory
#scpforce        : '/home/bla/uploads/'

##  history file maximum size 
#history_size     : 100

##  set history file name (default is /home/%u/.lhistory)
#history_file     : "/home/%u/.lshell_history"
```

- lshell的配置文件详解

> 配置文件一共有四个小节
> [global] -lshell的系统配置(只能有一个)
> [default] -lshell的默认用户配置(只能有一个)
> [foo] -指定UNIX的系统用户"foo"的特别的配置
> [grp:bar] -指定UNIX用户组"bar"的特别的配置
> 
> 当加载参数的时候遵循以下顺序
> 1.User configuration
> 2.Group configuration
> 3.Default configuration
> 
> logpath
> 日志路径(默认是/var/log/lshell/)
> 
> loglevel
> 日志记录级别,0, 1, 2, 3 or 4 (0: no logs -4: logs everything)
> 
> logfilename
> 如果设置成syslog关键字，则表示日志记录到syslog中
> 如果设置成一个文件名, e.g. %u-%y%m%d (i.e foo-20091009.log): 
> 
> %u -username
> %d -day [1..31]
> %m -month [1..12]
> %y -year [00..99]
> %h -time [00:00..23:59]
> 
> syslogname
> 如果你打算记录进syslog中，则要设置你的syslog名称，默认是lshell 
> 
> [default]或者[username]或者[grp:groupname] 三个小节可用的配置项
> 
> aliases
> 命令别名
> 
> allowed
> 一个允许执行的命令列表，或者设置成all，则允许在user PATH中的所有命令可用
>               
> allowed_cmd_path
> 一个路径组成的列表，所有在路径中的可执行文件都被允许
> 
> env_path
> 更新用户的环境变量PATH
> 
> env_vars
> 设置用户的环境变量
> 
> forbidden
> 一个非法字符或者命令组成的列表
> 
> history_file
> history的文件名,%u -username (e.g. '/home/%u/.lhistory')
> 
> history_size
> history文件记录的maximum size(in lines)
> 
> home_path (deprecated)
> 默认是$HOME，不赞成使用，下一版会取消。%u -username (e.g. '/home/%u')
> 
> intro
> 在登陆时打印出入门信息
> 
> login_script
> 用户登陆时执行的脚本
> 
> passwd 
> 指定用户的密码(默认为空)
> 
> path 
> 严格限制用户可以去的系统路径，可以使用通配符(e.g. '/var/log/ap*')
> 
> prompt
> 设置用户的prompt格式(default: username)
> %u -username
> %h -hostname
> 
> scp
> 允许或者禁止使用scp连接(0禁止、1允许)。
> 
> scpforce
> 强制文件通过scp传输到一个特定目录
> 
> scp_download
> 允许或者禁止使用scp下载(0禁止、1允许)。
> 
> scp_upload
> 允许或者禁止使用scp上传(0禁止、1允许,默认为1)。
> 
> sftp 
> 允许或者禁止使用sftp连接(0禁止、1允许)。
> 
> sudo_commands
> 一组命令组成的列表，用户可以执行sudo 
> 
> timer 
> 会话维持的秒数
> 
> strict 
> 日志严格记录，如果设置成1，任何unknow的命令都被禁止，并且降低用户警告数，如果设置成0，unknow命令只是警告。 (i.e. *** unknown synthax) 
> 
> warning_counter
> 警告次数，如果用户达到该警告次数，则会被强制退出lshell，设置成-1，则禁止计数。

- lshell下始终可使用的指令
   
```
清屏
clear

打印可用命令
help, ?

打印命令历史
history

列出所有允许和禁止的路径
lpath 

列出所有允许sudo的命令
lsudo
```

### lshell实例

为了记录用户日志，首先需要创建相关目录

```
$ groupadd --system lshell
$ mkdir /var/log/lshell
$ chown :lshell /var/log/lshell
$ chmod 770 /var/log/lshell
```

添加test用户

```
$ useradd test -d /home/test -s /usr/bin/lshell
```

然后增加test用户到lshell group

```
$ usermod -aG lshell test
```

改变test用户默认shell，使用lshell作为默认shell

```
$ chsh -s /usr/bin/lshell test
```

修改配置文件让test用户只能使用受限命令

```
[test]
allowed         : ['ls','echo','cd','ll']      ##允许使用的命令
home_path       : '/home/test'                 ##设置用户的家目录
path            : ['/home/test','/tmp']             ##限制用户的目录
```

`home_path`和`path`注释掉则限制用户只能访问自己的家目录及其子目录。如果需要能访问其他目录，则需要在path中加入相应的目录，当前设置下用户可以访问家目录及其子目录，也可以访问`/tmp`目录及其子目录，但不能访问这以外的目录，比如`/etc`。

`allowed`中添加我们限定用户所能使用的命令，这里限定只能使用`ls`、`echo`、`cd`、`ll`四个命令。


测试登陆

```
$ ssh test@127.0.0.1                                                    
test@127.0.0.1's password: 
You are in a limited shell.
Type '?' or 'help' to get the list of allowed commands
test:~$
```

命令使用

```
test:~$ cd /etc
*** forbidden path -> "/etc/"
*** You have 1 warning(s) left, before getting kicked out.
This incident has been reported.

test:~$ touch test.txt
*** unknown command: touch
```

### 参考文档

http://www.google.com
https://github.com/ghantoos/lshell
http://m.oschina.net/blog/337374