---
category: Nginx
title: 利用ModSecurity在Nginx上构建WAF
date: 2017-06-12 9:00:00
tags: [Nginx,技巧]
abbrlink:
updated:
toc_number: false
---

ModSecurity原本是Apache上的一款开源WAF模块，可以有效的增强Web安全性。目前已经支持Nginx和IIS，配合Nginx的灵活和高效可以打造成生产级的WAF，是保护和审核Web安全的利器。

在这篇文章中，我们将学习配置ModSecurity与OWASP的核心规则集。

### 什么是ModSecurity

ModSecurity是一个入侵侦测与防护引擎，它主要是用于Web应用程序，所以也被称为Web应用程序防火墙(WAF)。它可以作为Web服务器的模块或是单独的应用程序来运作。ModSecurity的功能是增强Web Application 的安全性和保护Web application以避免遭受来自已知与未知的攻击。

ModSecurity计划是从2002年开始，后来由Breach Security Inc.收购，但Breach Security Inc.允诺ModSecurity仍旧为Open Source，并开放源代码给大家使用。最新版的ModSecurity开始支持核心规则集(Core Rule Set)，CRS可用于定义旨在保护Web应用免受0day及其它安全攻击的规则。

ModSecurity还包含了其他一些特性，如并行文本匹配、Geo IP解析和信用卡号检测等，同时还支持内容注入、自动化的规则更新和脚本等内容。此外，它还提供了一个面向Lua语言的新的API，为开发者提供一个脚本平台以实现用于保护Web应用的复杂逻辑。

官网：https://www.modsecurity.org/

<!-- more -->

### 什么是OWASP CRS

OWASP是一个安全社区，开发和维护着一套免费的应用程序保护规则，这就是所谓OWASP的ModSecurity的核心规则集(即CRS)。ModSecurity之所以强大就在于OWASP提供的规则，我们可以根据自己的需求选择不同的规则，也可以通过ModSecurity手工创建安全过滤器、定义攻击并实现主动的安全输入验证。

ModSecurity核心规则集(CRS)提供以下类别的保护来防止攻击。

- HTTP Protection(HTTP防御)

HTTP协议和本地定义使用的detectsviolations策略。

- Real-time Blacklist Lookups(实时黑名单查询)

利用第三方IP名单。

- HTTP Denial of Service Protections(HTTP的拒绝服务保护)

防御HTTP的洪水攻击和HTTP Dos攻击。  

- Common Web Attacks Protection(常见的Web攻击防护)

检测常见的Web应用程序的安全攻击。  

- Automation Detection(自动化检测)

检测机器人，爬虫，扫描仪和其他表面恶意活动。  

- Integration with AV Scanning for File Uploads(文件上传防病毒扫描)

检测通过Web应用程序上传的恶意文件。  

- Tracking Sensitive Data(跟踪敏感数据)

信用卡通道的使用，并阻止泄漏。  

- Trojan Protection(木马防护)

检测访问木马。  

- Identification of Application Defects(应用程序缺陷的鉴定)

检测应用程序的错误配置警报。

- Error Detection and Hiding(错误检测和隐藏)

检测伪装服务器发送错误消息。

### 安装ModSecurity

#### 软件基础环境准备

- 下载对应软件包

```
$ cd /root
$ wget 'http://nginx.org/download/nginx-1.9.2.tar.gz'
$ wget -O modsecurity-2.9.1.tar.gz https://github.com/SpiderLabs/ModSecurity/releases/download/v2.9.1/modsecurity-2.9.1.tar.gz
```

- 安装Nginx和ModSecurity依赖包

Centos/RHEL

```
$ yum install httpd-devel apr apr-util-devel apr-devel  pcre pcre-devel  libxml2 libxml2-devel zlib zlib-devel openssl openssl-devel
```

Ubuntu/Debian

```
$ apt-get install libreadline-dev libncurses5-dev libssl-dev perl make build-essential git  libpcre3 libpcre3-dev libtool autoconf apache2-dev libxml2 libxml2-dev libcurl4-openssl-dev g++ flex bison curl doxygen libyajl-dev libgeoip-dev dh-autoreconf libpcre++-dev
```

#### 编译安装ModSecurity

