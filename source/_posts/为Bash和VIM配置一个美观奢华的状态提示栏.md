---
title: 为Bash和VIM配置一个美观奢华的状态提示栏
tags:
  - Powerline
  - Linux
categories: Powerline
abbrlink: 49092
date: 2016-04-22 09:00:00
updated:
toc_number:
---
Powerline是使用Python所开发的一个外挂小工具，支援各种常见的Shell与应用程式，可以产生非常漂亮的提示字串与状态列文字，让终端机的文字看起来更舒服。除了Vim 之外也可以用于各种Shell 与应用程式中，如`zsh`、`bash`、`tmux`、`IPython`、`Awesome`与`Qtile`。

### 安装Powerline

Powerline 在使用前需要进行一些安装步骤。

#### 自动安装

如果您是使用Ubuntu Linux 14.10以后的版本，建议可以直接使用universe repository所打包好的套件自动安装：

```
sudo apt-get install powerline
```

只要执行这一行就装好了。<!-- more -->

#### 手动安装

##### 安装pip和git

首先安装Python的pip与git，若是Debian系列的 Linux(Ubuntu、Mint)则可用 apt 安装 python-pip 与 git 套件：

```
sudo apt-get install python-pip git
```

Red Hat系列的Linux(CentOS、RHEL、Fedora)，则可使用yum 安装：

```
sudo yum install python-pip git
```

若是Fedora Linux 22以后的版本，则可用dnf安装：

```
sudo dnf install python-pip git
```

##### 安装Powerline

使用pip安装Powerline：

```
pip install --user powerline-status
```

如果要取得最新的开发者版本，可以执行：

```
pip install --user git+git://github.com/powerline/powerline
```

#### Teriminal字体配置

执行完上面两步后，不出意外powerline就已经开始工作了。但是你会发现Bash提示符会和下图一样是一些非常恶心的符号,
出现这样情况的原因是powerline为了美观自己造了一些符号，而这些符号不在Unicode字库内。所以想要powerline正常显示的话，需要安装特殊处理过的字体。

1.Linux、MAC下字体配置

方法一

下载最新的Powerline字型以及fontconfig字型设定档：

```
wget https://github.com/powerline/powerline/raw/develop/font/PowerlineSymbols.otf
wget https://github.com/powerline/powerline/raw/develop/font/10-powerline-symbols.conf
```

将PowerlineSymbols.otf这个字型放进自己的字型目录：

```
mv PowerlineSymbols.otf ~/.fonts/
```

更新字型缓存：

```
fc-cache -vf ~/.fonts/
```

将字型设定档放进适当的目录：

```
mv 10-powerline-symbols.conf ~/.config/fontconfig/conf.d/
```

方法二

github上已有大部分打上了powerline patch的常用的等宽字体，首先我们从github上下载并安装字体：

```
#推荐字体Sauce Code Powerline Semibold.otf
shell> git clone https://github.com/powerline/fonts.git
shell> cd fonts
shell> ./install.sh
```

安装完成后我们就可以在iTerm2或者Terminal的字体选项里看到并选择多个xxx for powerline的字体了。*注意：对于ASCII fonts和non-ASCII fonts都需要选择for powerline的字体。如下图：

