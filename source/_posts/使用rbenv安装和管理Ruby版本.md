---
title: 使用rbenv安装和管理Ruby版本
tags:
  - Ruby
  - Linux
categories: Ruby
abbrlink: 41737
date: 2016-04-19 09:00:00
updated:
toc_number:
---

如果你是Ruby开发者应该知道用rvm来安装/管理Ruby版本，同时也能用它的gemset功能来管理各个工程的gems。因为rvm过于强大以至于违背了某个Linux软件开发原则。所以出现了很多轻便的替代者，其中来自37signals的rbenv就很受欢迎。

rbenv可以帮助你在一台机器上建立多个版本的ruby环境， 并提供方便的切换方法。

注意：rbenv和rvm是不兼容的，所以安装rbenv之前要先把rvm卸载。

### 卸载rvm

```bash
$ rvm implode
```

然后再将你zsh或bash中的这一句去掉。

```bash
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm" # Load RVM function
```

<!-- more -->

### 安装rbenv

#### Linux下安装

rbenv的源代码托管在github，在终端中从 github上将rbenv源码clone到本地，然后设置`$PATH`。

```bash
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
Optionally, try to compile dynamic bash extension to speed up rbenv. Don't worry if it fails; rbenv will still work normally:
cd ~/.rbenv && src/configure && make -C src
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
```

注意:如果用Zsh，就用`~/.zshrc`替换`~/.bash_profile`。

重启shell或者运行`exec $SHELL`，就可以开始用rbenv了。

测试rbenv是否设置正常

```bash
$ type rbenv
#=> "rbenv is a function"
```

#### Mac下安装

如果你有安装Homebrew的话，可以用以下命令来安装rbenv和 ruby-build

```bash
$ brew install rbenv
$ brew install ruby-build
```

配置并初始化SHELL

```bash
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
```

注意:如果用 Zsh，就用`~/.zshrc`替换`~/.bash_profile`。

#### 更新rbenv

```bash
cd ~/.rbenv
git pull
```

### 安装ruby-build

使用ruby-build可以自动下载编译安装Ruby相应的版本，只需指定版本号。

ruby-build是一个rbenv插件，用来编译安装Ruby源码。提供了一个`rbenv install`命令编译和安装类UNIX系统不同版本的Ruby。如果选择手动编译，可不使用这个工具。


#### 安装编译ruby的依赖

Ubuntu

```bash
apt-get install autoconf bison build-essential libssl-dev libyaml-dev libreadline6 libreadline6-dev zlib1g zlib1g-dev
```

CentOS

```bash
yum install -y gcc openssl-devel libyaml-devel libffi-devel readline-devel zlib-devel gdbm-devel ncurses-devel
```

#### 安装ruby-build

```bash
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
cd ~/.rbenv/plugins/ruby-build
./install.sh
```

### rbenv使用

#### 安装Ruby

查看可用的ruby版本

```bash
rbenv install --list
```

安装2.3.0版本

```bash
rbenv install 2.3.0
```

等待一会儿，安装完毕后可以查看已经安装的所有Ruby版本

```bash
rbenv versions
* system (set by /root/.rbenv/version)
  2.3.0
```

显示所有版本，前面加*的为当前激活的版本。

#### 选择一个Ruby版本

rbenv中的Ruby版本有三个不同的作用域：全局(global)，本地(local)，当前终端(shell)。

查找版本的优先级是当前终端>本地>全局。

##### 设置全局版本

全局版本是在没有找到当前终端或本地作用域的设置时执行。通过以下命令设置

```bash
rbenv global 2.3.0
```

##### 设置本地版本

本地作用域是针对各个项目的，通过项目文件夹中的 .rbenv-version 这个文件进行管理，需要将相应的 Ruby 版本号写入这个文件。所以一般设置这个选项就可以了，这个过程可以通过以下命令执行

```bash
rbenv local 2.3.0
```

会在当前目录下生成`.rbenv-version`文件，此文件会覆盖`rbenv global`设定。