Nginx加载ModSecurity模块有两种方式:一种是编译为Nginx静态模块，一种是通过ModSecurity-Nginx Connector加载动态模块。

方法一：编译为Nginx静态模块

- 编译为独立模块(modsecurity-2.9.1)

```
$ tar xzvf modsecurity-2.9.1.tar.gz
$ cd modsecurity-2.9.1/
$ ./autogen.sh
$ ./configure --enable-standalone-module --disable-mlogc
$ make
```

- 编译安装Nginx并添加ModSecurity模块

```
$ tar xzvf nginx-1.9.2.tar.gz
$ cd nginx-1.9.2
$ ./configure --add-module=/root/modsecurity-2.9.1/nginx/modsecurity/
$ make && make install
```

方法二：编译通过ModSecurity-Nginx Connector加载的动态模块

- 编译LibModSecurity(modsecurity-3.0)

```
$ cd /root
$ git clone https://github.com/SpiderLabs/ModSecurity
$ cd ModSecurity
$ git checkout -b v3/master origin/v3/master
$ sh build.sh
$ git submodule init
$ git submodule update
$ ./configure
$ make
$ make install
```

LibModSecurity会安装在`/usr/local/modsecurity/lib`目录下。

```
$ ls /usr/local/modsecurity/lib
libmodsecurity.a  libmodsecurity.la  libmodsecurity.so  libmodsecurity.so.3  libmodsecurity.so.3.0.0
```

- 编译安装Nginx并添加ModSecurity-Nginx Connector模块

使用ModSecurity-Nginx模块来连接LibModSecurity

```
$ cd /root
$ git clone https://github.com/SpiderLabs/ModSecurity-nginx.git modsecurity-nginx
$ tar xzvf nginx-1.9.2.tar.gz
$ cd nginx-1.9.2
$ ./configure --add-module=/root/modsecurity-nginx
$ make
$ make && make install
```

### 添加OWASP规则

ModSecurity倾向于过滤和阻止Web危险，之所以强大就在于规则。OWASP提供的规则是社区志愿者维护的被称为核心规则CRS,规则可靠强大，当然也可以自定义规则来满足各种需求。

#### 下载OWASP规则并生成配置文件

```
$ git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git
$ cp -rf owasp-modsecurity-crs  /usr/local/nginx/conf/
$ cd /usr/local/nginx/conf/owasp-modsecurity-crs
$ cp crs-setup.conf.example  crs-setup.conf   
```

#### 配置OWASP规则

编辑crs-setup.conf文件

```
$ sed -ie 's/SecDefaultAction "phase:1,log,auditlog,pass"/#SecDefaultAction "phase:1,log,auditlog,pass"/g' crs-setup.conf
$ sed -ie 's/SecDefaultAction "phase:2,log,auditlog,pass"/#SecDefaultAction "phase:2,log,auditlog,pass"/g' crs-setup.conf
$ sed -ie 's/#.*SecDefaultAction "phase:1,log,auditlog,deny,status:403"/SecDefaultAction "phase:1,log,auditlog,deny,status:403"/g' crs-setup.conf
$ sed -ie 's/# SecDefaultAction "phase:2,log,auditlog,deny,status:403"/SecDefaultAction "phase:2,log,auditlog,deny,status:403"/g' crs-setup.conf
```

默认ModSecurity不会阻挡恶意连接，只会记录在Log里。修改SecDefaultAction选项，默认开启阻挡。

#### 启用ModSecurity模块和CRS规则

复制ModSecurity源码目录下的modsecurity.conf-recommended和unicode.mapping到Nginx的conf目录下，并将modsecurity.conf-recommended重新命名为modsecurity.conf。

modsecurity.conf-recommended是ModSecurity工作的主配置文件。默认情况下，它带有.recommended扩展名。要初始化ModSecurity，我们就要重命名此文件。

```
$ cd /root/modsecurity-2.9.1/
$ cp modsecurity.conf-recommended /usr/local/nginx/conf/modsecurity.conf  
$ cp unicode.mapping  /usr/local/nginx/conf/
```

将SecRuleEngine设置为On，默认值为DetectOnly即为观察模式，建议大家在安装时先默认使用这个模式，规则测试完成后在设置为On，避免出现对网站、服务器某些不可知的影响。

```
$ vim /usr/local/nginx/conf/modsecurity.conf
SecRuleEngine On
```

