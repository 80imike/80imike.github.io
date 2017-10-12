---
category: mssql
title: Ubuntu下部署SQL Server 2017
date: 2017-10-12 09:00:00
tags: [linux, mssql]
abbrlink:
updated:
toc_number: false
---

SQL Server 2017 最近已正式发布。这是 SQL Server 历史上首次同时发布 Windows 和 Linux 版。此外，微软还发布了能使用 Docker 部署的容器版本。对 SQL Server 而言，这是其历史上具有里程碑意义的一步，因为这是跨出 Windows 的第一个版本，标志着 SQL Server 在 Linux 平台上首次可用。

SQL Server 2017 新版本成为第一个云端、跨不同操作系统的版本，包括 Linux、Docker。SQL Server 2017 目前支持的 Linux 发行版包括：Red Hat Enterprise Linux(RHEL), SUSE Linux Enterprise Server 和 Ubuntu。SQL Server 2017 支持 Docker 企业版，Kubernetes 和 OpenShift 这三大容器平台。

<!-- more -->

SQL Server 2017 新特性

- SQL Server 2017 支持使用 R 和 Python 的分析方法，来做资料库内的机器学习，意味着不必迁移资料，省下不少时间。
- 图数据分析功能将使客户能够使用图形数据存储和查询语言扩展来使用原生的图形查询语法，以便在高度互连的数据中发现新的关系。
- 自适应查询处理可为数据库带来更智能的体验。例如，SQL Server 中的 Adaptive Memory Grants 跟踪并了解对给定的查询使用了多少内存，以调整内存的使用。
- Automatic Plan Correction 通过查找和修正性能的回归来确保持续的性能。

SQL Server 2017 的核心功能在 Windows 和 Linux 上保持一致，但有少部分依赖于 Windows 功能的特性没有提供给 Linux (例如集群支持和集成 Windows 身份验证)。

本文将介绍如何在 Ubuntu 下部署 SQL Server 2017 。

### 安装 SQL Server 2017

在 Linux 上 安装 SQL Server 2017 的先决条件

设备类型 | 设备要求 | 
---------|----------
 内存| 3.25 GB 及以上 
 文件系统 | XFS或EXT4 (其他文件系统，如BTRFS，不支持)
 磁盘空间 | 6 GB 
 处理器速度 |  2 GHz
 处理器核心 | 2 核
 处理器类型 | 仅 x64 兼容

#### 安装 SQL Server 2017 服务端

- 导入公共存储库 GPG 密钥

```
$ curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
```

- 增加 Microsoft SQL Server Ubuntu 仓库

```
$ add-apt-repository "$(curl https://packages.microsoft.com/config/ubuntu/16.04/mssql-server-2017.list)"
```

- 安装 SQL Server 服务端

```
$ apt-get update
$ apt-get install -y mssql-server
```

- 设置 SA 密码，并选择要安装的版本

```
$ /opt/mssql/bin/mssql-conf setup

Choose an edition of SQL Server:
  1) Evaluation (free, no production use rights, 180-day limit)
  2) Developer (free, no production use rights)
  3) Express (free)
  4) Web (PAID)
  5) Standard (PAID)
  6) Enterprise (PAID)
  7) Enterprise Core (PAID)
  8) I bought a license through a retail sales channel and have a product key to enter.

Details about editions can be found at
https://go.microsoft.com/fwlink/?LinkId=852748&clcid=0x409

Use of PAID editions of this software requires separate licensing through a
Microsoft Volume Licensing program.
By choosing a PAID edition, you are verifying that you have the appropriate
number of licenses in place to install and run this software.

Enter your edition(1-8): 1
The license terms for this product can be found in
/usr/share/doc/mssql-server or downloaded from:
https://go.microsoft.com/fwlink/?LinkId=855864&clcid=0x409

The privacy statement can be viewed at:
https://go.microsoft.com/fwlink/?LinkId=853010&clcid=0x409

Do you accept the license terms? [Yes/No]:yes

Enter the SQL Server system administrator password:
Confirm the SQL Server system administrator password:
Configuring SQL Server...

The licensing PID was successfully processed. The new edition is [Enterprise Evaluation Edition].
Created symlink from /etc/systemd/system/multi-user.target.wants/mssql-server.service to /lib/systemd/system/mssql-server.service.
Setup has completed successfully. SQL Server is now starting.
```

> 一共提供了 8 个版本供选择，其中自由授予许可版本有：评估、开发人员和快速。
> SA 帐户必须为强密码（最少 8 个字符，包括大写和小写字母、十进制数字和/或非字母数字符号）。

- 验证服务是否正在运行

