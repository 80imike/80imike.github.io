---
title: Linux系统分析工具之slabtop
tags:
  - Linux
  - 技巧
  - 工具
categories: Linux
abbrlink: 36447
date: 2016-03-15 09:51:54
---

### 一、简介

> slabtop - display kernel slab cache information in real time（实时的显示内核slab缓存信息，透过/proc/slabinfo）
> 内核的模块在分配资源的时候，为了提高效率和资源的利用率，都是透过slab来分配的。通过slab的信息，再配合源码能粗粗了解系统的运行情况，比如说什么资源有没有不正常的多，或者什么资源有没有泄漏。linux系统透过/proc/slabinfo来向用户暴露slab的使用情况。
> 
> Linux所使用的 slab 分配器的基础是 Jeff Bonwick 为 SunOS 操作系统首次引入的一种算法。Jeff 的分配器是围绕对象缓存进行的。在内核中，会为有限的对象集（例如文件描述符和其他常见结构）分配大量内存。Jeff 发现对内核中普通对象进行初始化所需的时间超过了对其进行分配和释放所需的时间。因此他的结论是不应该将内存释放回一个全局的内存池，而是将内存保持为针对特定目而初始化的状态。Linux slab 分配器使用了这种思想和其他一些思想来构建一个在空间和时间上都具有高效性的内存分配器。
> 
> 保存着监视系统中所有活动的slab缓存的信息的文件为/proc/slabinfo
<!-- more -->

### 二、用法

slabtop-实时显示内核slab内存缓存信息
slabtop [options]

**描述：**
> slabtop displays detailed  kernel  slab  cache  information in real time. It displays a listing of the top caches sorted by one of the listed sort criteria.  It also displays a statistics header filled with slab layer information.

**选项：**
> --delay=n, -d n		#每n秒更新一次显示的信息，默认是每3秒
> --sort=S, -s S			#指定排序标准进行排序（排序标准，参照下面或者man手册）
> --once, -o			#显示一次后退出
> --version, -V			#显示版本
> --help				#显示帮助信息

**排序标准：**
> a:     sort by number of active objects
> b:     sort by objects per slab
> c:     sort by cache size
> l:     sort by number of slabs
> v：    sort by number of active slabs
> n:     sort by name
> o:     sort by number of objects
> p:     sort by pages per slab
> s:     sort by object size
> u:     sort by cache utilization

**输出界面可用的命令：**
> <SPACEBAR>：	        刷新显示内容
> Q：			退出

### 三、数据分析

```
#slabtop -o
Active / Total Objects (% used) : 342368 / 362880 (94.3%)
Active / Total Slabs (% used) : 7873 / 7873 (100.0%)
Active / Total Caches (% used) : 103 / 150 (68.7%)
Active / Total Size (% used) : 27814.06K / 29616.44K (93.9%)
Minimum / Average / Maximum Object : 0.01K / 0.08K / 128.00K

OBJS ACTIVE USE OBJ SIZE SLABS OBJ/SLAB CACHE SIZE NAME
133980 133862 99% 0.02K 660 203 2640K avtab_node
92886 92653 99% 0.03K 822 113 3288K size-32
28626 27174 94% 0.05K 367 78 1468K selinux_inode_security
25816 25614 99% 0.48K 3227 8 12908K ext3_inode_cache
23693 18692 78% 0.13K 817 29 3268K dentry_cache
21240 15306 72% 0.05K 295 72 1180K buffer_head
6174 5758 93% 0.27K 441 14 1764K radix_tree_node
```