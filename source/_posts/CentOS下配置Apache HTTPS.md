---
title: CentOS下配置Apache HTTPS
tags:
  - Linux
  - Apache
  - 技巧
categories: Apache
abbrlink: 18762
date: 2016-03-15 09:51:54
---

### 一、安装Apache支持SSL/TLS

```bash
yum install mod_ssl openssl
```
<!-- more -->
### 二、创建证书

> 证书(Cerificate)的基本作用是将一个公钥和安全个体(个人、公司、组织等)的名字绑定在一起。
> 
> 一般情况下，制作证书要经过几个步骤，如上图所示。首先用openssl genrsa生成一个私钥，然后用openssl req生成一个签署请求，最后把请求交给CA，CA签署后就成为该CA认证的证书了。如果在第二步请求时加上-x509参数，那么就直接生成一个self-signed的证书，即自己充当CA认证自己。<!--more-->
> 
> 除了这种方式外，在Debian或者Ubuntu系统中有更加简便的方法制作self-signed证书使用make-ssl-cert命令。该命令在ssl-cert的包里，一般会伴随着Apache的安装而安装，可能单独安装也可以。
> 
> 如果您只是想做一张测试用的电子证书或不想花钱去找个 CA 签署，您可以造一张自签 (Self-signed) 的电子证书。当然这类电子证书没有任何保证，大部份软件偶到这证书会发出警告，甚至不接收这类证书。 使用自签名(self-signed)的证书，它的主要目的不是防伪，而是使用户和系统之间能够进行SSL通信，保证密码等个人信息传输时的安全。
> 
> 这里先说下证书相关的几个名词：
> 
> RSA私钥能解密用证书公钥加密后的信息。通常以.key为后缀，表示私钥也称作密钥。是需要管理员小心保管，不能泄露的。
> 
> CSR(Certificate Signing Request)包含了公钥和名字信息。通常以.csr为后缀，是网站向CA发起认证请求的文件，是中间文件。
> 
> 证书通常以.crt为后缀，表示证书文件。
> 
> CA(Certifying Authority)表示证书权威机构，它的职责是证明公钥属于个人、公司或其他的组织。
 

**由于默认配置文件中证书名为localhost.crt和localhost.key，这里就按两个文件名生成。**

#### 步骤1、生成私钥
```bash
cd /etc/pki/tls/private/
openssl genrsa -des3 1024 >localhost.key
```
> 注：采用DES3加密新产生的私钥localhost.key文件，每次要使用这个私钥时都要用输入密码。如果您的电子证书是用在apache等服务器中，您每次启动服务器时都要输入密码一次。


```bash
openssl genrsa 1024 >localhost.key
```

> 注：采用128位rsa算法生成密钥localhost.key文件，这种方法产生的证书在apache等服务器中启动服务器时不会要求输入密码，同时也不会把私钥加密。 

#### 步骤2: 生成证书请求文件(Certificate Signing Request)

```bash
openssl req -new -key localhost.key > localhost.csr
```

> 注：这是用步骤1的密钥生成证书请求文件localhost.csr, 这一步输入内容和创建自签名证书的内容类似，按要求输入就可以了。

#### 步骤3: 签署生成证书

- 三方签署

您只要把localhost.csr这个档案给第三方CA(Certificate Authority)机构签署生成证书就可以了。

- 自签名证书
```bash
openssl -x509 -req -days 365 -in localhost.csr -signkey localhost.key -out localhost.crt
```

### 三、配置Apache


ssl配置文件在/etc/httpd/conf.d/ssl.conf,默认就行，不需要更改。

这里看下证书及密钥的默认位置

```bash
cat /etc/httpd/conf.d/ssl.conf

SSLCertificateFile /etc/pki/tls/certs/localhost.crt
SSLCertificateKeyFile /etc/pki/tls/private/localhost.key
```

#### 配置虚拟主机

编辑ssl.conf文件，加入证书对应的主机头。

```bash
vi /etc/httpd/conf.d/ssl.conf

ServerName www.example.com
```