如果想取消的话，可以这样

```bash
rbenv local --unset
```

##### 设置当前终端版本

"当前终端"作用域的优先级最高。通过以下命令设置

```bash
rbenv shell 2.3.0
```

##### 使用系统Ruby

如果要使用系统原有的Ruby，则通过system指定

```bash
rbenv global system
```

每当切换ruby版本和执行bundle install之后必须执行这个命令

```bash
rbenv rehash
```

设置完毕后可以通过以下命令进行验证

```bash
which ruby  
# ~/.rbenv/shims/ruby
```

#### 列出目前使用的版本

```bash
rbenv version
#2.3.0 (set by RBENV_VERSION environment variable)
```

#### 列出irb这个命令的完整路径

```bash
rbenv which irb
```

#### 列出包含irb这个命令的版本

```bash
rbenv whence irb
```

#### 查看对应Ruby版主的目录

```bash
rbenv prefix
```

#### 卸载Ruby

直接用用rm -rf 命令删除`~/.rbenv/versions`文件夹下对应的Ruby版本即可

如果安装了 ruby-build 插件，那么使用如下命令即可

```bash
rbenv uninstall 2.3.0
```

#### 查看当前使用的ruby版本

```bash
rbenv version
```


#### 安装gem

使用rbenv后，gem还是按照原有的方式进行安装、升级，只是gem的安装路径是在~/.rbenv 文件夹中当前Ruby版本文件夹下。而且安装带有可执行文件的gem后，需要执行一个特别的命令，告诉rbenv更新相应的映射关系，这个命令在安装新版本的Ruby后也需要执行

```bash
rbenv rehash
```

安装rails

```bash
gem install bundler rails
```

检查安装后的软件版本

```bash
ruby -v gem -v rake -V rails -v
```

告诉Rubygems安装软件包的时候不安装文档

```bash
echo "gem: --no-ri --no-rdoc" > ~/.gemrc
```



### 一些好用的rbenv插件

ruby-build
自动编译安装ruby

```bash
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
```

gemset
管理gemset

```bash
git clone https://github.com/jf/rbenv-gemset.git  ~/.rbenv/plugins/rbenv-gemset
```

rbenv-gem-rehash
通过gem命令安装完gem后无需手动输入rbenv rehash命令

```bash
git clone https://github.com/rbenv/rbenv-gem-rehash.git ~/.rbenv/plugins/rbenv-gem-rehash
```

rbenv-update
通过rbenv update命令来更新rbenv以及所有插件

```bash
git clone https://github.com/rkh/rbenv-update ~/.rbenv/plugins/rbenv-update
```

rbenv-aliases

```bash
git clone https://github.com/tpope/rbenv-aliases.git ~/.rbenv/plugins/rbenv-aliases
```


### 故障排除

rbenv安装太慢的解决办法

rbenv+ruby-build插件，可以直接使用命令`rbenv install 2.3.0`安装对应的ruby版本。但这样太慢，很长时间都在下载。

解决方法

#### 使用国内镜像源

因为检查md5sum，所以需要在url后面加个#或者?

```bash
$env RUBY_BUILD_MIRROR_URL=https://ruby.taobao.org/mirrors/ruby/ruby-2.3.0.tar.gz# rbenv install 2.3.0
```

#### 使用wget下载

如果速度还慢，可以用wget先下载完成

```bash
$ wget -q https://ruby.taobao.org/mirrors/ruby/ruby-2.3.0.tar.gz -O ~/.rbenv/versions/ruby-2.3.0.tar.gz
$ env RUBY_BUILD_MIRROR_URL=file:///root/.rbenv/versions/ruby-2.3.0.tar.gz# rbenv install 2.3.0
```

### 参考文档

http://www.google.com
http://www.dreamxu.com/install-ruby-on-mac-with-rbenv/
http://www.4wei.cn/archives/1002162
http://iplayboy.tk/troubleshooting/2015-12/centos-install-jekyll.html
http://about.ac/2012/04/install-ruby-with-rbenv.html