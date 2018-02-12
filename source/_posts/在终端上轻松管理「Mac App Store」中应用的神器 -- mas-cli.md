---
category: macOS
title: 在终端上轻松管理「Mac App Store」中应用的神器 -- mas-cli
date: 2018-02-12 09:00:00
tags: [macOS, 技巧]
abbrlink:
updated:
toc_number: false
---

在 macOS 下安装或更新应用软件我们大多数时候都在 MAS 「Mac App Store」上进行， MAS 虽好但有时需要批量安装或更新 MAS 上应用软件时就会相对麻烦一些。

也许这时你会想到 macOS 下命令行包管理神器 Homebrew 和 Homebrew-Cask，Homebrew 虽然好用，但 Homebrew 并不能管理 MAS 上的应用软件。今天就给你介绍一款可在命令行下管理 MAS 应用软件的神器 `mas-cli`。

`mas-cli` 官方用「A simple command line interface for the Mac App Store. Designed for scripting and automation.」这样简洁的话说明了它的用途。`mas-cli` 功能非常的强大，下面我们就介绍下 `mas-cli` 几个常用的功能。

项目地址：https://github.com/mas-cli/mas

<!-- more -->


### 安装 mas-cli

`mas-cli` 安装还是比较容易的，官方推荐用 Homebrew 安装。只要把以下代码复制到终端后运行即可：

```
$ brew install mas
```

