---
category: openssh
title: 关于云服务器相同系统镜像模板中OpenSSH密钥相同的处理方法
date: 2017-02-13 09:00:00
tags: [linux, openssh]
updated:
toc_number: false
---

OpenSSH 通信过程中有两类证书会被使用，一是服务器端证书，共八个文件，四种加密类型 `rsa` 、`dsa` 、`ecdsa` 、`ed25519`。

> /etc/ssh/ssh_host_rsa_key       # RSA 密钥
> /etc/ssh/ssh_host_rsa_key.pub   # RSA 公钥
> /etc/ssh/ssh_host_dsa_key       # DSA 密钥
> /etc/ssh/ssh_host_dsa_key.pub   # DSA 公钥
> /etc/ssh/ssh_host_ecdsa_key     # ECDSA 公钥
> /etc/ssh/ssh_host_ecdsa_key.pub # ECDSA 密钥
> /etc/ssh/ssh_host_ed25519_key   # ED25519 公钥
> /etc/ssh/ssh_host_ed25519_key.pub # ED25519 密钥

服务器端证书的用途是加密传输数据，当客户端连接服务器端时，服务器端会选择一种加密协议，如 rsa ，并将服务器端的 RSA 公钥（`/etc/ssh/ssh_host_rsa_key.pub`）发送给客户端，客户端使用这个公钥将要发送给服务器端的数据（例如认证密码）加密，再通过网络传输给服务器端。服务器端再使用服务器端 RSA 密钥解开被加密的数据，得到明文。只有拥有这个 RSA 密钥的用户可以解开这个加密数据。

<!-- more -->

二是当用户使用证书认证时，上传到 `~/.ssh/` 目录的证书公钥，和保存在客户端主机上的证书密钥。客户端证书的用途是鉴定用户身份。

现在的问题是云主机服务商的系统镜像模板都是预安装了 openssh 服务器程序的，而服务器端证书一般是安装包里的脚本在安装时生成的。**换句话说就是相同系统镜像模板的系统 OpenSSH 的服务器端证书都一样！每个使用相同系统镜像模板用户都有能力拿到密钥，这是很危险的！**

解决方法也很简单，就是重新生成相应的证书。

- 对于CENTOS来说只要删除ssh的host key，重新启动ssh服务的时候，Centos的SystemV脚本会重新生成一个新的。

```bash
$ rm -v /etc/ssh/ssh_host_*
$ service sshd restart
```

- 对于Debian系统来说，则必须重新调用dpkg配置一下。

```bash
$ rm -v /etc/ssh/ssh_host_*
$ dpkg-reconfigure openssh-server
```

### 参考文档

http://www.google.com
https://hev.cc/2030.html#comment-447806
http://blog.ihipop.info/2017/02/4932.html
