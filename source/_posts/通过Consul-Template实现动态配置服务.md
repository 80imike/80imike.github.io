---
category: Consul
title: 通过Consul-Template实现动态配置服务
date: 2017-05-16 09:00:00
tags: [Docker,Consul]
abbrlink:
updated:
toc_number: false
---

### Consul-Template简介

Consul-Template是基于Consul的自动替换配置文件的应用。在Consul-Template没出现之前，大家构建服务发现系统大多采用的是Zookeeper、Etcd+Confd这样类似的系统。

Consul官方推出了自己的模板系统Consul-Template后，动态的配置系统可以分化为Etcd+Confd和Consul+Consul-Template两大阵营。Consul-Template的定位和Confd差不多，Confd的后端可以是Etcd或者Consul。

Consul-Template提供了一个便捷的方式从Consul中获取存储的值，Consul-Template守护进程会查询Consul实例来更新系统上指定的任何模板。当更新完成后，模板还可以选择运行一些任意的命令。

<!-- more -->

**Consul-Template的使用场景**

Consul-Template可以查询Consul中的服务目录、Key、Key-values等。这种强大的抽象功能和查询语言模板可以使Consul-Template特别适合动态的创建配置文件。例如：创建Apache/Nginx Proxy Balancers、Haproxy Backends、Varnish Servers、Application Configurations等。

**Consul-Template特性**

- Quiescence：Consul-Template内置静止平衡功能，可以智能的发现Consul实例中的更改信息。这个功能可以防止频繁的更新模板而引起系统的波动。
- Dry Mode：不确定当前架构的状态，担心模板的变化会破坏子系统？无须担心。因为Consul-Template还有Dry模式。在Dry模式，Consul-Template会将结果呈现在STDOUT，所以操作员可以检查输出是否正常，以决定更换模板是否安全。
- CLI and Config：Consul-Template同时支持命令行和配置文件。
- Verbose Debugging：即使每件事你都做的近乎完美，但是有时候还是会有失败发生。Consul-Template可以提供更详细的Debug日志信息。

项目地址：https://github.com/hashicorp/consul-template

### Consul-Template安装

Consul-Template和Consul一样，也是用Golang实现。因此具有天然可移植性(支持 Linux、windows 和macOS)。安装包仅包含一个可执行文件。Consul-Template安装非常简单，只需要下载对应系统的软件包并解压后就可使用。

这里以Linux系统为例：

```
$ wget https://releases.hashicorp.com/consul-template/0.18.3/consul-template_0.18.3_linux_amd64.zip
$ unzip consul-template_0.18.3_linux_amd64.zip
$ mv consul-template /usr/local/bin/
```

其它系统版本可在这里下载：https://releases.hashicorp.com/consul-template/

### Consul-Template常用命令