如果你还不会使用 Homebrew，可参考 「[macOS不可或缺的套件管理器——Homebrew](https://mp.weixin.qq.com/s/0WXfIpg9pRa6YGQYdozY7w)」和「[如何用Homebrew安装指定版本软件](https://mp.weixin.qq.com/s/1KbSvqvAMq516rrVCX9mZQ)」两篇文章先了解下 Homebrew 。


当然你实在不愿意用 Homebrew 进行安装，也可使用官方提供的二进制版本进行安装，下载地址如下：https://github.com/mas-cli/mas/releases 。


### 查询应用

MAS 中每一个应用都有自己的应用识别码 (Product Identifier)，MAS 就是根据 Product Identifier 安装与更新应用的。使用 `mas list` 命令将显示所有已安装的应用程序及其应用识别码。

```
$ mas list
836500024 WeChat (2.3.10)
1284863847 Unsplash Wallpapers (1.0.2)
1012930195 HandShaker (2.1.1)
935235287 Encrypto (1.3.1)
1176895641 Spark (1.5.6)
439700005 CatchMouse (1.2)
...
```

如果我们要新安装一个应用软件要如何才能得到其应用识别码呢？通常你可以使用以下几种方法得到对应软件的应用识别码，下面以应用程序 1Password 为例：

- 从 MAS 中应用程序的链接信息中获得

打开 MAS，搜索到要安装的软件并点击界面上「获取-复制链接」按钮。就会取得如下链接地址：`https://itunes.apple.com/cn/app/1password/id443987910?mt=12`。由链接便可知其识别码为 `443987910`。 

- 使用 mas-cli 指令获得

显然从应用链接中查看应用识别码是比较麻烦的，`mas-cli` 自身便提供了 `mas search` 命令来查询应用程序对应的应用识别码。

在终端中执行以下命令，很快就会显示 `1Password` 的应用识别码：

```
$ mas search 1Password
443987910 1Password
```

> 搜索关键字不区分大小写且支持模糊查询。

### 安装应用

使用 `mas-cli` 安装一个新的应用软件也是非常容易的，安装一个新的应用软件只需知道此应用软件的识别码就可以很方便的安装这个软件了。上面我们已经讲了如何取得软件的应用识别码，接下来我们只需使用 `mas install` 命令便可完成应用软件的安装。

#### 安装单个应用

```
# 安装 1Password
$ mas install 443987910
############################------------- 67.0% Downloading
==> Downloading 1Password
==> Installed 1Password
```

#### 安装多个应用

我们不仅可以使用 `mac-cli` 安装单个应用，还可以批量安装多个应用。只需在应用识别码之间加上空格：

```
$ mas install A应用识别码 B应用识别码 C应用识别码
```

> 注意：
> 1. 安装的应用软件必须是在 MAS 商店登陆账号的已购列表中存在的，因为 mas-cli 命令行无法在 MAS 中完成「购买」这个操作。否则安装时就会报类似：无法使用此 Apple ID 重新下载的错误。
> 2. 对于 MAS 中新上架的应用，可能无法查询到其应用识别码。因为 mas-cli 的查询列表在其缓存文件中，可能暂时未更新。如若由其他途径（如应用链接）得知新上架应用识别码，仍可正常安装。

### 更新应用

如果要更新所有 MAS 中已安装的应用，只需终端执行以下命令：

```
$ mas upgrade
```

如果要更新特定应用，首先需要使用命令 `mas outdated` 查询待更新应用列表以获取应用的识别码。

```
$ mas outdated
497799835 Xcode (7.0)
446107677 Screens VNC - Access Your Computer From Anywhere (3.6.7)
```

其次再使用其对应的应用识别码对应用软件进行更新。

```
# 更新一个应用软件
$ mas upgrade 497799835

# 更新多个应用软件
$ mas upgrade 497799835 446107677
```

> 注意：mas-cli 无法用于系统更新，即只能更新显示在 MAS 中已购列表的应用。如果要进行系统更新可以使用 `softwareupdate` 命令， 使用 `softwareupdate -l`可获取系统更新列表；使用 `sudo softwareupdate -iva` 可进行系统更新。

### 下载 macOS 安装程序

`mas-cli` 不仅能安装应用程序，还能直接下载各个版本的 macOS 安装程序。 以下为各版本 macOS 应用识别码列表：

- macOS 10.7 Lion – 444303913
- macOS 10.8 Mountain Lion – 537386512
- macOS 10.9 Mavericks – 675248567
- macOS 10.10 Yosemite – 915041082
- macOS 10.11 El Capitan – 1147835434（适用于无法升级 10.12 的机型）
- macOS 10.11 El Capitan – 1018109117
- macOS 10.12 Sierra – 1127487414
- macOS 10.13 High Sierra – 1246284741

以下载 macOS 10.13 High Sierra 为例：

```
$ mas install 1246284741
```

> 注：如要下载不同版本的 macOS 安装程序只需将应用识别码变更为对应的 macOS 安装程序即可。

### 快速切换 MAS 账号

如果你有多个 Apple ID，`mas-cli` 可以很方便的在多个账号间切换。这也是多区账号拥有者的福音，这样我们终于可以更方便地下载和更新其他区的应用了。

- 查询当前登陆帐号

```
$ mas account
```

- 切换一个新账号

```
# 退出当前帐号
$ mas signout

# 登陆新的账号
$ mas signin mas@example.com "mypassword"
```

如果要使用图形界面进行登陆，可加上 `--dialog` 参数。

```
$ mas signin --dialog mas@example.com
```

为了更方便的切换，可以在 SHELL 中设置别名以得到更爽快的体验。

- 如果你使用 Bash，在 ~/.bashrc 文件中加入：

```
$ vim ~/.bashrc

alias masus='mas signout && mas signin myusappleid "mypassword"'
alias mascn='mas signout && mas signin mycnappleid "mypassword"'
alias mas?='mas account'
```

- 如果你使用 ZSH，在 ~/.zshrc 文件中加入：

```
$ vim ~/.zshrc

alias masus='mas signout && mas signin myusappleid "mypassword"'
alias mascn='mas signout && mas signin mycnappleid "mypassword"'
alias mas?='mas account'
```

重新打开终端以载入设置，那么以后在终端中执行 masus 即可切换到美区账号，mascn 即切到中区账号，mas? 可查询目前登陆帐号。

> 注：mas-cli 切换帐号功能暂时不支持 macOS 10.13.x 版本，使用时会报 `libc++abi.dylib: terminating with uncaught exception of type NSException` 类似错误。

### mas-cli 的不足和期望

文档写得差不多的时候，我才发现 `mas-cli` 已经很久没有更新了，这是个悲伤的故事。期待官方早日更新和完善以下的不足点：

- `mas-cli` 快速切换帐号功能暂不支持 macOS 10.13.x 版本。
- `mas-cli` 只能安装和更新已存在购买列表中的应用软件。

如果你有更好的类似工具，欢迎留言告诉我~

### 参考文档

http://www.google.com
http://t.cn/RR5LHNo
http://t.cn/R9dieYt

> 本文是年前最后推送的文章，感谢你一直的关注和支持。亲爱的读者们，我们年后见。最后祝大家春节快乐~