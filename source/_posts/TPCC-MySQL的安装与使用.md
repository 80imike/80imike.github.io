---
title: TPCC-MySQL的安装与使用
tags:
  - MySQL
  - Linux
categories: MySQL
abbrlink: 38534
date: 2016-04-11 09:00:00
updated:
toc_number:
---

### 什么是TPC-C

TPC-C是专门针对联机交易处理系统（OLTP系统）的规范，一般情况下我们也把这类系统称为业务处理系统。

TPC-C是TPC(Transaction Processing Performance Council)组织发布的一个测试规范，用于模拟测试复杂的在线事务处理系统。其测试结果包括每分钟事务数(tpmC)，以及每事务的成本(Price/tpmC)。在进行大压力下MySQL的一些行为时经常使用。

### 什么是TPCC-MYSQL

TPCC-MYSQL是percona基于TPC-C(下面简写成TPCC)衍生出来的产品，专用于MySQL基准测试。用来测试数据库的压力工具，模拟一个电商的业务，主要的业务有新增订单，库存查询，发货，支付等模块的测试。
<!-- more -->

### percona官方版本

#### 安装依赖包

MySQL 5.1

```bash
yum install mysql-devel
```

MySQL 5.6

```bash
yum install mysql-community-devel
```

#### 编译安装

```bash
git clone https://github.com/Percona-Lab/tpcc-mysql
cd tpcc-mysql/src
make
```

如果make没报错，就会在tpcc-mysql文件夹下生成tpcc二进制命令行工具tpcc_load、tpcc_start

#### 使用

tpcc-mysql的业务逻辑及其相关的几个表作用如下

> New-Order：新订单，一次完整的订单事务，几乎涉及到全部表
> Payment：支付，主要对应orders、history表
> Order-Status：订单状态，主要对应 orders、order_line表
> Delivery：发货，主要对应order_line表
> Stock-Level：库存，主要对应stock表

其它表说明

> 客户：主要对应customer表
> 地区：主要对应district表
> 商品：主要对应item表
> 仓库：主要对应warehouse表

#### TPCC测试前准备

查看README文件的内容(简单实用的说明)

> 1.Build binaries
> 
> cd scr ; make ( you should have mysql_config available in $PATH)
> 
> 2.Load data
> 
> create database mysqladmin create tpcc1000
> create tables mysql tpcc1000 < create_table.sql
> create indexes and FK ( this step can be done after loading data) mysql tpcc1000 < add_fkey_idx.sql
> 
> populate data
> 
> simple step tpcc_load -h127.0.0.1 -d tpcc1000 -u root -p "" -w 1000 |hostname:port| |dbname| |user| |password| |WAREHOUSES| ref. tpcc_load --help for all options
> load data in parallel check load.sh script
> 
> 3.start benchmark
> ./tpcc_start -h127.0.0.1 -P3306 -dtpcc1000 -uroot -w1000 -c32 -r10 -l10800
> |hostname| |port| |dbname| |user| |WAREHOUSES| |CONNECTIONS| |WARMUP TIME| |BENCHMARK TIME|
> ref. tpcc_start --help for all options

初始化测试库环境，先创建一个测试库然后导入create_table.sql,顾名思义是创表的sql语句

创建tpcc数据库

```bash
$mysql -uroot -p -e "CREATE DATABASE TPCC DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
```

初始化表结构

```bash
$mysql -uroot -p TPCC <./create_table.sql
```

创建相关索引和主外键
```bash
$mysql -uroot -p TPCC <./add_fkey_idx.sql
```

显示创建的表
```bash
$mysql -uroot -p -e "show tables from  TPCC"
+--------------------+
| Tables_in_tpcctest |
+--------------------+
| customer           |
| district           |
| history            |
| item               |
| new_orders         |
| order_line         |
| orders             |
| stock              |
| warehouse          |
+--------------------+
```

初始化完毕后，就可以开始加载测试数据了

tpcc_load用法如下

```bash
Usage: tpcc_load -h server_host -P port -d database_name -u mysql_user -p mysql_password -w warehouses -l part -m min_wh -n max_wh
* [part]: 1=ITEMS 2=WAREHOUSE 3=CUSTOMER 4=ORDERS
```

> 选项[warehouse]意为指定测试库下的仓库数量
> 选项[part]为只创建数据到[part]对应的表中
> 选项[min_wh]、[max_wh]为min_wid max_wid

