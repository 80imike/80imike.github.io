---
title: 让Windows用上OMZ的神器Babun
tags:
  - babun
  - Shell
categories: babun
abbrlink: 57246
date: 2016-05-05 09:00:02
updated:
toc_number:
---

### 什么是babun

babun是windows上的一个第三方shell，在这个shell上面你可以使用几乎所有linux，unix上面的命令，他几乎可以取代windows的shell。用官方的题目说就是A Windows shell you will love!


![](http://www.hi-linux.com/img/linux/screen_zsh_update.png)
<!-- more -->
> babun的几个特点
> 
> 使用babun无需管理员权限
> 先进的安装包管理器(类似于linux上面的apt-get或yum)
> 预先配置了Cygwin和很多插件
> 拥有256色的兼容控制台
> HTTP(S)的代理支持
> 面向插件的体系结构
> 可以使用它来配置你的git
> 集成了oh-my-zsh
> 自动升级
> 支持shell编程，内置VIM等
> 
> Cygwin
> 
> babun的核心包括一个预配置的Cygwin。cygwin是一个非常好的工具，但有很多使用技巧，使你能够节省大量的时间。babun解决了很多问题，它里面包含了很多重要的软件包，是你能够第一时间能够使用它们。
> 
> 包的管理：
> babun的包管理在shell输入：pact，这类似于：apt-get或yum，来非常方便的管理软件包，安装、升级、搜索和删除，让你省区很多麻烦，shell输入pact --help能够获得帮助信息。
> 
> shell
> 
> babun的shell通过调整，已达到最佳的用户体验，babun有两个配置之后马上使用的shell(默认使用zsh)，babun的shell具有以下的特点
> 
> 语法高亮
> 具有unix的工具
> 软件开发工具
> git-语义提示
> 自定义脚本和别名
> 等等.........
> 
> Console
> 
> babun支持HTTP代理，只需添加地址和HTTP代理服务器的凭据。babunrc文件所在文件夹执行源babunrc启用HTTP代理。目前还不支持SOCKS代理。
> 
> 开发者工具
> 
> babun提供多种方便的工具和脚本，是你的开发工作更轻松，具有的功能如下
> 
> 编程语言(python,Perl, etc等)
> git(各种各样的别名调整)
> UNIX工具((grep, wget, curl, etc)
> vcs (svn, git)
> oh-my-zsh
> 自定义脚本(pbcopy, pbpaste, babun, etc)

babun官网链接：http://babun.github.io/

### 什么是cmder

cmder是window下的多标签命令行工具，可以方便的新建cmd、cmd admin、powershell、powershell admin多种命令行，设置很多，功能强大。


### 安装

#### cmder安装

下载：http://cmder.net/

cmder是开箱即用的软件就不在详述了，具体使用可参考官网说明。

#### babun安装

下载：http://babun.github.io/

##### 默认安装

下载完成之后解压babun，直接双击目录中install.bat脚本(需管理员权限)进行安装。几分钟之后自动安装完成，默认会被安装在`%userprofile%\.babun`目录下。

##### 自定义安装位置

通过cmd命令行在执行install.bat时指定参数/t或/target指定安装的目录。

执行：`babun.bat /t c:\babun`

安装好之后会在c:\babun目录下生成一个.babun的目录，babun所有文件都在这个目录中。注意安装目录最好不要有空格，这是cygwin要求的。

##### 测试安装成功

安装完毕后，一般需要以下两个命令检查

```
babun check(用于判断环境是否正确)
babun update(用于判断是否有新的更新包)
```
### Babun配置

默认根目录

```
%userprofile%\.babun\cygwin\home\Mike
```

#### windows cmd内置命令显示中文

babun默认编码是UTF-8的，而windows的cmd命令输出是GBK编码的，所以在Babun里面运行ipconfig等windows命令时，中文会是一大堆乱码。

![](http://www.hi-linux.com/img/linux/ipconfig-error1.png)


解决：在babun自带的shell(mintty)右上角右键options-text,在character set选择default或者GBK,之后执行ipconfig等cmd内置的命令时就正常显示中文了。

如果把Babun的编码改成GBK的话，命令的中文输出倒是正常了，PS1却会出现一个乱码字符，如图

![](http://www.hi-linux.com/img/linux/ipconfig-error2.jpg)

去掉命令提示符乱码

babun内置两个shell，默认是zsh,另一个是bash,设置成中文后命令提示符最后会有一个乱码字符，看着很不爽，要修改PS1变量去掉。把乱码字符替换为：>>

bash

```
vi /usr/local/etc/babun.bash
PS1="\[\033[00;34m\]{ \[\033[01;34m\]\W \[\033[00;34m\]}\[\033[01;32m\] \$( git rev-parse --abbrev-ref HEAD 2> /dev/null || echo "" ) \[\033[01;31m\]>>\[\033[00m\]"
```

zsh

```
vi ~/.oh-my-zsh/custom/babun.zsh-theme

PROMPT='%{$fg[blue]%}{ %c } \
%{$fg[green]%}$(  git rev-parse --abbrev-ref HEAD 2> /dev/null || echo ""  )%{$reset_color%} \
%{$fg[red]%}%(!.#.>>)%{$reset_color%} '
```

这样改好后命令提示符就变成： `{ ~ } >>`

**注：将编码修改成GBK后，ls命令中文文件名的会出现乱码。最好在Babun环境中使用UTF-8编码，ipconfig等windows指令用cmder或默认cmd执行就行了。**

#### 将Babun整合到ConEmu/cmder

在cmder窗口右上角右键Settings>Startup>Tasks,点+号添加一个新task，命名为babun。            

在Task parameters中填入

```
/icon "%userprofile%\.babun\cygwin\bin\mintty.exe" /dir "%userprofile%"
```

在Commands中填入以下任意一种都可以

```
#默认使用ZSH
%userprofile%\.babun\cygwin\bin\mintty.exe /bin/env CHERE_INVOKING=1 /bin/zsh.exe

#使用自定义mintty配置
%userprofile%\.babun\cygwin\bin\mintty.exe -t "%userprofile%\.babun\cygwin\etc\minttyrc"
```

保存后,建立一个新终端时选Babun就可用了。


#### 配置个性化的mintty

```
vim ~/.minttyrc

CursorType=block
Term=xterm-256color
Font=Source Code Pro Semibold
FontHeight=10
```

#### 开发环境配置

pip

Babun内置了Python、Perl等解释器。cygwin自带的python没有pip,需手动安装。

直接执行下面这个命令就好了。

```
wget https://bootstrap.pypa.io/get-pip.py -O - | python
```

有了pip就可以自由的安装诸如ipython之类的东西，还有包罗万象的类库。

#### 常用插件

Babun默认是安装了Oh My ZSH的，这里可以根据自身情况安装一些插件。具体可参考[利用Oh-My-Zsh打造你的超级终端](http://www.imike.me/2016/04/28/%E5%88%A9%E7%94%A8Oh-My-Zsh%E6%89%93%E9%80%A0%E4%BD%A0%E7%9A%84%E8%B6%85%E7%BA%A7%E7%BB%88%E7%AB%AF/)一文

### 包管理器使用

babun提供一个叫pact包管理工具，类似于linux上面的apt-get或yum的包管理工具。

pact使用语法

```
pact: Installs and removes Cygwin packages.

Usage:
  "pact install <package names>" to install given packages
  "pact remove <package names>" to remove given packages
  "pact update <package names>" to update given packages
  "pact show" to show installed packages
  "pact find <patterns>" to find packages matching patterns
  "pact describe <patterns>" to describe packages matching patterns
  "pact packageof <commands or files>" to locate parent packages
  "pact invalidate" to invalidate pact caches (setup.ini, etc.)
Options:
  --mirror, -m <url> : set mirror
  --invalidate, -i       : invalidates pact caches (setup.ini, etc.)
  --force, -f : force the execution
  --help
  --version
```

pact使用比较简单，不在详述了！

常用软件安装

```
#安装tmux
pact install tmux        

#安装screen
pact install screen

#安装zip
pact install zip

#安装svn
pact install subversion

#安装lftp命令
pact install lftp

#安装p7zip命令
pact install p7zip

#基于openssh的socks https代理
pact install connect-proxy

#安装linux基础命令行工具more/col/whereis等命令
pact install util-linux    

#安装dig命令
pact install bind-utils

#安装Telnet等常用网络命令
pact install inetutils  

#安装python环境
pact install python        
pact install python-crypto
```

这个包管理很方便，用法也简单，按照自己需要安装吧!


### 总结

Babun虽然没有多少技术创新，但是它博采众长，追求极致的体验，把其他同类软件狠狠的甩在了后面。Babun是近年来最好的在Windows下使用Linux Shell的一站式解决方案。

无论是被迫使用Windows的Linuxer，还是离不开Windows却又羡慕Linux下强大的命令行工具的PC用户，Babun都是一个不容错过的好东西，相信你们会爱上它的。


### 参考文档

http://www.google.com
http://babun.github.io/
http://www.cnblogs.com/Leekin/p/4830868.html
http://0x0d.im/archives/windows-build-linux-like-environment.html
