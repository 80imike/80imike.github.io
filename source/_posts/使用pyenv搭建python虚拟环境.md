---
title: 使用pyenv搭建python虚拟环境
tags:
  - Python
  - Linux
categories: Python
abbrlink: 63429
date: 2016-04-25 09:00:00
updated:
toc_number:
---
pyenv可以帮助你在一台开发机上建立多个版本的python环境， 并提供方便的切换方法。

例如系统自带的Python是2.6，自己需要Python 2.7中的某些特性；此时需要在系统中安装多个Python，但又不能影响系统自带的Python，即需要实现Python的多版本共存，pyenv就是这样一个Python版本管理器。

pyenv项目地址: https://github.com/yyuu/pyenv

### 安装pyenv

#### 通过脚本自动安装方式


通过`https://github.com/yyuu/pyenv-installer`提供脚本进行自动安装
<!-- more -->
##### 安装

```
$ curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash
```

##### 添加环境变量

`PYENV_ROOT`指向pyenv检出的根目录，并向`$PATH`添加`$PYENV_ROOT/bin`以提供访问`pyenv`这条命令的路径(这里的shell配置文件(`~/.bash_profile`)依不同SHELL而需作修改,如Zsh：`~/.zshrc`)


BASH

```
$ echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
$ echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
$ echo 'eval "$(pyenv init -)"' >> ~/.bashrc
```

重启shell(因为修改了$PATH)

```
$ exec $SHELL
```

ZSH

```
$ echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
$ echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
$ echo 'eval "$(pyenv init -)"' >> ~/.zshrc
```

重启shell(因为修改了$PATH)

```
$ exec $SHELL
```

##### 更新

```
$ pyenv update
```

##### 卸载

```
#Uninstall: pyenv is installed within $PYENV_ROOT (default: ~/.pyenv). To uninstall, just remove it:
$ rm -fr ~/.pyenv
```

#### 手动安装方式

##### 安装

将pyenv检出到你想安装的目录。建议路径为`$HOME/.pyenv`

```
$ git clone git://github.com/yyuu/pyenv.git ~/.pyenv
```

##### 添加环境变量

`PYENV_ROOT`指向pyenv检出的根目录，并向`$PATH`添加`$PYENV_ROOT/bin`以提供访问`pyenv`这条命令的路径(这里的shell配置文件(`~/.bash_profile`)依不同SHELL而需作修改，如Zsh：`~/.zshrc`)

BASH

```
$ echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
$ echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
$ echo 'eval "$(pyenv init -)"' >> ~/.bashrc
```

重启shell(因为修改了$PATH)

```
$ exec $SHELL
```

ZSH

```
$ echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.zshrc
$ echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.zshrc
$ echo 'eval "$(pyenv init -)"' >> ~/.zshrc
```

重启shell(因为修改了$PATH)

```
$ exec $SHELL
```

##### 更新pyenv

```
$ cd ~/.pyenv
$ git pull
```

##### 删除特定版本Python

查找特定版本Python文件夹位置，之后直接删除即可。

```
$ pyenv prefix 3.4.3
$ rm -rf ~/.pyenv/versions/3.4.3
```

#### 包安装

##### Linux

```
$ pip install  --egg  pyenv
```

##### MAC

```
$ brew install pyenv
```

### pyenv可用的命令

#### 查看pyenv的命令

```
$ pyenv -h

commands    List all available pyenv commands
local       Set or show the local application-specific Python version
global      Set or show the global Python version
shell       Set or show the shell-specific Python version
install     Install a Python version using python-build
uninstall   Uninstall a specific Python version
rehash      Rehash pyenv shims (run this after installing executables)
version     Show the current Python version and its origin
versions    List all Python versions available to pyenv
which       Display the full path to an executable
whence      List all Python versions that contain the given executable
```

#### 使用

查看当前 pyenv 可检测到的所有版本，处于激活状态的版本前以`*`标示。

```
$ pyenv versions
 2.5.6
 2.6.8
*2.7.6 (set by /home/yyuu/.pyenv/version)
 3.3.3
 jython-2.5.3
 pypy-2.2.1
```

查看当前处于激活状态的版本，括号中内容表示这个版本是由哪条途径激活的（global、local、shell）

```
$ pyenv version
2.7.6 (set by /home/yyuu/.pyenv/version)
```


使用python-build(一个插件)安装一个Python版本，到`$PYENV_ROOT/versions`路径下。

```
$ pyenv install -v 2.7.3
```

建议添加`-v`参数用于显示细节。`python-build`会首先尝试从一个镜像站点下载包，此时可以去/tmp/python-build.xxx 里面关心一下下载速度。如果太慢，可以直接在shell里`ctrl-c`终止此次下载，然后`python-build`会自动去`python.org/ftp`下载。不一定哪个更快。

卸载一个版本

```
$ pyenv uninstall 2.7.3
```

