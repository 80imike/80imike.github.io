---
category: Linux
title: 最牛最暴力的开源协议——WTFPL
date: 2017-05-19 09:00:00
tags: [Linux,开源协议]
abbrlink:
updated:
toc_number: false
---

你知道这个世界上有多少种开源软件的许可证吗？GPL，BSD，MIT，Apache...等等。目前市面上有的的开源协议很多很多，至少有100多种。经过开源促进会(Open Source Initiative)认可的开源协议也多达70多种。 GNU上有个网页记录了几乎所有的开源软件的许可证：http://www.gnu.org/licenses/license-list.html。

那么，你知道怎么区别和选择它们吗？下面这张比较复杂的图说明了它们的关系：

<!-- more -->

![](https://www.hi-linux.com/img/linux/wtfpl1.jpg)

看上去是不是很头大？不过大多数公司用得最多的只有6种开源协议：LGPL、Mozilla、GPL、BSD、MIT、Apache。下面这张图可以快速搞清楚这6种许可证之间的最大区别。

![](https://www.hi-linux.com/img/linux/wtfpl2.jpg)

如果你觉得上面的协议还是太多限制，不够自由。今天给你介绍一种最牛最暴力的开源协议--WTFPL。

WTFPL协议官网：http://www.wtfpl.net/

![](https://www.hi-linux.com/img/linux/wtfpl3.jpeg)

WTFPL(Do What The Fuck You Want To Public License)，中文译名：你他妈的想干嘛就干嘛公共许可证。WTFPL是一种不太常用的、极度放任的自由软件许可证。它的条款基本等同于贡献到公有领域。

此许可证在2000年3月发布的1.0版，是Banlu Kemiyatorn撰写，最初是供Window Maker的美工品使用。一位任Debian项目领导的法国程序员桑·奥塞瓦(英语：Sam Hocevar)撰写了2.0版本。它允许根据任何条款修改和再发布软件，许可证鼓励他们"想干嘛就干嘛"。该许可证已被自由软件基金会认证为兼容GPL的自由软件许可证。

WTFPL许可协议全文：

```
DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
        Version 2, December 2004

Copyright (C) 2004 Sam Hocevar <sam@hocevar.net>

Everyone is permitted to copy and distribute verbatim or modified
copies of this license document, and changing it is allowed as long
as the name is changed.

DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

0. You just DO WHAT THE FUCK YOU WANT TO.
```

WTFPL许可协议译文：

```
你他妈的想干嘛就干嘛公共许可证
              第二版，2004年12月

版权所有(C) 2004 桑·奥塞瓦<sam@hocevar.net>

任何人都有复制与发布本协议的原始或修改过的版本的权利。
若本协议被修改，须修改协议名称。

         你他妈的想干嘛就干嘛公共许可证
             复制、发布和修改条款

 0. 你只要他妈的想干嘛就干嘛好了。
```

WTFPL使用

WTFPL目前很少项目使用，毕竟太自由了，完全没限制。不过也有一些软件已采用它来发布，比如：Potlatch，一个OpenStreetMap项目的在线编辑器。øbin，一个客户端处加密的剪贴板。知乎上有很多有价值的问答也引用了该协议。

看完介绍有没有自由得想要飞的感觉，赶快去发布你的WTFPL协议项目吧！

参考文档

http://www.google.com
http://coolshell.cn/articles/4657.html
https://zh.m.wikipedia.org/zh-hans/WTFPL
