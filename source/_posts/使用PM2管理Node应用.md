---
title: 使用PM2管理Node应用
tags:
  - Nodejs
  - Linux
categories: Nodejs
abbrlink: 20296
date: 2016-03-24 09:00:01
updated:
---

### 简介

Node.js应用能够简单地通过命令行启动，只要有Node 运行环境。对于生产环境，情况要复杂得多。不仅需要数据库等功能性组件，更对安全性、可靠性、可扩展性等方面有更高的要求。

PM2是一个针对Node应用且自带负载均衡的进程管理器，拥有forever和Upstart都不具备的特性。能够管理Node 应用，使其随系统启动，出错挂掉能自动重启。还能对应用的运行状态进行监控，为应用生成SystemV, SystemD 服务启动脚本。PM2支持CoffeeScript，可以运行在Linux和OSX环境。

PM2是非常优秀工具，它提供对基于node.js的项目运行托管服务。它基于命令行界面，提供很多特性：
<!-- more -->
> 内置的负载均衡器（使用nodecluster module）
> 以守护进程运行
> 0s(不间断)重启
> 为ubuntu/CentOS 提供启动脚本
> 关闭不稳定的进程（避免无限死循环）
> 基于控制台监控
> HTTP API
> 远程控制以及实时监控接口
> pm2使用nodecluster构建一个内置的负载均衡器。部署多个app的实例来达到分流的目的以减轻单app处理的压力。

### 安装
```bash
npm install pm2 -g
npm install pm2@latest -g
npm install git://github.com/Unitech/pm2#master -g
```

### 升级安装
```bash
npm install pm2@latest -g
pm2 update  #Update in memory pm2
```

### 启动应用
```bash
pm2 start <app_name|id|all>  #可以指定应用名称pm2 start app,js --name=test
pm2 start app.js -i 4 --name "episode"   #-i 4 表示启动四个app.js, 也可以-i max 将会最大限度利用cpu核心数目 --name 用于命名进程
pm2 start app.js
pm2 start app.js -i 1  #cluster_mode
pm2 start app.js -i 0  #支持使用多核 CPU
pm2 start big-app.js --max-memory-restart 20M
cluster_mode 需要Node 0.11.x 以上，否则请用fork mode。
```

### 传递参数
```bash
pm2 start app.js -- -p 8080 
pm2 start app.js --node-args="--debug=7001 --trace-deprecation"
```

### 命名应用
```bash
NODE_ENV=production pm2 start index.js -n Ghost
```

### 生成服务脚本
```bash
pm2 startup <ubuntu|centos|gentoo|systemd>  #产生init脚本，保持进程活着
```

### 查看信息
```bash
pm2 list          # 显示所有进程状态
pm2 jlist         # Print process list in raw JSON
pm2 prettylist    # Print process list in beautified JSON
pm2 info 0        # Display all informations about a specific process
```

### 运行控制
```bash
pm2 stop 0             # 停止指定进程
pm2 stop all           # 停止所有进程
pm2 restart 0          # Restart specific process id
pm2 restart all        # 重启所有进程
pm2 delete 0           # Will remove process from pm2 list
pm2 delete all         # Will remove all processes from pm2 list
pm2 reload 0           # 类似restart，0秒重载，支持 cluster_mode
pm2 reload all         # Will 0s downtime reload (for NETWORKED apps)
pm2 gracefulReload all # Send exit message then reload (for networked apps)
pm2 dump               # ~/.pm2/dump.pm2
pm2 kill               # 杀掉PM2
pm2 resurrect          # 复活所有进程
```

### 代码监控
```bash
pm2 start app.js --watch  # 代码修改自动重启
pm2 stop 0                # not stop watching
pm2 stop --watch 0        # stop watching
```

### 运行监测
```bash
pm2 monit              # Monitor all processes
```

### 日志
```bash
pm2 logs               # 显示所有进程日志
pm2 ilogs              # Advanced termcaps interface to display logs
pm2 flush              # Empty all log file
pm2 reloadLogs         # Reload all logs
```

### 杂项
```bash
pm2 ping  # Ensure pm2 daemon has been launched
pm2 reset <process>  # Reset meta data (restarted time...)
pm2 sendSignal SIGUSR2 my-app  # Send system signal to script
pm2 start app.js --no-daemon  # run pm2 daemon in the foreground
pm2 describe id|all #查看启动程序的详细信息
pm2 web  #API(端口:9615)
```

### 实例

管理Ghost

```bash
cd /path/to/ghost/folder
echo "export NODE_ENV=production" >> ~/.profile
source ~/.profile
pm2 kill
pm2 start index.js --name "Ghost"

#Ghost已经运行在PM2管理下
pm2 ls
pm2 stop <process ID>
pm2 monit
pm2 logs

#生成服务启动脚本：/etc/init.d/pm2-init.sh。只会将pm2 list中的应用加入服务启动脚本，确保需要启动的应用就在其中。不要使用root账户(下面用的是ghost账户)。
pm2 startup ubuntu

#生成命令如下：包含node路径，用户账户。执行即可
sudo env PATH=$PATH:/usr/local/bin pm2 startup ubuntu -u ghost
pm2 save或reboot
```

### 参考资料
http://www.google.com
https://github.com/Unitech/pm2
http://www.allaboutghost.com/keep-ghost-running-with-pm2/