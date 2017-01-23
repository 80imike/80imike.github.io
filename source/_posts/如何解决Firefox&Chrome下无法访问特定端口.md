---
title: 如何解决Firefox&Chrome下无法访问特定端口
tags:
  - Chrome
  - Firefox
categories: 技巧
abbrlink: 21003
date: 2016-06-27 09:00:01
updated:
toc_number:
---

在做测试、调试时我们会给Web服务器(如Tomcat、Nginx)等设置一些特殊的访问端口，比如`87,6666,556,6667`等。

如果用Chorme访问就会报类似错误，如下所示： 

```
错误312(net：：ERR_UNSAFE_PORT)
```

如果用Firefox访问就会报类似错误，如下所示： 

```
此地址访问受限，此地址使用了一个通常用于网络浏览以外目的的端口。出于安全原因，Firefox 取消了该请求。
```

<!-- more -->

如果一定要使用上述端口，可使用以下的方法解决：

- Firefox

在Firefox地址栏输入`about:config`，然后在右键新建一个字符串键`network.security.ports.banned.override`，值就是将需访问网站的端口号即可。如有多个就半角逗号隔开，例：`87,6666,556,6667`。在能保证安全的前提下，还简化成这样写`0-65535`。这样就可以浏览任意端口的网站了。

- Google Chrome

右键单击Chrome快捷方式>>选择属性>>在"目标"对应文本框中添加如下参数：

```
--explicitly-allowed-ports=xxx (xxx为目标端口号)
```

例如：

```
"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe" --explicitly-allowed-ports=87,6666,556,6667
```

Chrome默认支持的端口有：

```
HTTP: 80, 81, 1025-65535
HTTPS: 443, 563, 8443 
FTP: 21
```

- 附录

Google Chrome 默认非安全端口列表，虽然以上方法可以解决问题，但建议尽量避免以下端口：

>   1,    // tcpmux
>   7,    // echo
>   9,    // discard
>   11,   // systat
>   13,   // daytime
>   15,   // netstat
>   17,   // qotd
>   19,   // chargen
>   20,   // ftp data
>   21,   // ftp access
>   22,   // ssh
>   23,   // telnet
>   25,   // smtp
>   37,   // time
>   42,   // name
>   43,   // nicname
>   53,   // domain
>   77,   // priv-rjs
>   79,   // finger
>   87,   // ttylink
>   95,   // supdup
>   101,  // hostriame
>   102,  // iso-tsap
>   103,  // gppitnp
>   104,  // acr-nema
>   109,  // pop2
>   110,  // pop3
>   111,  // sunrpc
>   113,  // auth
>   115,  // sftp
>   117,  // uucp-path
>   119,  // nntp
>   123,  // NTP
>   135,  // loc-srv /epmap
>   139,  // netbios
>   143,  // imap2
>   179,  // BGP
>   389,  // ldap
>   465,  // smtp+ssl
>   512,  // print / exec
>   513,  // login
>   514,  // shell
>   515,  // printer
>   526,  // tempo
>   530,  // courier
>   531,  // chat
>   532,  // netnews
>   540,  // uucp
>   556,  // remotefs
>   563,  // nntp+ssl
>   587,  // stmp+ssl
>   601,  // Reliable Syslog Service
>   636,  // ldap+ssl
>   993,  // ldap+ssl
>   995,  // pop3+ssl
>   2049, // nfs
>   3659, // apple-sasl / PasswordServer
>   4045, // lockd
>   6000, // X11
>   6665, // Alternate IRC [Apple addition]
>   6666, // Alternate IRC [Apple addition]
>   6667, // Standard IRC [Apple addition]
>   6668, // Alternate IRC [Apple addition]
>   6669, // Alternate IRC [Apple addition]