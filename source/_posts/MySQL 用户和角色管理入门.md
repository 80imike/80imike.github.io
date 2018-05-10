---
category: MySQL
title: MySQL 用户和角色管理入门
date: 2018-05-08 09:00:00
tags: [Linux, MySQL]
abbrlink:
updated:
toc_number: false
---

MySQL 8.0 正式版目前已发布，MySQL 8.0 增加了很多新的功能，具体可参考「[MySQL 8.0 正式版 8.0.11 发布！](https://mp.weixin.qq.com/s/LbYghdQwLmHtiYjmSO16Ow)」一文。

MySQL 8.0 在用户管理方面增加了角色管理，默认的密码加密方式也做了调整，由之前的 `SHA1` 改为了 `SHA2`。同时加上 MySQL 5.7 的禁用用户和用户过期的功能，MySQL 在用户管理方面的功能和安全性都较之前版本大大的增强了。

在本教程中，我们将介绍 MySQL 下用户管理上的一些新特性和如何使用角色来简化权限管理。

> 注：本教程大部分特性要 MySQL 8.0 + 以上版本才支持。

<!-- more -->

### MySQL 用户管理

#### 验证插件和密码加密方式的变化

在 MySQL 8.0 中，`caching_sha2_password` 是默认的身份验证插件而不是之前版本的 `mysql_native_password`，默认的密码加密方式是 `SHA2` 。

```
mysql> show variables like 'default_authentication_plugin';
+-------------------------------+-----------------------+
| Variable_name                 | Value                 |
+-------------------------------+-----------------------+
| default_authentication_plugin | caching_sha2_password |
+-------------------------------+-----------------------+
1 row in set (0.00 sec)

mysql> select user,host,plugin from mysql.user;
+------------------+-----------+-----------------------+
| user             | host      | plugin                |
+------------------+-----------+-----------------------+
| root             | %         | caching_sha2_password |
| mysql.infoschema | localhost | mysql_native_password |
| mysql.session    | localhost | mysql_native_password |
| mysql.sys        | localhost | mysql_native_password |
| root             | localhost | caching_sha2_password |
+------------------+-----------+-----------------------+
5 rows in set (0.00 sec)
```

如果需要保持之前的验证方式并保持之前版本的密码加密方式需要在配置文件 my.cnf 中修改以下配置项并重启服务后生效。

```
[mysqld]
default_authentication_plugin = mysql_native_password
```

> 注：此选项暂不支持 MySQL 8.0 动态修改特性。

将 MySQL 8.0 中已有的 `SHA2` 密码修改为 `SHA1` 的模式。

```
# 更新用户的密码加密方式为之前版本的方式
mysql> ALTER USER 'root'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY 'password';
# 刷新权限
mysql> FLUSH PRIVILEGES;
```

> 注：如果没有特殊的原因，建议使用更安全的新加密方式。

#### 用户授权和修改密码

MySQL 8.0 的用户授权语句和之前版本有所区别，老版本的常用授权语句在 MySQL 8.0 版本中 已不能使用，如使用旧版本授权语句会报错。

- 在 MySQL 8.0 用之前版本授权语句创建用户。

```
mysql> GRANT ALL PRIVILEGES ON *.* TO `mike`@`%` IDENTIFIED BY '000000' WITH GRANT OPTION;
ERROR 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MySQL server version for the right syntax to use near 'IDENTIFIED BY '000000' WITH GRANT OPTION' at line 1
```

- 在 MySQL 8.0 版本中正确授权语句。

```
mysql> CREATE USER 'mike'@'%' IDENTIFIED BY '000000';
mysql> GRANT ALL ON *.* TO 'mike'@'%' WITH GRANT OPTION;
```

#### 密码过期时间管理

MySQL 从 5.6.6 开始引入密码自动过期的新功能，并在 MySQL 5.7.4 版本中改进了用户密码过期时间这个特性。现在可以通过一个全局变量 `default_password_lifetime` 来设置一个全局的自动密码过期策略。

`default_password_lifetime` 其默认值为 0，表示禁用自动密码过期。`default_password_lifetime` 的值如是是正整数 N ，则表示允许的设置密码生存周期 为 N，单位为天 。

- `default_password_lifetime` 全局密码到期策略默认为永久，不过期。

```
mysql> show variables like 'default_password_lifetime';
+---------------------------+-------+
| Variable_name             | Value |
+---------------------------+-------+
| default_password_lifetime | 0     |
+---------------------------+-------+
1 row in set (0.00 sec)
```

- 如果你要建立一个全局策略，让所有用户的密码的使用期限为六个月，可在服务端配置文件 my.cnf 中修改 `default_password_lifetime` 配置项的值为 180。

```
[mysqld]
default_password_lifetime=180
```

- 如果你要恢复全局策略，让所有用户的密码永不过期，可在服务端配置文件 my.cnf 中修改 `default_password_lifetime` 配置项的值为 0。

```
[mysqld]
default_password_lifetime=0
```

- `default_password_lifetime` 参数是支持永久动态设置的，你也可以用以下命令在 MySQL 命令行下直接设置生效。

```
# 设置默认密码过期策略为 180 天后过期
mysql> SET PERSIST default_password_lifetime = 180;

# 设置默认密码过期策略为永不过期
mysql> SET PERSIST default_password_lifetime = 0;

# MySQL 8.0 永久动态修改参数会保存在配置文件 mysqld-auto.cnf 中，保存的格式为JSON串。
$ cat  /var/lib/mysql/mysqld-auto.cnf
{ "Version" : 1 , "mysql_server" : { "default_password_lifetime" : { "Value" : "180" , "Metadata" : { "Timestamp" : 1525663928688419 , "User" : "root" , "Host" : "" } } } }
```

- 创建和修改带有密码过期时间的用户示例

创建或修改一个用户的密码过期时间为 90 天。

```
mysql> CREATE USER 'mike'@'%' IDENTIFIED BY '000000' PASSWORD EXPIRE INTERVAL 90 DAY;
mysql> ALTER USER `mike`@`%` PASSWORD EXPIRE INTERVAL 90 DAY;
```

创建或修改一个用户的密码过期时间为永不过期。

```
mysql> CREATE USER 'mike'@'%' PASSWORD EXPIRE NEVER;
mysql> ALTER USER 'mike'@'%' PASSWORD EXPIRE NEVER;
```

创建或修改一个遵循全局到期策略的用户。

```
mysql> CREATE USER 'mike'@'%' PASSWORD EXPIRE DEFAULT;
mysql> ALTER USER 'mike'@'%' PASSWORD EXPIRE DEFAULT;
```

查看用户的密码过期时间。

```
mysql> select user,host,password_last_changed,password_lifetime,password_expired from mysql.user;
+------------------+-----------+-----------------------+-------------------+------------------+
| user             | host      | password_last_changed | password_lifetime | password_expired |
+------------------+-----------+-----------------------+-------------------+------------------+
| mike             | %         | 2018-05-07 11:13:39   |                90 | N                |
| root             | %         | 2018-05-04 16:46:05   |              NULL | N                |
| mysql.infoschema | localhost | 2018-05-04 16:45:55   |              NULL | N                |
| mysql.session    | localhost | 2018-05-04 16:45:55   |              NULL | N                |
| mysql.sys        | localhost | 2018-05-04 16:45:55   |              NULL | N                |
| root             | localhost | 2018-05-04 16:46:05   |              NULL | N                |
+------------------+-----------+-----------------------+-------------------+------------------+
6 rows in set (0.00 sec)
```

#### 锁定/解锁用户帐户

从 MySQL 5.7.8 开始，用户管理方面添加了锁定/解锁用户帐户的新特性。下面我们就来看下这个特性的一些具体示例。

- 创建一个带帐户锁的用户

```
mysql> CREATE USER 'mike-temp1'@'%' IDENTIFIED BY '000000' ACCOUNT LOCK;
```

接下来尝试用新创建的用户登陆，此时会得到一个 ERROR 3118 错误消息提示。

```
$ mysql -umike-temp1 -p000000
mysql: [Warning] Using a password on the command line interface can be insecure.
ERROR 3118 (HY000): Access denied for user 'mike-temp1'@'172.22.0.1'. Account is locked.
```

如果你需要解锁此用户，此时就需要使用以下语句对其进行解锁了。

```
mysql> ALTER USER 'mike-temp1'@'%' ACCOUNT UNLOCK;
Query OK, 0 rows affected (0.00 sec)
```

现在，这个用户就已经解锁，再次尝试登陆。

```
$ mysql -umike-temp1 -p000000
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 10
Server version: 8.0.11 MySQL Community Server - GPL

Copyright (c) 2000, 2018, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql>
```

- 修改一个用户为锁定状态

如果用户已建立，你也可以这样锁定用户帐户。

```
mysql> ALTER USER 'mike'@'%' ACCOUNT LOCK;
Query OK, 0 rows affected (0.00 sec)
```

#### 设置 MySQL 用户密码重用策略

从 MySQL 8.0 开始允许限制重复使用以前的密码。可以根据密码更改次数、已用时间或两者来建立密码重用限制。帐户的密码历史由过去分配的密码组成，MySQL 可以限制从此历史记录中选择新密码。

- 如果根据密码更改次数限制帐户，则无法从指定数量的最新密码中选择新密码。例如：如果密码更改的最小数量设置为 3，则新密码不能与任何最近的3个密码相同。
- 如果根据密码修改时间来限制帐户，则无法将指定时间历史记录中的密码中选择为新密码。例如：如果密码重用间隔设置为 60，则新密码不得在最近 60 天内选择的密码相同。

> 注：空密码不记录在密码历史记录中，并随时可以重复使用。

要建立全局密码重用策略，可修改 `password_history` 和 `password_reuse_interval` 系统变量。该变量可在服务配置文件 my.cnf 中配置，以禁止重复使用最近 6 个密码或最近 180 天内使用过的任何密码为例。

```
[mysqld]
password_history=6
password_reuse_interval=180
```

该参数是支持永久动态设置，也可以直接用下面语句进行设置。

```
mysql> SET PERSIST password_history = 6;
mysql> SET PERSIST password_reuse_interval = 180;
```

### MySQL 角色管理

MySQL 数据库中通常都会出现多个拥有相同权限集合的用户，在之前版本中只有分别向多个用户授予和撤销权限才能实现单独更改每个用户的权限。在用户数量比较多的时候，这样的操作是非常耗时的。

MySQL 8.0 为了用户权限管理更容易，提供了一个角色管理的新功能。角色是指定的权限集合，和用户帐户一样可以对角色进行权限的授予和撤消。如果用户被授予角色权限，则该用户拥有该角色的权限。

MySQL 8.0 提供的角色管理功能如下：

```
CREATE ROLE 角色创建
DROP ROLE 角色删除
GRANT 为用户和角色分配权限
REVOKE 为用户和角色撤销权限
SHOW GRANTS 显示用户和角色的权限
SET DEFAULT ROLE 指定哪些帐户角色默认处于活动状态
SET ROLE 更改当前会话中的活动角色
CURRENT_ROLE() 显示当前会话中的活动角色
```

#### 创建角色并授予用户角色权限

这里我们以几种常见场景为例。

- 应用程序需要读/写权限。
- 运维人员需要完全访问数据库。
- 部分开发人员需要读取权限。
- 部分开发人员需要读写权限。

如果要向多个用户授予相同的权限集，则应按如下步骤来进行。

- 创建新的角色
- 授予角色权限
- 授予用户角色

首先，我们创建四个角色。为了清楚区分角色的权限，建议将角色名称命名得比较直观。

```
mysql> CREATE ROLE 'app', 'ops', 'dev_read', 'dev_write';
```

> 注：角色名称格式类似于由用户和主机部分组成的用户帐户，如：role_name@host_name。如果省略主机部分，则默认为 "%"，表示任何主机。

创建好角色后，我们就给角色授予对应的权限。要授予角色权限，您可以使用 `GRANT` 语句。 

```
# 以下语句是向 app 角色授予 wordpress 数据库的读写权限
mysql> GRANT SELECT, INSERT, UPDATE, DELETE ON wordpress.* TO 'app';
# 以下语句是向 ops 角色授予 wordpress 数据库的所有权限
mysql> GRANT ALL PRIVILEGES ON wordpress.* TO 'ops';
# 以下语句是向 dev_read 角色授予 wordpress 数据库的只读权限
mysql> GRANT SELECT ON wordpress.* TO 'dev_read';
# 以下语句是向 dev_write 角色授予 wordpress 数据库的写权限
mysql> GRANT INSERT, UPDATE, DELETE ON wordpress.* TO 'dev_write';
```

> 注：这里假定需授权的数据库名称为 wordpress。

最后根据实际情况，我们将指定用户加入到对应的角色。假设需要一个应用程序使用的帐户、一个运维人员帐户、一个是开发人员只读帐户和两个开发人员读写帐户。

- 创建新用户

```
# 应用程序帐户
mysql> CREATE USER 'app01'@'%' IDENTIFIED BY '000000';
# 运维人员帐户
mysql> CREATE USER 'ops01'@'%' IDENTIFIED BY '000000';
# 开发人员只读帐户
mysql> CREATE USER 'dev01'@'%' IDENTIFIED BY '000000';
# 开发读写帐户
mysql> CREATE USER 'dev02'@'%' IDENTIFIED BY '000000';
mysql> CREATE USER 'dev03'@'%' IDENTIFIED BY '000000';
```

- 给用户分配角色

```
mysql> GRANT app TO 'app01'@'%';
mysql> GRANT ops TO 'ops01'@'%';
mysql> GRANT dev_read TO 'dev01'@'%';
```

如果要将多个用户同时加入多个角色，可以使用类似语句。

```
mysql> GRANT dev_read, dev_write TO 'dev02'@'%', 'dev03'@'%';
```

#### 检查角色权限

要验证角色是否正确分配，可以使用 `SHOW GRANTS` 语句。

```
mysql> SHOW GRANTS FOR 'dev01'@'%';
+-------------------------------------+
| Grants for dev01@%                  |
+-------------------------------------+
| GRANT USAGE ON *.* TO `dev01`@`%`   |
| GRANT `dev_read`@`%` TO `dev01`@`%` |
+-------------------------------------+
2 rows in set (0.00 sec)
```

正如你所看到的，和之前版本不同的是 `SHOW GRANTS` 只返回授予角色。如果要显示角色所代表的权限，需要加上 `USING` 子句和授权角色的名称。

```
mysql> SHOW GRANTS FOR 'dev01'@'%' USING dev_read;
+----------------------------------------------+
| Grants for dev01@%                           |
+----------------------------------------------+
| GRANT USAGE ON *.* TO `dev01`@`%`            |
| GRANT SELECT ON `wordpress`.* TO `dev01`@`%` |
| GRANT `dev_read`@`%` TO `dev01`@`%`          |
+----------------------------------------------+
3 rows in set (0.00 sec)
```

#### 设置默认角色

现在，如果您使用 dev01 用户帐户连接到 MySQL，并尝试访问 wordpress 数据库会出现以下错误。

```
$ mysql -u dev01 -p000000
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 11
Server version: 8.0.11 MySQL Community Server - GPL

Copyright (c) 2000, 2018, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> use wordpress;
ERROR 1044 (42000): Access denied for user 'dev01'@'%' to database 'wordpress'
```

这是因为在向用户帐户授予角色后，当用户帐户连接到数据库服务器时，它并不会自动使角色变为活动状态。

```
# 调用 CURRENT_ROLE() 函数查看当前角色。
mysql> SELECT current_role();
+----------------+
| current_role() |
+----------------+
| NONE           |
+----------------+
1 row in set (0.00 sec)
```

这里返回 NONE，就意味着当前没有启用任何角色。要在每次用户帐户连接到数据库服务器时指定哪些角色应该处于活动状态，需用使用 `SET DEFAULT ROLE` 语句来指定。

```
# 以下语句将把 dev01 帐户分配的所有角色都设置为默认值。
mysql> SET DEFAULT ROLE ALL TO 'dev01'@'%';
```

再次使用 dev01 用户帐户连接到 MySQL 数据库服务器并调用 `CURRENT_ROLE()` 函数，您将看到 dev01 用户帐户的默认角色。

```
$ mysql -u dev01 -p000000
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 11
Server version: 8.0.11 MySQL Community Server - GPL

Copyright (c) 2000, 2018, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> 

# 查看 dev01 用户帐户的默认角色。
mysql> SELECT current_role();
+----------------+
| current_role() |
+----------------+
| `dev_read`@`%` |
+----------------+
1 row in set (0.00 sec)

```

最后通过将当前数据库切换到 wordpress 数据库，并执行 `SELECT` 语句和 `DELETE` 语句来测试 dev01 帐户的权限。

```
mysql> use wordpress;
Database changed

mysql> select  count(*) from wp_terms;
+----------+
| count(*) |
+----------+
|      357 |
+----------+
1 row in set (0.00 sec)

mysql> DELETE from wp_terms;
ERROR 1142 (42000): DELETE command denied to user 'dev01'@'172.22.0.1' for table 'wp_terms'
```

如上面结果所示，当我们发出 `DELETE` 语句时，就收到一个错误。因为 dev01 用户帐户只有读取访问权限。

#### 设置活动角色

用户帐户可以通过指定哪个授权角色处于活动状态来修改当前用户在当前会话中的有效权限。

- 将活动角色设置为 NONE，表示没有活动角色。

```
mysql> SET ROLE NONE;
```

- 将活动角色设置为所有授予的角色。

```
mysql> SET ROLE ALL;
```

- 将活动角色设置为由 `SET DEFAULT ROLE` 语句设置的默认角色。

```
mysql> SET ROLE DEFAULT;
```

- 同时设置多个活动的角色。

```
mysql> SET ROLE granted_role_1, granted_role_2, ...
```

#### 撤消角色或角色权限

正如可以授权某个用户的角色一样，也可以从用户帐户中撤销这些角色。要从用户帐户中撤销角色需要使用 `REVOKE` 语句。

```
mysql> REVOKE role FROM user;
```

`REVOKE` 也可以用于修改角色权限。这不仅影响角色本身权限，还影响任何授予该角色的用户权限。假设想临时让所有开发用户只读，可以使用 `REVOKE` 从 dev_write 角色中撤消修改权限。我们先来看下用户帐户 dev02 撤消前的权限。

```
mysql> SHOW GRANTS FOR 'dev02'@'%' USING 'dev_read', 'dev_write';
+----------------------------------------------------------------------+
| Grants for dev02@%                                                   |
+----------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `dev02`@`%`                                    |
| GRANT SELECT, INSERT, UPDATE, DELETE ON `wordpress`.* TO `dev02`@`%` |
| GRANT `dev_read`@`%`,`dev_write`@`%` TO `dev02`@`%`                  |
+----------------------------------------------------------------------+
3 rows in set (0.00 sec)
```

接下来从 dev_write 角色中撤消掉修改权限。

```
mysql> REVOKE INSERT, UPDATE, DELETE ON wordpress.* FROM 'dev_write';
Query OK, 0 rows affected (0.03 sec)
```

最后我们在来看看 dev02 用户帐户当前权限。

```
mysql> SHOW GRANTS FOR 'dev02'@'%' USING 'dev_read', 'dev_write';
+-----------------------------------------------------+
| Grants for dev02@%                                  |
+-----------------------------------------------------+
| GRANT USAGE ON *.* TO `dev02`@`%`                   |
| GRANT SELECT ON `wordpress`.* TO `dev02`@`%`        |
| GRANT `dev_read`@`%`,`dev_write`@`%` TO `dev02`@`%` |
+-----------------------------------------------------+
3 rows in set (0.00 sec)
```

从上面的结果可以看出，角色中撤销权限会影响到该角色中任何用户的权限。因此 dev02 现在已经没有表修改权限（INSERT，UPDATE，和 DELETE 权限已经去掉）。如果要恢复角色的修改权限，只需重新授予它们即可。

```
# 授予 dev_write 角色修改权限。
mysql> GRANT INSERT, UPDATE, DELETE ON wordpress.* TO 'dev_write';

# 再次查看 dev02 用户权限，修改权限已经恢复。
mysql> SHOW GRANTS FOR 'dev02'@'%' USING 'dev_read', 'dev_write';
+----------------------------------------------------------------------+
| Grants for dev02@%                                                   |
+----------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `dev02`@`%`                                    |
| GRANT SELECT, INSERT, UPDATE, DELETE ON `wordpress`.* TO `dev02`@`%` |
| GRANT `dev_read`@`%`,`dev_write`@`%` TO `dev02`@`%`                  |
+----------------------------------------------------------------------+
3 rows in set (0.00 sec)
```

#### 删除角色

要删除一个或多个角色，可以使用 `DROP ROLE` 语句。

```
mysql> DROP ROLE 'role_name', 'role_name', ...;
```

如同 `REVOKE` 语句一样，删除角色会从授权它的每个帐户中撤消该角色。例如，要删除 dev_read，dev_write角色，可使用以下语句。

```
mysql> DROP ROLE 'dev_read', 'dev_write';
```

#### 复制用户帐户权限到另一个用户

MySQL 8.0 将每一个用户帐户视为角色，因此可以将用户帐户授予另一个用户帐户。例如：将一开发人员帐号权限复制到另一开发人员帐号。

- 创建一个新的开发用户帐户

```
mysql> CREATE USER 'dev04'@'%' IDENTIFIED BY '000000';
Query OK, 0 rows affected (0.04 sec)
```

- 将 dev02 用户帐户的权限复制到 dev04 用户帐户

```
mysql> GRANT 'dev02'@'%' TO 'dev04'@'%';
Query OK, 0 rows affected (0.09 sec)
```

- 查看 dev04 用户帐户的权限

```
mysql> SHOW GRANTS FOR 'dev04'@'%' USING 'dev02';
+----------------------------------------------------------------------+
| Grants for dev04@%                                                   |
+----------------------------------------------------------------------+
| GRANT USAGE ON *.* TO `dev04`@`%`                                    |
| GRANT SELECT, INSERT, UPDATE, DELETE ON `wordpress`.* TO `dev04`@`%` |
| GRANT `dev02`@`%` TO `dev04`@`%`                                     |
+----------------------------------------------------------------------+
3 rows in set (0.00 sec)
```

### 参考文档

http://www.google.com
http://t.cn/RuTna0t
http://t.cn/RuTnEPH
http://t.cn/RuTnFGz
http://t.cn/RuTnFGz