---
title: 'curl酷炫技巧:使用curl命令发送邮件'
tags:
  - CURL
  - Linux
categories: CURL
abbrlink: 54000
date: 2016-04-01 09:00:00
updated:
---

关于curl，大家都知道可以用它来访问web页面、下载文件等等。其实它的功能远不止这么点，它支持众多协议，今天，来随凉白开看看如何使用curl发送邮件

### 确认curl是否支持SMTP

首先确认你的curl是否支持smtp

```bash
curl-config --protocols | grep SMTP
SMTP
SMTPS
```
如果不支持smtp协议，那么升级curl(需7.20以上版本才支持)<!-- more -->

### 安装高版本CURL

使用yum安装的curl一般不支持smtp协议，接下来我们使用源码包来安装curl

```bash
cd /usr/local/src
wget https://curl.haxx.se/download/curl-7.48.0.tar.gz
unzip master.zip
cd curl-master
./buildconf
./configure 
make && make install
```

再次确认下是否支持curl

```bash
/usr/local/bin/curl-config --protocols | grep SMTP
SMTP
SMTPS
```

备注：默认情况下，curl会被安装到/usr/local/bin下，与老版本同时存在。

### 使用curl发送邮件

试着给dengyun@ttlsa.com发送一份邮件

#### 编写邮件内容

```bash
cat mail.txt
From:support@ttlsa.com
To:dengyun@ttlsa.com
Subject: curl发送邮件标题

这里是内容，上面有一个空行别忘记了
```

#### 发送邮件

```bash
/usr/local/bin/curl -s --url "smtp://smtp.ttlsa.com" --mail-from "support@ttlsa.com" \
--mail-rcpt "dengyun@ttlsa.com" --upload-file mail.txt --user "support@ttlsa.com:123456"
```

#### 参数说明

```bash
--url ：smtp地址
--mail-from：发件人邮箱
--mail-rcpt：收件人邮箱
--upload-file：信件内容，包含发件人、收件人、标题、内容
--user：账号密码，中间用冒号分隔
```

### curl更多协议

curl支持众多协议，想知道当前curl支持哪些协议，使用如下命令

```bash
/usr/local/bin/curl-config --protocols
DICT
FILE
FTP
FTPS
GOPHER
HTTP
HTTPS
IMAP
IMAPS
POP3
POP3S
RTSP
SMB
SMBS
SMTP
SMTPS
TELNET
TFTP
```

### zabbix curl发邮件脚本

我们通常使用sendEmail来发送告警，下面分享一个zabbix使用curl发送告警邮件的脚本

```bash
curl zabbix_curl_sendmail.sh

#!/bin/bash
# -------------------------------------------------------------------------------
# FileName:    zabbix_curl_sendmail.sh
# Revision:    1.0
# Date:        2015/11/14
# Author:      凉白开
# Email:       dengyun@ttlsa.com
# Website:     www.ttlsa.com
# Description: use curl send email
# Notes:       ~
# -------------------------------------------------------------------------------
# Copyright:   2015 (c) 凉白开
# License:     GPL

MAIL_FROM='support@ttlsa.com'
MAIL_TO=$1
MAIL_SUBJECT=$2
MAIL_CONTENT=$3
MAIL_CONTENT_FILE="/tmp/`/bin/date +%s`.txt"
MAIL_SMTP='smtp://smtp.ttlsa.com'
MAIL_USER='support@ttlsa.com'
MAIL_PASSWORD='123456'

# create mail content file
echo "From:${MAIL_FROM}
To:$1
Subject: $MAIL_SUBJECT

$MAIL_CONTENT "> ${MAIL_CONTENT_FILE}

# send mail
/usr/local/bin/curl -s --url "${MAIL_SMTP}" --mail-from "${MAIL_FROM}" --mail-rcpt ${MAIL_TO} \
--upload-file ${MAIL_CONTENT_FILE} --user "${MAIL_USER}:${MAIL_PASSWORD}" 

# delete mail content file
rm ${MAIL_CONTENT_FILE}
```

### 项目地址

WEB SITE: https://curl.haxx.se/
GitHub： https://github.com/bagder/curl/

转载自: https://www.ttlsa.com/linux/curl-skill-use-curl-send-email/