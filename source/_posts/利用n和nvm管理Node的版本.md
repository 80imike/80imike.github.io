---
title: 利用n和nvm管理Node的版本
tags:
  - Node
  - Linux
categories: Node
abbrlink: 51355
date: 2016-04-07 09:00:00
updated:
toc_number:
---

### 使用nvm安装管理nodejs

本文将介绍如何使用nvm来安装管理nodejs运行环境，在不更改系统级配置的情况下，使普通用户可以在自己的用户目录下安装nodejs，多版本的nodejs不但可以同时共存，而且可以很方便地在多个版本之间进行切换。

#### nvm介绍

nvm全称Node Version Manager,它是通过shell脚本实现nodejs版本管理的。从他的名字可以看出来，他和rvm有着非常类似的设计思路。如果是需要管理Windows下的node，官方推荐是使用nvmw或nvm-windows。

官方网站地址是：https://github.com/creationix/nvm
<!-- more -->
#### nvm安装

nvm安装非常方便，输入以下命令即可完成安装

安装方式有两种

通过CURL

```bash
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.0/install.sh | bash
```

通过WGET

```bash
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.31.0/install.sh | bash
```

以上脚本会把nvm库clone到~/.nvm，然后会在~/.bash_profile, ~/.zshrc或`~/.profile末尾添加source，安装完成之后，你可以用以下命令来安装node.

以上命令会将nvm仓库克隆到~/.nvm目录，并将启动脚本添加到shell配置文件中(~/.bash_profile、 ~/.zshrc 或~/.profile)

你还可以通过参数NVM_SOURCE NVM_DIR NVM_PROFILE 进行自定义安装，比如`curl ... | NVM_DIR=/usr/local/nvm sh`

通过源码手动安装

```bash
$git clone https://github.com/creationix/nvm.git ~/.nvm
$cd ~/.nvm

将以下内容加入到shell配置文件中，根据环境不同，可能是~/.bashrc, ~/.profile, 或 ~/.zshrc

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
```

#### nvm使用

安装

首先使用nvm ls-remote命令查看当前都支持哪些版本的 nodejs，会输出很长很长的一堆，挑一个最新的稳定版，使用 nvm install 命令安装上即可。

```bash
$ nvm ls-remote
  ....
  v4.4.0
  ....
```

安装指定版本

```bash
$nvm install v4.4.0
```

在输出一个进度条之后，这个版本的nodejs 就安装好了

```bash
$node -v
v4.4.0
```

安装最新稳定版node

```bash
nvm install stable
```

删除某版本的node

```bash
nvm uninstall 4.4.0
nvm uninstall default
```

设置默认版本

nvm使用default的alias来实现默认版本，只要执行个命令

```bash
nvm alias default v4.4.0
```

以后再登录进系统时，就默认使用的是nodejs v4.4.0这个版本了

使用指定的版本

```bash
$nvm use 5.10.1
```

使用别名设置的默认的版本

```bash
$nvm use default
```

查看当前已经安装的版本

```bash
$nvm ls
->       v4.4.0
        v5.10.1
