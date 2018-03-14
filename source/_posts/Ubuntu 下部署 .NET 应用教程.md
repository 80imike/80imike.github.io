---
category: .NET
title: Ubuntu 下部署 .NET 应用教程
date: 2018-03-14 09:00:00
tags: [Linux, .NET]
abbrlink:
updated:
toc_number: false
---

.NET Core 是一个通用开发平台，由 Microsoft 和 GitHub 上的 .NET 社区共同维护。 它是跨平台的，支持 Windows、macOS 和 Linux，并且可用于设备、云和嵌入式/IoT 方案。

.NET Core 支持使用 C#、Visual Basic 和 F# 语言编写的应用程序和库。 

.NET Core 可以用来搭建 Web应用、微服务、创立应用库和控制台应用。

**.NET Core 特性**

- 部署灵活：可以包含在应用或已安装的并行用户或计算机范围中。
- 跨平台：可以在 Windows、macOS 和 Linux 上运行；也可移植到其他操作系统。 Microsoft、其他公司和个人提供的支持的操作系统 (OS)、CPU 和应用程序方案会随着时间推移而增多。
- 命令行工具：可在命令行中执行所有产品方案。
- 兼容性：.NET Core 通过 .NET 标准与 .NET Framework、Xamarin 和 Mono 兼容。
- 开放源：.NET Core 是一个开放源平台，使用 MIT 和 Apache 2 许可证。 文档由 CC-BY 许可发行。 .NET Core 是一个 .NET Foundation 项目。
- 由 Microsoft 支持：.NET Core 由 Microsoft 依据 .NET Core 支持提供支持

<!-- more -->

**.NET Core 组成**

- .NET 运行时：提供类型系统、程序集加载、垃圾回收器、本机互操作和其他基本服务。
- 框架库：提供基元数据类型、应用编写类型和基本实用程序。
- .NET Core SDK 工具和语言编译器：相关系列的SDK工具和语言编译器。
- .NET Core 应用的命令行工具集。

### 安装 .NET Core

.NET Core 目前一共发行了 1.x 和 2.x 两个大版本，两个版本可支持的操作系统版本也有所不同，具体如下：

**.NET Core 1.x 支持的 Linux (仅支持 64 位) 发行版本:**

- Red Hat Enterprise Linux 7
- CentOS 7
- Oracle Linux 7
- Fedora 24
- Debian 8.2 or later versions
- Ubuntu 14.04, Ubuntu 16.04, Ubuntu 16.10*
- Ubuntu 16.10 is supported by the latest patch release of .NET Core 1.1
- Linux Mint 17
- openSUSE 42.1 or later versions (.NET Core 1.1)

.NET Core 安装还是比较简单，直接通过官方提供的软件源便可很容易的完成安装。这里以 Ubuntu 16.04 为例：

```
# 增加软件源并导入密钥
$ sudo sh -c 'echo "deb [arch=amd64] https://apt-mo.trafficmanager.net/repos/dotnet-release/ xenial main" > /etc/apt/sources.list.d/dotnetdev.list'
$ sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys B02C46DF417A0893
# 更新软件源列表
$ sudo apt-get update
# 安装.NET Core
$ sudo apt-get install dotnet-dev-1.0.4
# 验证安装的.NET Core版本
$ dotnet --version
```

更多发行版本的安装可参考：https://docs.microsoft.com/en-us/dotnet/core/linux-prerequisites?tabs=netcore1x

**.NET Core 2.x 支持的 Linux (仅支持 64 位) 发行版本:**

- Red Hat Enterprise Linux 7
- CentOS 7
- Oracle Linux 7
- Fedora 25, Fedora 26
- Debian 8.7 or later versions
- Ubuntu 17.04, Ubuntu 16.04, Ubuntu 14.04
- Linux Mint 18, Linux Mint 17
- openSUSE 42.2 or later versions
- SUSE Enterprise Linux (SLES) 12 SP2 or later versions

.NET Core 2.x 的安装和 .NET Core 1.x 类似，同样可以直接通过官方提供的软件源来完成安装。这里以 Ubuntu 16.04 为例：

```
# 增加软件源并导入密钥
$ curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
$ sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
$ sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-xenial-prod xenial main" > /etc/apt/sources.list.d/dotnetdev.list'
# 更新软件源列表
$ sudo apt-get update
# 安装.NET Core
$ sudo apt-get install apt-transport-https
$ sudo apt-get install dotnet-sdk-2.1.4
# 验证安装的.NET Core版本
$ dotnet --version
```

