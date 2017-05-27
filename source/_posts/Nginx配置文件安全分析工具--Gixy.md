---
category: Nginx
title: Nginx配置文件安全分析工具——Gixy
date: 2017-05-27 9:00:00
tags: [Nginx,技巧]
abbrlink:
updated:
toc_number: false
---

Gixy是一款用来分析Nginx配置的工具。 Gixy的主要目标是防止安全配置错误，并自动进行缺陷检测。

**Gixy特性**

- 找出服务器端请求伪造。
- 验证HTTP拆分。
- 验证referrer/origin问题。
- 验证是否正确通过add_header指令重新定义Response Headers。
- 验证请求的主机头是否伪造。
- 验证valid_referers是否为空。
- 验证是否存在多行主机头。

项目地址：https://github.com/yandex/gixy

<!-- more -->

**Gixy安装**

Gixy是一个Python开发的应用，目前支持的Python版本是2.7和3.5+。

安装步骤非常简单，直接使用pip安装即可：

```
$ pip install gixy
```

如果你的系统比较老，自带Python版本比较低。可参考「[使用pyenv搭建python虚拟环境](https://www.hi-linux.com/posts/63429.html)」或者「[如何在CentOS上启用软件集Software Collections(SCL)](https://www.hi-linux.com/posts/62916.html)」升级Python版本。

**Gixy使用**

Gixy默认会检查`/etc/nginx/nginx.conf`配置文件。


```
$ gixy
```

也可以指定NGINX配置文件所在的位置。


```
$ gixy /usr/local/nginx/conf/nginx.conf

==================== Results ===================
No issues found.

==================== Summary ===================
Total issues:
    Unspecified: 0
    Low: 0
    Medium: 0
    High: 0
```


来看一个http折分配置有问题的示例，修改Nginx配置：

```
server {

...

  location ~ /v1/((?<action>[^.]*)\.json)?$ {
    add_header X-Action $action;
  }
...

}
```

再次运行Gixy检查配置。

```
$ gixy /usr/local/nginx/conf/nginx.conf


==================== Results ===================

>> Problem: [http_splitting] Possible HTTP-Splitting vulnerability.
Description: Using variables that can contain "\n" may lead to http injection.
Additional info: https://github.com/yandex/gixy/blob/master/docs/en/plugins/httpsplitting.md
Reason: At least variable "$action" can contain "\n"
Pseudo config:

server {
	server_name localhost mike.hi-linux.com;

	location ~ /v1/((?<action>[^.]*)\.json)?$ {
		add_header X-Action $action;
	}
}

==================== Summary ===================
Total issues:
    Unspecified: 0
    Low: 0
    Medium: 0
    High: 1
```

从结果可以看出检测到了一个问题，指出问题类型为`http_splitting`。原因是`$action`变量中可以含有换行符。这就是HTTP响应头拆分漏洞，通过CRLFZ注入实现攻击。


如果你要暂时忽略某类错误检查，可以使用`--skips`参数：

```
$ gixy --skips http_splitting /usr/local/nginx/conf/nginx.conf
==================== Results ===================
No issues found.

==================== Summary ===================
Total issues:
    Unspecified: 0
    Low: 0
    Medium: 0
    High: 0
```

更多使用方法可以参考`gixy --help`命令。

**参考文档**

http://www.google.com
https://github.com/yandex/gixy
