---
title: CentOS7开机加载内核模块
tags:
  - CentOS
  - Linux
categories: CentOS
abbrlink: 60936
date: 2016-04-15 09:00:00
updated:
toc_number:
---

以bridge模块为例

```bash
$ cd /etc/sysconfig/modules/
```

新建一个bridge.modules文件并添加如下内容

```bash
$ vim bridge.modules

#！/bin/sh 
/sbin/modinfo -F filename bridge > /dev/null 2>&1 
if [ $? -eq 0 ]; then 
    /sbin/modprobe bridge 
fi
```
<!-- more -->
增加执行权限

```bash
$chmod 755 bridge.modules   //这一步至关重要
```

重启系统

```bash
$reboot
```

验证模块是否加载

```bash
$ lsmod|grep bridge
bridge                119562  0 
stp                    12976  1 bridge
llc                    14552  2 stp,bridge
```

就可以看到bridge模块被加载到系统中。