default -> v4.4.0
node -> stable (-> v5.10.1) (default)
stable -> 5.10 (-> v5.10.1) (default)
```

查看正在使用的版本

```bash
$nvm current
v4.4.0
```

以指定版本执行脚本

```bash
$nvm run 4.4.0 myApp.js
```

卸载nvm

```bash
$rm -rf ~/.nvm
```

在不同版本下安装模块

切换至4.4.0版本

```bash
nvm use 4      #版本名可简写
```

安装mz-fis模块至全局目录,安装完成的路径是~/.nvm/versions/node/v4.4.0/lib/node_modules/mz-fis

```bash
npm install -g mz-fis 
```

切换至5.10版本

```bash
nvm use 5     #版本名可简写
```

安装react-native-cli模块至全局目录,安装完成的路径是~/.nvm/versions/node/v5.10.1/lib/node_modules/react-native-cli 

```bash
npm install -g react-native-cli
```

你还可以在你的项目根目录中新建.nvmrc文件来存放node版本，然后在该目录运行

```bash
$nvm use
```

使用.nvmrc文件配置项目所使用的node版本

如果你的默认node 版本(通过 nvm alias 命令设置的)与项目所需的版本不同，则可在项目根目录或其任意父级目录中创建.nvmrc文件，在文件中指定使用的node 版本号，例如：

```bash
cd  <项目根目录>  #进入项目根目录
echo 4 > .nvmrc #添加 .nvmrc 文件
nvm use #无需指定版本号，会自动使用 .nvmrc 文件中配置的版本
node -v #查看 node 是否切换为对应版本
```

恢复使用系统安装的版本，撤销nvm使用的版本

```bash
$nvm deactivate
```

指定安装源

```bash
$export NVM_NODEJS_ORG_MIRROR=http://nodejs.org/dist
$nvm install 0.10
#或者
$NVM_NODEJS_ORG_MIRROR=http://nodejs.org/dist nvm install 0.10
```

### 使用n安装管理nodejs

n是非常简单易用的node版本管理器,Node的一个模块，作者是TJ Holowaychuk(鼎鼎大名的Express框架作者)，就像它的名字一样，它的理念就是简单:[no subshells, no profile setup, no convoluted api, just simple]

#### 安装

```bash
$npm install -g n
```

安装完成之后，直接输入n后输出当前已经安装的node版本以及正在使用的版本(前面有一个o)，你可以通过移动上下方向键来选择要使用的版本，最后按回车生效。

```bash
$ n
    0.10.1 
    0.10.15 
o   0.10.21 
    0.11.8
```
	
通过源代码安装

方法一

```bash
curl -L http://git.io/n-install | bash
```

方法二

```bash
$git clone https://github.com/visionmedia/n.git
$cd n
$make install
```

如果需要安装到指定目录，需要在安装前增加PREFIX前缀

将n安装到~/bin/n

```bash
$PREFIX=$HOME make install
```

#### n使用

如果你要安装其他的版本(比如0.11.12)，那么如下

```bash
$ n 0.11.12
install : 0.11.12
   mkdir : /usr/local/n/versions/0.11.12
   fetch : http://nodejs.org/dist/v0.11.12/node-v0.11.12-darwin-x64.tar.gz
####                                                     5.9%
```

安装最新的版本

```bash
$n latest
```

安装稳定版本

```bash
$n stable
```

注：通过n安装的node存放在/usr/local/n/versions目录中。

查看可使用和安装的node版本

```bash
n ls
```

删除某版本node

```bash
$n rm 0.10.26 v0.11.12
或者
$n - 0.11.12
```

以指定的版本来执行脚本

```bash
$n use 0.10.21 some.js
$n use 0.11.12 --harmony some.js #带参数
```

切换到之前的版本

```bash
$n prev
```

查看某版本node的安装路径

```bash
$n bin 0.11.12
/usr/local/n/versions/0.11.12/bin/node
```

命令别名

```bash
which   bin
use     as
list    ls
-       rm
```

### nvm与n的区别

n命令是作为一个node的模块而存在，而nvm 是一个独立于node/npm的外部 shell 脚本，因此n命令相比nvm更加局限。

由于npm安装的模块路径均为/usr/local/lib/node_modules ，当使用n切换不同的node版本时，实际上会共用全局的node/npm目录。 因此不能很好的满足按不同node版本使用不同全局node模块的需求。因此建议各位尽早开始使用nvm，以免出现全局模块无法更新的问题。

不要在使用nvm的同时，再去使用n，这将会导致node版本混乱，反之亦是如此。根据自己的喜好和习惯，选择其一。

### 参考

http://www.google.com
https://github.com/creationix/nvm
https://github.com/tj/n
http://weizhifeng.net/node-version-management-via-n-and-nvm.html

