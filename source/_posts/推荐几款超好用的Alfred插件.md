---
category: macOS
title: 推荐几款超好用的 Alfred 插件
date: 2018-06-20 09:00:00
tags: [Alfred, macOS]
abbrlink:
updated:
toc_number: false
---

Alfred 可以说是 Mac 上必装的神器，作为 Mac 上最强大的效率工具 Alfred 早已不仅仅是最开始的快速启动与搜索工具。 它的 Workflow 扩展功能，让它成为了一个拥有无限自动化潜力的「工具台」软件，你可以用它来实现你的一切有关自动化的想法。

下面这张官方图中标出了 Alfred 的所有功能，从中你可以直观的感受到它的强大。

![](https://www.hi-linux.com/img/linux/alfred19.png)

### 获取 Alfred

从 Alfred 官网就可以下载 Alfred 安装程序，安装完成即可使用。不过 Alfred 将功能分为免费和付费两大部分：

- 免费用户只能使用其 Features 中的功能（即基本搜索和快速启动应用等功能，其实这已满足非重度使用者日常需求）。
- 若要使用 Workflows (即自定义插件的工作流)，则需要激活 Powerpack 功能。

激活 Powerpack 功能的正常途径当然是在官方购买序列号，当然你也可以通过一些技术手段获得此功能，不过还是强烈建议读者购买并使用正版。

<!-- more -->

激活 Powerpack 后，你可以在设置界面的 Powerpack 子界面中看到类似下图。这样就表明可以使用 Alfred 的所有功能，当然也包括工作流。

![](https://www.hi-linux.com/img/linux/alfred1.png)

如果你还不知道 Alfred 基本功能如何使用，推荐先读下 「[Alfred 3.0 新版详解](https://sspai.com/post/34468)」 和 「[OS X 效率启动器 Alfred 详解与使用技巧](https://sspai.com/post/27900)」 这两篇入门文章。

今天主要给大家推荐几款我长期使用且功能异常强大和好用的 Alfred 插件。

### Secure SHell

一个可在 Alfred 上快速打开 SSH/SFTP/mosh 链接的插件，其功能非常的强大。

插件官方地址：https://github.com/deanishe/alfred-ssh

如果你和我一样经常使用 SSH 访问服务器,相信这会是你的不二之选，通过这个插件也弥补了 iTerm2 不方便管理多主机的功能。插件效果如下：

![](https://www.hi-linux.com/img/linux/alfred20.gif)

该插件默认启动关键字是：`ssh`。默认情况下，在选中的 SSH 链接上直接回车后就会在终端中访问对应的 SSH 服务器。

如果在选中的指定链接上配合一些功能键，就可以实现以下更多的功能：

```
⌘+↩ — 打开一个 SFTP 链接。
⌥+↩ — 使用 mosh 访问当前 SSH 链接。
⇧+↩ — 使用 Ping 命令测试当前主机的连通性。
^+↩ — 从历史记录中清出之前访问过的连接信息。
```

Secure SHell 默认支持从以下文件中读出 SSH 链接配置信息：

```
~/.ssh/config
~/.ssh/known_hosts
/etc/hosts
/etc/ssh/ssh_config
History (用户以前输入的用户名+主机地址)
```

Secure SHell 默认情况下已经非常的强大和方便了，如果结合上 SSH 用户配置文件，你会发现更加完美。如果你还不知道如何用 SSH 用户配置文件管理多主机，可参考「[利用SSH的用户配置文件Config管理SSH会话](https://mp.weixin.qq.com/s/gaeu6nGxxQPRbbbWbwDiiA)」一文。

### TerminalFinder

一个可以在 Terminal 和 Finder 间快速切换的插件。

插件官方地址：https://github.com/LeEnno/alfred-terminalfinder

TerminalFinder 的主要作用是在 Finder 和 Terminal 间快速切换到当前目录。TerminalFinder 使用非常简单，只需在 Alfred 输入以下关键字就可进行快速切换:

```
ft: 在 Terminal 打开当前 Finder 中的目录
tf: 在 Finder 打开当前 Terminal 中的目录
fi: 在 iTerm 中打开当前 Finder 中的目录
if: 在 Finder 中打开当前 iTerm 中的目录

pt: 在 Terminal 打开当前 Path Finder 中的目录
tp: 在 Path Finder 打开当前 Terminal 中的目录
pi: 在 iTerm 中打开当前 Path Finder 中的目录
ip: 在 Path Finder 中打开当前 iTerm 中的目录
```

比如你要在 iTerm 中打开当前 Finder 中的目录，在 Alfred 上输入 `fi` 就可以了。

![](https://www.hi-linux.com/img/linux/alfred10.png)

### Password Generator

一个快速随机密码生成器。

插件官方地址：https://github.com/deanishe/alfred-pwgen

如果你需要经常生成随机密码，Password Generator 会是一个不错的选择。插件效果如下：

![](https://www.hi-linux.com/img/linux/alfred21.gif)

该插件默认提供：`pwgen`、`pwlen`、`pwconf` 三个启动关键字。`pwgen` 默认情况下会生成一组随机密码并显示其长度信息，此时只需在选中的条目上直接回车便可以方便将其复制。

![](https://www.hi-linux.com/img/linux/alfred16.png)

如果你想对密码生成规则进行定制，只需输入 `pwconf` 就可以进入 Password Generator 配置界面。Password Generator 提供的配置功能非常丰富，可以根据不同需求进行定制。

![](https://www.hi-linux.com/img/linux/alfred17.png)

如果你想快速生成一个指定长度的随机密码，此时你可以用 `pwlen` 来实现。比如要生成一个密码长度为 10 位的随机密码，此时只需输入 `pwlen 10`：

![](https://www.hi-linux.com/img/linux/alfred18.png)

> `pwlen` 默认是生成一个长度为 20 位的随机密码的。

Password Generator 功能非常强大，远不止这里介绍的这一点。官方文档对其一些高级功能的使用已经做了详细说明，这里就不在重复累述了。

### New Files

一个可以在任意位置快速创建新文档和文件夹的插件。

插件官方地址：https://github.com/cpimhoff/alfred3-newFiles

默认情况下，macOS 不能通过右键菜单来完成新文件的创建。macOS 这样的设计是鼓励用户都通过应用程序来创建所需的文件，而不是通过创建文件来打开应用。如果你之前一直是个 Windows 用户，对这样的设计应该很不习惯。New Files 就是用来解决这个问题的，有了 New Files 你就可以在任意位置新建你所需文件格式的文档。

该插件默认启动关键字是：`new`。默认情况下，你可以直接新建 TXT、MD、自定义文件类型这三种类型的文件和目录。其中 TXT、MD 格式也是比较常用的文本格式，插件就将这两种类型的文件直接作为了默认文件类型。真是非常贴心！

![](https://www.hi-linux.com/img/linux/alfred2.png)

New Files 的功能非常强大，不但可以随时随地的新建需要的文档类型文档，而且还可以让你在新建文档的时候选择新建文档的位置、是否将剪贴版里的内容直接放入到新建的文档中。

下面我们就来看看如何快速建立一个 MD 格式的文件：

![](https://www.hi-linux.com/img/linux/alfred4.png)

输入新建文件的文件名：

![](https://www.hi-linux.com/img/linux/alfred5.png)

选择文件保存的位置：

![](https://www.hi-linux.com/img/linux/alfred6.png)

并把剪贴版中内容自动粘贴到新建的文件中：

![](https://www.hi-linux.com/img/linux/alfred7.png)

完成文件创建后，插件还会自动用文件类型默认关联的程序打开新建的文件。

![](https://www.hi-linux.com/img/linux/alfred8.png)

经过以上简单几步，一个指定文件格式且包含剪贴版里内容的文件就建立完成了，有没有很方便呢？

如果你要自定义常用的文件类型也是可以的，直接在插件的设置界面进行增加即可。

![](https://www.hi-linux.com/img/linux/alfred3.png)

如果你要自定义常用的文件存放路径当然也是可以的，同样在插件的设置界面进行增加即可了。

![](https://www.hi-linux.com/img/linux/alfred9.png)

### Recent Items

显示最近访问过的文件、文件夹、应用程序、文档、下载内容等。

插件官方地址：http://t.cn/RmFG5Zy

该插件默认启动关键字是：`rec`。通过以下关键字可以快速访问相对应的类型。

![](https://www.hi-linux.com/img/linux/alfred11.png)

各关键字对应的分类说明：

```
now: 显示当前使用过的文档
fol: 显示最近使用过的目录
apps: 显示最近使用过的应用程序
docs: 显示最近使用过的文档
dow: 显示最近下载过的文件
fav: 显示最近收藏过的项目
c1: 插件默认预留关键字用作自定义分类项目
c2: 插件默认预留关键字用作自定义分类项目
```

默认情况下在选中条目上直接回车会打开文件或者目录，如果在选中的条目上配合一些功能键，就可以实现以下更多的功能：

```
⌘+↩ — 在 Finder 中显示文件或文件夹
⌥+↩ — 将文件/目录的路径传递到打开/保存对话框或者Finder窗口
⇧+↩ — 快速预览选中的文件或者目录
^+↩ — 将选中的文件或者目录加入或移出收藏夹
```

比如你要在 Alfred 中显示最近使用过的应用，在 Alfred 上输入 `rec apps` 就可以了。

![](https://www.hi-linux.com/img/linux/alfred12.png)

### Hidden Files

一个可以在 Finder 中快速切换是否显示隐藏文件的插件。

该插件默认启动关键字是：`hide`。使用非常简单，效果如下图：

![](https://www.hi-linux.com/img/linux/alfred13.png)

此时在 Finder 中打开的目录中就会显示隐藏文件。

![](https://www.hi-linux.com/img/linux/alfred14.png)

在显示隐藏文件状态下，再次输入 `hide` 就可以在 Finder 中不显示隐藏文件。

![](https://www.hi-linux.com/img/linux/alfred15.png)

通常我都在是终端下查看隐藏文件的，这个插件相对使用频率就要低得多了。插件下载地址暂时也找不到了，如果你觉得插件对你有用，可留下联系方式单独发给你！

此次推荐的几款 Alfred 插件就介绍完了。如果你有什么更好用的 Alfred 插件推荐，欢迎积极留言哟！