在这里，需要注意的是tpcc默认会读取`/var/lib/mysql/mysql.sock`这个socket 文件。因此，如果你的socket文件不在相应路径的话，可以做个软连接，或者通过TCP/IP的方式连接测试服务器

真实测试场景中，仓库数一般不建议少于100个，视服务器硬件配置而定，如果是配备了SSD或者PCIE SSD这种高IOPS设备的话，建议最少不低于1000个。仓库越多，造数据的时间越长，需要耐心等待

执行下面的命令，开始灌入测试数据：选择单进程或并发加载(本人的是虚拟机，仓库数就弄了10,省得压死了，哈哈)

##### 单进程加载

```bash
$./tpcc_load -h 127.0.0.1 -P 3306 -d TPCC -u root -p 000000 -w 10
```

##### 并发加载

需根据实际情况修改一下

方法一

```bash
$./load.sh TPCC 10
```
通过load.sh并发加载数据(创建10个warsehouse)

造数据成功后，会提示：...DATA LOADING COMPLETED SUCCESSFULLY.

方法二

GitHub上另一个并行加载脚本: https://gist.github.com/sh2/3458844

根据实际情况情况修改用户名、密码、数据库名，初始仓库为10个。

由于最新版本tpcc_load使用方法需要显示使用参数，修改脚本如下

vim tpcc_load_parallel.sh

```bash
#!/bin/bash

# Configration

MYSQL=/usr/bin/mysql
TPCCLOAD=./tpcc_load
TABLESQL=./create_table.sql
CONSTRAINTSQL=./add_fkey_idx.sql
DEGREE=`getconf _NPROCESSORS_ONLN`

SERVER=localhost
DATABASE=tpcc
USER=tpcc
PASS=tpcc
WAREHOUSE=10

# Load

set -e
$MYSQL -u $USER -p$PASS -e "DROP DATABASE IF EXISTS $DATABASE"
$MYSQL -u $USER -p$PASS -e "CREATE DATABASE $DATABASE"
$MYSQL -u $USER -p$PASS $DATABASE < $TABLESQL
$MYSQL -u $USER -p$PASS $DATABASE < $CONSTRAINTSQL

echo 'Loading item ...'
$TPCCLOAD  -h $SERVER -d $DATABASE -u $USER -p $PASS -w $WAREHOUSE 1 1 -n $WAREHOUSE > /dev/null

set +e
STATUS=0
trap 'STATUS=1; kill 0' INT TERM

for ((WID = 1; WID <= WAREHOUSE; WID++)); do
    echo "Loading warehouse id $WID ..."
    
    (
        set -e
        
        # warehouse, stock, district
        $TPCCLOAD -h $SERVER -d $DATABASE -u $USER -p $PASS -w $WAREHOUSE 2 -m $WID  -n $WID > /dev/null
        
        # customer, history
        $TPCCLOAD -h $SERVER -d $DATABASE -u $USER -p $PASS -w $WAREHOUSE 3 -m $WID  -n $WID > /dev/null
        
        # orders, new_orders, order_line
        $TPCCLOAD -h $SERVER -d $DATABASE -u $USER -p $PASS -w $WAREHOUSE 4 -m $WID  -n $WID > /dev/null
    ) &
    
    PIDLIST=(${PIDLIST[@]} $!)
    
    if [ $((WID % DEGREE)) -eq 0 ]; then
        for PID in ${PIDLIST[@]}; do
            wait $PID
            
            if [ $? -ne 0 ]; then
                STATUS=1
            fi
        done
        
        if [ $STATUS -ne 0 ]; then
            exit $STATUS
        fi
        
        PIDLIST=()
    fi
done

for PID in ${PIDLIST[@]}; do
    wait $PID
    
    if [ $? -ne 0 ]; then
        STATUS=1
    fi
done

if [ $STATUS -eq 0 ]; then
    echo 'Completed.'
fi

exit $STATUS
```

#### 进行TPCC测试及结果解读

tpcc_start工具用于tpcc压测，其用法如下：

```bash
$./tpcc_start --help
***************************************
*** ###easy### TPC-C Load Generator ***
***************************************
./tpcc_start: invalid option -- '-'
Usage: tpcc_start -h server_host -P port -d database_name -u mysql_user -p mysql_password -w warehouses -c connections -r warmup_time -l running_time -i report_interval -f report_file -t trx_file
```

> 选项说明
> 
> -w 指定仓库数量
> -c 指定并发连接数
> -r 指定开始测试前进行warmup的时间，进行预热后，测试效果更好(单位:秒)
> -l 指定测试持续时间(单位:秒)
> -i 指定生成报告间隔时长
> -f 指定生成的报告文件名

