---
title: Nginx/Apache下禁止指定目录运行PHP脚本
tags:
  - Nginx
  - Linux
categories: Nginx
abbrlink: 42933
date: 2016-09-22 09:00:00
updated:
toc_number:
---

网站程序的上传目录通常是不需要PHP执行解释权限，通过限制目录的PHP执行权限可以提网站的安全性,减少被攻击的机率。

下面和大家一起分享下如何在Apache和Nginx禁止上传目录里PHP的执行权限。

- Apache下禁止指定目录运行PHP脚本

在虚拟主机配置文件中增加php_flag engine off指令即可，配置如下

```bash
<Directory ~ "/website/uploads">
  Options FollowSymLinks
  AllowOverride None
  Order allow,deny
  Allow from all 
  php_flag engine off
</Directory>
```

<!-- more -->

- Nginx下禁止指定目录运行PHP脚本

Nginx更简单,直接通过location条件匹配定位后进行权限禁止。

在server配置段中增加如下的配置

如果是单个目录

```bash
location ~* ^/uploads/.*\.(php|php5)$
{
  deny all;
}
```

如果是多个目录

```bash
location ~* ^/(attachments|uploads)/.*\.(php|php5)$
{
  deny all;
}
```

**注意:这段配置文件一定要放在下面配置的前面才可以生效的。**

```bash
location ~ \.php$ {
fastcgi_pass   127.0.0.1:9000;
fastcgi_index  index.php;
fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
include        fastcgi_params;
}
```

最后给一个完整的配置示例

```bash

location ~ /mm/(data|uploads|templets)/*.(php)$ {
  deny all;
}


location ~ .php$ {
  try_files $uri /404.html;
  fastcgi_pass   127.0.0.1:9000;
  fastcgi_index  index.php;
  fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
  include        fastcgi_params;
}
```
		
配置完后记得重启Nginx生效。