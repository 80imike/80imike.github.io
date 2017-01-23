---
title: Linux命令行下交互式HTTP客户端--HTTP Prompt
tags:
  - HTTP Prompt
  - Linux
categories: Linux
abbrlink: 57570
date: 2016-06-20 09:00:00
updated:
toc_number:
---

HTTP Prompt是一个交互式的命令行HTTP客户端，支持自动完成、语法高亮，基于HTTPie和prompt_toolkit构建。HTTP Prompt相对于其它命令行的HTTP客户端(如HTTPie、Curl等)使用上更加直观方便。如对HTTPie有兴趣，可参考之前写的[[如何用httpie更高效的调试接口](http://www.hi-linux.com/2016/05/12/%E5%A6%82%E4%BD%95%E7%94%A8httpie%E6%9B%B4%E9%AB%98%E6%95%88%E7%9A%84%E8%B0%83%E8%AF%95%E6%8E%A5%E5%8F%A3/)] 一文。

项目地址: https://github.com/eliangcs/http-prompt

<!-- more -->

先展示一下HTTP Prompt官方给出的效果图。

![](http://www.hi-linux.com/img/linux/http-prompt.gif)

有没有觉得很酷！

### HTTP Prompt安装

通过Python包管理工具安装

Root用户

```
$ pip install http-prompt
```

非Root用户

```
$ sudo pip install http-prompt
```

注：需要Root权限，否则会报权限错误。这种方式会安装到全系统中，所有用户都可使用。

使用`--user`选项可只安装到你的用户目录中

```
$ pip install --user http-prompt
```

升级 

```
$ pip install -U http-prompt
```

### HTTP Prompt配置

HTTP Prompt首次运行时会建立一个用户配置文件。配置文件默认放在` ~/.config/http-prompt/config.py`(Linux)或`~/AppData/Local/http-prompt/config.py`(Windows)。

config.py提供`command_style`、`output_style`、`pager`三个选项可对输出的样式进行控制。

```
$ cat ~/.config/http-prompt/config.py

# Highlighting style for prompt commands. Available values:
# algol, algol_nu, autumn, borland, bw, colorful, default, emacs, friendly,
# fruity, igor, lovelace, manni, monokai, murphy, native, paraiso-dark,
# paraiso-light, pastie, perldoc, rrt, solarized, tango, trac, vim, vs, xcode.
# See gallery at http://eliangcs.github.io/http-prompt/style-gallery.html
command_style = 'solarized'

# Highlighting style for HTTPie's output. Available values are the same as
# command_style. Set this to None to use HTTPie's default style, which you
# can refer to https://github.com/jkbrzt/httpie#default_options
output_style = None

# The tool used to paginate output. Available values: 'less' and 'more'.
# Note that 'more' does not support ANSI colors.
pager = 'less'
```

### HTTP Prompt使用

开始一个会话，执行如下:

```
# 访问一个URL
$ http-prompt http://httpbin.org

# 如访问URL需身份验证，可通过指定相应参数。
$ http-prompt localhost:8000/api --auth user:pass username=somebody
```

进入一个会话后，你可执行以下命令。

使用cd命令改变URL地址:

```
# 切换到一个相对地址
> cd api/v1

# 切换到一个绝对地址
> cd http://localhost/api
```

要添加headers、查询字符串，使用的语法与HTTPie类似。如下：

```
> Content-Type:application/json username=john
> 'name=John Doe' apikey==abc
> Authorization:"Bearer auth_token"
```

还可以添加HTTPie选项，如以下这样：

```
> --form --auth user:pass
> --verify=no username=jane
```

通过HTTPie生成提交预览：

```
> httpie post
http --auth user:pass --form POST http://httpbin.org/api apikey==abc username=john
```

您可以通过命令httpie提供选项和参数暂时覆盖请求参数，该覆盖不会影响以后的请求。

```
# 没有初始参数
> httpie
http http://localhost

# 临时覆盖请求参数
> httpie /api/something page==2 --json
http --json http://localhost/api/something page==2

# 当前状态并不受影响
> httpie
http http://localhost
```

要实际发送请求, 使用以下HTTP方法:

```
> get
> post
> put
> patch
> delete
> head
```

以上的HTTP方法也支持暂时覆盖所有选项和参数:

```
# 没有初始参数

> httpie
http http://localhost

# 发送一个包含参数的请求
> post /api/v1 --form name=jane

# 当前状态并不受影响
> httpie
http http://localhost
```

删除现有的header、参数、或HTTPie选项:

```
> rm -h Content-Type
> rm -q apikey
> rm -b username
> rm -o --auth
```

删除当前会话中所有参数和选项:

```
> rm *
```

离开当前会话:

```
> exit
```

### 参考文档

http://www.google.com
https://github.com/eliangcs/http-prompt