更多发行版本的安装可参考：https://www.microsoft.com/net/learn/get-started/

###  创建一个.NET Core 项目

- 创建一个.NET Core项目：

在当前目录下建立一个 myApp 目录并使用 console 模板初始化一个项目。

```
$ dotnet new console -o myApp
```

- 编译并运行项目

该项目成功编译运行会在终端输出一个 Hello World!。

```
$ dotnet run
Hello World!
```

### 创建 ASP.NET Core 网站

#### 下载演示代码

这里使用 NETCoreBBS 这个项目来演示，NETCoreBBS 是一个轻量级的论坛应用。首先下载代码：

```
$ git clone https://github.com/linezero/NETCoreBBS
```

NETCoreBBS 项目默认运行在 80 端口，如果和你本地端口冲突。可以到 Program.cs 中更改。

```
$ vim NETCoreBBS/src/NetCoreBBS/Program.cs

# 默认为 80 端口，这里修改为 8000 端口
.UseUrls("http://*:8000")
```

#### 发布应用

- 编译应用

```
$ cd NETCoreBBS
$ dotnet restore
$ dotnet publish 
  ....
  Restore completed in 3.24 ms for /root/dotnet/NETCoreBBS/src/Infrastructure/Infrastructure.csproj.
  Bundling with configuration from /root/dotnet/NETCoreBBS/src/NetCoreBBS/bundleconfig.json
  Processing wwwroot/css/site.min.css
    Minified
  Processing wwwroot/js/site.min.js
    wwwroot/js/site.js was not found
  ApplicationCore -> /root/dotnet/NETCoreBBS/src/ApplicationCore/bin/Debug/netstandard2.0/ApplicationCore.dll
  ApplicationCore -> /root/dotnet/NETCoreBBS/src/ApplicationCore/bin/Debug/netstandard2.0/publish/
  UnitTests -> /root/dotnet/NETCoreBBS/tests/UnitTests/bin/Debug/netcoreapp2.0/UnitTests.dll
  UnitTests -> /root/dotnet/NETCoreBBS/tests/UnitTests/bin/Debug/netcoreapp2.0/publish/
  Infrastructure -> /root/dotnet/NETCoreBBS/src/Infrastructure/bin/Debug/netstandard2.0/Infrastructure.dll
  Infrastructure -> /root/dotnet/NETCoreBBS/src/Infrastructure/bin/Debug/netstandard2.0/publish/
  NetCoreBBS -> /root/dotnet/NETCoreBBS/src/NetCoreBBS/bin/Debug/netcoreapp2.0/NetCoreBBS.dll
  Bundling with configuration from /root/dotnet/NETCoreBBS/src/NetCoreBBS/bundleconfig.json
  Processing wwwroot/css/site.min.css
  Processing wwwroot/js/site.min.js
    wwwroot/js/site.js was not found
  NetCoreBBS -> /root/dotnet/NETCoreBBS/src/NetCoreBBS/bin/Debug/netcoreapp2.0/publish/
```

编译成功后会在项目下生成一个 publish 目录，这就是默认发布生成的文件夹，在这个文件夹中可以看到我们程序所有依赖的程序集文件。

```
$ ls ./src/NetCoreBBS/bin/Debug/netcoreapp2.0/publish/

...
ApplicationCore.dll				       Microsoft.AspNetCore.JsonPatch.dll			       Microsoft.EntityFrameworkCore.Design.dll			    Microsoft.VisualStudio.Web.CodeGeneration.EntityFrameworkCore.dll
ApplicationCore.pdb				       Microsoft.AspNetCore.Localization.dll			       Microsoft.EntityFrameworkCore.dll			    Microsoft.VisualStudio.Web.CodeGeneration.Templating.dll
appsettings.json				       Microsoft.AspNetCore.Mvc.Abstractions.dll		       Microsoft.EntityFrameworkCore.Relational.dll		    Microsoft.VisualStudio.Web.CodeGeneration.Utils.dll
....
```

publish 目录里常用文件说明：

