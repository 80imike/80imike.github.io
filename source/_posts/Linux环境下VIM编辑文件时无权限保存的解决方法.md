---
title: Linux环境下VI/VIM编辑文件时无权限保存的解决方法
tags:
  - VIM
  - Linux
categories: VIM
abbrlink: 46870
date: 2016-04-18 09:00:00
updated:
toc_number:
---

在Linux环境下，如果直接使用VI/VIM命令编辑没有修改权限的文件时，保存的时候就会提示用户无法进行保存操作，一般的解决方法只能是关闭文件重新以sudo权限打开该文件编辑后再保存(前提是用户具有sudo权限)。其实，在VI/VIM模式下通过一些简单的命令，就能在不关闭当前文件的情况下达到保存文件的目的。

**方法一**

```bash
输入命令:%! sudo tee % > /dev/null
按提示输入sudo权限密码
输入"L"(Load File)
输入:q命令退出
```
<!-- more -->

关于`%! sudo tee % > /dev/null`这条命令的说明如下

此命令是把当前文件(即%)作为stdin传给sudo tee命令来执行。

```bash
%　　　　　  #VI/VIM编辑的文件内容
!　　　　　　#执行一个外部命令
sudo　　　　 #以root权限执行命令
tee　　　　　#将标准输入(即通过管道过来的当前编辑的文件内容)输出到标准输出，同时写入到指定的文件中(即VI/VIM当前编辑的文件)
%　　　　　  #vim当中一个只读寄存器的名字，总保存着当前编辑文件的文件路径。
> /dev/null　   #将标准输出重定向到/dev/null(不输出显示)
```

**方法二**

```bash
:%!sudo bash -c "cat > '%'"
按提示输入sudo权限密码
输入"L"(Load File)
输入:q命令退出
```

更详细的解释可参考：http://feihu.me/blog/2014/vim-write-read-only-file/