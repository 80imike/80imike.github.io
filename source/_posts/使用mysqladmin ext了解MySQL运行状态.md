---
title: 使用mysqladmin ext了解MySQL运行状态
tags:
  - Linux
  - MySQL
  - 技巧
categories: MySQL
abbrlink: 50039
date: 2016-03-15 09:51:54
---
mysqladmin是MySQL一个重要的客户端，最常见的是使用它来关闭数据库，除此，该命令还可以了解MySQL运行状态、进程信息、进程杀死等。本文介绍一下如何使用mysqladmin extended-status(因为没有"歧义"，所以可以使用ext代替)了解MySQL的运行状态。

#### 1.使用-r/-i参数
使用mysqladmin extended-status命令可以获得所有MySQL性能指标，即show global status的输出，不过，因为多数这些指标都是累计值，如果想了解当前的状态，则需要进行一次差值计算，这就是mysqladmin extended-status的一个额外功能，非常实用。默认的，使用extended-status，看到也是累计值，但是，加上参数-r(--relative)，就可以看到各个指标的差值，配合参数-i(--sleep)就可以指定刷新的频率，那么就有如下命令：
```mysql
mysqladmin -uroot -r -i 1 -pxxx extended-status
+------------------------------------------+----------------------+
| Variable_name                            | Value                |
+------------------------------------------+----------------------+
| Aborted_clients                          | 0                    |
| Com_select                               | 336                  |
| Com_insert                               | 243                  |
......
| Threads_created                          | 0                    |
+------------------------------------------+----------------------+
```
<!-- more -->
#### 2.配合grep使用

配合grep使用，我们就有：

```mysql
mysqladmin -uroot -r -i 1 -pxxx extended-status \
|grep "Questions\|Queries\|Innodb_rows\|Com_select \|Com_insert \|Com_update \|Com_delete "
| Com_delete                               | 1                    |
| Com_delete_multi                         | 0                    |
| Com_insert                               | 321                  |
| Com_select                               | 286                  |
| Com_update                               | 63                   |
| Innodb_rows_deleted                      | 1                    |
| Innodb_rows_inserted                     | 207                  |
| Innodb_rows_read                         | 5211                 |
| Innodb_rows_updated                      | 65                   |
| Queries                                  | 2721                 |
| Questions                                | 2721                 |
```
#### 3.配合简单的awk使用

使用awk，同时输出时间信息：

```mysql
mysqladmin -uroot -p -h127.0.0.1 -P3306 -r -i 1 ext |\
awk -F"|" '{\
  if($2 ~ /Variable_name/){\
    print " <-------------    "  strftime("%H:%M:%S") "    ------------->";\
  }\
  if($2 ~ /Questions|Queries|Innodb_rows|Com_select |Com_insert |Com_update |Com_delete |Innodb_buffer_pool_read_requests/)\
    print $2 $3;\
}'
<-------------    12:38:49    ------------->
 Com_delete                             0
 Com_insert                             0
 Com_select                             0
 Com_update                             0
 Innodb_buffer_pool_read_requests       589
 Innodb_rows_deleted                    0
 Innodb_rows_inserted                   2
 Innodb_rows_read                       50
 Innodb_rows_updated                    50
 Queries                                105
 Questions                              1
 <-------------    12:38:50    ------------->
 Com_delete                             0
 Com_insert                             0
 Com_select                             0
 Com_update                             0
 Innodb_buffer_pool_read_requests       1814
 Innodb_rows_deleted                    0
 Innodb_rows_inserted                   0
 Innodb_rows_read                       8
 Innodb_rows_updated                    8
 Queries                                17
 Questions                              1
```

#### 4.配合复杂一点的awk

反正也不简单了，那就更复杂一点，这样让输出结果更友好点，因为awk不支持动态变量，所以代码看起来比较复杂：

```
mysqladmin -P3306 -uroot -p -h127.0.0.1 -r -i 1 ext |\
awk -F"|" \
"BEGIN{ count=0; }"\
'{ if($2 ~ /Variable_name/ && ++count == 1){\
    print "----------|---------|--- MySQL Command Status --|----- Innodb row operation ----|-- Buffer Pool Read --";\
    print "---Time---|---QPS---|select insert update delete|  read inserted updated deleted|   logical    physical";\
}\
else if ($2 ~ /Queries/){queries=$3;}\
else if ($2 ~ /Com_select /){com_select=$3;}\
else if ($2 ~ /Com_insert /){com_insert=$3;}\
else if ($2 ~ /Com_update /){com_update=$3;}\
else if ($2 ~ /Com_delete /){com_delete=$3;}\
else if ($2 ~ /Innodb_rows_read/){innodb_rows_read=$3;}\
else if ($2 ~ /Innodb_rows_deleted/){innodb_rows_deleted=$3;}\
else if ($2 ~ /Innodb_rows_inserted/){innodb_rows_inserted=$3;}\
else if ($2 ~ /Innodb_rows_updated/){innodb_rows_updated=$3;}\
else if ($2 ~ /Innodb_buffer_pool_read_requests/){innodb_lor=$3;}\
else if ($2 ~ /Innodb_buffer_pool_reads/){innodb_phr=$3;}\
else if ($2 ~ /Uptime / && count >= 2){\
  printf(" %s |%9d",strftime("%H:%M:%S"),queries);\
  printf("|%6d %6d %6d %6d",com_select,com_insert,com_update,com_delete);\
  printf("|%6d %8d %7d %7d",innodb_rows_read,innodb_rows_inserted,innodb_rows_updated,innodb_rows_deleted);\
  printf("|%10d %11d\n",innodb_lor,innodb_phr);\
}}'
```
```myql
----------|---------|--- MySQL Command Status --|----- Innodb row operation ----|-- Buffer Pool Read --
---Time---|---QPS---|select insert update delete|  read inserted updated deleted|   logical    physical
 10:37:13 |     2231|   274    214     70      0|  4811      160      71       0|      4146           0
 10:37:14 |     2972|   403    256     84     23|  2509      173      85      23|      4545           0
 10:37:15 |     2334|   282    232     66      1|  1266      154      67       1|      3543           0
 10:37:15 |     2241|   271    217     66      0|  1160      129      66       0|      2935           0
 10:37:17 |     2497|   299    224     97      0|  1141      149      95       0|      3831           0
 10:37:18 |     2871|   352    304     74     23|  8202      226      73      23|      6167           0
 10:37:19 |     2441|   284    233     82      0|  1099      121      78       0|      3292           0
 10:37:20 |     2342|   279    242     61      0|  1083      224      61       0|      3366           0
```

就这样了，这几个命令自己用的比较多，随手分享出来。