```
appsettiong.json  # 应用程序的配置文件
refs # 应用程序引用的 .net fx系统程序集
runtimes # 运行时环境，可以看到里面的文件夹包含 Windows、Linux，macOS等，说明我们这个应用程序是跨平台的。
views # 存放的是 mvc 的视图文件。
wwwroot # 存放的是前端使用的 js 库，css 样式表，和图片等。
```

如果你要将编译结果输出到指定目录，可以使用以下命令来完成。

```
$ dotnet publish -c Release -o /tmp/bbs.hi-linux.com
```

- 发布应用

```
# 把工作目录切换到需要发布的文件夹，这里是默认的 publish。
$ cd ./src/NetCoreBBS/bin/Debug/netcoreapp2.0/publish/

# 发布应用
$ dotnet NetCoreBBS.dll 
Hosting environment: Production
Content root path: /root/dotnet/NETCoreBBS/src/NetCoreBBS/bin/Debug/netcoreapp2.0/publish
Now listening on: http://[::]:8000
Application started. Press Ctrl+C to shut down.
```

-  访问应用

打开浏览器访问 `http://IP:8000/`，成功出现以下页面就表示部署成功了。

![](https://www.hi-linux.com/img/linux/dotnetcore1.png)

### 使用 Supervisor 让应用在后台运行

默认情况下 .NET Core 在前台进程运行，如果要将服务放到后台我们这里可以使用 Supervisor 来实现。

- 安装 Supervisor

```
$ sudo apt-get install supervisor
```

- 配置 Supervisor

安装好 Supervisor 以后，下面就在 Supervisor 中配置一个 NetCoreBBS 的后台守护。

要增加一个应用的后台守护，我们需要在 `/etc/supervisor/conf.d/` 目录中新增一个 NetCoreBBS.conf 的配置文件。


```
$ vim /etc/supervisor/conf.d/NetCoreBBS.conf

[program:NetCoreBBS]

directory=/root/dotnet/NETCoreBBS/src/NetCoreBBS/bin/Debug/netcoreapp2.0/publish
command=dotnet NetCoreBBS.dll
autostart=true
autorestart=true
startsecs=10
startretries=50
stderr_logfile=/var/log/NetCoreBBS.err.log
stdout_logfile=/var/log/NetCoreBBS.out.log
environment=ASPNETCORE__ENVIRONMENT=Production
user=root
stopsignal=INT
```

- 启动 Supervisor

```
$ /etc/init.d/supervisor restart
[ ok ] Restarting supervisor (via systemctl): supervisor.service.
```

如果一切配置正确，查看相应日志你可以看到类似以下输出，表示应用已正常启动。

```
$ tail -f  /var/log/NetCoreBBS.out.log
Hosting environment: Production
Content root path: /root/dotnet/NETCoreBBS/src/NetCoreBBS/bin/Debug/netcoreapp2.0/publish
Now listening on: http://[::]:8000
Application started. Press Ctrl+C to shut down.
```

### 配置 Nginx 反向代理

通常现在主流的 Web 服务器都使用的 Nginx，相应的 80 端口也被占用了。如果你想把 .NET 应用也运行在 80 端口，这时只需在 Nginx 上增加一个网站的反向代理就可实现。

Nginx 使用非常的广泛了，之前也讲过很多了。关于 Nginx 的安装使用这里就不再赘述了。Nginx 配置文件片断如下:

```
server {
	listen 80;
	server_name bbs.hi-linux.com;

	location / {
		proxy_pass http://127.0.0.1:8000;
		proxy_http_version 1.1;
		proxy_set_header Upgrade $http_upgrade;
		proxy_set_header Connection keep-alive;
		proxy_set_header Host $http_host;
		proxy_cache_bypass $http_upgrade;
	}
}
```

到此，我们就演示了如何在 Ubuntu 上搭建了一个完整的  .NET 应用。


### 参考文档

https://www.google.com
https://aka.ms/dotnet-docs
https://aka.ms/dotnet-cli-docs
http://blog.topspeedsnail.com/archives/6559
https://docs.microsoft.com/zh-cn/aspnet/core/
https://www.microsoft.com/net/learn/get-started/
http://www.cnblogs.com/linezero/p/aspnetcoreubuntu.html
https://www.cnblogs.com/savorboard/p/dotnet-core-publish-nginx.html
https://www.microsoft.com/net/download/linux-package-manager/ubuntu14-04/sdk-current