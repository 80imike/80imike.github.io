---
category: PHP
title: 利用 PHP 快速建立一个 Web 服务器
date: 2018-06-04 09:00:00
tags: [Linux, PHP]
abbrlink:
updated:
toc_number: false
---

在「[用 Python 快速实现 HTTP 和 FTP 服务器](https://mp.weixin.qq.com/s?__biz=MzI3MTI2NzkxMA==&mid=2247485646&idx=1&sn=7f4d90f0ae008fc3fc3d6857a6f697ea&chksm=eac529e7ddb2a0f1dca9460dd8ab8f9bb4b3506176443133f3618cd83a499b29508c844e5824&mpshare=1&scene=23&srcid=0604RCv1lCh21KgmI3hB8FoB%23rd)」一文中，我们介绍了如何用 Python 快速建立一个 HTTP 和 FTP 服务器的方法。今天我们再来分享一个用 PHP 快速建立 Web 服务器的方法。

从 PHP 5.4.0 起， CLI SAPI 提供了一个内置的 Web 服务器。我们可以通过这个内置的 Web 服务器很方便的搭建一个本地开发环境。

- 启动 Web 服务器

默认情况下，URI 请求会被发送到 PHP 所在的的工作目录进行处理。

```
$ cd /tmp/wordpress-install
$ php -S localhost:8000
PHP 7.1.16 Development Server started at Mon Jun  4 16:48:42 2018
Listening on http://localhost:8000
Document root is /private/tmp/wordpress-install
Press Ctrl-C to quit.
```

> 如果请求未指定执行 PHP 文件，则默认执行目录内的 `index.php` 或者 `index.html`。如果这两个文件都不存在，服务器会则返回 404 错误。

<!-- more -->

接着通过浏览器打开 `http://localhost:8000/` 就可访问对应的 Web 程序，在终端窗口会输出类似以下的访问日志：

```
[Mon Jun  4 16:50:55 2018] ::1:54854 [302]: /
[Mon Jun  4 16:50:55 2018] ::1:54855 [200]: /wp-admin/setup-config.php
[Mon Jun  4 16:50:55 2018] ::1:54858 [200]: /wp-includes/css/buttons.min.css?ver=4.9.4
[Mon Jun  4 16:50:55 2018] ::1:54860 [200]: /wp-includes/js/jquery/jquery.js?ver=1.12.4
[Mon Jun  4 16:50:55 2018] ::1:54859 [200]: /wp-admin/css/install.min.css?ver=4.9.4
[Mon Jun  4 16:50:55 2018] ::1:54861 [200]: /wp-includes/js/jquery/jquery-migrate.min.js?ver=1.4.1
[Mon Jun  4 16:50:55 2018] ::1:54862 [200]: /wp-admin/js/language-chooser.min.js?ver=4.9.4
[Mon Jun  4 16:50:56 2018] ::1:54863 [200]: /wp-admin/images/wordpress-logo.svg?ver=20131107
[Mon Jun  4 16:50:57 2018] ::1:54864 [404]: /favicon.ico - No such file or directory
```

- 启动时指定根目录

如果要自定义启动根目录，你可以使用 `-t` 参数来自定义不同的目录。

```
$ cd /tmp/wordpress-install
$ php -S localhost:8000 -t wp-admin/
PHP 7.1.16 Development Server started at Mon Jun  4 16:53:55 2018
Listening on http://localhost:8000
Document root is /private/tmp/wordpress-install/wp-admin
Press Ctrl-C to quit.
[Mon Jun  4 16:54:04 2018] ::1:54912 [302]: /
```

- 使用路由脚本

默认情况下，PHP 建立的 Web 服务器会由 `index.php` 接收所有请求参数。如果要让指定的 PHP 文件来处理请求，可以在启动这个 Web 服务器时直接指定要处理请求的文件名。这个文件会作为一个路由脚本，意味着每次请求都会先执行这个脚本。(通常将此文件命名为 router.php)

下面我们来看一个例子，请求图片直接显示图片，请求 HTML 则显示 "Welcome to PHP"。

```
$ vim router.php

<?php
// router.php
if (preg_match('/\.(?:png|jpg|jpeg|gif)$/', $_SERVER["REQUEST_URI"]))
    return false;    // 直接返回请求的文件
else { 
    echo "<p>Welcome to PHP</p>";
}
?>
```

执行后，访问 HTML 文件就会在终端窗口输出对应的 HTML 代码。

```
$ php -S localhost:8000 router.php
PHP 7.1.16 Development Server started at Mon Jun  4 17:00:19 2018
Listening on http://localhost:8000
Document root is /private/tmp/wordpress-install
Press Ctrl-C to quit.

$ curl http://localhost:8000/index.html
<p>Welcome to PHP</p>%
```

接下来，我们在看看访问图片。访问图片后就会在终端窗口输出类似以下的访问日志：

```
[Mon Jun  4 17:00:39 2018] ::1:55008 [200]: /wp-content/themes/twentyseventeen/assets/images/coffee.jpg
[Mon Jun  4 17:00:57 2018] ::1:55034 [200]: /wp-content/themes/twentyseventeen/assets/images/espresso.jpg
[Mon Jun  4 17:01:08 2018] ::1:55035 [200]: /wp-content/themes/twentyseventeen/assets/images/header.jpg
[Mon Jun  4 17:01:16 2018] ::1:55037 [200]: /wp-content/themes/twentyseventeen/assets/images/sandwich.jpg
```

- 参考文档

http://www.google.com
http://t.cn/RGpN4yf
http://t.cn/R18XGlM