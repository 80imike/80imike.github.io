---
category: Nginx
title: Nginx 宣布从 1.13.10 开始正式支持 gRPC
date: 2018-03-23 09:00:00
tags: [Linux, Nginx]
abbrlink:
updated:
toc_number: false
---

近日，NGINX 在其博客宣布，NGINX 已完成对 gRPC 的原生支持，现在就可以从代码仓库拉取快照版本。该特性将会被包含在 NGINX OSS 1.13.10、NGINX Plus R15 以及 NGINX 1.13.9 当中。

有了对 gRPC 的支持，NGINX 就可以代理 gRPC TCP 连接，还可以终止、检查和跟踪 gRPC 的方法调用。你可以：

- 发布 gRPC 服务，然后使用 NGINX 应用 HTTP/2 TLS 加密、速率限制、基于 IP 的访问控制列表和日志记录。
- 通过单个端点发布多个 gRPC 服务，使用 NGINX 检查并跟踪每个内部服务的调用。
- 对一组 gRPC 服务进行负载均衡，可以使用轮询算法、最少连接数原则或其他方式在集群上分发流量。

<!-- more -->

### 什么是 gRPC

gRPC 是一种远程过程调用协议，用于客户端和服务器端之间的通信。gRPC设计的很紧凑并且多语言支持良好，同时支持请求与响应式的交互方式和流式交互方式。gRPC 因其跨语言特性和简洁的设计变得越来越流行，其中 Service Mesh 的实现就使用了 gRPC。

