---
category: 工具
title: 推荐一款比 Find 快 10 倍的搜索工具 FD
date: 2018-08-13 09:00:00
tags: [Linux, 工具]
abbrlink:
updated:
toc_number: false
---

fd 是基于 Rust 开发的一个速度超快的命令行搜索工具，fd 旨在成为 Linux / Unix 下 find 命令的替代品。

fd 虽然不能提供现在 find 命令所有的强大功能，但它也提供了足够强大的功能来满足你日常需要。比如：简洁的语法、彩色的终端输出、超快的查询速度、智能大小写、支持正则表达式以及可并行执行命令等特性。

项目地址：https://github.com/sharkdp/fd

### 安装 fd

fd 具有良好跨平台特性，支持在 Linux、macOS、Windows 等多种平台下安装。下面我们介绍下几个比较常用平台的安装方法：

- Ubuntu / Debain

```
$ wget https://github.com/sharkdp/fd/releases/download/v7.0.0/fd_7.0.0_amd64.deb
$ sudo dpkg -i fd_7.0.0_amd64.deb
```

<!-- more -->

-  Fedora

```
$ dnf install fd-find
```

- macOS

```
$ brew install fd
```

- Windows

[Scoop](http://scoop.sh/) 和 [Chocolatey](https://chocolatey.org/) 都是 Windows 下的包管理系统，其具体使用方法都可参考其官网。

```
# 通过 Scoop 安装
$ scoop install fd

# 通过 Chocolatey 安装
$ choco install fd
```

更多系统的安装方法可参考[官方文档](https://github.com/sharkdp/fd)。

### fd 命令行选项

```
USAGE:
    fd [FLAGS/OPTIONS] [<pattern>] [<path>...]

FLAGS:
    -H, --hidden            Search hidden files and directories
    -I, --no-ignore         Do not respect .(git|fd)ignore files
        --no-ignore-vcs     Do not respect .gitignore files
    -s, --case-sensitive    Case-sensitive search (default: smart case)
    -i, --ignore-case       Case-insensitive search (default: smart case)
    -F, --fixed-strings     Treat the pattern as a literal string
    -a, --absolute-path     Show absolute instead of relative paths
    -L, --follow            Follow symbolic links
    -p, --full-path         Search full path (default: file-/dirname only)
    -0, --print0            Separate results by the null character
    -h, --help              Prints help information
    -V, --version           Prints version information

OPTIONS:
    -d, --max-depth <depth>        Set maximum search depth (default: none)
    -t, --type <filetype>...       Filter by type: file (f), directory (d), symlink (l),
                                   executable (x)
    -e, --extension <ext>...       Filter by file extension
    -x, --exec <cmd>               Execute a command for each search result
    -E, --exclude <pattern>...     Exclude entries that match the given glob pattern
        --ignore-file <path>...    Add a custom ignore-file in .gitignore format
    -c, --color <when>             When to use colors: never, *auto*, always
    -j, --threads <num>            Set number of threads to use for searching & executing

ARGS:
    <pattern>    the search pattern, a regular expression (optional)
    <path>...    the root directory for the filesystem search (optional)
```

### fd 使用实例

#### 简单搜索

fd 只需带上一个需要查找的参数就可以执行最简单的搜索，该参数就是你要搜索的任何东西。例如：你想要找一个包含 pace 关键字的文件名或目录。

```
$ fd pace
source/lib/Han/dist/font/han-space.otf
source/lib/Han/dist/font/han-space.woff
source/lib/pace
source/lib/pace/pace-theme-barber-shop.min.css
source/lib/pace/pace-theme-big-counter.min.css
source/lib/pace/pace-theme-bounce.min.css
source/lib/pace/pace-theme-center-atom.min.css
source/lib/pace/pace-theme-center-circle.min.css
source/lib/pace/pace-theme-center-radar.min.css
```

> 注：fd 默认是不区分大小写和支持模糊查询的。

#### 按指定类型进行搜索

默认情况下，fd 会搜索所有符合条件的结果。如果你想指定搜索的类型可以使用 `-t` 参数，fd 目前支持四种类型：`f`、`d`、`l`、`x`，分别表示：文件、目录、符号链接、可执行文件。下面我们来看几个实际的例子：

- 只搜索包含 pace 关键字的文件

```
$ fd -tf pace
source/lib/Han/dist/font/han-space.otf
source/lib/Han/dist/font/han-space.woff
source/lib/pace/pace-theme-barber-shop.min.css
source/lib/pace/pace-theme-big-counter.min.css
source/lib/pace/pace-theme-bounce.min.css
source/lib/pace/pace-theme-center-atom.min.css
source/lib/pace/pace-theme-center-circle.min.css
source/lib/pace/pace-theme-center-radar.min.css
```

- 只搜索包含 pace 关键字的目录

```
$ fd -td pace
source/lib/pace
```

#### 搜索指定目录

fd 默认会在当前目录和其下所有子目录中搜索，如果你想搜索指定的目录就需要在第二个参数中指定。例如：要在指定的 `/etc` 目录中搜索包含 passwd 关键字的文件或目录。

```
$ fd passwd /etc
/etc/master.passwd
/etc/pam.d/chkpasswd
/etc/pam.d/passwd
/etc/passwd
```

#### 通过正则表达式搜索

- 搜索当前目录下以 head 开头并以 swig 结尾的文件。

```
$ fd '^head.*swig$'
layout/_custom/header.swig
layout/_partials/head.swig
layout/_partials/header.swig
```

- 搜索当前目录下文件名包含字母且文件名后缀为 PNG 的文件。

```
$ fd '[a-z]\.png$'
source/images/apple-touch-icon-next.png
source/images/searchicon.png
source/lib/fancybox/source/fancybox_overlay.png
source/lib/fancybox/source/fancybox_sprite.png
source/lib/fancybox/source/helpers/fancybox_buttons.png
```

#### 其它技巧

- 搜索隐藏文件

fd 支持隐藏文件搜索，如果你需要搜索隐藏文件可以加上 `-H` 参数。例如：在当前目录下搜索关键字为 zshrc 的隐藏文件。

```
$ fd -H zshrc
.zshrc
```

- 搜索指定扩展名的文件

在当前目录下搜索文件扩展名为 md 的文件。

```
$ fd -e md
README.cn.md
README.md
source/lib/fastclick/README.md
source/lib/jquery_lazyload/CONTRIBUTING.md
source/lib/jquery_lazyload/README.md
```

在当前目录下搜索文件名包含 reademe 且扩展名为 md 的文件。

```
$ fd -e md readme
README.cn.md
README.md
source/lib/fastclick/README.md
source/lib/jquery_lazyload/README.md
```

- 排除特定的目录或文件

搜索当前目录下除 lib 目录外的所有包含关键字 readme 的文件或目录。

```
$ fd -E lib readme
README.cn.md
README.md
```

搜索指定目录下除文件名后缀为 js 的所有文件。

```
$ fd  -E '*.js' -tf  . source/lib/fastclick
source/lib/fastclick/LICENSE
source/lib/fastclick/README.md
source/lib/fastclick/bower.json
```

- 结合外部命令对结果进行批量处理

实现的方式有两种：一是和 find 命令的类似的处理方法，通过 `xargs` 命令来关联相关命令处理。二是通过 fd 自己的 `-x` 参数来实现。

我们来看一个具体的例子，统计当前目录下所有文件名后缀为 js 的文件的行数。

```
# 通过 -x 参数实现
$ fd -e js -x  wc  -l

      30 scripts/merge-configs.js
    2225 scripts/merge.js
      31 scripts/tags/button.js
      12 scripts/tags/center-quote.js
      59 scripts/tags/exturl.js
      26 scripts/tags/full-image.js
     833 scripts/tags/group-pictures.js

# 通过 xargs 参数实现
$ fd -0 -e js | xargs -0 wc  -l
      30 scripts/merge-configs.js
    2225 scripts/merge.js
      31 scripts/tags/button.js
      12 scripts/tags/center-quote.js
      59 scripts/tags/exturl.js
      26 scripts/tags/full-image.js
     833 scripts/tags/group-pictures.js
```

### 参考文档

http://www.google.com
http://t.cn/RD03Aom
http://t.cn/ROV0Xos