```
$ consul-template -h

Usage: consul-template [options]

  Watches a series of templates on the file system, writing new changes when
  Consul is updated. It runs until an interrupt is received unless the -once
  flag is specified.

Options:

  -config=<path>
      Sets the path to a configuration file or folder on disk. This can be
      specified multiple times to load multiple files or folders. If multiple
      values are given, they are merged left-to-right, and CLI arguments take
      the top-most precedence.

  -consul-addr=<address>
      Sets the address of the Consul instance

  -consul-auth=<username[:password]>
      Set the basic authentication username and password for communicating
      with Consul.

  -consul-retry
      Use retry logic when communication with Consul fails

  -consul-retry-attempts=<int>
      The number of attempts to use when retrying failed communications

  -consul-retry-backoff=<duration>
      The base amount to use for the backoff duration. This number will be
      increased exponentially for each retry attempt.

  -consul-ssl
      Use SSL when connecting to Consul

  -consul-ssl-ca-cert=<string>
      Validate server certificate against this CA certificate file list

  -consul-ssl-ca-path=<string>
      Sets the path to the CA to use for TLS verification

  -consul-ssl-cert=<string>
      SSL client certificate to send to server

  -consul-ssl-key=<string>
      SSL/TLS private key for use in client authentication key exchange

  -consul-ssl-server-name=<string>
      Sets the name of the server to use when validating TLS.

  -consul-ssl-verify
      Verify certificates when connecting via SSL

  -consul-token=<token>
      Sets the Consul API token

  -consul-transport-dial-keep-alive=<duration>
      Sets the amount of time to use for keep-alives

  -consul-transport-dial-timeout=<duration>
      Sets the amount of time to wait to establish a connection

  -consul-transport-disable-keep-alives
      Disables keep-alives (this will impact performance)

  -consul-transport-max-idle-conns-per-host=<int>
      Sets the maximum number of idle connections to permit per host

  -consul-transport-tls-handshake-timeout=<duration>
      Sets the handshake timeout

  -dedup
      Enable de-duplication mode - reduces load on Consul when many instances of
      Consul Template are rendering a common template

  -dry
      Print generated templates to stdout instead of rendering

  -exec=<command>
      Enable exec mode to run as a supervisor-like process - the given command
      will receive all signals provided to the parent process and will receive a
      signal when templates change

  -exec-kill-signal=<signal>
      Signal to send when gracefully killing the process

  -exec-kill-timeout=<duration>
      Amount of time to wait before force-killing the child

  -exec-reload-signal=<signal>
      Signal to send when a reload takes place

  -exec-splay=<duration>
      Amount of time to wait before sending signals

  -kill-signal=<signal>
      Signal to listen to gracefully terminate the process

  -log-level=<level>
      Set the logging level - values are "debug", "info", "warn", and "err"

  -max-stale=<duration>
      Set the maximum staleness and allow stale queries to Consul which will
      distribute work among all servers instead of just the leader

  -once
      Do not run the process as a daemon

  -pid-file=<path>
      Path on disk to write the PID of the process

  -reload-signal=<signal>
      Signal to listen to reload configuration

  -retry=<duration>
      The amount of time to wait if Consul returns an error when communicating
      with the API

  -syslog
      Send the output to syslog instead of standard error and standard out. The
      syslog facility defaults to LOCAL0 and can be changed using a
      configuration file

  -syslog-facility=<facility>
      Set the facility where syslog should log - if this attribute is supplied,
      the -syslog flag must also be supplied

  -template=<template>
       Adds a new template to watch on disk in the format 'in:out(:command)'

  -vault-addr=<address>
      Sets the address of the Vault server

  -vault-renew-token
      Periodically renew the provided Vault API token - this defaults to "true"
      and will renew the token at half of the lease duration

  -vault-retry
      Use retry logic when communication with Vault fails

  -vault-retry-attempts=<int>
      The number of attempts to use when retrying failed communications

  -vault-retry-backoff=<duration>
      The base amount to use for the backoff duration. This number will be
      increased exponentially for each retry attempt.

  -vault-ssl
      Specifies is communications with Vault should be done via SSL

  -vault-ssl-ca-cert=<string>
      Sets the path to the CA certificate to use for TLS verification

  -vault-ssl-ca-path=<string>
      Sets the path to the CA to use for TLS verification

  -vault-ssl-cert=<string>
      Sets the path to the certificate to use for TLS verification

  -vault-ssl-key=<string>
      Sets the path to the key to use for TLS verification

  -vault-ssl-server-name=<string>
      Sets the name of the server to use when validating TLS.

  -vault-ssl-verify
      Enable SSL verification for communications with Vault.

  -vault-token=<token>
      Sets the Vault API token

  -vault-transport-dial-keep-alive=<duration>
      Sets the amount of time to use for keep-alives

  -vault-transport-dial-timeout=<duration>
      Sets the amount of time to wait to establish a connection

  -vault-transport-disable-keep-alives
      Disables keep-alives (this will impact performance)

  -vault-transport-max-idle-conns-per-host=<int>
      Sets the maximum number of idle connections to permit per host

  -vault-transport-tls-handshake-timeout=<duration>
      Sets the handshake timeout

  -vault-unwrap-token
      Unwrap the provided Vault API token (see Vault documentation for more
      information on this feature)

  -wait=<duration>
      Sets the 'min(:max)' amount of time to wait before writing a template (and
      triggering a command)

  -v, -version
      Print the version of this daemon
```

这里介绍下几个常用参数的作用：

