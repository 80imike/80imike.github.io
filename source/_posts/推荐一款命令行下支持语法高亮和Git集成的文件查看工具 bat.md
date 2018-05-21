---
category: 工具
title: 推荐一款命令行下支持语法高亮和Git集成的文件查看工具 bat
date: 2018-05-14 09:00:00
tags: [Linux, 工具]
abbrlink:
updated:
toc_number: false
---

`bat` 是命令行下一款用来显示文件内容的工具，`bat` 命令功能跟常用命令 `cat` 类似。只是 `bat` 功能上更加强大一些，`bat` 在 `cat` 命令的基础上加入了行号显示、代码高亮和 Git 集成。

项目官方地址： `https://github.com/sharkdp/bat`

- bat 语法高亮显示效果

![](https://www.hi-linux.com/img/linux/bat1.png)

<!-- more -->

- bat 整合 Git 显示效果

![](https://www.hi-linux.com/img/linux/bat2.png)

**bat 安装**

`bat` 安装还是比较简单的，官方提供了多种多样的安装方式，比如二进制包、源码编译等常规安装方式。

- 通过二进制包安装

目前官方暂时只提供了 Debian 系的二进制安装包，如果你刚好使用的是这个系列的 Linux 发行版本，可直接下载安装即可。

```
$ wget https://github.com/sharkdp/bat/releases/download/v0.3.0/bat_0.3.0_amd64.deb
$ dpkg -i bat_0.3.0_amd64.deb
```

- 通过源码包安装

如果你使用的是其它的 Linux 发行版本，当然也是可以通过源码包的方式进行安装的。与传统的源码包安装方式不同的是这里使用的是 Cargo 来进行安装，因为 `bat` 是采用 Rust 语言开发的。

```
$ cargo install bat
```

> 1. 编译环境的 Rust 必须大于 1.24 版本。
> 2. Cargo 是一个 Rust 语言的包管理器。

- 通过 Homebrew 安装

macOS 下有 Homebrew 的加持，安装当然是非常简单的，只需以下一条命令就搞定了。

```
$ brew install bat
```

> 如果你不知道什么是 Homebrew，可在公众号搜索下相关文章。

**bat 使用**

- 显示单个文件

```
$ bat README.md
```

- 一次显示多个文件

```
$ bat src/*.rs
```

- 指定显示文件的语言类型

```
$ bat -l php index.php
```

**参考文档**

http://www.googel.com
https://github.com/sharkdp/bat/