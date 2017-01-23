---
title: CentOS 6下搭建OpenVPN服务器
tags:
  - OpenVPN
  - Linux
categories: OpenVPN
abbrlink: 43594
date: 2016-05-19 19:51:54
updated:
toc_number:
---
OpenVPN是一个用于创建虚拟专用网络(Virtual Private Network)加密通道的免费开源软件。使用OpenVPN可以方便地在家庭、办公场所、住宿酒店等不同网络访问场所之间搭建类似于局域网的专用网络通道。

使用OpenVPN配合特定的代理服务器，可用于访问Youtube、FaceBook、Twitter等受限网站，也可用于突破公司的网络限制。

**OpenVPN架构图**

![](http://www.hi-linux.com/img/linux/openvpnflows.jpg)

<!-- more -->

### OpenVPN服务器端安装

#### 安装前准备

- 关闭selinux

```
$ setenforce 0
$ sed -i '/^SELINUX=/c\SELINUX=disabled' /etc/selinux/config
```

- 安装EPEL扩展库

```
$ yum install http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
```

- 安装所需依赖软件包

```
$ yum install -y openssl openssl-devel lzo lzo-devel pam pam-devel automake pkgconfig
```

#### 安装OpenVPN和Easy-Rsa

```
$ yum -y install openvpn easy-rsa   #EPEL源
```

#### 启动OpenVPN并设置为开机启动

```
$ service openvpn start
$ chkconfig openvpn on
```

### OpenVPN服务器端配置

#### 配置Easy-Rsa Vars

- 修改vars文件

```
$ cd /usr/share/easy-rsa/2.0/

$ vim vars
#修改注册信息，比如公司地址、公司名称、部门名称等。
export KEY_COUNTRY="CN"
export KEY_PROVINCE="ChongQing"
export KEY_CITY="ChongQing"
export KEY_ORG="jinke"
export KEY_EMAIL="jinke@qq.com"
export KEY_OU="P2P_TECH"
```

- 初始化环境变量

```
$ source vars
NOTE: If you run ./clean-all, I will be doing a rm -rf on /usr/share/easy-rsa/2.0/keys
```
 
- 清除keys目录下所有与证书相关的文件

```
下面步骤生成的证书和密钥都在/usr/share/easy-rsa/2.0/keys目录里
$ ./clean-all
```
 
- 生成服务器端CA证书根证书ca.crt和根密钥ca.key，由于在vars文件中做过缺省设置，在出现交互界面时，直接一路回车即可

```
$ ./build-ca
```
 
- 为服务端生成证书和密钥(一路按回车，直到提示需要输入y/n时，输入y再按回车，一共两次)

```
$ ./build-key-server server
```
 
- 创建迪菲·赫尔曼(DH)密钥，会生成dh2048.pem文件(生成过程比较慢，在此期间不要去中断它)

```
$ ./build-dh
```

- 生成TLS私密文件ta.key(防DDos攻击、UDP淹没等恶意攻击)

```
$ openvpn --genkey --secret keys/ta.key
```

- 每一个登陆的VPN客户端需要有一个证书，每个证书在同一时刻只能供一个客户端连接，下面建立2份

```
为客户端生成证书和密钥(一路按回车，直到提示需要输入y/n时，输入y再按回车，一共两次)
$ ./build-key client1
$ ./build-key client2
```

**注意:进行证书制作工作时，仍旧需要进行初始化，但只需要进入easy-rsa目录，运行`source vars`就可以了，不需要./clean-all 步骤，它会清除一切证书文件，这一点一定要注意！！！**

- 查看keys目录下生成的文件

```
$ ls keys/
01.pem  02.pem  03.pem  ca.crt  ca.key  client1.crt  client1.csr  client1.key  client2.crt  client2.csr  client2.key  dh2048.pem  index.txt  index.txt.attr  index.txt.attr.old  index.txt.old  serial  serial.old  server.crt  server.csr  server.key  ta.key
```

#### 配置OpenVPN服务端

- 在OpenVPN的配置目录下新建一个keys目录

```
$ mkdir /etc/openvpn/keys
```
 
- 将需要用到的OpenVPN证书和密钥复制一份到刚创建好的keys目录中

```
$ cp /usr/share/easy-rsa/2.0/keys/{ca.crt,server.{crt,key},dh2048.pem,ta.key} /etc/openvpn/keys/
```
 
- 复制一份服务器端配置文件模板server.conf到/etc/openvpn/

```
$ cp /usr/share/doc/openvpn-2.3.9/sample/sample-config-files/server.conf /etc/openvpn/
```

- 编辑server.conf配置文件

```
$ vim /etc/openvpn/server.conf

#本机要侦听使用的IP地址
local 192.168.1.201
#使用的端口，默认1194
port 1194
#改成tcp，默认使用udp，如果使用HTTP Proxy，必须使用tcp协议
proto tcp
#使用的设备可选tap和tun，tap是二层设备，支持链路层协议。
#tun是ip层的点对点协议，限制稍微多一些，建议使用tun,如果使用桥接的话，就必须要使用tap
dev tun
#路径前面加keys，全路径为/etc/openvpn/keys/ca.crt
#OpenVPN使用的ROOT CA，使用build-ca生成的，用于验证客户是证书是否合法
ca keys/ca.crt
#Server使用的证书文件
cert keys/server.crt
#Server使用的证书对应的key，注意文件的权限，防止被盗
key keys/server.key  # This file should be kept secret
dh keys/dh2048.pem
#注销用户需要增加
#crl-verify /usr/share/easy-rsa/2.0/keys/crl.pem
#默认虚拟局域网网段，不要和实际的局域网冲突即可
server 10.8.0.0 255.255.255.0
#用于记录某个Client获得的IP地址，类似于dhcpd.lease文件，
#防止openvpn重新启动后“忘记”Client曾经使用过的IP地址
ifconfig-pool-persist ipp.txt
#通过VPN Server往Client push路由，client通过pull指令获得Server push的所有选项并应用
#10.0.0.0/8是我这台VPN服务器所在的内网的网段，读者应该根据自身实际情况进行修改
push "route 10.0.0.0 255.0.0.0"
#配置客户端dns
push "dhcp-option DNS 114.114.114.114"
push "dhcp-option DNS 8.8.4.4"
#可以让客户端之间相互访问直接通过openvpn程序转发，根据需要设置
#不用发送到tun或者tap设备后重新转发，优化Client to Client的访问效率
client-to-client
#如果客户端都使用相同的证书和密钥连接VPN，一定要打开这个选项，否则每个证书只允许一个人连接VPN,建议一人一个证书。
duplicate-cn
#定义最大连接数
max-clients 10
#NAT后面使用VPN，如果VPN长时间不通信，NAT Session可能会失效，
#导致VPN连接丢失，为防止之类事情的发生，keepalive提供一个类似于ping的机制，
#下面表示每10秒通过VPN的Control通道ping对方，如果连续120秒无法ping通，
#认为连接丢失，并重新启动VPN，重新连接
#(对于mode server模式下的openvpn不会重新连接)。
keepalive 10 120
tls-auth keys/ta.key 0 # This file is secret
#对数据进行压缩，注意Server和Client一致
comp-lzo
#通过keepalive检测超时后，重新启动VPN，不重新读取keys，保留第一次使用的keys
persist-key
#通过keepalive检测超时后，重新启动VPN，一直保持tun或者tap设备是linkup的，
#否则网络连接会先linkdown然后linkup
persist-tun
#OpenVPN的状态日志，默认为/etc/openvpn/openvpn-status.log
status openvpn-status.log
#OpenVPN的运行日志，默认为/etc/openvpn/openvpn.log，和log一致，每次重新启动openvpn后保留原有的log信息，新信息追加到文件最后 
log-append  /var/log/openvpn/openvpn.log
#相当于debug level
verb 3
```

- 配置内核和防火墙

**开启路由转发功能**

```
$ sed -i '/net.ipv4.ip_forward/s/0/1/' /etc/sysctl.conf
$ sysctl -p
```
 
**配置防火墙**

```
$ iptables -I INPUT -p tcp --dport 1194 -m comment --comment "openvpn" -j ACCEPT
$ iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j MASQUERADE
$ service iptables save
```

### OpenVPN客户端安装及配置

#### 生成客户端配置文件

- 复制一份client.conf模板命名为client.ovpn

```
$ cp /usr/share/doc/openvpn-2.3.9/sample/sample-config-files/client.conf client.ovpn
```

- 编辑client.ovpn

```
$ vim client.ovpn
client
dev tun
#改为tcp
proto tcp
#OpenVPN服务器的外网IP和端口
remote xxx.xxx.xxx.xxx 1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
#client1的证书
cert client1.crt
#client1的密钥
key client1.key
ns-cert-type server
#去掉前面的注释
tls-auth ta.key 1
comp-lzo
verb 3
```

#### Linux客户端

- 安装客户端

```
$ yum -y install openvpn   #EPEL源
```

- 配置客户端

将OpenVPN服务器上的`client.ovpn`、`ca.crt`、`client1.crt`、`client1.key`、`ta.key`上传到Linux客户端`/etc/openvpn/keys/`文件夹


- 连接OpenVPN

```
$ openvpn --daemon --config /etc/openvpn/keys/client.ovpn
```

#### Windows客户端

- 下载并安装客户端

OpenVPN版本:OpenVPN 2.3.3 Windows 64位

> OpenVPN Windows 32位安装文件: https://swupdate.openvpn.org/community/releases/openvpn-install-2.3.10-I601-i686.exe
> OpenVPN Windows 64位安装文件: https://swupdate.openvpn.org/community/releases/openvpn-install-2.3.10-I601-x86_64.exe

- 配置客户端

将OpenVPN服务器上的`client.ovpn`、`ca.crt`、`client1.crt`、`client1.key`、`ta.key`上传到Windows客户端安装目录下的config文件夹(`C:\Program Files\OpenVPN\config`)

- 启动OpenVPN GUI

在电脑右下角的openvpn图标上右击，选择"Connect"。正常情况下应该能够连接成功，分配正常的IP。

#### MAC客户端

- Tunnelblick: https://tunnelblick.net/

#### Android客户端

- OpenVPN Connect: https://play.google.com/store/apps/details?id=net.openvpn.openvpn


### 参考文档

http://www.google.com
http://heylinux.com/archives/3499.html
http://qicheng0211.blog.51cto.com/3958621/1575273