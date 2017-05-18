---
title: Linux群常见问题整理(一)
tags:
  - Linux
  - 技巧
categories: Linux
abbrlink: 17022
date: 2016-03-15 09:51:54
---

突然的一个想法，计划开始对群里平时各位群友总结的小技巧做一个汇总，便于查询、也便于分享。先简单总结了下面几条做一个样本，我对一些知识点稍为注解了下，方便理解。希望以后提供的群友也简单注解下，便于其它人理解。以后积累多了，我会整理后以[Linux群常见问题整理]系列的形式发出来。最后给群打打广告，QQ群：19558533[Linux/Unix技术交流]。欢迎有兴趣的网友加入，加群请先回答：<a href="http://tinyurl.com/groupask" target="_blank">入群测试题</a>。呵呵！

Q：如何取消浮动IP？(提供人:土猪一号)
A：ifconfig eth0:1 0.0.0.0

Q：各种网络状态统计(提供人:蜗牛)
A：用netstat和awk实现，具体语句如下：
```bash
netstat -n | awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}'
```
Q：减少自定义内核尺寸(提供人:蜗牛)
A：修改KERNELDIR下的Makefile，找到其中CFLAGS += -g这样的，前面加注释，然后编译模块即可
<!-- more -->
注解：这样做目的是去掉编译好的二进制模块文件中的调试信息，以达到减少自定义内核尺寸的目的。

Q：解决Apache中ETag在Web集群环境中的验证问题(提供人:蜗牛)
A：去掉ETAG中的inode
```bash
<Directory /usr/local/httpd/htdocs>
    FileETag MTime Size
</Directory>
```
注解：在多台负载平衡的服务器(WEB集群)环境下，同一个文件会有不同的ETag(INode不一样,不同的服务器生成的ETag也就不一样)或者不同的文件修改日期，这样浏览器每次都会重新下载。所以有人建议使用WEB集群时不要使用ETag(设置为'FileETag None'使响应头不再包含ETag字段)。

其实在WEB集群环境中要使用ETag也是可以的。解决方法很容易：只要ETag的计算没有INode参于计算生成Hash值，只让ETag后面只使用MTime和Size二个参数参于计算就好了。生成的Hash值就会很准确了。

关于Etag的知识点：<a href="http://www.php-oa.com/2008/08/27/etag.html" target="_blank">HTTP参数中Etag的重要性</a>

Q：Apache里让所有pl文件支持mod_perl(提供人:蜗牛)
A：具体配置语句如下：
```bash
<IfModule mod_perl>
PerlModule ModPerl::Registry
<FilesMatch \.pl$>
SetHandler perl-script
PerlResponseHandler ModPerl::Registry
PerlOptions +ParseHeaders
</FilesMatch>
</IfModule> 
```
Q：apache里通过rewrite将多个域名合并为一个(提供人:蜗牛)
A：Rewrite的具体语句如下：
```bash
RewriteCond %{HTTP_HOST} ^(www.)?info-steel.(com|cn) [NC]
RewriteRule ^(.*) http://www.shsteeljy.com$1 [R=permanent,L] 
```
Q：手动释放Linux内存(提供人:蜗牛)
A：清除系统对内存的cache，使用root做下面几步：
```bash
#sync 
#echo 3 > /proc/sys/vm/drop_caches
#sync 
#echo 0 > /proc/sys/vm/drop_caches
```
注解：/proc是一个虚拟文件系统，我们可以通过对它的读写操作做为与kernel实体间进行通信的一种手段。也就是说可以通过修改/proc中的文件，来对当前kernel的行为做出调整。那么我们就可以通过调整/proc/sys/vm/drop_caches来释放内存。

手动执行sync命令是为了确保文件系统的完整性(描述：sync命令运行sync 子例程。如果必须停止系统，则运行sync命令以确保文件系统的完整性。sync命令将所有未写的系统缓冲区写到磁盘中，包含已修改的 i-node、已延迟的块 I/O 和读写映射文件)，所以这一步必须先做。

有关/proc/sys/vm/drop_caches的用法如下:

Writing to this will cause the kernel to drop clean caches, dentries and inodes from memory, causing that memory to become free.
```bash
To free pagecache:
echo 1 > /proc/sys/vm/drop_caches
To free dentries and inodes:
echo 2 > /proc/sys/vm/drop_caches
To free pagecache, dentries and inodes:
echo 3 > /proc/sys/vm/drop_caches
```
As this is a non-destructive operation and dirty objects are not freeable, the user should run `sync' first.