```
-consul-auth=<username[:password]>      设置基本的认证用户名和密码。
-consul-addr=<address>                  设置Consul实例的地址。
-max-stale=<duration>                   查询过期的最大频率，默认是1s。
-dedup                                  启用重复数据删除，当许多consul template实例渲染一个模板的时候可以降低consul的负载。
-consul-ssl                             使用https连接Consul。
-consul-ssl-verify                      通过SSL连接的时候检查证书。
-consul-ssl-cert                        SSL客户端证书发送给服务器。
-consul-ssl-key                         客户端认证时使用的SSL/TLS私钥。
-consul-ssl-ca-cert                     验证服务器的CA证书列表。
-consul-token=<token>                   设置Consul API的token。
-syslog                                 把标准输出和标准错误重定向到syslog，syslog的默认级别是local0。
-syslog-facility=<facility>             设置syslog级别，默认是local0，必须和-syslog配合使用。
-template=<template>                    增加一个需要监控的模板，格式是：'templatePath:outputPath(:command)'，多个模板则可以设置多次。
-wait=<duration>                        当呈现一个新的模板到系统和触发一个命令的时候，等待的最大最小时间。如果最大值被忽略，默认是最小值的4倍。
-retry=<duration>                       当在和consul api交互的返回值是error的时候，等待的时间，默认是5s。
-config=<path>                          配置文件或者配置目录的路径。
-pid-file=<path>                        PID文件的路径。
-log-level=<level>                      设置日志级别，可以是"debug","info", "warn" (default), and "err"。
-dry                                    Dump生成的模板到标准输出，不会生成到磁盘。
-once                                   运行consul-template一次后退出，不以守护进程运行。
```

### Consul-Template模版语法

Consul-Template模板文件的语法和Go Template的格式一样，Confd也是遵循Go Template的。

这里主要说下API相关的函数：

- datacenters

在Consul目录中查询所有的数据中心。使用以下语法:

```
{{datacenters}}
```

- file

读取并输出磁盘上的本地文件，如果无法读取产生一个错误。使用如下语法：

```
{{file "/path/to/local/file"}}
```

这个例子将输出`/path/to/local/file`文件内容到模板. 注意:这不会在嵌套模板中被处理。

- key

查询Consul指定key的值，如果key的值不能转换为字符串，将产生错误。使用如下语法:

```
{{key "service/redis/maxconns@east-aws"}}
```

上面的例子查询了在east-aws数据中心的service/redis/maxconns的值。如果忽略数据中心参数，将会查询本地数据中心的值：

```
{{key "service/redis/maxconns"}}
```

- keyOrDefault

查询Consul中指定的key的值，如果key不存在，则返回默认值。使用方式如下：

```
{{keyOrDefault "service/redis/maxconns@east-aws" "5"}}
```

注意Consul Template使用了多个阶段的运算。在第一阶段的运算如果Consul没有返回值，则会一直使用默认值。后续模板解析中如果值存在了则会读取真实的值。Consul Templae不会因为keyOrDefault没找到key而阻塞模板的的渲染。即使key存在如果Consul没有按时返回这个数据，也会使用默认值来进行替代。

- ls

查看Consul的所有以指定前缀开头的key-value对。如果有值无法转换成字符串则会产生一个错误:

```
{{range ls "service/redis@east-aws"}}
{{.Key}} {{.Value}}{{end}}
```

如果Consul实例在east-aws数据中心存在这个结构service/redis，渲染后的模板应该类似这样:

```
minconns 2
maxconns 12
```

如果你忽略数据中心属性,则会返回本地数据中心的查询结果。

- node

查询目录中的一个节点信息。

```
{{node "node1"}}
```

如果未指定任何参数，则当前Agent所在节点将会被返回:

```
{{node}}
```

你可以指定一个可选的参数来指定数据中心:

```
{{node "node1" "@east-aws"}}
```

如果指定的节点没有找到则会返回nil，如果节点存在就会列出节点的信息和节点提供的服务。

```
{{with node}}{{.Node.Node}} ({{.Node.Address}}){{range .Services}}
  {{.Service}} {{.Port}} ({{.Tags | join ","}}){{end}}
{{end}}
```

- nodes

查询Consul目录中的全部节点，使用如下语法：

```
{{nodes}}
```

这个例子会查询Consul的默认数据中心。你可以使用可选参数指定一个可选参数来指定数据中心:

```
{{nodes "@east-aws"}}
```

这个例子会查询east-aws数据中心的所有节点。


- secret

查询Vault中指定路径的密匙，如果指定的路径不存在或者Vault的Token没有足够权限去读取指定的路径，将会产生一个错误。如果路径存在但是key不存在则返回`<no value>`。