为所有已安装的可执行文件 （如：~/.pyenv/versions/*/bin/*） 创建shims，因此，每当你增删了Python 版本或带有可执行文件的包(如 pip)以后，都应该执行一次本命令

```
$ pyenv install 2.7.3
$ pyenv rehash  #安装新版本的python或者其他二进制包后都需要运行
```

设置全局的 Python 版本，通过将版本号写入 ~/.pyenv/version 文件的方式。

```
$ pyenv global 3.4.0
```

设置面向程序的本地版本，通过将版本号写入当前目录下的`.python-version`文件的方式。通过这种方式设置的 Python 版本优先级较 global 高。pyenv会从当前目录开始向上逐级查找`.python-version`文件，直到根目录为止。若找不到，就用global版本。

```
$ pyenv local 2.7.3
$ pyenv local --unset #取消改变
```

设置面向shell的Python版本，通过设置当前shell的PYENV_VERSION环境变量的方式。这个版本的优先级比local和global都要高。`--unset`参数可以用于取消当前shell设定的版本。

```
$ pyenv shell pypy-2.2.1
$ pyenv shell --unset
```

查看pyenv可用的命令

```
$ pyenv commands
```


显示当前Python的安裝路径 

```
$ pyenv which python                 
```

#### 安装不同版本Python

查看可安装的版本

该命令会列出可以用pyenv安装的Python版本，仅列举几个

```
$ pyenv install --list

2.7.8   #Python 2最新版本
3.4.1   #Python 3最新版本
anaconda-2.0.1  #支持Python 2.6和2.7
anaconda3-2.0.1 #支持Python 3.3和3.4
```

其中形如x.x.x这样的只有版本号的为Python官方版本，其他的形如xxxxx-x.x.x这种既有名称又有版本后的属于衍生版或发行版。

安装Python的依赖包

在安装Python时需要首先安装其依赖的其他软件包，已知的一些需要预先安装的库如下。

在CentOS/RHEL/Fedora下:

```
$ yum install readline readline-devel readline-static
$ yum install openssl openssl-devel openssl-static
$ yum install sqlite-devel
$ yum install bzip2-devel bzip2-libs
```

安装指定版本

使用如下命令即可安装python 3.4.1

```
$ pyenv install 3.4.1 -v
```

该命令会从github上下载python的源代码，并解压到/tmp目录下，然后在/tmp中执行编译工作。若依赖包没有安装，则会出现编译错误，需要在安装依赖包后重新执行该命令。

对于科研环境，更推荐安装专为科学计算准备的Anaconda发行版 

安装2.x版本

```
$ pyenv install anaconda-2.1.0 
```

安装3.x版本

```
$ pyenv install anaconda3-2.1.0 
```

Anacoda很大，用pyenv下载会比较慢，可以自己到Anaconda官方网站下载，并将下载得到的文件放在`~/.pyenv/cache`目录下，则pyenv不会重复下载。

更新数据库

安装完成之后需要对数据库进行更新

```
$ pyenv rehash
```

查看当前已安装的python版本

```
$ pyenv versions
* system (set by /home/seisman/.pyenv/version)
3.4.1
```

其中的星号表示当前正在使用的是系统自带的python。

设置全局的python版本

```
$ pyenv global 3.4.1
pyenv versions
system
* 3.4.1 (set by /home/seisman/.pyenv/version)
```
当前全局的python版本已经变成了3.4.1。也可以使用pyenv local或pyenv shell临时改变python版本。


确认python版本

```
$ python
Python 3.4.1 (default, Sep 10 2014, 17:10:18)
[GCC 4.4.7 20120313 (Red Hat 4.4.7-1)] on linux
Type "help", "copyright", "credits" or "license" for more information.
>>>
```

使用python

输入python即可使用新版本的python；
系统自带的脚本会以`/usr/bin/python`的方式直接调用老版本的python，因而不会对系统脚本产生影响；
使用pip安装第三方模块时会安装到`~/.pyenv/versions/3.4.1`下，不会和系统模块发生冲突。
使用pip安装模块后，可能需要执行`pyenv rehash`更新数据库；

### Pyenv的pyenv-virtualenv插件

如果你是安装我们前面的方式安装pyenv的，那它已经帮我们以plugin的形式安装好了virtualenv, 我们只要使用就好了

pyenv virtualenv是pyenv的插件，为Unix系统上的python virtualenv提供`pyenv virtualenv`命令。它可以为pyenv管理的python版本运行提供隔离的虚拟环境，在此虚拟环境下的操作例如安装第三方模块以及修改库搜索路径等，都不会在原始的python环境里直接操作，从而保证了各python版本本身的纯净。

#### 安装pyenv-virtualenv插件

##### Linux

```
$ git clone https://github.com/yyuu/pyenv-virtualenv.git ~/.pyenv/plugins/pyenv-virtualenv
```

注:用pyenv自动安装脚本安装的已自带


##### MAC

```
$ brew install pyenv-virtualenv
$ brew install --HEAD pyenv-virtualenv
```

#### 添加环境变量

BASH

```
$ echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.bash_profile
```

重启SHELL启用pyenv-virtualenv

```
$ exec $SHELL
```

ZSH

```
$ echo 'eval "$(pyenv virtualenv-init -)"' >> ~/.zshrc
```

重启SHELL启用pyenv-virtualenv
```
$ exec "$SHELL"
```

#### pyenv-virtualenv使用

`pyenv-virtualenv`会为`pyenv`引入一些新命令，例如`virtualenv/virtualenv-delete`用户创建/删除虚拟环境，virtualenvs用于列出所有的虚拟环境，activate和deactivate用于激活/禁用已有虚拟环境，用于获取使用帮助：

```
$ pyenv help virtualenv
Usage: pyenv virtualenv [-f|--force] [VIRTUALENV_OPTIONS] [version] virtualenv-name
pyenv virtualenv --version
pyenv virtualenv --help
-f/--force       Install even if the version appears to be installed already
```

使用pyenv-virtualenv建立虚拟python环境

pyenv virtualenv依赖于通过pyenv已安装的python版本，只能建立已安装python版本的虚拟环境

查看可用python版本列表
```
$ pyenv versions
* system (set by /root/.pyenv/version)
2.7.9
3.4.2
3.4.2/envs/myenv
```

创建一个虚拟的python环境

创建一个名为myenv的虚拟python环境，其使用3.4.2的版本。

这条命令在本机上创建了一个名为myenv的python虚拟环境，这个环境的真实目录位于：`~/.pyenv/versions/`

```
$ pyenv virtualenv 3.4.2 myenv

Ignoring indexes: https://pypi.python.org/simple/
Requirement already satisfied (use --upgrade to upgrade): setuptools in /root/.pyenv/versions/3.4.2/envs/myenv/lib/python3.4/site-packages
Requirement already satisfied (use --upgrade to upgrade): pip in /root/.pyenv/versions/3.4.2/envs/myenv/lib/python3.4/site-packages
 Cleaning up...
```

注意，命令中的3.4.2必须是一个安装前面步骤已经安装好的python版本， 否则会出错。

然后我们可以继续通过pyenv versions 命令来查看当前的虚拟环境， 结果如下：

```
$ pyenv versions
* system (set by /root/.pyenv/version)
2.7.9
3.4.2
3.4.2/envs/myenv
myenv
```

这里我们可以看到， 除了已经安装的python版本， 我们多出了一个myenv的python虚拟环境。

仅查看python的虚拟环境

```
$ pyenv virtualenvs
3.4.2/envs/myenv (created from /root/.pyenv/versions/3.4.2)
myenv (created from /root/.pyenv/versions/3.4.2)
```

在当前工作目录激活虚拟环境myenv,此时Python版本自动变为3.4.2, 且是独立环境

```
$ pyenv activate myenv
(myenv) $ python --version
Python 3.4.2
```

接下来我们的python环境就已经切换到3.4.2的虚拟环境了， 运行python命令认证

```
$ python
Python 3.4.2 (r271:86832, May  9 2014, 01:07:17) 
[GCC 4.8.2] on linux3
Type "help", "copyright", "credits" or "license" for more information.
>>>
可以看到， python版本已经是3.4.2, 而且是在虚拟环境之中(myenv)
```

查看可用pip及其版本

```
(myenv) $ pip -V
pip 1.5.6 from /root/.pyenv/versions/3.4.2/envs/myenv/lib/python3.4/site-packages (python 3.4)
为当前虚拟环境使用pip命令安装一个第三方模块，例如pymysql和ipython
pip install pymysql
pip install ipython
```

运行ipython，并尝试导入pymysql模块，如果能导入成功，则表示模块已然就绪；

```
$ ipython
Python 3.4.2 (default, Nov 23 2015, 13:14:16)
Type "copyright", "credits" or "license" for more information.
     
IPython 4.1.1 -- An enhanced Interactive Python.
?         -> Introduction and overview of IPython's features.
%quickref -> Quick reference.
help      -> Python's own help system.
object?   -> Details about 'object', use 'object??' for extra details.
 
In [1]: import pymysql
In [2]:
```

如果要切换回系统环境， 运行这个命令即可

```
$ pyenv deactivate
```
那如果要删除这个虚拟环境呢？ 答案简单而且粗暴，只要直接删除它所在的目录就好：

```
$ rm -rf ~/.pyenv/versions/myenv/
```


顺带一提，Python3自带了一个叫做venv的虚拟环境模块，搭配pyenv使用简直爽

```
$ python3 -m venv venv  # 报错的话那就 python3 -m venv --without-pip venv
$ ln -s ./venv/bin/activate activate
$ . ./activate
```

### 参考

http://www.google.com/
https://github.com/yyuu/pyenv
http://m.oschina.net/blog/267469
https://blog.laisky.com/p/pyenv/
https://wp-lai.gitbooks.io/learn-python/content/0MOOC/pyenv.html
http://www.cnblogs.com/npumenglei/p/3719412.html
http://seisman.info/python-pyenv.html