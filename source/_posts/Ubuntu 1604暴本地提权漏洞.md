---
category: Ubuntu
title: Ubuntu 16.04 暴本地提权漏洞
date: 2018-03-17 09:00:00
tags: [Linux, Ubuntu]
abbrlink:
updated:
toc_number: false
---

**漏洞简介**

Twitter 上 Nikolenko 发推表示 Ubuntu 最新版本存在一个本地提权漏洞，攻击者通过该漏洞可以直接获取 root 权限。该漏洞（CVE-2017-16995）早在老版本中已经完成修复，但是在 Ubuntu 16.04 版本中依旧可以被利用。

![](https://www.hi-linux.com/img/linux/ubuntu1604-0.png)

**影响范围**

目前已知范围:

- Ubuntu 16.04
- Linux Kernel Version 4.14-4.4 （主要影响 Debian 和 Ubuntu 发行版，Redhat 和 CentOS 不受影响。）

<!-- more -->

**漏洞复现**

![](https://www.hi-linux.com/img/linux/ubuntu1604-1.png)

POC 下载链接：https://www.hackersb.cn/usr/uploads/2018/03/1930063493.zip

**修复方案**

- 风险临时缓解方案

Ubuntu 官网暂时没有提供修复方案，建议用户在评估风险后通过修改内核参数限制普通用户使用  bpf(2) 系统调用来临时修复此漏洞。

```
$ echo 1 > /proc/sys/kernel/unprivileged_bpf_disabled
```

![](https://www.hi-linux.com/img/linux/ubuntu1604-2.png)

Ubuntu 官方补丁更新请及时关注漏洞公告：https://usn.ubuntu.com/

- 彻底根治方案

目前阿里云 xenial-proposed 源已提供补丁修复此漏洞，具体方法如下：

首先添加 xenial-proposed 软件源：

1. 公网网络环境下添加以下软件源

```
$ echo "deb http://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse" >> /etc/apt/sources.list
```

2. 阿里云经典网络环境下添加以下软件源

```
$ echo "deb http://mirrors.aliyuncs.com/ubuntu/ xenial-proposed main restricted universe multiverse" >> /etc/apt/sources.list
```

3. 阿里云VPC网络环境下添加以下软件源

```
$ echo "deb http://mirrors.cloud.aliyuncs.com/ubuntu/ xenial-proposed main restricted universe multiverse" >> /etc/apt/sources.list
```

其次执行以下命令更新内核：  

```
$ apt update && apt install linux-image-generic
```

最后重启机器：  

```
$ reboot
```

重启完成后，使用 `uname -r` 检测内核是否更新，如果内核版本为 `4.4.0-117` 即修复成功。

![](https://www.hi-linux.com/img/linux/ubuntu1604-3.png)

**参考文档**

http://www.google.com
http://t.cn/RnL8uPM
http://t.cn/RnyjN39
https://www.hackersb.cn/linux/244.html