```
{{with secret "secret/passwords"}}{{.Data.password}}{{end}}
```

- service

查询Consul中匹配表达式的服务，语法如下:

```
{{service "release.web@east-aws"}}
```

上面的例子查询Consul中，在east-aws数据中心存在的健康的web服务。tag和数据中心参数是可选的，从当前数据中心查询所有节点的web服务而不管tag。查询语法如下:

```
{{service "web"}}
```

这个函数返回`[]*HealthService`结构.可按照如下方式应用到模板:


```
{{range service "web@data center"}}
server {{.Name}} {{.Address}}:{{.Port}}{{end}}
```

产生类似如下输出:

```
server nyc_web_01 1.2.3.4:8080
server nyc_web_02 10.20.30.40:8080
```

默认值会返回健康的服务。如果你想获取所有服务，可以增加any选项。如下：

```
{{service "web" "any"}}
```

这样就会返回注册过的所有服务，而不论它的状态如何。

如果你想过滤指定的一个或者多个健康状态，你可以通过逗号隔开多个健康状态：

```
{{service "web" "passing, warning"}}
```

这样将会返回被它们的节点和服务级别的检查定义标记为"passing"或者"warning"的服务。请注意逗号是OR而不是AND的意思。指定了超过一个状态过滤，并包含any将会返回一个错误。因为any是比所有状态更高级的过滤。

后面这2种方式有些架构上的不同:

```
{{service "web"}}
{{service "web" "passing"}}
```

前者会返回Consul认为healthy和passing的所有服务。后者将返回所有已经在Consul注册的服务，然后会执行一个客户端的过滤。通常如果你想获取健康的服务，你应该不要使用passing参数。直接忽略第三个参数即可。然而第三个参数在你想查询passing或者warning的服务会比较有用,如下:

```
{{service "web" "passing, warning"}}
```

服务的状态也是可见的，如果你想自己做一些额外的过滤。语法如下：

```
{{range service "web" "any"}}
{{if eq .Status "critical"}}
// Critical state!{{end}}
{{if eq .Status "passing"}}
// Ok{{end}}
```

执行命令时，在Consul将服务设置为维护模式只需要在你的命令上包上Consul的maint调用:

```
#!/bin/sh
set -e
consul maint -enable -service web -reason "Consul Template updated"
service nginx reload
consul maint -disable -service web
```

另外如果你没有安装Consul agent,你可以直接调用API请求:

```
#!/bin/sh
set -e
curl -X PUT "http://$CONSUL_HTTP_ADDR/v1/agent/service/maintenance/web?enable=true&reason=Consul+Template+Updated"
service nginx reload
curl -X PUT "http://$CONSUL_HTTP_ADDR/v1/agent/service/maintenance/web?enable=false"
```

- services

查询Consul目录中的所有服务，使用如下语法:

```
{{services}}
```

这个例子将查询Consul的默认数据中心，你可以指定一个可选参数来指定数据中心:

```
{{services "@east-aws"}}
```

请注意: services函数与service是不同的，service接受更多参数并且查询监控的服务列表。这个查询Consul目录并返回一个服务的tag的Map。如下:

```
{{range services}}
{{.Name}}
{{range .Tags}}
  {{.}}{{end}}
{{end}}
```

- tree

查询所有指定前缀的key-value值对，如果其中的值有无法转换为字符串的则引发错误:

```
{{range tree "service/redis@east-aws"}}
{{.Key}} {{.Value}}{{end}}
```

如果Consul实例在east-aws数据中心有一个service/redis结构，模板的渲染结果类似下面:

```
minconns 2
maxconns 12
nested/config/value "value"
```

和ls不同tree返回前缀下的所有key，和Unix的tree命令比较像。如果忽略数据中心参数，则会使用本地数据中心。

更多辅助函数，比如 scratch、byKey、byTag、contains、explode、in、loop、trimSpace、join、parseBool、parseFloat、parseInt、parseJSON、parseUint、regexMatch等可参考：https://github.com/hashicorp/consul-template#templating-language

### Consul-Template使用实例