![](https://www.hi-linux.com/img/linux/powerlinefonts.png)

2.Windows字体

Win7

下载[consolas-powerline](https://github.com/eugeii/consolas-powerline-vim) 

```
git clone https://github.com/eugeii/consolas-powerline-vim.git
```

安装这几个字体到系统fonts文件夹下即可。

PS:区分两个系统不同的字体下载是因为网上有文档说在Windows下安装powerline fonts有可能不生效。我WIN10实测[powerline fonts](https://github.com/powerline/fonts)中的字体也可用于Windows系统。

### 使用Powerline

以下介绍Bash Shell与Vim 的使用方式，其他的应用可参考Powerline官方的[说明文件](https://powerline.readthedocs.org/en/latest/)。

查看powerline所处的具体路径

```
#pip show powerline-status
Metadata-Version: 1.0
Name: powerline-status
Version: 2.3
Summary: The ultimate statusline/prompt utility.
Home-page: https://github.com/powerline/powerline
Author: Kim Silkebaekken
Author-email: kim.silkebaekken+vim@gmail.com
License: MIT
Location: /usr/lib/python2.6/site-packages
Requires:
```

#### Bash Shell

方法一

安装好Powerline之后，若要在Bash Shell中使用，只要在~/.bashrc 中加入下面这段程式码：

```
POWERLINE_SCRIPT=/usr/lib/python2.6/site-packages/powerline/bindings/bash/powerline.sh
if [ -f $POWERLINE_SCRIPT ]; then
  source $POWERLINE_SCRIPT
fi
```

然后再关闭终端机，重新开启(或是登出再登入)后就可以看到Powerline的效果了。

方法二

配置方法很简单，只需要在Bash配置文件(例如：/etc/bashrc，~/.bashrc，~/.bash_profile)中增加一行调用安装路径下的bindings/bash/powerline.sh即可。这样每次调用生成新的Bash窗口时，都会自动执行powerline.sh文件中的内容。下面以~/.bash_profile为例：
```
shell> echo << EOF >> ~/.bash_profile 
. /usr/lib/python2.6/site-packages/powerline/bindings/bash/powerline.sh
EOF

shell> . /usr/lib/python2.6/site-packages/powerline/bindings/bash/powerline.sh
```

注意：根据python安装方式的不同，你的powerline所在路径也可能不同。如果你是通过python官网或者apple store通过安装工具安装的python，那么你的powerline安装路径就是`/Library/Python/2.7/site-packages/powerline/`。如果你是通过`brew install python`的话，那么你的powerline路径可能会有不同。请根据实际情况修改上面的命令。


#### ZShell

安装好Powerline之后，若要在ZSH Shell中使用，只要在~/.zshrc中加入下面这段程式码：

```
POWERLINE_SCRIPT=/usr/lib/python2.6/site-packages/powerline/bindings/zsh/powerline.zsh 
if [ -f $POWERLINE_SCRIPT ]; then
  source $POWERLINE_SCRIPT
fi
```

然后再关闭终端机，重新开启(或是登出再登入)后就可以看到Powerline的效果了。

##### Oh-My-Zsh

如果你用Oh-My-Zsh就更方便了,oh-my-zsh本身的agnoster主题就支持Powerline

这里推荐几个好用的OMZ主题

1.oh-my-zsh-powerline-theme

项目地址：https://github.com/jeremyFreeAgent/oh-my-zsh-powerline-theme

![](https://www.hi-linux.com/img/linux/oh-my-zsh-powerline-theme.png)

安装

```
git clone https://github.com/jeremyFreeAgent/oh-my-zsh-powerline-theme 
cd oh-my-zsh-powerline-theme
./install_in_omz.sh
```

安装完之后记得再zshrc中加入

```
ZSH_THEME="powerline"
```

如果要更多定制化设定可以参考repo内的设定

2.bullet-train-oh-my-zsh-theme

项目地址：https://github.com/caiogondim/bullet-train-oh-my-zsh-theme

![](https://www.hi-linux.com/img/linux/bullet-train-oh-my-zsh-theme.png)

安装

```
git clone https://github.com/caiogondim/bullet-train-oh-my-zsh-theme.git
cd bullet-train-oh-my-zsh-theme
cp bullet-train.zsh-theme  ~/.oh-my-zsh/themes/
```

安装完之后记得再zshrc中加入

```
ZSH_THEME="bullet-train"
```

#### Vim中使用Powerline

若要在Vim的状态列中使用Powerline，则在~/.vimrc 中加入这几行：

方法一

```
vim ~/.vimrc
set laststatus=2
set t_Co=256
python from powerline.vim import setup as powerline_setup
python powerline_setup()
python del powerline_setup
```

方法二

```
vim ~/.vimrc
set rtp+=/usr/lib/python2.6/site-packages/powerline/bindings/vim/

" These lines setup the environment to show graphics and colors correctly.
set nocompatible
set t_Co=256
 
let g:minBufExplForceSyntaxEnable = 1
python from powerline.vim import setup as powerline_setup
python powerline_setup()
python del powerline_setup
 
if ! has('gui_running')
   set ttimeoutlen=10
   augroup FastEscape
      autocmd!
      au InsertEnter * set timeoutlen=0
      au InsertLeave * set timeoutlen=1000
   augroup END
endif
 
set laststatus=2 " Always display the statusline in all windows
set guifont=Inconsolata\ for\ Powerline:h14
set noshowmode " Hide the default mode text (e.g. -- INSERT -- below the statusline)
```

注：`set rtp+=/usr/lib/python2.6/site-packages/powerline/bindings/vim/`需要按照自己的powerline实际安装情况调整。

方法三

```
set rtp+=/usr/lib/python2.6/site-packages/powerline/bindings/vim/
set guifont=Monaco\ for\ Powerline:h14.5  
set laststatus=2  
let g:Powerline_symbols = 'fancy'  
set encoding=utf-8  
set t_Co=256  
set number  
set fillchars+=stl:\ ,stlnc:\  
set term=xterm-256color  
set termencoding=utf-8  
syntax enable  
set background=light  
colorscheme solarized
```

方法四

```
set rtp+=/usr/lib/python2.6/site-packages/powerline/bindings/vim/
set guifont=Consolas\ for\ Powerline\ FixedD:h11 
let g:Powerline_symbols = 'fancy'
set laststatus=2
set encoding=utf-8
set t_Co=256
set fillchars+=stl:\ ,stlnc:\
set term=xterm-256color
set termencoding=utf-8
set nocompatible
syntax enable
colorscheme solarized
set background=dark
let g:solarized_termcolors=256
```
 
注意事项

使用Powerline需要在vimrc中设置`set laststatus=2`
Powerline中的分隔符实际上是特殊字体，如果显示错误请下载修改过的字体：`https://gist.github.com/1595572`

### 参考文档
http://www.google.com
http://blog.gtwang.org/linux/powerline-adds-powerful-statuslines-and-prompts-to-vim-and-bash/
http://lee-w-blog.logdown.com/posts/210946-powerline-on-zsh-vim-tmux
https://github.com/powerline/powerline
http://blog.csdn.net/little__zm/article/details/21786773
http://hessian.cn/p/1026.html