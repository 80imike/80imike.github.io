---
title: Dnsyo-在全球超过1500个DNS服务器上检查你的域名解析记录
tags:
  - Dnsyo
  - Linux
categories: Dnsyo
abbrlink: 14864
date: 2016-05-30 09:00:00
updated:
toc_number:
---

Dnsyo是一个命令行DNS检测工具，能够在多达1500个不同网络的开放DNS服务器上进行查询。在做了DNS变更的时候用来检查DNS生效或排查DNS设置的时候是非常有用的。

项目地址：https://github.com/samarudge/dnsyo

### Dnsyo安装

Ubuntu, Debian or Linux Mint

```
$ sudo apt-get install python-pip
$ sudo pip install dnsyo --upgrade
```

<!-- more -->

CentOS, Fedora or RHEL

```
$ sudo yum install python-pip
$ sudo pip install dnsyo --upgrade
```

### Dnsyo使用

**Dnsyo语法**

```
$ dnsyo --help                    
usage: dnsyo [options] domain [type]

Query lots of DNS servers and colate the results

positional arguments:
  domain                Domain to query
  type                  Record type (A, CNAME, MX, etc.)

optional arguments:
  -h, --help            show this help message and exit
  --resolverlist RESOLVERLIST
                        Location of the yaml resolvers list to download
                        (http/https)
  --resolverfile RESOLVERFILE
                        Location of the local yaml resolvers file
  --verbose, -v         Extended debug info
  --simple, -s          Simple output mode (good for UNIX parsing)
  --extended, -x        Extended output mode including server addresses
  --threads THREADS, -t THREADS
                        Number of worker threads to use
  --servers SERVERS, -q SERVERS
                        Maximum number of servers to query (or ALL)
  --country COUNTRY, -c COUNTRY
                        Query servers by two letter country code
  --update              Check the list for working servers
  --updateSummary UPDATESUMMARY
                        Location for the summary status of the update
  --updateDestination UPDATEDESTINATION
                        Destination resolver list for update

```

**Dnsyo使用实例**

用100个线程同时查询所有DNS服务器上的结果。

```
$ dnsyo -t 100 -q ALL hi-linux.com

Status: Queried 1097 of 1097 servers, duration: 0:00:42.016678

 - RESULTS

I asked 1097 servers for A records related to hi-linux.com,
324 responded with records and 773 gave errors
Here are the results;


22 servers responded with;
199.27.79.133

39 servers responded with;
103.245.222.133

24 servers responded with;
23.235.47.133

18 servers responded with;
23.235.40.133

69 servers responded with;
185.31.17.133

14 servers responded with;
23.235.46.133

14 servers responded with;
185.31.19.133

14 servers responded with;
199.27.76.133

39 servers responded with;
23.235.43.133

17 servers responded with;
23.235.44.133

26 servers responded with;
185.31.18.133

15 servers responded with;
23.91.98.188

11 servers responded with;
23.235.39.133

2 servers responded with;
141.211.28.87

And here are the errors;


42 servers responded with;
No Nameservers

22 servers responded with;
No Answer

709 servers responded with;
Server Timeout
```

使用`--simple`选项采用简单的输出模式，对于UNIX脚本是非常有用的。

```
$ dnsyo --simple hi-linux.com

INFO QUERIED 500
INFO SUCCESS 222
INFO ERROR 278
RESULT 10 23.91.98.188
RESULT 30 103.245.222.133
RESULT 16 199.27.79.133
RESULT 11 23.235.47.133
RESULT 11 23.235.40.133
RESULT 16 23.235.44.133
RESULT 18 185.31.19.133
RESULT 24 23.235.43.133
RESULT 53 185.31.17.133
RESULT 13 185.31.18.133
RESULT 8 199.27.76.133
RESULT 4 23.235.46.133
RESULT 7 23.235.39.133
RESULT 1 141.211.28.87
ERROR 17 No Answer
ERROR 18 No Nameservers
ERROR 243 Server Timeout
```

使用`--extended`选项查询结果更加详细，包含其查询的服务器的名称和地址。