![](https://mmbiz.qpic.cn/mmbiz_png/UicsouxJOkBdvbftRgZNSFDUJ8vJs2BTkkeToqiaI2uWg9TG2WAq0JL6JYFHtBJK2f3As9BHVgrzdiahvfNsnwZTg/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1)


gRPC 通过 HTTP/2 传输数据，可以传输明文文本数据和 TLS 加密过的数据。gRPC 调用是通过 HTTP POST 请求来实现的，每个请求里包含了一个编码过的消息体（protocol buffer 是默认的编码方式）。gRPC 的响应消息里也包含一个编码过的消息体，并在消息尾部带上状态码。

gRPC 不能通过 HTTP 进行传输，而必须使用 HTTP/2，这是因为要充分利用 HTTP/2 连接的多路复用和流式特性。

### 使用 NGINX 管理 gRPC 服务

#### 暴露简单的 gRPC 服务

首先，在客户端和服务器端之间插入 NGINX，NGINX 为服务器端的应用程序提供了一个稳定可靠的网关。

![](https://mmbiz.qpic.cn/mmbiz_png/UicsouxJOkBdvbftRgZNSFDUJ8vJs2BTkYibJXicwZCmvN5lvTbXT3ZJocGKOEzqFvb8M2seIe4Kmb4icOibVNibPz0w/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1)

然后开始部署包含了 gRPC 更新的 NGINX。如果要从源代码开始编译 NGINX，要记得把 http_ssl 和 http_v2 两个模块包含进去：

```
$ ./configure --with-http_ssl_module —with-http_v2_module
```

NGINX 使用 HTTP 服务器监听 gRPC 流量，并使用 grpc_pass 指令代理流量。 为 NGINX 创建以下代理配置，在端口 80 上侦听未加密的 gRPC 流量并将请求转发到端口 50051 上的服务器：

```
http {
  log_format main '$remote_addr - $remote_user [$time_local] "$request" '
           '$status $body_bytes_sent "$http_referer" '
           '"$http_user_agent"';

  server {
    listen 80 http2;

    access_log logs/access.log main;

    location / {
      # Replace localhost:50051 with the address and port of your gRPC server
      # The 'grpc://' prefix is optional; unencrypted gRPC is the default   
      grpc_pass grpc://localhost:50051;
    }
  }
}
```

我们需要确保 grpc_pass 指令中的地址是正确的。重新编译客户端以指向 NGINX 的IP地址和监听端口。当运行修改后的客户端时，会看到与之前相同的响应，但请求是经由GINX转发。 我们可以在访问日志中看到请求记录：

```
$ tail logs/access.log
192.168.20.1 - - [01/Mar/2018:13:35:02 +0000] "POST /helloworld.Greeter/SayHello HTTP/2.0" 200 18 "-" "grpc-go/1.11.0-dev"
192.168.20.1 - - [01/Mar/2018:13:35:02 +0000] "POST /helloworld.Greeter/SayHelloAgain HTTP/2.0" 200 24 "-" “grpc-go/1.11.0-dev"
```

> 注意： NGINX不支持在明文（非TLS）端口上同时支持HTTP/1和HTTP/2。 如果你想同时处理两个协议版本，你应该为每个协议版本创建一个监听端口。

#### 使用 TLS 加密发布 gRPC 服务

上面的示例使用未加密的 HTTP/2（明文）进行通信。这对测试和部署来说非常简单，但生产环境为了安全需要加密，你可以使用 NGINX 来添加这个加密层。

![](https://cdn-1.wp.nginx.com/wp-content/uploads/2018/03/grpc-nginx-encrypted.png)

首先创建一个自签名证书对并修改您的NGINX服务器配置，如下所示：

```
server {
  listen 1443 ssl http2;

  ssl_certificate ssl/cert.pem;
  ssl_certificate_key ssl/key.pem;

  #...
}
```

修改 gRPC 客户端以使用 TLS ，连接到端口 1443，并禁用证书检查（使用自签名或不可信证书时需要如此）。 例如，以 Go 为示例，则需要：

- `crypto/tls` 和 `google.golang.org/grpc/credentials` 添加到导入列表中。
- 将 grpc.Dial() 调用修改为以下内容：

```
creds := credentials.NewTLS( &tls.Config{ InsecureSkipVerify: true } )

// 记得修改地址，使用新的端口
conn, err := grpc.Dial( address, grpc.WithTransportCredentials( creds ) )
```

这样就可以加密 gRPC 流量了。在部署到生产环境时，需要将自签名证书换成由可信任证书机构发布的证书，客户端也需要配置成信任该证书。

#### 反向代理加密的 gRPC 服务

如果想在内部调用对 gRPC 请求加密。 首先需要修改服务器应用程序以侦听 TLS 加密（grpcs）连接：

```
cer, err := tls.LoadX509KeyPair( "cert.pem", "key.pem" )
config := &tls.Config{ Certificates: []tls.Certificate{cer} }
lis, err := tls.Listen( "tcp", port, config )
```

在 NGINX 配置中，您需要修改将 gRPC 流量代理到 upstream server 的协议：

```
# Use grpcs for TLS-encrypted gRPC traffic
grpc_pass grpcs://localhost:50051;
```

#### 路由 gRPC 流量

这里将会介绍如何使用 NGINX 代理多个 gRPC 后端服务。如果同时存在多个 gRPC 服务，并且每个服务是由不同的服务器应用程序提供的，那么该怎么办？如果能够将这些服务通过单个 TLS 端点暴露出来是不是更好？

![](https://mmbiz.qpic.cn/mmbiz_png/UicsouxJOkBdvbftRgZNSFDUJ8vJs2BTklpwlOPZ3b9g3posOzDOtsw9ZYGatRZt9AfCMFgbOjuNaNPWkU5tFsQ/640?wx_fmt=png&tp=webp&wxfrom=5&wx_lazy=1)

在 NGINX 里，可以对服务和它的方法稍作修改，然后使用 location 指令来路由流量。gRPC 的请求 URL 是使用包名、服务名和方法名来生成的。比如这个叫作 SayHello 的 RPC 方法：

```
package helloworld;

service Greeter {
  rpc SayHello (HelloRequest) returns (HelloReply) {}
}
```

调用这个方法就会生成一个 POST 请求，URL 是 /helloworld.Greeter/SayHello，这个可以从日志中看出来：

```
192.168.20.1 - - [01/Mar/2018:13:35:02 +0000] "POST /helloworld.Greeter/SayHello HTTP/2.0" 200 18 "-" “grpc-go/1.11.0-dev"
```

使用 Nginx 路由请求非常简单，可以这样配置：

```
location /helloworld.Greeter {
  grpc_pass grpc://192.168.20.11:50051;
}

location /helloworld.Dispatcher {
  grpc_pass grpc://192.168.20.21:50052;
}

location / {
  root html;
  index index.html index.htm;
}
```

#### 对 gRPC 流量进行负载均衡

如果大并发请求下，我们如何保证 gRPC 服务高可用性呢？ NGINX 的 upstream group 就是做这事的：

```
upstream grpcservers {
  server 192.168.20.21:50051;
  server 192.168.20.22:50052;
}

server {
  listen 1443 ssl http2;

  ssl_certificate   ssl/certificate.pem;
  ssl_certificate_key ssl/key.pem;

  location /helloworld.Greeter {
    grpc_pass grpc://grpcservers;
    error_page 502 = /error502grpc;
  }

  location = /error502grpc {
    internal;
    default_type application/grpc;
    add_header grpc-status 14;
    add_header grpc-message "unavailable";
    return 204;
  }
}
```

当然，如果 upstream 监听的是 TLS 端口，可以使用 `grpc_pass grpcs://upstreams`。

NGINX 支持多种负载均衡算法，其内置的健康检测机制可以检测到无法及时响应或发生错误的服务器，并把它们移除。如果没有可用的服务器，就会返回 `/error 502 grpc` 指定的错误消息。


### 参考文档

http://www.google.com
http://t.cn/RnSlnSE
http://t.cn/RnSlBYq
http://t.cn/RnV1qMo
https://grpc.io/docs/quickstart/
https://www.nginx.com/blog/nginx-1-13-10-grpc/









