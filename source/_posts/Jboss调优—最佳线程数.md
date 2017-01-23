---
title: JBoss调优—最佳线程数
tags:
  - Linux
  - JBoss
  - 技巧
categories: JBoss
abbrlink: 35609
date: 2016-03-15 09:51:54
---

在设置jboss的参数中，maxThreads(最大线程数)和acceptCount(最大等待线程数)是两个非常重要的指标，直接影响到程序的QPS。本文讲解jboss连接的运行原理，以及如何设置这两个参数。

### 最佳线程数：

在做压力测试时，刚开始，随着并发量的增加，QPS也会随之增大，但当并发量超过一个阀值之后，QPS就不会再增大，甚至很多时候还会降低，类似于下图。而这个阀值就是我们所说的最佳线程数，他也是设置jboss时的maxThreads参数时的重要指标。

![](http://hi.csdn.net/attachment/201104/12/0_13026154879Qex.gif)
       
     
#### jboss连接的原理

jboss连接的基本原理如下图，一般情况下，当用户访问jboss服务器时，会先进入等待队列，然后再到运行区被执行。运行区中连接的线程数量是固定的，也就是说cpu在同一时间内处理的用户访问数量也是固定的。

而那些已经建立连接，但暂时还不能被cpu处理的，就在等待列队中等待，直到运行区中有空闲时，才进入运行区被cpu执行的。而如果等待队列也满了，再有用户申请连接，jboss就会直接直接拒绝掉。

这样做的目的是为了更好地利用系统资源（cpu，内存等）。试想，每个连接都是要占用系统资源的，假如jboss不做这样的设置，一有连接请求，jboss马上建立连接，内存消耗非常大，更加致命的是，随着连接数量的增多，cpu用于调度的时间增大，用于计算的时间相对减少，这样系统的性能就被活活拖垮了。

![](http://hi.csdn.net/attachment/201104/13/0_1302700843PpQd.gif)
           
    
在jboss中，acceptCount和maxThreads，这两个参数就是用于设置分别对待队列长度和运行区线程数。具体操作，进入JBOSS_HOME/server/default/deploy/jbossweb.sar/ 文件夹下，找到server.xml文件，修改这连个参数如下：

```xml
<Connector protocol="HTTP/1.1" port="9999" address="${jboss.bind.address}"  
         connectionTimeout="20000" redirectPort="${jboss.web.https.port}"  
maxThreads="150" acceptCount="8000"  
/>
```
<!-- more -->
####如何找到最佳连接数

1. 根据公式计算: 最佳线程数量=((线程等待时间+线程cpu时间)/线程cpu时间) * cpu数量
2. 通过用户慢慢递增来进行性能压测，观察QPS，响应时间。

这里重点讲讲第二种方法。

首先在jboss的设置上，maxThreads值要设置得尽量大，以便压力都能压到cpu上。这同时也要注意，线程连接是占用内存资源的，假如maxThreads太大了，可能会消耗完所有内存，最终造成程序崩溃。

具体步骤。我以自己最近做的压力测试，并从中找到最佳线程数为例进行进行说明

我先设置的maxThreads=2000，acceptCount=4000。测试结果如下，横轴表示并发量，纵轴表示QPS

![](http://hi.csdn.net/attachment/201104/14/0_13027866036TTt.gif)
      
跟据上图，我们就可以大致知道这个系统的最佳线程数是在红色区间范围内。
      
#### 真实的maxThreads的设置

但在真实环境中，maxThreads的值要略大于压力测试时得到的最佳线程数。这是因为系统依靠的资源是可能发生变化的，比如原先系统在压力测试得到的最佳线程数是30，我们设置maxThreads也是30的话，但在真实运行时，可能突然有段时间，IO的响应变慢，这样造成的就是是最佳线程数可能变成35，这样cpu资源就白白被浪费了，QPS降低.所以在设置maxThreads时，留下一切缓冲余地还是很有必要的。