```
$ dnsyo --extended hi-linux.com

Status: Queried 500 of 500 servers, duration: 0:00:16.818680

 - RESULTS

I asked 500 servers for A records related to hi-linux.com,
221 responded with records and 279 gave errors
Here are the results;


The following servers
 - 69.16.169.11 (HIGHWINDS - Highwinds Network Group, Inc. - US)
 - 4.2.2.4 (LEVEL3 Level 3 Communications - US)
 - 148.233.151.8 (Uninet S.A. de C.V. - MX)
 - 216.52.97.33 (INTERNAP-2BLK - Internap Network Services Corporation - US)
 - 204.97.212.10 (AS1239 SprintLink Global Network - US)
 - 201.69.193.143 (TELEFNICA BRASIL S.A,BR - BR)
 - 69.16.170.11 (HIGHWINDS - Highwinds Network Group, Inc. - US)
 - 199.2.252.10 (AS1239 SprintLink Global Network - US)
 - 216.165.129.158 (TDS-AS - TDS TELECOM - US)
 - 216.170.153.146 (TDS-AS - TDS TELECOM - US)
 - 186.224.32.6 (Portal Medianeira Informtica Ltda,BR - BR)
 - 4.2.2.1 (LEVEL3 Level 3 Communications - US)
 - 64.136.52.73 (AS-NETZERO - Netzero,INC. - US)
 - 216.52.254.1 (INTERNAP-BLK - Internap Network Services Corporation - US)
responded with;
23.235.47.133

The following servers
 - 103.238.195.226 (BEACHHEADGROUP-AS-AP Beachhead Group Pty. Ltd.,AU - AU)
 - 203.50.2.71 (ASN-TELSTRA Telstra Pty Ltd - AU)
 - 60.241.64.224 (TPG-INTERNET-AP TPG Telecom Limited,AU - AU)
 - 74.82.42.42 (HURRICANE - Hurricane Electric, Inc. - US)
 - 60.225.26.2 (ASN-TELSTRA Telstra Pty Ltd,AU - AU)
 - 120.151.240.35 (ASN-TELSTRA Telstra Pty Ltd,AU - AU)
 - 165.21.83.88 (ERX-SINGNET SingNet - SG)
 - 203.144.207.29 (TRUEINTERNET-AS-AP TRUE INTERNET Co.,Ltd. - TH)
 - 14.203.108.78 (TPG-INTERNET-AP TPG Telecom Limited,AU - AU)
 - 164.124.107.9 (BORANET-KR, LG DACOM Corporation - KR)
 - 203.219.45.219 (TPG-INTERNET-AP TPG Telecom Limited,AU - AU)
 - 202.248.37.74 (INFOWEB FUJITSU LIMITED - JP)
 - 222.151.241.10 (OCN NTT Communications Corporation - JP)
 - 219.250.36.130 (broadNnet-KR, SK Broadband Co Ltd - KR)
 - 156.154.70.22 (ULTRADNS - NeuStar, Inc. - US)
 - 164.124.101.2 (BORANET-KR, LG DACOM Corporation - KR)
 - 216.146.35.35 (DYNDNS - Dynamic Network Services, Inc. - US)
 - 203.112.2.5 (MIINET UCOM Corporation - JP)
 - 110.143.125.229 (ASN-TELSTRA Telstra Pty Ltd,AU - AU)
 - 61.208.115.242 (OCN NTT Communications Corporation - JP)
 - 198.153.194.40 (DYNDNS - Dynamic Network Services, Inc. - US)
 - 203.112.2.4 (MIINET UCOM Corporation - JP)
 - 74.82.46.6 (HURRICANE - Hurricane Electric, Inc. - US)
 - 211.75.111.220 (HINET Data Communication Business Group,TW - TW)
 - 202.248.20.133 (INFOWEB FUJITSU LIMITED - JP)
responded with;
103.245.222.133
```

通过指定记录类型查询特定类型的DNS记录，如查询MX记录。

```
$ dnsyo google.com MX


Status: Queried 500 of 500 servers, duration: 0:00:06.193986

 - RESULTS

I asked 500 servers for MX records related to google.com,
14 responded with records and 486 gave errors
Here are the results;


14 servers responded with;
10 aspmx.l.google.com.
20 alt1.aspmx.l.google.com.
30 alt2.aspmx.l.google.com.
40 alt3.aspmx.l.google.com.
50 alt4.aspmx.l.google.com.



And here are the errors;


473 servers responded with;
No Answer

4 servers responded with;
No Nameservers

9 servers responded with;
Server Timeout
```

### 参考文档

http://www.google.com
https://github.com/samarudge/dnsyo
http://xmodulo.com/check-dns-propagation-linux.html