ModSecurity中几个常用配置说明：

> 1.SecRuleEngine：是否接受来自ModSecurity-CRS目录下的所有规则的安全规则引擎。因此，我们可以根据需求设置不同的规则。要设置不同的规则有以下几种。SecRuleEngine On：将在服务器上激活ModSecurity防火墙，它会检测并阻止该服务器上的任何恶意攻击。SecRuleEngine Detection Only：如果设置这个规则它只会检测到所有的攻击，并根据攻击产生错误，但它不会在服务器上阻止任何东西。SecRuleEngine Off:这将在服务器上上停用ModSecurity的防火墙。
>
> 2.SecRequestBodyAccess：它会告诉ModSecurity是否会检查请求，它起着非常重要的作用。它只有两个参数ON或OFF。
>
> 3.SecResponseBodyAccess：如果此参数设置为ON，然后ModeSecurity可以分析服务器响应，并做适当处理。它也有只有两个参数ON和Off，我们可以根据求要进行设置。
>
> 4.SecDataDir：定义ModSecurity的工作目录，该目录将作为ModSecurity的临时目录使用。

在`owasp-modsecurity-crs/rules`下有很多定义好的规则，将需要启用的规则用Include指令添加进来就可以了。

- 3.x版本CRS

```
$ cd /usr/local/nginx/conf/owasp-modsecurity-crs
# 生成例外排除请求的配置文件
$ cp rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
$ cp rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
$ cp rules/*.data /usr/local/nginx/conf
```

为了保持modsecurity.conf简洁，这里新建一个modsec_includes.conf文件,内容为需要启用的规则。

```
$ vim /usr/local/nginx/conf/modsec_includes.conf

include modsecurity.conf
include owasp-modsecurity-crs/crs-setup.conf
include owasp-modsecurity-crs/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
include owasp-modsecurity-crs/rules/REQUEST-901-INITIALIZATION.conf
Include owasp-modsecurity-crs/rules/REQUEST-903.9002-WORDPRESS-EXCLUSION-RULES.conf
include owasp-modsecurity-crs/rules/REQUEST-905-COMMON-EXCEPTIONS.conf
include owasp-modsecurity-crs/rules/REQUEST-910-IP-REPUTATION.conf
include owasp-modsecurity-crs/rules/REQUEST-911-METHOD-ENFORCEMENT.conf
include owasp-modsecurity-crs/rules/REQUEST-912-DOS-PROTECTION.conf
include owasp-modsecurity-crs/rules/REQUEST-913-SCANNER-DETECTION.conf
include owasp-modsecurity-crs/rules/REQUEST-920-PROTOCOL-ENFORCEMENT.conf
include owasp-modsecurity-crs/rules/REQUEST-921-PROTOCOL-ATTACK.conf
include owasp-modsecurity-crs/rules/REQUEST-930-APPLICATION-ATTACK-LFI.conf
include owasp-modsecurity-crs/rules/REQUEST-931-APPLICATION-ATTACK-RFI.conf
include owasp-modsecurity-crs/rules/REQUEST-932-APPLICATION-ATTACK-RCE.conf
include owasp-modsecurity-crs/rules/REQUEST-933-APPLICATION-ATTACK-PHP.conf
include owasp-modsecurity-crs/rules/REQUEST-941-APPLICATION-ATTACK-XSS.conf
include owasp-modsecurity-crs/rules/REQUEST-942-APPLICATION-ATTACK-SQLI.conf
include owasp-modsecurity-crs/rules/REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION.conf
include owasp-modsecurity-crs/rules/REQUEST-949-BLOCKING-EVALUATION.conf
include owasp-modsecurity-crs/rules/RESPONSE-950-DATA-LEAKAGES.conf
include owasp-modsecurity-crs/rules/RESPONSE-951-DATA-LEAKAGES-SQL.conf
include owasp-modsecurity-crs/rules/RESPONSE-952-DATA-LEAKAGES-JAVA.conf
include owasp-modsecurity-crs/rules/RESPONSE-953-DATA-LEAKAGES-PHP.conf
include owasp-modsecurity-crs/rules/RESPONSE-954-DATA-LEAKAGES-IIS.conf
include owasp-modsecurity-crs/rules/RESPONSE-959-BLOCKING-EVALUATION.conf
include owasp-modsecurity-crs/rules/RESPONSE-980-CORRELATION.conf
include owasp-modsecurity-crs/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf
```

