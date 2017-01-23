---
title: 谈mysql中utf8和utf8mb4区别
tags:
  - MySQL
  - Linux
categories: MySQL
abbrlink: 51173
date: 2016-03-31 09:00:00
updated:
---

### 简介

MySQL在5.5.3之后增加了这个utf8mb4的编码，mb4就是most bytes 4的意思，专门用来兼容四字节的unicode。好在utf8mb4是utf8的超集，除了将编码改为utf8mb4外不需要做其他转换。当然，为了节省空间一般情况下使用utf8也就够了。

### 内容描述

那上面说了既然utf8能够存下大部分中文汉字,那为什么还要使用utf8mb4呢? 原来mysql支持的utf8编码最大字符长度为3字节，如果遇到4字节的宽字符就会插入异常了。三个字节的 UTF-8 最大能编码的Unicode字符是0xffff，也就是Unicode中的基本多文种平面(BMP)。也就是说，任何不在基本多文本平面的Unicode字符，都无法使用Mysql的utf8字符集存储。包括Emoji表情(Emoji是一种特殊的Unicode编码，常见于ios和 android手机上)，和很多不常用的汉字，以及任何新增的Unicode字符等等。
<!-- more -->

### 问题根源

最初的UTF-8格式使用一至六个字节，最大能编码31位字符。最新的UTF-8规范只使用一到四个字节，最大能编码21位，正好能够表示所有的17个Unicode平面。

utf8是Mysql中的一种字符集，只支持最长三个字节的UTF-8字符，也就是Unicode中的基本多文本平面。

Mysql中的utf8为什么只支持持最长三个字节的UTF-8字符呢？我想了一下，可能是因为Mysql刚开始开发那会，Unicode还没有辅助平面这一说呢。那时候，Unicode委员会还做着[65535个字符足够全世界用了]的美梦。Mysql中的字符串长度算的是字符数而非字节数，对于CHAR数据类型来说，需要为字符串保留足够的长。当使用utf8字符集时，需要保留的长度就是utf8最长字符长度乘以字符串长度，所以这里理所当然的限制了utf8最大长度为3，比如CHAR(100)Mysql会保留300字节长度。至于后续的版本为什么不对4字节长度的UTF-8字符提供支持，我想一个是为了向后兼容性的考虑，还有就是基本多文种平面之外的字符确实很少用到。

要在Mysql中保存4字节长度的UTF-8字符，需要使用utf8mb4字符集，但只有5.5.3版本以后的才支持(查看版本：`select version();`)。我觉得，为了获取更好的兼容性，应该总是使用utf8mb4而非utf8. 对于CHAR类型数据，utf8mb4会多消耗一些空间，根据Mysql官方建议，使用 VARCHAR替代CHAR。


> 引用批注
> [1] 谈谈字符集与字符编码
> http://my.oschina.net/leejun2005/blog/232732#OSC_h3_4
> [2] 关于 MySQL UTF8 编码下生僻字符插入失败/假死问题的分析
> http://my.oschina.net/leejun2005/blog/343353

转载自：http://ourmysql.com/archives/1402