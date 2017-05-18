---
title: Ubuntu 14.04 sudo免密码的方法
tags:
  - sudo
  - Linux
categories: sudo
abbrlink: 8737
date: 2016-04-15 09:00:00
updated:
toc_number:
---

Ubuntu 14.04的方法与之前版本不太一样，Ubuntu建议把自定义部分内容放到/etc/sudoers.d目录，以减少对/etc/sudoers的错误修改，造成对系统的错误影响。

以用户名mike为例：具体实现方法如下

以下两种格式都可以

方法一

```bash
cd /etc/sudoers.d
sudo vi nopasswdsudo
mike ALL=(ALL) NOPASSWD : ALL
```
<!-- more -->
方法二

```bash
cd /etc/sudoers.d
sudo vi nopasswdsudo
mike  ALL=NOPASSWD: ALL    
```

保存后,这样使用sudo就不用一遍遍的输入密码了！