```
$ systemctl status mssql-server

● mssql-server.service - Microsoft SQL Server Database Engine
   Loaded: loaded (/lib/systemd/system/mssql-server.service; enabled; vendor preset: enabled)
   Active: active (running) since Thu 2017-10-12 11:50:29 CST; 1min 22s ago
     Docs: https://docs.microsoft.com/en-us/sql/linux
 Main PID: 20776 (sqlservr)
   CGroup: /system.slice/mssql-server.service
           ├─20776 /opt/mssql/bin/sqlservr
           └─20796 /opt/mssql/bin/sqlservr
```

#### 安装 SQL Server 2017 命令行工具

如果要创建数据库，需要使用客户端工具 `sqlcmd` 和 `bcp`。

- 导入公共存储库 GPG 密钥

```
$ curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
```

- 增加 Microsoft Ubuntu 仓库

```
$ add-apt-repository "$(curl https://packages.microsoft.com/config/ubuntu/16.04/prod.list)"
```

- 安装 SQL Server 命令行工具 和 unixODBC 开发人员工具包

```
$ apt-get update
$ apt-get install -y mssql-tools unixodbc-dev
```

`Sqlcmd` 工具默认安装到 /opt/mssql-tools/bin/ 中的，为方便使用把 /opt/mssql-tools/bin/ 添加到环境变量中。 

```
$ echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
$ echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
$ source ~/.bashrc
```

> `Sqlcmd` 是用于连接到 SQL Server 以运行查询并执行管理和开发的一个命令行工具。如果要使用功能更强大的图形工具，可使用 SQL Server Management Studio 或 Visual Studio Code 的 mssql 插件。

- 使用 Sqlcmd 建立本地连接

`Sqlcmd` 连接到本地的 SQL Server 实例。密码是在安装过程中配置的 SA 帐户密码。

```
$ sqlcmd -S localhost -U SA -P '<YourPassword>'
```

参数说明

> -S 连接 SQL Server 的机器名 
>
> -U 连接 SQL Server 的用户名
>
> -P 连接 SQL Server 的密码

连接成功，应会显示 Sqlcmd 命令提示符：`1>`，就类似下面这样

```
$ sqlcmd -S localhost -U SA
Password:
1>
```

### 创建数据库和查询数据

#### 新建数据库

- 创建一个名为 TestDB 的新数据库

在 `sqlcmd` 命令提示符中，执行 Transact-SQL 命令以创建测试数据库。

```
1> CREATE DATABASE TestDB
```

在 SQL Server 中 命令并没有立即执行， 必须在新行中键入 `GO` 才能执行命令。

```
2> GO
```

- 返回服务器上所有数据库的名称

```
1> SELECT Name from sys.Databases
2> GO
Name
----------------------------------------
master
tempdb
model
msdb
TestDB

(5 rows affected)
```

#### 插入数据

- 创建一个新表 Inventory，然后插入两个新行。

在 `sqlcmd` 命令提示符中，切换到新的 TestDB 数据库。

```
1> USE TestDB
```
创建名为 Inventory 的新表

```
2> CREATE TABLE Inventory (id INT, name NVARCHAR(50), quantity INT)
```

将数据插入新表

```
3> INSERT INTO Inventory VALUES (1, 'banana', 150); INSERT INTO Inventory VALUES (2, 'orange', 154);
```

批量执行上述命令

```
4> GO
```

整个执行过程如下

```
1> USE TestDB
2> CREATE TABLE Inventory (id INT, name NVARCHAR(50), quantity INT)
3> INSERT INTO Inventory VALUES (1, 'banana', 150); INSERT INTO Inventory VALUES (2, 'orange', 154);
4> GO
Changed database context to 'TestDB'.

(1 rows affected)

(1 rows affected)
```

- 查询数据

通过 `sqlcmd` 命令查询 Inventory 表中数量大于 152 的行

```
1> SELECT * FROM Inventory WHERE quantity > 152;
2> GO
id          name         quantity
------ ------------ -----------
     2 orange       154

(1 rows affected)
```

- 退出 sqlcmd 

要结束 sqlcmd 会话，请键入 QUIT。

```
1> QUIT
```

### 卸载 SQL Server 2017

若要删除 SQL Server 2017，可使用以下命令

```
$ apt-get remove mssql-server
```

删除包不会删除生成的数据库文件。 如果你想要删除的数据库文件，可使用以下命令

```
$ sudo rm -rf /var/opt/mssql/
```

最后在推荐下微软良心出品 `Visual Studio Code` 这个编辑器，功能异常强大、跨平台并且是开源的。最最最重要的是它比 Atom 快，插件也很丰富。我已从 Atom 转坑入 VSCode了。感谢蜗牛大神的推荐！ 

下图为 VSCode+MSSQL 插件的效果图，有没有很赞的~ 

![](https://www.hi-linux.com/img/linux/mssql2017-02.png)
![](https://www.hi-linux.com/img/linux/mssql2017-03.png)
![](https://www.hi-linux.com/img/linux/mssql2017-04.png)

### 参考文档

http://www.google.com
https://docs.microsoft.com/en-us/sql/linux/quickstart-install-connect-ubuntu