使用例子

```bash
$./tpcc_start -h127.0.0.1 -P3306 -d TPCC -u root -p 000000 -w 10 -c 10 -r 120 -l 120 >> mysql_tpcc_20160411
```

模拟对10个仓库(-w 10),并发10个线程(-c 10),预热120s(-r 120),持续压测120s(-l 120)

真实测试场景中，建议预热时间不小于5分钟，持续压测时长不小于30分钟，否则测试数据可能不具参考意义。

结果解读

```bash
***************************************
*** ###easy### TPC-C Load Generator ***
***************************************
option h with value '127.0.0.1'
option P with value '3306'
option d with value 'TPCC'
option u with value 'root'
option p with value '000000'
option w with value '10'
option c with value '10'
option r with value '120'
option l with value '120'
<Parameters>
     [server]: 127.0.0.1      -- 主机
     [port]: 3306             -- 端口
     [DBname]: TPCC       -- 压测的数据库
       [user]: root           -- 账号
       [pass]: 000000         -- 密码
  [warehouse]: 10             -- 仓库数
 [connection]: 10             -- 并发线程数 
     [rampup]: 120 (sec.)     -- 数据预热时长 
    [measure]: 120 (sec.)     -- 压测时长

RAMP-UP TIME.(120 sec.)       --预热结束

MEASURING START.              --开始压测

  10, 27(0):3.829|7.321, 26(0):1.854|4.399, 3(0):1.503|1.670, 3(0):4.467|5.559, 3(0):14.525|20.229 --每10秒输出一次压测数据
  20, 31(0):3.153|3.247, 29(0):0.861|1.202, 3(0):0.400|0.475, 3(0):4.471|4.980, 0(0):0.000|0.000
  30, 28(0):3.559|3.943, 27(0):0.807|0.838, 2(0):0.285|0.379, 2(0):3.273|3.628, 3(0):13.534|13.577
  40, 26(0):3.643|4.040, 32(0):0.676|0.686, 4(0):0.337|0.393, 4(0):4.397|5.081, 6(0):13.890|16.757
  50, 32(1):4.377|5.695, 30(0):0.749|0.813, 2(0):0.254|0.309, 3(0):3.418|4.066, 2(0):11.356|12.581
  60, 32(0):3.561|3.602, 33(0):1.024|1.645, 4(0):0.318|0.413, 3(0):3.446|3.542, 5(0):11.772|12.417
  70, 41(0):3.228|3.415, 39(0):0.956|1.296, 4(0):0.394|0.396, 5(0):3.671|3.925, 1(0):0.000|13.920
  80, 35(1):4.096|6.454, 35(0):0.727|0.877, 3(0):0.344|0.410, 3(0):3.100|3.961, 4(0):11.251|11.489
  90, 27(0):2.787|3.505, 25(0):0.945|1.093, 2(0):0.394|0.423, 2(0):2.804|5.293, 3(0):11.637|12.463
 100, 31(2):5.050|5.467, 31(0):0.835|0.884, 4(0):0.334|0.363, 4(0):3.094|3.738, 2(0):11.853|11.885
 110, 32(0):3.101|3.968, 33(0):0.606|1.503, 3(0):0.255|0.347, 3(0):3.007|3.427, 5(0):11.685|12.653
 120, 34(0):3.359|3.713, 33(0):0.730|0.844, 3(0):0.319|0.504, 3(0):3.092|3.502, 2(0):8.187|10.347

-- 以逗号分隔，共6列
-- 第一列，第N次10秒
-- 第二列，新订单成功执行压测的次数(推迟执行压测的次数):90%事务的响应时间|本轮测试最大响应时间，新订单事务数也被认为是总有效事务数的指标
-- 第三列，支付业务成功执行次数(推迟执行次数):90%事务的响应时间|本轮测试最大响应时间
-- 第四列，订单状态业务的结果，后面几个的意义同上
-- 第五列，物流发货业务的结果，后面几个的意义同上
-- 第六列，库存仓储业务的结果，后面几个的意义同上

STOPPING THREADS..........          -- 结束压测
 
<Raw Results>                       -- 第一次统计结果
  [0] sc:372  lt:4  rt:0  fl:0      -- New-Order，新订单业务成功(success,简写sc)次数，延迟(late,简写lt)次数，重试(retry,简写rt)次数，失败(failure,简写fl)次数
  [1] sc:373  lt:0  rt:0  fl:0      -- Payment，支付业务统计，其他同上
  [2] sc:37  lt:0  rt:0  fl:0       -- Order-Status，订单状态业务统计，其他同上
  [3] sc:38  lt:0  rt:0  fl:0       -- Delivery，发货业务统计，其他同上
  [4] sc:36  lt:0  rt:0  fl:0       -- Stock-Level，库存业务统计，其他同上
 in 120 sec.

<Raw Results2(sum ver.)>            -- 第二次统计结果，其他同上
  [0] sc:372  lt:4  rt:0  fl:0 
  [1] sc:373  lt:0  rt:0  fl:0 
  [2] sc:37  lt:0  rt:0  fl:0 
  [3] sc:38  lt:0  rt:0  fl:0 
  [4] sc:36  lt:0  rt:0  fl:0 

<Constraint Check> (all must be [OK])     -- 下面所有业务逻辑结果都必须为OK才行
 [transaction percentage]

        Payment: 43.37% (>=43.0%) [OK]    -- 支付成功次数(上述统计结果中 sc + lt)必须大于43.0%，否则结果为NG，而不是OK
   Order-Status: 4.30% (>= 4.0%) [OK]     --订单状态，其他同上
       Delivery: 4.42% (>= 4.0%) [OK]     -- 发货，其他同上
    Stock-Level: 4.19% (>= 4.0%) [OK]     -- 库存，其他同上
 [response time (at least 90% passed)]    -- 响应耗时指标必须超过90%通过才行
      New-Order: 98.94%  [OK]             -- 下面几个响应耗时指标全部 100% 通过
        Payment: 100.00%  [OK]
   Order-Status: 100.00%  [OK]
       Delivery: 100.00%  [OK]
    Stock-Level: 100.00%  [OK]

<TpmC>
                 188.000 TpmC  -- TpmC结果值(每分钟事务数，该值是第一次统计结果中的新订单事务数除以总耗时分钟数，例如本例中是：372/2=186)
　　　　　　　　 　　　　　　　　　　　　tpmC值在国内外被广泛用于衡量计算机系统的事务处理能力
```

