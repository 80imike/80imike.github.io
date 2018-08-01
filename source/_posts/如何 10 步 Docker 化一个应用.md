---
category: Docker
title: 如何 10 步 Docker 化一个应用
date: 2018-08-01 09:00:00
tags: [Linux, Docker]
abbrlink:
updated:
toc_number: false
---

本文将讲解如何将应用 Docker 化的一些很实用的技巧和准则，推荐一读。

**一、选择基础镜像**

每种对应技术几乎都有自己的基础镜像，例如：

- https://hub.docker.com/_/java/
- https://hub.docker.com/_/python/
- https://hub.docker.com/_/nginx/

如果不能直接使用这些镜像，我们就需要从基础操作系统镜像开始安装所有的依赖。

网上大多数教程使用的都是以 Ubuntu（例如：Ubuntu:16.04 ）作为基础镜像，这并不是一个问题，但是我建议优先考虑 Alpine 镜像：

- https://hub.docker.com/_/alpine/

Alpine 是一个非常小的基础镜像（它的容量大约只有 5MB）。

> 注：在基于 Alpine 的镜像中你无法使用 apt-get 命令。不过你不必担心，因为 Alpine 系统有自己的软件包仓库和包管理工具 apk。关于 apk 的具体使用你可以详细参考：「[Alpine Linux配置使用技巧](https://mp.weixin.qq.com/s?__biz=MzI3MTI2NzkxMA==&mid=2247484888&idx=1&sn=bfdd55a668b068ab34251512613e5267&chksm=eac524f1ddb2ade7739c10440af8b33a39b81b8a4a57b628cc6c0d0ec3a82f18b914f4e12641&mpshare=1&scene=23&srcid=0731dgw9eDCTtafPzAd3VxDV%23rd)」一文。

**二、安装必要软件包**

这个步骤通常比较琐碎，有一些容易忽略的细节：

- `apt-get update` 和 `apt-get install` 命令应该写在一行（如果使用 Alpine 则对应的是 apk 命令）。这不是一个常见的做法，但是在 Dockerfile 中应该要这么做。否则 `apt-get update` 命令产出的临时层可能会被缓存，导致构建时没有更新包信息。（具体可参见[此文](https://forums.docker.com/t/dockerfile-run-apt-get-install-all-packages-at-once-or-one-by-one/17191)）。

- 确认是否只安装了实际需要的软件（特别是在生产环境中运行这个容器）。

> 注：我见过有人在他们的镜像中安装了 vim 和其他开发工具。如果这是必要的，应该针对构建、调试和开发环境创建不同的 Dockerfile。这不仅仅关系到镜像大小，还涉及到安全性、可维护性等等。

<!-- more -->

**三、添加自定义文件**

一些优化 Dockerfile 的小提示：

- 理解 COPY 和 ADD 指令的区别，具体可参考[此文](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#add-or-copy)。

- 尽可能遵照[文件系统](http://www.pathname.com/fhs/)惯例来存放文件。例如：针对解释型应用程序（如：Python），使用 /usr/src 目录。

- 检查添加文件的属性。如果需要可执行权限，没有必要在镜像上新建一个层（ 通过 RUN chmod +x ... 指令来增加权限）。你只需要在代码仓库的源文件上修正这些属性即可，即使开发平台是 Windows，也可以参照[此文](https://stackoverflow.com/questions/21691202/how-to-create-file-execute-mode-permissions-in-git-on-windows)给文件增加可执行权限。

**四、定义容器运行时的用户权限**

- 容器中的进程默认情况下是以 root 权限运行的。
- 如果容器中的应用程序需要使用特定的用户或组（/etc/passwd 或 /etc/group）来运行时，可以在容器启动时使用 `docker run` 命令的 `--user` 参数来指定其固定的 UID 或 GID。
- 尽可能避免容器中的进程以 root 权限运行。

> 注：现在不少热门应用程序镜像都需要用特定的用户 ID 来运行（例如:Elastic Search 需要 uid:gid = 1000:1000），请尽量不要在写出这样的镜像。更多关于容器内运行应用程序的权限说明可参考[此文](https://medium.com/@mccode/understanding-how-uid-and-gid-work-in-docker-containers-c37a01d01cf)。

**五、定义暴露的端口**

不要为了暴露特权端口（例如：80）而将容器以 root 权限运行。如果有这样的需求，可以让容器暴露一个非特权端口（例如：8080），然后在启动时进行端口映射。

> 注：低于 1024 的 TCP / IP 端口号就是特权端口，因为不允许普通用户在这些端口上运行服务。 

**六、定义入口点（entrypoint）**

- 普通方式：直接运行可执行文件。

- 更好的方式：创建一个 docker-entrypoint.sh 脚本，这样可以通过环境变量来配置容器的入口点。这也是一个非常普遍的做法，可参考下面这些例子：elasticsearch 的 [docker-entrypoint.sh](https://github.com/elastic/elasticsearch-docker/tree/master/build/elasticsearch/bin) 文件 和 postgres 的 [docker-entrypoint.sh](https://github.com/docker-library/postgres/tree/de8ba87d50de466a1e05e111927d2bc30c2db36d/10) 文件。

**七、定义一种配置方式**

每个应用程序都需要参数化，你基本上可以遵循以下两个原则：

- 使用应用程序特定的配置文件：该方式需要通过文档来说明配置文件的格式、字段、放置位置等等（当运行环境比较复杂，例如：应用程序跨越不同的技术，则不太合适）。

- 使用操作系统环境变量：简单而有效。这也是 [12-factors](https://12factor.net/zh_cn/config) 推荐的方式。

>注：使用环境变量方式并不意味着您需要丢弃配置文件并重构应用程序的配置机制，你只需要通过 [envsubst](https://blog.csdn.net/zh515858237/article/details/79218176) 命令来替换配置文件模板中的值就可以了（这个流程一般需要在 docker-entrypoint.sh 文件中完成，因为这需要在容器进程运行前完成）。例如：在 Nginx 配置中使用环境变量，具体方法可参考[此文](https://docs.docker.com/samples/library/nginx/#using-environment-variables-in-nginx-configuration)。

这种方式可以将应用程序的配置文件封装在容器内部。

**八、外部化数据**

关于数据存储有一条黄金法则：绝对不要将任何持久化数据保存到容器内。

容器的文件系统本身是被设计成临时和短暂的。因此任何由应用程序生成的内容、数据文件和处理结果都应该保存到挂载的卷或者操作系统绑定挂载点上（既：将宿主机操作系统的目录挂载到容器中）。

如果将数据保存到绑定挂载点，对于要绑定到容器的宿主机上的目录，你需要注意以下几点：

- 在宿主机操作系统上创建非特权用户和组。
- 所有需要绑定目录的所有者都是该用户。
- 根据使用场景给授权（仅针对这个特定的用户和组，其他用户无权访问）。
- 容器也以该用户运行。
- 容器可以完全控制这些目录。

**九、确保处理好日志**

如果这是一个新的应用程序，并且希望它能够坚持 Docker 约定，就不应该将日志写入任何文件。应用程序应该使用标准输出和标准错误输出日志，这和之前推荐使用环境变量传递参数一样，这也是 12-factors 之一，具体可以参见[这里](https://12factor.net/zh_cn/logs)。

Docker 会自动捕捉应用程序的标准输出，并可以通过 `docker logs` 命令查看。有关于 `docker logs` 的具体使用你可以参考[这里](https://docs.docker.com/engine/reference/commandline/logs/)。 

但是在一些实际场景下你可能会遇到问题，例如：运行一个简单的 Nginx 容器，至少会有两种不同的日志文件：

- HTTP 访问日志（Access Logs）
- 错误日志（Error Logs）

对于这种按照特定结构输出日志的应用，就不太适合将它们的日志输出到标准输出。这种情况下，你需要按持久化的方式处理这些日志，并确保这些日志文件的能正常的轮转。

**十、轮转日志**

如果应用程序将日志写到文件，或者会无限追加内容到文件，就需要关注这些文件的轮转（rotation），这对于防止服务器空间耗尽非常有用的。

如果使用绑定挂载，我们可以依靠宿主机的一些工具来实现文件轮转功能。例如：logrotate，关于 logrotate 的使用你可以参考[示例一](https://www.aerospike.com/docs/operations/configure/log/logrotate.html)、[示例二](https://www.digitalocean.com/community/tutorials/how-to-manage-logfiles-with-logrotate-on-ubuntu-16-04)。

> 注：本文在 「[如何 Docker 化任意一个应用](http://t.cn/ReT0AyJ)」的基础上整理和修改，原文地址：http://t.cn/ReT0AyJ 。
>
> 由于微信不允许外部链接，如果你需要访问文中链接可点击文末左下角的阅读原文。