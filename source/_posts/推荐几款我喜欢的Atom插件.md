---
category: Atom
title: 推荐几款我喜欢的Atom插件
date: 2017-05-05 09:00:00
tags: [技巧,Atom]
abbrlink:
updated:
toc_number: false
---

Atom是一个由GitHub开发的开源编辑器，采用MIT证书授权方式。支持OS X、Windows和Linux操作系统。Atom具有很强的扩展性，插件和主题非常丰富。Atom使用其内建的apm软件包管理器管理软件包和主题。

从TextMate转为使用Atom也有一段时间了，Atom越用越顺手。这里将我经常使用的一些插件分享给大家。

**主题类**

- atom-material-ui

一个好用好看的MD风格的主题。

- atom-material-syntax

atom-material-syntax用于语法高亮，配合Atom Material UI主题使用会更加完美。

<!-- more -->

**插件类**

- activate-power-mode

一个可以让你打字的时候体验狂拽酷炫的效果的插件

- atom-beautify

一个可以快速美化代码排版本的神器，支持HTML, CSS, JavaScript, PHP, Python, Ruby, Java, C, C++, C#, Objective-C,SQL等语言。

- atom-open-recent

给Atom增加一个打开最近文件的功能，默认情况下Atom是没有这个功能。

- file-icons

在Atom中显示文件类型对应的图标。

- highlight-selected

高亮显示所有和选中文本一样的文本，很适用的插件。

- language-docker

支持Dockerfile文件中的语法高亮。

- linter

linter是一语法检查插件，它可以识别大部分语法，并对你的语法错误进行纠正。linter只是一个框架，针对不同语言的有不同具体插件。

- linter-docker

基于inter，针对Dockerfile做语法检查。

- linter-shellcheck

基于inter，针对shell做语法检查。

- markdown-preview-enhanced

非常强大markdown实时预览插件，强烈推荐。

- markdown-writer

给Atom增加一个markdown编辑器，让编辑markdown更加方便直观。

- platformio-atom-ide-terminal

给Atom增加一个好用的终端，需要用命令行的时候非常方便。

- qolor

一个给SQL语法高亮的插件。

- split-diff

文本比较工具，可比较两个窗口里的文档内容。

- sync-settings

Atom的插件备份神器，可将已安装的插件的配置信息自动备份到gist。

**一些技巧**

由于Atom插件官方源是是放在S3上的，国内安装会很慢。目前国内好像也没有镜像，推荐用ProxyChains+APM的方法安装。

```
$ proxychains4 apm install packages
```

如果你不知道ProxyChains是什么，可以参考下 「[通过ProxyChains-NG实现终端下任意应用代理](https://www.hi-linux.com/posts/48321.html)」 一文 。

最后给一张我的Atom的美图：

![](https://www.hi-linux.com/img/linux/atom1.png)

你在Atom上用过哪些优秀的插件呢？欢迎大家留言讨论~