测试期间，tpcc_start工具会输出实时的日志信息，这些信息包含了TPC-C模型中的五个业务逻辑:New-Order:新订单、Payment:支付、Order-Status:订单查询、Delivery:发货、Stock-Level：库存，在指定响应时间内，事务处理和完成情况。

除了MySQL的输出日志之外，还需要关心系统的性能指标，因此需要借助`iostat`、`vmstat`等系统工具，查看系统的性能特征。


##### 测试结果分析

```bash
cd scripts
./analyze.sh ../mysql_tpcc_20160411>/tmp/mysql_tpcc_20160411.res
```


##### 使用gnuplot绘图

安装gnuplot

```bash
yum install gnuplot
```

生成绘图数据

```bash
innodb_buffer_pool_size值为512M
./tpcc_analyze.sh 512m-tpcc-data.log >512m-tpcc-data.data

innodb_buffer_pool_size值为1G
./tpcc_analyze.sh 1g-tpcc-data.log >1g-tpcc-data.data

innodb_buffer_pool_size值为2G
./tpcc_analyze.sh 2g-tpcc-data.log >2g-tpcc-data.data
```

合并三组数据

```bash
paste 512m-tpcc-data.data  1g-tpcc-data.data 2g-tpcc-data.data>tpcc-data.data
```

生成图片

```bash
./tpcc_graph.sh tpcc-data.data  tpcc.jpg
```

tpcc_analyze.sh脚本

```bash
cat tpcc_analyze.sh 


#!/bin/bash
TIMESLOT=1
         
if [ -n "$2" ]
then
    TIMESLOT=$2
    echo "Defined $2"
fi  
         
cat $1 | grep -v HY000 | grep -v payment | grep -v neword | \
awk -v timeslot=$TIMESLOT ' BEGIN { FS="[,():]"; s=0; cntr=0; aggr=0 } \
/MEASURING START/ { s=1} /STOPPING THREADS/ {s=0} /0/ { if (s==1) { cntr++; aggr+=$2; } \
if ( cntr==timeslot ) { printf ("%d %3f\n",$1,$5) ; cntr=0; aggr=0  }  } '
```

tpcc_graph.sh脚本

