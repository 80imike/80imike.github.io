---
title: CentOS下部署Ngrok服务器
tags:
  - Ngrok
  - Linux
categories: Ngrok
abbrlink: 29097
date: 2016-03-23 09:00:00
updated:
---

### 什么是Ngrok

Ngrok是一款用go语言开发的开源软件，它是一个反向代理。通过在公共的端点和本地运行的Web服务器之间建立一个安全的通道。Ngrok可捕获和分析所有通道上的流量，便于后期分析和重放。

下图简述了Ngrok的原理

![ngrok](https://www.hi-linux.com/img/linux/ngrok-768x478.png)
<!-- more -->
### 应用场景

> 用于对处在内网环境中，无外网IP的计算机的远程连接。
> 
> Ngrok可以做TCP端口转发，对于Linux可以将其映射到22端口进行SSH连接。Windows的远程桌面可以将其映射到3389端口来实现。同理，如果要做MySQL的远程连接，只需映射3306端口即可。
> 
> 用作临时搭建网站并分配二级域名，可用作微信二次开发的本地调试。
> 
> 微信公众平台二次开发时，服务器必须要能通过外网访问，而且必须是80接口。我们一般会在自己的电脑上写代码，但是由于电信运营商将80端口屏蔽了，甚至很多人通过无线路由器上网，根本就没有公网ip。在这种情况下，我们每次都要上传代码到服务器对微信公众平台进行接口调试，十分的不方便。而Ngrok可以将内网映射到一个公网地址，这样就完美的解决了我们的问题。
> 
> Ngrok官方为我们免费提供了一个服务器，我们只需要下载Ngrok客户端即可正常使用，但是后来官方的服务越来越慢，直到Ngrok官网被完全屏蔽。现在我们已经无法使用ngrok官方的服务器了。所以，接下来我们自行搭建属于自己的ngrok服务器，为自己提供方便快捷又稳定的服务，一劳永逸。

**注意:ngrok.com 提供的服务是基于 ngrok 2.0，github 上目前只有 1.0 的源码，二者功能和命令有一些区别，用的时候别搞混了**


### 编译ngrok

#### 安装go get工具

```bash
#ubuntu
apt-get install build-essential golang mercurial git

#centos
yum install mercurial git bzr subversion  golang

#git版本需要在1.7.9.5以上，如果不符合条件需要将git版本升级。
yum --disablerepo=base,updates --enablerepo=rpmforge-extras update git
```

#### 获取ngrok源码

```bash
GOPATH=~/goproj
mkdir ~/goproj/src/github.com/inconshreveable
cd ~/goproj/src/github.com/inconshreveable
#官方地址编译时要报错
git clone https://github.com/inconshreveable/ngrok.git
#请使用下面的地址，修复了无法访问的包地址
git clone https://github.com/tutumcloud/ngrok.git ngrok
export GOPATH=~/goproj/src/github.com/inconshreveable/ngrok

修改源代码中库引用的错误
由于google code的关闭，所以我们要把作者代码中的库引用地址修改一下
修改src/ngrok/log/logger.go文件
log "code.google.com/p/log4go" 改为log "github.com/alecthomas/log4go"
注：最新github.com上的代码这个问题已修复
```

#### 生成自签名证书

使用ngrok.com官方服务时，我们使用的是官方的SSL证书。自建ngrokd服务，我们需要生成自己的证书，并提供携带该证书的ngrok客户端。生成并替换源码里默认的证书，注意域名修改为你自己的。(之后编译出来的服务端客户端会基于这个证书来加密通讯，保证了安全性)

证书生成过程需要一个NGROK_DOMAIN。以ngrok官方随机生成的地址693c358d.ngrok.com为例，其NGROK_DOMAIN就是"ngrok.com"，如果你要提供服务的地址为"example.tunnel.imike.me"，那NGROK_BASE_DOMAIN就应该是"tunnel.imike.me"。
```bash
cd ngrok
NGROK_DOMAIN="tunnel.imike.me"
openssl genrsa -out base.key 2048
openssl req -new -x509 -nodes -key base.key -days 10000 -subj "/CN=$NGROK_DOMAIN" -out base.pem
openssl genrsa -out server.key 2048
openssl req -new -key server.key -subj "/CN=$NGROK_DOMAIN" -out server.csr
openssl x509 -req -in server.csr -CA base.pem -CAkey base.key -CAcreateserial -days 10000 -out server.crt
```
执行完以上命令，在ngrok目录下就会新生成6个文件
```bash
ls -lt                           
总用量 56
-rw-r--r-- 1 root root  973 3月  23 11:23 server.crt
-rw-r--r-- 1 root root   17 3月  23 11:23 base.srl
-rw-r--r-- 1 root root  891 3月  23 11:23 server.csr
-rw-r--r-- 1 root root 1675 3月  23 11:23 server.key
-rw-r--r-- 1 root root 1115 3月  23 11:23 base.pem
-rw-r--r-- 1 root root 1679 3月  23 11:23 base.key
```
Ngrok通过bindata将ngrok源码目录下的assets目录(资源文件)打包到可执行文件(ngrokd和ngrok)中去，assets/client/tls和assets/server/tls下分别存放着用于ngrok和ngrokd的默认证书文件，我们需要将它们替换成我们自己生成的(因此这一步务必放在编译可执行文件之前)
```bash
cp base.pem assets/client/tls/ngrokroot.crt
cp server.crt assets/server/tls/snakeoil.crt
cp server.key assets/server/tls/snakeoil.key
```
#### 编译Linux服务端和客户端
```bash
make release-server release-client
```
编译之后，就会在ngrok源码的bin目录下生成两个可执行文件：ngrokd、ngrok。其中ngrokd就是ngrok的服务端程序，ngrok就是ngrok的客户端程序。

#### 编译Linux客户端
```bash
make release-client
```
#### 编译window版本客户端
上述编译过程生成的服务端和客户端都是linux下的，不能在windows下用。如果想编译生成windows客户端，需要重新配置环境并编译。交叉编译过程如下：
```bash
进入go目录，进行环境配置
cd  /usr/local/go/src/
GOOS=windows GOARCH=amd64 CGO_ENABLED=0 ./make.bash  
进入ngrok目录重新编译
GOOS=windows GOARCH=amd64 make release-client
编译后，就会在bin目录下生成windows_amd64目录，其中就包含着windows下运行的服务器和客户端程序。
#以上GOARCH=amd64指的是编译为64位版本，如需32位改成GOARCH=386即可
```
#### 编译arm客户端
```bash
cd /usr/lib/golang/src/
sudo GOOS=linux GOARCH=arm CGO_ENABLED=0 ./make.bash
sudo GOOS=linux GOARCH=arm make release-client
```
#### 编译mac版本客户端
```bash
GOOS=darwin GOARCH=amd64 make  release-client
```
### 设置域名解析
添加两条A记录：tunnel.imike.me和*.tunnel.imike.me，指向所在的Ngrok服务器ip。

### 运行Ngrok

#### 服务端启动
指定证书、域名和端口启动它(证书就是前面生成的，注意修改域名)
```bash
./bin/ngrokd -tlsKey=server.key -tlsCrt=server.crt -domain="tunnel.imike.me" -httpAddr=":8081" -httpsAddr=":8082"
[14:54:30 CST 2016/03/23] [INFO] (ngrok/log.(*PrefixLogger).Info:83) [registry] [tun] No affinity cache specified
[14:54:30 CST 2016/03/23] [INFO] (ngrok/log.(*PrefixLogger).Info:83) [metrics] Reporting every 30 seconds
[14:54:30 CST 2016/03/23] [INFO] (ngrok/log.Info:112) Listening for public http connections on [::]:8081
[14:54:30 CST 2016/03/23] [INFO] (ngrok/log.Info:112) Listening for public https connections on [::]:8082
[14:54:30 CST 2016/03/23] [INFO] (ngrok/log.Info:112) Listening for control and proxy connections on [::]:4443
```
到这一步，ngrok 服务已经跑起来了，可以通过屏幕上显示的日志查看更多信息。httpAddr、httpsAddr 分别是ngrok用来转发http、https服务的端口，可以随意指定。ngrokd还会开一个4443端口用来跟客户端通讯(可通过-tunnelAddr=":xxx" 指定)，如果你配置了iptables 规则，需要放行这三个端口上的TCP协议。

现在通过`http://tunnel.imike.me:8081`和`https://tunnel.imike.me:8082`就可以访问到ngrok提供的转发服务。

#### 设置开机自动启动ngrok服务
```bash
vim /etc/init.d/ngrok_start:
cd /root/goproj/src/github.com/inconshreveable
./bin/ngrokd -tlsKey=server.key -tlsCrt=server.crt -domain="tunnel.imike.me" -httpAddr=":8081" -httpsAddr=":8082"
chmod 755 /etc/init.d/ngrok_start
```
#### 客户端启动

##### 使用默认配置文件启动

对默认设置文件 ~/.ngrok 进行编辑：
```bash
server_addr: tunnel.imike.me:4443
trust_host_root_certs: false
tunnels:
    #http:subdomain: "test"
    web:
        #auth: "AuthUser:AuthPassWord"
        proto:
            http: 80
    ssh:
        remote_port: 12222
        proto:
            tcp: 22
```
从命令行运行:
```bash
./bin/ngrok start web ssh
```
当客户端使用http/https协议连接，可指定一个二级域名，服务端会分配该二级域名给客户端作为入口，比如web.tunnel.imike.me; 

当客户端使用tcp 协议连接，则服务端不会分配二级域名，改为监控一个随机端口，比如 tunnel.imike.me:12345，remote_port可由客户端对该端口进行指定，比如tunnel.imike.me:12222。

##### 使用自定义配置文件

创建一个配置文件ngrok.cfg，内容如下：
```bash
vim ngrok.cfg:
server_addr: tunnel.imike.me:4443
trust_host_root_certs: false
```
###### 映射HTTP

```bash
#启动ngrok客户端
#指定子域、要转发的协议和端口，以及配置文件，运行客户端：
#注意：如果不加参数-subdomain=test，将会随机自动分配子域名。
./bin/ngrok -subdomain web -proto=http -config=ngrok.cfg 80

#客户端ngrok正常执行显示的内容
ngrok                                                  (Ctrl+C to quit)

Tunnel Status     online
Version           1.7/1.7
Forwarding        http://web.tunnel.imike.me:8081 -> 127.0.0.1:80
Web Interface     127.0.0.1:4040
# Conn            0
Avg Conn Time     0.00ms
```
打开浏览器，分别在地址栏中输入`http://localhost`和`http://web.tunnel.imike.me:8081`，如果后者正常显示并且和`http://localhost`显示的内容相同，则证明我们已经成功了。

###### 映射TCP

有时候，我们使用远程桌面功能，或者在linux中进行SSH连接，对于处在内网环境中的计算机，我们可以对该端口进行TCP映射。
```bash
#这里以SSH连接Linux时的22端口为例
./bin/ngrok -config=ngrok.cfg -proto=tcp 22
映射成功的话，会显示如下内容：
#客户端ngrok正常执行显示的内容

ngrok                                                  (Ctrl+C to quit)

Tunnel Status     online
Version           1.7/1.7
Forwarding        tcp://imike.me:12222 -> 127.0.0.1:22
Web Interface     127.0.0.1:4040
# Conn            0
Avg Conn Time     0.00ms
```
现在，在putty等ssh工具中即可连接imike.me。切记端口是号12222，是随机分配的一个端口号，而不是默认的22端口了。Windows的远程桌面可以将其映射到3389端口来实现。同理，如果要做MySQL的远程连接，只需映射3306端口即可。FTP可映射21端口。

**注意:客户端必须使用自己编译的ngrok文件**


### 管理界面

Ngrok客户端运行后，有一个Web Interface地址，这是ngrok 提供的监控界面。通过这个界面可以看到远端转发过来的http 详情，包括完整的request/response 信息，可以不刷新页面通过replay按钮重新发出请求,非常方便。

访问管理界面:`http://127.0.0.1:4040`


### 后续定制及优化

通过以上操作，我们的ngrok服务器就已经成功搭建了，客户端也成功的跑了起来。但是，如果我们想要对ngrok进行一些定制和优化，可以参考这些后续定制及优化的方法。

#### 为什么在启动服务端的时候，端口不指定为80

很遗憾，因为这台vps不是只用来做ngrok服务的，我博客还在上面呢，80端口已经被nginx占用了。
那怎么办？不得不提nginx是个牛逼的软件，我们可以在nginx中配置一个server,就绑定web.tunnel.imike.me域名，然后将所有请求转发到后端:8081端口上，这就是反向代理。我发一下自己的nginx配置：
```bash
#ngrok.imike.me.conf
upstream ngrok {
    server 127.0.0.1:8000;
    keepalive 64;
}

server {
    listen 80;
    server_name *.tunnel.imike.me;
    access_log /var/log/nginx/ngrok_access.log;
    location / {
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host  $http_host:8081;
        proxy_set_header X-Nginx-Proxy true;
        proxy_set_header Connection "";
        proxy_pass      http://ngrok;

    }

}
```

#### 修改客户端ngrok默认服务地址
客户端每次还需要加载配置文件，这样显得有些麻烦。能不能像官方服务那样直接执行命令 ngrok 80就能使用呢？我们只需要在编译客户端之前，稍作修改即可。同样，如果需要指定域名可以执行命令 ngrok -subdomain=test 80来运行客户端。

#### 修改默认服务地址
```bash
vim ./src/ngrok/client/model.go
找到第23行，将 defaultServerAddr = "ngrokd.ngrok.com:443"
修改为defaultServerAddr = "tunnel.mydomain:4443" 即可。
```

#### 修改客户端ngrok左上角蓝色文字logo
运行客户端后，我们会发现在客户端左上角会有一个蓝色字体的"ngrok"字样的文字logo，如果觉得不太喜欢，或者想修改一下的话，可以在编译客户端之前，作如下修改。

#### 修改客户端蓝色文字logo
```bash
Vim ./src/ngrok/client/views/term/view.go
找到第100行，将
v.APrintf(termbox.ColorBlue|termbox.AttrBold, 0, 0, "ngrok")
修改为
v.APrintf(termbox.ColorBlue|termbox.AttrBold, 0, 0, "your logo")
即可。
```

#### 修改客户端帮助信息
Ngrok客户端默认的帮助信息很少，我们可以在编译客户端之前，自己定制帮助内容。

#### 修改客户端默认帮助信息
```bash
vim ./src/ngrok/client/client/cli.go
找到第14行，修改 const usage2 string的值即可。
```
#### 客户端程序加壳优化
编译好的Windows客户端ngrok.exe大小为10MB，感觉有点大，这样加载到内存中，需要读取硬盘的内容也相对较多，影响速度。所以，我们来给客户端程序加个压缩壳，对程序进行压缩。
这里采用mpress进行加壳，先从网上下载mpress.exe，之后将ngrok.exe拖放到mpress.exe的图标上，就能完成加壳操作。我们可以看到，加壳后的程序只有1.94MB，压缩率不到20%，大大节省了磁盘空间。同时小文件加载起来，速度会更快。



### 常见错误

#### 在编译ngrok的时候,安装yaml的时候不能下载，无反应
```bash
gopkg.in/inconshreveable/go-update.v0  (download)
或者
gopkg.in/yaml.v1 (download)
原因git版本太低，需>= 1.7.9.5，通过RPMForge源安装最新版本git解决：
yum --enablerepo=rpmforge-extras install git
```
  
#### 把编译出来的32位客户端放在64位上运行时会报错
```bash
/lib/ld-linux.so.2: bad ELF interpreter
 
#解决方法
yum install -y glibc.i686
```

#### 在ngrok目录下执行如下命令，编译ngrokd
```bash
$ make release-server

出现如下错误：
GOOS="" GOARCH="" go get github.com/jteeuwen/go-bindata/go-bindata
bin/go-bindata -nomemcopy -pkg=assets -tags=release \
        -debug=false \
        -o=src/ngrok/client/assets/assets_release.go \
        assets/client/…
make: bin/go-bindata: Command not found
make: *** [client-assets] Error 127
go-bindata被安装到了$GOBIN下了，go编译器找不到了。修正方法是将$GOBIN/go-bindata拷贝到当前ngrok/bin下。

$cp /home/ubuntu/.bin/go14/bin/go-bindata ./bin
```

#### 客户端ngrok.cfg中server_addr后的值必须严格与-domain以及证书中的NGROK_BASE_DOMAIN相同，否则Server端就会出现如下错误日志
```bash
[03/13/15 09:55:46] [INFO] [tun:15dd7522] New connection from 54.149.100.42:38252
[03/13/15 09:55:46] [DEBG] [tun:15dd7522] Waiting to read message
[03/13/15 09:55:46] [WARN] [tun:15dd7522] Failed to read message: remote error: bad certificate
[03/13/15 09:55:46] [DEBG] [tun:15dd7522] Closing
```

### 一此国内的Ngrok免费服务
http://www.ittun.com
http://qydev.com/
http://natapp.cn/
http://www.ngrok.cc/

### 参考文档
http://www.google.com
http://blog.lzp.name/archives/24
http://tonybai.com/2015/03/14/selfhost-ngrok-service/


