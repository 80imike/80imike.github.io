---
title: Apache中文乱码解决办法
tags:
  - Linux
  - Apache
  - 技巧
categories: Apache
abbrlink: 38860
date: 2016-03-15 09:00:00
---


### 方法一、通过服务器配置

#### 1.设定默认的编码

- 修改httpd.conf(CentOS为/etc/httpd/conf/)

```bash
vim /etc/httpd/conf/http.conf

查找AddDefaultCharset改成AddDefaultCharset UTF-8即可(具体设置编码视情况而定，通常为UTF-8)。
```
- 关闭AddDefaultCharset

低版本的apache可能需要设置成AddDefaultCharset off。这种方式关掉了服务器的默认语言的发送，这样仅凭html文件头中设置的语言来决定网页语言。 
<!-- more -->
- 重启Apache

```bash
/etc/init.d/httpd restart
``` 
- Apache关于defaultcharset的设置和优先级的问题

> 1.页面没有指定charset，Apache配置defaultcharset gbk , 页面文件编码是utf-8。
>   执行结果是页面乱码。这个几乎是肯定的，在页面没有meta指明charset，而服务器的defaultcharset又没有被注释掉，可以肯定页面是会乱码的，这个时候服务器的设置生效；
>   
> 2.页面指定charset为utf-8,  Apache配置defaultcharset  gbk. 页面文件是utf-8。
>   执行结果是页面乱码。这个就验证了当服务器的defaultcharset打开时，会忽略掉页面的编码设置；
>   
> 3.PHP header申明charset为utf8, Apache配置defaultcharst gbk,页面文件编码是utf8。
>   执行结果是页面正常。这个说明header中指定的信息的优先级要高于服务器及浏览器的设置；
>   
> 4.Apache设置DefaultCharset off。
>   页面显示正常。

> 最后，在Apache的手册中找到结论。
> 
> AddDefaultCharset 指令
> 说明    当应答内容是text/plain或text/html时，在HTTP应答头中加入的默认字符集
> 语法    AddDefaultCharset On|Off|charset
> 默认值    AddDefaultCharset Off
> 作用域    server config, virtual host, directory, .htaccess
> 覆盖项    FileInfo
> 状态    核心(C)
> 模块    core
> 
> 当且仅当应答内容是text/plain或text/html时，此指令将会在HTTP应答头中加入的默认字符集。理论上这将覆盖在文档体中通过<meta>标 签指定的字符集，但是实际的行为通常取决于用户浏览器的设置。AddDefaultCharset Off将会禁用此功能。 AddDefaultCharset On将启用Apache内部的默认字符集iso-8859-1 。您也可以指定使用在IANA注册过的字符集名字 中的另外一个charset 。比如说：
> 
> AddDefaultCharset utf-8 
> 
> 如果服务器和页面都没有指定编码，我想这时编码是由浏览器的默认编码来确定的，这时Firefox和IE就会发生区别，当然是指安装在中文系统里的浏览器，如果系统不同我想结果还会有差异。


#### 2.当使用一些网页脚本引擎。如PHP,还可能需要修改相应的配置文件。

以PHP为例，需要修改php.ini (Centos中位置在/etc/)

```bash
vim /etc/php.ini 
找到：  
default_charset = "iso-8859-1" 或者类似的将其注释掉，默认是没有打开的。  
;default_charset="iso-8859-1"
``` 

### 方法二、通过代码指定

在中文网页请中依情况在标签中添加：

```  
GB2312:  
<META content="text/html; charset=gb2312" http-equiv="Content-Type">  

BIG5:  
<META content="text/html; charset=big5" http-equiv="Content-Type">  

UTF-8: (注意是UTF-8)  
<META content="text/html; charset=utf-8" http-equiv="Content-Type">
```