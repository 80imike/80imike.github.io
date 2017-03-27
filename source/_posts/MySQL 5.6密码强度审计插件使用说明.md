---
title: MySQL 5.6密码强度审计插件使用说明
tags:
  - MySQL
  - Linux
categories: MySQL
abbrlink: 49609
date: 2016-06-30 09:00:00
updated:
toc_number:
---

相信很多人在日常工作中，都会遇到设置用户、密码之类的问题。很多人使用Keepass来生成和保存密码；但是很多人为了易于记忆，会选择相对简答的密码，这样在安全性方面，会存在非常严重的安全隐患。

在MySQL 5.6对密码的强度进行了加强，推出了`Password Validation Plugin`插件。可支持用户设置密码时强制使用强密码的要求。

所需MySQL版本：MySQL 5.6.6以上版本

<!-- more -->

### 安装方式

#### 配置插件

##### 插件启用

插件对应的库对象文件需在配置选项`plugin_dir`指定的目录中。可使用`--plugin-load=validate_password.so`，在Server启动时载入插件，或者将`plugin-load=validate_password.so`写入配置文件。也可以通过如下语句在Server运行时载入插件(会注册进mysql.plugins表)

- 运行时载入插件

```
mysql> INSTALL PLUGIN validate_password SONAME 'validate_password.so';
```

- 在配置文件中添加

```
[mysqld]

plugin-load=validate_password.so
validate_password_policy=2
validate-password=FORCE_PLUS_PERMANENT
```

##### 插件关闭

关闭插件很简单，在MySQL配置文件(Centos系统下是`/etc/my.conf`)里面`[mysqld]`选项下面添加下面一条语句即可。

```
[mysqld]

validate_password=off
```

记得配置后要重启MySQL,在Shell下面运行下面两条语句

```
$ service mysqld stop
$ service mysqld start
```

##### 验证插件

通过命令`SHOW PLUGINS`进行观察，应该观察到插件已启用。

![](https://www.hi-linux.com/img/linux/pvp.png)

#### 测试插件

- 设置简单的密码，则MySQL数据库会报类似如下的错误

```
mysql> SET PASSWORD = PASSWORD('abc');
ERROR 1819 (HY000): Your password does not satisfy the current policy requirements
```

- 设置复杂密码，则可以成功修改。

```
mysql> SET PASSWORD = '*0D3CED9BEC10A777AEC23CCC353A8C08A633045E';
Query OK, 0 rows affected (0.01 sec)
```

### 插件相关说明

- 相关选项

```
validate-password=ON/OFF/FORCE/FORCE_PLUS_PERMANENT: 决定是否使用该插件(及强制/永久强制使用)。
validate_password_dictionary_file：插件用于验证密码强度的字典文件路径。
validate_password_length：密码最小长度。
validate_password_mixed_case_count：密码至少要包含的小写字母个数和大写字母个数。
validate_password_number_count：密码至少要包含的数字个数。
validate_password_policy：密码强度检查等级，0/LOW、1/MEDIUM、2/STRONG。
validate_password_special_char_count：密码至少要包含的特殊字符数。
```

- 关于`validate_password_policy`密码强度检查等级

```
0/LOW：只检查长度。
1/MEDIUM：检查长度、数字、大小写、特殊字符。
2/STRONG：检查长度、数字、大小写、特殊字符字典文件。
```

### 参考文档

http://www.google.com
http://blog.csdn.net/zyz511919766/article/details/12752741
http://www.xuchanggang.cn/archives/1033.html
http://www.07net01.com/storage_networking/2016/01/1212625.html