#### 配置SSL证书

编辑配置文件，修改如下几行：

- 如果是自签名证书，按如下配置：

```bash
vi /etc/httpd/conf.d/ssl.conf

SSLEngine on
SSLCertificateFile /etc/pki/tls/certs/localhost.crt
SSLCertificateKeyFile /etc/pki/tls/private/localhost.key
```

> 注：如果SSLCertificateFile中指定的证书已包含相应私钥，SSLCertificateKeyFile这一行就可以注释掉。

- 如果是第三方签署的CA证书，按如下配置：

```bash
SSLEngine on
SSLCertificateFile    /etc/ssl/certs/ssl-cert-snakeoil.pem
SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
SSLCertificateChainFile /etc/ssl/certs/server-ca.crt
```

>各指令含义：
>
>SSLEngine ：这个指令用于开启或关闭SSL/TLS协议引擎。
> 
>SSLCertificateFile：该指令用于指定服务器持有的X.509证书(PEM编码)，其中还可以包含对应的RSA或DSA私钥。如果其中包含的私钥已经使用密语加密，那么在Apache启动的时候将会提示输入密语。
> 
>SSLCertificateKeyFile：指定了服务器私钥文件(PEM编码)的位置。如果SSLCertificateFile指定的服务器证书文件中不包含相应的私钥，那么就必须使用该指令，否则就不需要使用。
> 
>SSLCertificateChainFile：这个指令指定了一个多合一的CA证书，用于明确的创建服务器的证书链。这个证书链将被与服务器证书一起发送给客户端，由直接签发服务器证书的CA证书开始，按证书链顺序回溯，一直到根CA的证书结束，这一系列的CA证书(PEM格式)就构成了服务器的证书链。这有利于避免在执行客户端认证时多个CA证书之间出现混淆或冲突。

#### 测试Apache HTTPS

- 重启Apache

```bash
/etc/init.d/httpd restart
```
> 注：如果有设置的私人密钥的密码，则会要求输入。

> Apache/2.2.21 mod_ssl/2.2.21 (Pass Phrase Dialog)
> Some of your private key files are encrypted for security reasons.
> In order to read them you have to provide the pass phrases.
>  
> Server www.example.com:443 (RSA)
> Enter pass phrase:
> OK: Pass Phrase Dialog successful.

- 使用curl来验证

curl https://localhost/ -k 

> -k参数的意思是允许不验证访问SSL站点，因为如果要验证，就不能使用localhost做测试，而只能用生成证书时明确指定的域名。

- 使用浏览器

访问服务器时输入https://域名(或IP)，浏览器会弹出安装服务器证明书的窗口。说明服务器已经支持SSL了。

### 四、其它知识点

在上面SSL站点配置文件中所使用的是"_default_"(默认虚拟主机)，下面说下相关的知识点。

"_default_"(默认虚拟主机)虚拟主机可以捕获所有指向没指定的IP地址和端口的请求。比如：一个没被任何虚拟主机使用的地址/端口对。

仅当没有其他虚拟主机符合客户端请求的IP地址和端口号时，"_default_"虚拟主机才会捕获这个请求。并且仅当"_default_"虚拟主机的端口号(默认值由您的Listen指定)与客户端发送请求的目的端口号相符时，这个请求才会被捕获。也可以使用通配符(例如："_default_:*")来捕获任何端口号的请求。

服务器配置示例：

```bash
<VirtualHost _default_:443>
DocumentRoot /www/default
......
</VirtualHost>
```

这段配置内容的意思是所有访问这个WEB服务器的443端口的请求会被这个默认虚拟主机处理。

另外仅当客户端连接的目的IP地址和端口号没有指定而且不与任何一个虚拟主机(包括"_default_"虚拟主机)匹配的时候，才会用主服务器来伺服请求。换句话说，主服务器仅捕获没有指定IP地址和端口的请求。

### 五、参考文档

> <http://www.goolge.com>
> <http://www.itchenyi.com/4057.html>
> <http://www.centoscn.com/image-text/config/2013/1226/2269.html>