在进行以下测试前，你首先得有一个Consul集群。如果你还没有，可参考「[Consul集群部署](https://www.hi-linux.com/posts/28048.html)」 一文搭建一个。当然单节点Consul环境也是可以的，如果你只想做一下简单的测试也可以参考「[Consul入门](https://www.hi-linux.com/posts/6132.html)」一文先快速搭建一个单节点环境。

#### 命令行方式


- 输出已注册服务的名称和Tags。

创建一个服务文件

```
$ vim  /opt/consul/conf/hi-linux.json
{"service": {"name": "hi-linux", "tags": ["web"], "port": 8080,
"check": {"http": "http://192.168.2.210:8080", "interval": "10s"}}}
```

通过`consul reload`进行热注册

```
$ consul reload --http-addr=192.168.2.210:8500
Configuration reload triggered
```

验证服务是否注册成功

```
$ curl http://192.168.2.210:8500/v1/catalog/service/hi-linux

[{"ID":"7d3b4fa3-b284-b761-f973-d856cd41ab7a","Node":"consul-server01","Address":"192.168.2.210","TaggedAddresses":{"lan":"192.168.2.210","wan":"192.168.2.210"},"NodeMeta":{},"ServiceID":"hi-linux","ServiceName":"hi-linux","ServiceTags":["web"],"ServiceAddress":"","ServicePort":8080,"ServiceEnableTagOverride":false,"CreateIndex":4985,"ModifyIndex":4985}]
```

创建模板文件

```
$ vim tmpltest.ctmpl

{{range services}}
{{.Name}}
{{range .Tags}}
{{.}}{{end}}
{{end}}
```

调用模板文件生成查询结果

```
$ consul-template -consul-addr 192.168.2.210:8500 -template "tmpltest.ctmpl:result" -once
```

> 命令说明：
> -consul-addr:指定Consul的API接口 ，默认是8500端口。
> -template：模板参数，第一个参数是模板文件位置，第二个参数是结果输出位置。
> -once：只运行一次就退出。


查看模板渲染的结果

```
$ cat result

consul

hi-linux
web
```

输出结果说明：consul是系统自带的服务，hi-linux是刚才注册的服务,其Tags为web。

- 根据已注册的服务动态生成Nginx配置文件

新建Nginx配置模板文件

```
$ vim nginx.conf.ctmpl

{{range services}} {{$name := .Name}} {{$service := service .Name}}
upstream {{$name}} {
  zone upstream-{{$name}} 64k;
  {{range $service}}server {{.Address}}:{{.Port}} max_fails=3 fail_timeout=60 weight=1;
  {{else}}server 127.0.0.1:65535; # force a 502{{end}}
} {{end}}

server {
  listen 80 default_server;

  location / {
    root /usr/share/nginx/html/;
    index index.html;
  }

  location /stub_status {
    stub_status;
  }

{{range services}} {{$name := .Name}}
  location /{{$name}} {
    proxy_pass http://{{$name}};
  }
{{end}}
}
```

调用模板文件生成Nginx配置文件

```
$ consul-template  -consul-addr 192.168.2.210:8500 -template="nginx.conf.ctmpl:default.conf" -once

# 渲染后的Nginx配置文件
$ cat default.conf

upstream consul {
  zone upstream-consul 64k;
  server 192.168.2.210:8300 max_fails=3 fail_timeout=60 weight=1;
  server 192.168.2.211:8300 max_fails=3 fail_timeout=60 weight=1;
  server 192.168.2.212:8300 max_fails=3 fail_timeout=60 weight=1;

}
upstream hi-linux {
  zone upstream-hi-linux 64k;
  server 192.168.2.210:8080 max_fails=3 fail_timeout=60 weight=1;

}
upstream web {
  zone upstream-web 64k;
  server 192.168.2.210:8080 max_fails=3 fail_timeout=60 weight=1;

}

server {
  listen 80 default_server;

  location / {
    root /usr/share/nginx/html/;
    index index.html;
  }

  location /stub_status {
    stub_status;
  }

  location /consul {
    proxy_pass http://consul;
  }

  location /hi-linux {
    proxy_pass http://hi-linux;
  }

}
```

如果想生成Nginx配置文件后自动加载配置，可以这样：

```
$ consul-template  -consul-addr 192.168.2.210:8500 -template="nginx.conf.ctmpl:/usr/local/nginx/conf/conf.d/default.conf:service nginx reload" -once
```

- 运行consul-temple作为一个服务

上面两个例子都是consul-template运行一次后就退出了，如果想运行为一个服务可以这样：

```
$ consul-template \
  -consul-addr=192.168.2.210:8500 \
  -template "tmpltest.ctmpl:test.out"
```

- 查询Consul实例同时渲染多个模板，然后重启相关服务。如果API故障则每30s尝试检测一次值，consul-template运行一次后退出。

```
$ consul-template \
  -consul-addr=192.168.2.210:8500 \
  -retry 30s \
  -once \
  -template "nginx.ctmpl:/etc/nginx/nginx.conf:service nginx restart" \
  -template "redis.ctmpl:/etc/redis/redis.conf:service redis restart" \
  -template "haproxy.ctmpl:/etc/haproxy/haproxy.conf:service haproxy restart"
```

- 查询一个实例，Dump模板到标准输出。主要用作测试模板输出。

```
$ consul-template \
  -consul-addr=192.168.2.210:8500 \
  -template "tmpltest.ctmpl:result" \
  -once \
  -dry
```

#### 配置文件方式

以上参数除了在命令行使用也可以直接配置在文件中，下面看看Consul-Template的配置文件，简称HCL(HashiCorp Configuration Language)，它是和JSON兼容的。

下面先看看官方给的配置文件格式：

```
consul {

  auth {
    enabled  = true
    username = "test"
    password = "test"
  }

  address = "192.168.2.210:8500"
  token = "abcd1234"

  retry {
    enabled = true
    attempts = 5
    backoff = "250ms"
  }

  ssl {

    enabled = true
    verify = false
    cert = "/path/to/client/cert"
    key = "/path/to/client/key"
    ca_cert = "/path/to/ca"
    ca_path = "path/to/certs/"
    server_name = "my-server.com"
  }
}

reload_signal = "SIGHUP"
dump_signal = "SIGQUIT"
kill_signal = "SIGINT"
max_stale = "10m"
log_level = "warn"
pid_file = "/path/to/pid"


wait {
  min = "5s"
  max = "10s"
}

vault {
  address = "https://vault.service.consul:8200"
  token = "abcd1234"
  unwrap_token = true
  renew_token = true
  retry {
    # ...
  }

  ssl {
    # ...
  }
}


syslog {
  enabled = true
  facility = "LOCAL5"
}


deduplicate {
  enabled = true
  prefix = "consul-template/dedup/"
}


exec {
  command = "/usr/bin/app"
  splay = "5s"
  env {

    pristine = false
    custom = ["PATH=$PATH:/etc/myapp/bin"]
    whitelist = ["CONSUL_*"]
    blacklist = ["VAULT_*"]
  }

  reload_signal = ""
  kill_signal = "SIGINT"
  kill_timeout = "2s"
}

template {

  source = "/path/on/disk/to/template.ctmpl"
  destination = "/path/on/disk/where/template/will/render.txt"
  contents = "{{ keyOrDefault \"service/redis/maxconns@east-aws\" \"5\" }}"
  command = "restart service foo"
  command_timeout = "60s"
  perms = 0600
  backup = true
  left_delimiter  = "{{"
  right_delimiter = "}}"

  wait {
    min = "2s"
    max = "10s"
  }
}
```

更多详细的参数可以参考这里： https://github.com/hashicorp/consul-template#configuration-file-format

注意: 上面的选项不都是必选的，可根据实际情况调整。为了更加安全，token也可以从环境变量里读取，使用`CONSUL_TOKEN`和`VAULT_TOKEN`。强烈建议你不要把token放到未加密的文本配置文件中。


接下来我们看一个简单的实例，生成Nginx配置文件并重新加载：

```
$ vim nginx.hcl

consul {
address = "192.168.2.210:8500"
}

template {
source = "nginx.conf.ctmpl"
destination = "/usr/local/nginx/conf/conf.d/default.conf"
command = "service nginx reload"
}

```

注：nginx.conf.ctmpl模板文件内容还是和前面的一样。


执行以下命令就可渲染文件了：

```
$ consul-template -config "nginx.hcl"
```

更多官方例子可参考：https://github.com/hashicorp/consul-template/tree/master/examples


### 参考文档

http://www.google.com
https://my.oschina.net/guol/blog/675281
http://liangxiansen.cn/2017/04/06/consul/
https://github.com/hashicorp/consul-template