注：考虑到可能对主机性能上的损耗，可以根据实际需求加入对应的漏洞的防护规则即可。

### 配置Nginx支持Modsecurity

#### 启用Modsecurity

- 使用静态模块加载的配置方法

在需要启用Modsecurity的主机的location下面加入下面两行即可：

```
ModSecurityEnabled on;
ModSecurityConfig modsec_includes.conf;
```

修改Nginx配置文件，在需要启用Modsecurity的location开启Modsecurity。

```
$ vim /usr/local/nginx/conf/nginx.conf

server {
  listen       80;
  server_name  example.com;

  location / {
    ModSecurityEnabled on;
    ModSecurityConfig modsec_includes.conf;
    root   html;
    index  index.html index.htm;
  }
}
```

- 使用动态模块加载的配置方法

在需要启用Modsecurity的主机的location下面加入下面两行即可：

```
modsecurity on;
modsecurity_rules_file modsec_includes.conf;
```

修改Nginx配置文件，在需要启用Modsecurity的location开启Modsecurity。

```
$ vim /usr/local/nginx/conf/nginx.conf

server {
  listen  80;
  server_name localhost mike.hi-linux.com;
  access_log /var/log/nginx/yourdomain.log;

  location / {

  modsecurity on;
  modsecurity_rules_file modsec_includes.conf;
  root   html;
  index  index.html index.htm;
}
}
```

#### 验证Nginx配置文件

```
$ /usr/local/nginx/sbin/nginx -t
nginx: the configuration file /usr/local/nginx/conf/nginx.conf syntax is ok
nginx: configuration file /usr/local/nginx/conf/nginx.conf test is successful
```

- 启动Nginx

```
$ /usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
```

### 测试Modsecurity

ModSecurity现在已经成功配置了OWASP的规则。现在我们将测试对一些最常见的Web应用攻击。来测试ModSecurity是否挡住了攻击。这里我们启用了XSS和SQL注入的过滤规则，下面的例子中不正常的请求会直接返回403。

在浏览器中访问默认首页，会看到Nginx默认的欢迎页：

![](https://www.hi-linux.com/img/linux/Modsecurity1.png)

这时我们在网址后面自己加上正常参数，例如：`http://mike.hi-linux.com/?id=1`。同样会看到Nginx默认的欢迎页：

![](https://www.hi-linux.com/img/linux/Modsecurity2.png)

接下来，我们在前面正常参数的基础上再加上`AND 1=1`,整个请求变成：`http://mike.hi-linux.com/?id=1 AND 1=1`

![](https://www.hi-linux.com/img/linux/Modsecurity3.png)

就会看到Nginx返回403 Forbidden的信息了，说明Modsecurity成功拦截了此请求。再来看一个XSS的例子，同样会被Modsecurity拦截。

![](https://www.hi-linux.com/img/linux/Modsecurity4.png)

查看Modsecurity日志

![](https://www.hi-linux.com/img/linux/Modsecurity5.png)

所有命中规则的外部攻击均会存在modsec_audit.log,用户可以对这个文件中记录进行审计。Log文件位置在modsecurity.conf中SecAuditLog选项配置，Linux默认在`/var/log/modsec_audit.log`。

```
$ cat /usr/local/nginx/conf/modsecurity.conf
SecAuditLog /var/log/modsec_audit.log
```

Modsecurity主要是规则验证(验证已知漏洞)，Nginx下还有另一个功能强大的WAF模块Naxsi。Naxsi最大特点是可以设置学习模式，抓取您的网站产生必要的白名单，以避免误报！Naxsi不依赖于预先定义的签名，Naxsi能够战胜更多复杂/未知/混淆的攻击模式。

### 参考文档

http://www.google.com
https://yq.aliyun.com/articles/54475
http://liubin0505star.blog.51cto.com/5550456/1784499
https://m.mobile01.com/topicdetail.php?f=506&t=5134424
http://www.52os.net/articles/nginx-use-modsecurity-module-as-waf.html
http://www.wuedc.com/nginx-installed-configuration-modsecurity-waf/
