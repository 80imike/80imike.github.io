---
category: HTTPS
title: 为基于Coding Pages的网站实现全站HTTPS
date: 2017-03-29 09:00:00
tags: [HTTPS, 技巧]
abbrlink:
updated:
toc_number: false
---

现在有不少Git托管平台提供了Pages服务，比如GitHub、Coding等。利用Git托管平台提供的Pages服务可以很方便的部署一个全静态化的网站。本文将介绍如何给Coding Pages上的网站实现HTTPS。

**前提**

本文默认读者已经掌握了用`GitHub Pages`或`Coding Page`服务部署网站、域名DNS解析等知识（若没掌握请自行谷歌）。

<!-- more -->

**启用HTTPS**

`Coding Pages`现已支持绑定域名启用`HTTPS`。在Coding Pages上启用`HTTPS`方法也非常简单，只需开启强制`HTTPS`访问功能即可。启用后`Coding Pages`会自动根据你绑定的域名向`Let's Encrypt`申请SSL证书。

![](https://www.hi-linux.com/img/linux/coding_page_01.png)


看起来一切都是这么美好？骚年，你太天真了！

启用过程中遇到几个需要注意的地方(坑)，在这里总结下：

- 如果你在启用HTTPS前，已经绑定好了自定义域名。记得全部解绑后，重新绑定。否则不会自动申请SSL证书。


- 如果你采用了`Coding Page`和`GitHub Page`双托管的方式，记得将DNS中解析到`GitHub Page`的记录暂停或删除。否则`Let's Encrypt`主机根据域名解析记录验证域名所有权时，会定位到`GitHub Page`的主机上，导致`Let's Encrypt`SSL证书申请失败。

启用成功后效果，如下图：

![](https://www.hi-linux.com/img/linux/coding_page_02.png)

**后续配置**

开启强制`HTTPS`访问后，网站内引用资源的`URL`必需以`https://`开头，避免引用资源加载失败。例如`Css`文件、`JavaScript`文件、`Image`文件。

我的网站是用`HEXO`+`NexT`构建的，修改起来还是比较容易的。主要修改了以下几处：

- 更换百度统计为CNZZ统计


- 修复`Gravatar`头像为HTTPS地址


- 更换评论系统为`livere`（多说不支持HTTPS且已宣布停止服务）


- 修复腾讯404公益页面。方法可参考:「[使腾讯404公益页面支持HTTPS](https://eason-yang.com/2016/08/06/set-tencent-lostchild-404-page-for-ssl/)」


- 批量修改日志文件中图片地址为HTTPS的（如果你的图片等静态资源拖管到七牛云，可以直接开启HTTPS支持。）

最后来个成果展示

![](https://www.hi-linux.com/img/linux/coding_page_03.png)

**参考文档**

http://www.google.com
https://segmentfault.com/a/1190000008648929
