---
title: Linux中SSH客户端登录缓慢的解决办法
tags:
  - Linux
  - SSH
  - 技巧
categories: Linux
abbrlink: 60599
date: 2016-03-15 09:51:54
---

今天在ssh登录到一台Linux服务器时，出现了登陆慢的问题，以前一直是正常的。

#### 一、问题

查看SSH日志中有如下错误提示,发现问题：

```bash
Connection closed by IP
```

使用debug模式`ssh -v ip`查看下ssh的连接过程，发现其中有这样一段提示：

```bash
debug1: Authentications that can continue: publickey,gssapi-keyex,gssapi-with-mic,password
debug1: Next authentication method: gssapi-keyex
debug1: No valid Key exchange context
debug1: Next authentication method: gssapi-with-mic
debug1: Unspecified GSS failure.  Minor code may provide more information
Cannot determine realm for numeric host address
 
debug1: Unspecified GSS failure.  Minor code may provide more information
Cannot determine realm for numeric host address
 
debug1: Unspecified GSS failure.  Minor code may provide more information
 
debug1: Unspecified GSS failure.  Minor code may provide more information
Cannot determine realm for numeric host address
```

可以看到，因为使用GSS认证导致认证失败重试造成登录缓慢。<!-- more -->

经过搜索，发现是SSH配置文件默认打开了GSSAPI Authentication，经过修改解决问题。

#### 二、解决办法：

- 临时解决办法：

在ssh登录时加上`"-o GSSAPIAuthentication=no"`参数

- 永久解决办法：

> 1.打开编辑ssh配置文件：`vim /etc/ssh/sshd_config`
> 2.在文件中查找`"GSSAPIAuthentication yes"`这一行，修改`"yes"`为`"no"`
> 3.保存退出
> 4.重启ssh后,登录正常。

> 补充:如果只是想针对某个用户来禁用GSSAPIAuthentication，只需要在用户目录下的.ssh目录中建立一个config文件，在文件中添加行`"GSSAPIAuthentication no"`即可。

经过修改，ssh登录开发机已经是秒登，如果有人ssh登录慢，可以试试这个简单的办法。

**关于GSSAPI：**
> GSSAPI是Generic Security Services Application Program Interface的缩写，译为通用安全服务应用程序接口，是ITEF的一个标准，这将允许不同的安全算法使用一个标准化的API来为网络产品提供加密认证。OPENssh 使用这个API并且底层的kerberos 5协议代码提供除了ssh_keys 的另一种ssh认证方式。


#### 三、其它一些SSH客户端登录缓慢的原因


- 如何通过关闭UseDNS选项加速SSH登录

> 通常情况下我们在连接OpenSSH服务器的时候假如UseDNS选项是打开的话，服务器会先根据客户端的IP地址进行DNS PTR反向查询出客户端的主机名，然后根据查询出的客户端主机名进行DNS正向A记录查询，并验证是否与原始 IP地址一致，通过此种措施来防止客户端欺骗。平时我们都是动态 IP不会有PTR记录，所以打开此选项也没有太多作用。我们可以通过关闭此功能来提高连接OpenSSH 服务器的速度。

服务端步骤如下：

- 编辑配置文件 /etc/ssh/sshd_config

```bash
vim /etc/ssh/sshd_config
找到 UseDNS选项，如果没有注释，将其注释
#UseDNS yes
添加
UseDNS no
```
- 保存配置文件

- 重启OpenSSH服务器
```bash
/etc/init.d/sshd restart
```