```bash
cat tpcc_graph.sh

#!/bin/bash
gnuplot << EOP
set style line 1 lt 1 lw 3
set style line 2 lt 5 lw 3
set style line 3 lt 7 lw 3
set terminal png size 960,480
set grid x y
set xlabel "Time(sec)"
set ylabel "Transactions"
set output "$2"
plot "$1" using 1:2 title "PS 5.1.56 buffer pool 512MM" ls 1 with lines,\
     "$1" using 3:4 title "PS 5.1.56 buffer pool 1g" ls 2 with lines,\
     "$1" using 3:6 title "PS 5.1.56 buffer pool 2g" ls 3 with lines axes x1y1                                                    
EOP
```

可能出现的错误

```bash
Could not find/open font when opening font "arial", using internal non-scalable font
```

解决

```bash
export GDFONTPATH=/usr/share/fonts/dejavu
export GNUPLOT_DEFAULT_GDFONT=DejaVuSansMono
source ~/.bashrc
```


### percona的tpcc-mysql分支版本

#### 项目简介

> 本项目是在percona的tpcc-mysql版本基础上衍生而来，根据InnoDB表结构设计规范建议做了小调整，可以作为官方版本的补充。
> 
> 该分支版本项目地址: https://github.com/yejr/tpcc-mysql
> 
> percona官方版本项目地址: https://github.com/Percona-Lab/tpcc-mysql
> 
> 为什么要做改造
> 
> tpcc-mysql是percona基于TPC-C(下面简写成TPCC)衍生出来的产品，专用于MySQL基准测试。
> 
> 它生成的测试表我认为有2个问题
> 
> 1、没有自增列作为主键。如果仅作为基准测试问题不大，但和我们实际生产中的设计模式可能有一定区别，相信大多数人还是习惯使用自增列作为主键的，如果你没这个习惯，那么可以忽略本文了；
> 2、使用外键。个人认为MySQL对外键支持并不是太好，并且一定程度上影响并发性能，因此建议取消外键，仅保留一般的索引。
> 
> 基于上面这2点，我微调了下tpcc-mysql的源码，主要改动有下面几个地方
> 
> 1、所有表都加上自增列做主键；
> 2、取消外键，仅保留普通索引；
> 3、降低tpcc测试过程中的输出频率，避免刷屏；
> 4、修改了表结构初始化DDL脚本以及load.c文件。
> 
> 利用该分支版本进行tpcc压力测试的结果表明，有自增列主键时，其TpmC相比没有自增列主键约提升了10%，还是比较可观的。

#### 编译安装tpcc-mysql

安装依赖包

MySQL 5.1

```bash
yum install mysql-devel
```

MySQL 5.6

```bash
yum install mysql-community-devel
```

进入tpcc-mysql源码目录，执行make，编译过程无报错即可

```bash
git clone  https://github.com/yejr/tpcc-mysql
cd tpcc-mysql
cd src
make
```

编译完成后，会在上一级目录下生成`tpcc_load`、`tpcc_start`这2个可执行文件。

#### 快速使用

##### 环境初始化

创建tpcc数据库

```bash
mysqladmin -u user -p passwd create tpcc
```

初始化表结构

```bash
mysql -u user -p passwd -f tpcc<create_table-autoinc-pk.sql
```

##### 开始测试

利用tpcc_load初始化测试数据，用法和原先的一样

```bash
./tpcc_load    
*************************************
*** ###easy### TPC-C Data Loader  ***
*************************************

 usage: tpcc_load [server] [DB] [user] [pass] [warehouse]
      OR
        tpcc_load [server] [DB] [user] [pass] [warehouse] [part] [min_wh] [max_wh]

           * [part]: 1=ITEMS 2=WAREHOUSE 3=CUSTOMER 4=ORDERS
```

利用tpcc_start开始测试，用法也和原先的一样

```bash
./tpcc_start --help                                                                                       
***************************************
*** ###easy### TPC-C Load Generator ***
***************************************
./tpcc_start: invalid option -- '-'
Usage: tpcc_start -h server_host -P port -d database_name -u mysql_user -p mysql_password -w warehouses -c connections -r warmup_time -l running_time -i report_interval -f report_file -t trx_file
```

##### 自动化测试脚本

根据各自的测试环境，调整`run_tpcc.sh`脚本里的相应参数，运行该脚本可进行自动化测试。


### 参考文档

http://www.google.com
http://imysql.com/2014/10/10/tpcc-mysql-full-user-manual.shtml
http://www.cnblogs.com/xuanzhi201111/p/4148434.html
http://imysql.com/2012/08/04/tpcc-for-mysql-manual.html
http://imysql.com/2014/10/10/tpcc-mysql-full-user-manual.shtml