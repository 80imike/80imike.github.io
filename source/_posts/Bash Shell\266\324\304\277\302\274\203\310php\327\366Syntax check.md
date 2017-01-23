---
title: Bash Shell对目录內php做Syntax check
tags:
  - Linux
  - PHP
  - 技巧
categories: PHP
abbrlink: 32955
date: 2016-03-15 09:51:54
---


Shell script要对此目录下所有PHP做Syntax check(注:-l Syntax check only), 可以用下述写法:

**此目录內 *.php 文件做Syntax check**

```bash
for f in `ls *.php`; do
    php -l $f;
done
```
<!-- more -->
**此目录內, 所有目录含有php都做Syntax check**

```
for f in `find ./ -name *.php`; do
    php -l $f;
done
```

> 注:可在搭配grep过滤。



