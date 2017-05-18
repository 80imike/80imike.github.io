---
title: 终端环境下更好用的文件比较差异工具icdiff
tags:
  - icdiff
  - Linux
categories: icdiff
abbrlink: 43087
date: 2016-05-05 09:00:00
updated:
toc_number:
---
在终端环境下，两个文件要进行差异比对，通常我们会使用系统内建的diff指令，效果如下

![](https://www.hi-linux.com/img/linux/regular-diff-demo.png)

diff指令仅仅是将文件差异处以上下对照呈现，并不会以颜色标示差异处。
<!-- more -->
再看看icdiff比较文件的结果，效果如下

![](https://www.hi-linux.com/img/linux/icdiff-css-demo-tall.png)

其中各种颜色代表的意义如下

> [绿色]表示[新增]
> [红色]表示[删除]

icdiff将文件差异处以左右对照呈现的方式，并且将差异处标记上颜色。看上去直观多了！

icdiff官网: http://www.jefftk.com/icdiff


### 安装方法

MAC OS X

```
$ brew icdiff
```

Liunx

```
$ pip install icdiff
```

### 使用方法

#### 如何比较两个文件差异

```
$ icdiff <file_1> <file_2>
```

#### 如何搭配git使用

```
$ git difftool --extcmd icdiff
```

更精简的git用法

```
$ git icdiff
```

**将icdiff设定为git预设比对差异工具**

我们可以设定git预设使用icdiff来做差异比对，只需要设定git difftool path指向git-icdiff即可。

设定方法如下

```
$ vim ~/.gitconfig

[diff]
    #使用icdiff来取代git内建的diff
    external = ~/bin/git-diff-wrapper.sh
```

建立`~/bin/git-diff-wrapper.sh`文件，加入以下内容

```
$ vim  ~/bin/git-diff-wrapper.sh

#!/bin/bash
icdiff $2 $5
```

给脚本加上执行权限

```
$ chmod +x ~/bin/git-diff-wrapper.sh
```

赶紧使用`$ git diff`试试吧,是不是已经默认使用icdiff做比较了！


如果你想要忽略这个外部diff而使用官方的diff效果的话

```
$ git diff --no-ext-diff
```

#### 如何搭配svn使用

```
$ svn diff --diff-cmd icdiff
```

**如何让svn预设使用icdiff**

设定方法如下

编辑`~/.subversion/config`文件

```
$ vim ~/.subversion/config 
将# diff-cmd = diff_program的注释行修改成diff-cmd = icdiff
```

保存退出,之后执行`svn diff`命令的时候，就可以彩色化的显示版本差异了，其实这样配置，相当于在执行`svn diff`的时候多加了一个参数`svn diff --diff-cmd = colordiff`

### 常见错误

使用`svn diff --diff-cmd icdiff`可能出现以下类似错误

```
Sorry I don't know python, I can just report the error :
(used from svn)

Traceback (most recent call last):
  File "/bin/icdiff", line 561, in <module>
    start()
  File "/bin/icdiff", line 476, in start
    diff_files(options, a, b, options.encoding)
  File "/bin/icdiff", line 556, in diff_files
    codec_print(line, options)
  File "/bin/icdiff", line 483, in codec_print
    sys.stdout.write(s.encode(options.output_encoding))
UnicodeDecodeError: 'ascii' codec can't decode byte 0xc3 in position 32: ordinal not in range(128)
```

解决:根据作者的回复，需改用python3

> Setting python=python3 in your bashrc won't make icdiff use python3. The easiest way to do that would be to change #!/usr/bin/env python to #!/usr/bin/env python3 at the top of icdiff.

具体可见[issues36](https://github.com/jeffkaufman/icdiff/issues/36)


### 参考文档

http://www.google.com
https://github.com/jeffkaufman/icdiff
https://github.com/jeffkaufman/icdiff/issues/36
https://gist.github.com/bobo52310/57db1af38cd87ddcd05a