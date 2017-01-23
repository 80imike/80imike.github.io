---
title: CentOS下安装高版本GCC
tags:
  - GCC
  - Linux
categories: GCC
abbrlink: 25767
date: 2016-05-09 09:00:01
updated:
toc_number:
---

有时编译需要用到4.8以上版本的GCC,由于CentOS源没有提供高版本的GCC安装包，这时就不能通过安装包安装。通常的解决方案就是通过编译安装高版本的GCC。

这里介绍一个更高级、更好用、更简单的方法来升级系统GCC，本文将介绍如何利用CentOS的新特性SCL进行高版本GCC的安装。

### 什么是SCL

请参考:[如何在CentOS上启用软件集Software Collections](http://www.imike.me/2016/05/09/%E5%A6%82%E4%BD%95%E5%9C%A8CentOS%E4%B8%8A%E5%90%AF%E7%94%A8%E8%BD%AF%E4%BB%B6%E9%9B%86Software%20Collections/)一文
<!-- more -->
### 通过SCL安装GCC

#### 官方SCL仓库

devtoolset-3: https://www.softwarecollections.org/en/scls/rhscl/devtoolset-3/

```
$ sudo yum install centos-release-scl
$ sudo yum-config-manager --enable rhel-server-rhscl-7-rpms
$ sudo yum install devtoolset-3
$ scl enable devtoolset-3 bash
```
			 
#### 三方SCL仓库

copr.fedoraproject.org提供了第三方构建的devtoolset-3/4的仓库, 可直接添加yum源repo后体验devtoolset-3(gcc-4.9.2)、devtoolset-4(gcc-5.2.1)。

devtoolset-3: https://copr.fedoraproject.org/coprs/rhscl/devtoolset-3/
devtoolset-4: https://copr.fedoraproject.org/coprs/hhorak/devtoolset-4-rebuild-bootstrap/

##### devtoolset-3

- CentOS 6

安装软件源

```
$ wget https://copr.fedoraproject.org/coprs/rhscl/devtoolset-3/repo/epel-6/rhscl-devtoolset-3-epel-6.repo   -O /etc/yum.repos.d/rhscl-devtoolset-3-epel-6.repo
```

安装devtoolset-3

```
$ yum --disablerepo='*' --enablerepo='rhscl-devtoolset-3' list
$ yum --disablerepo='*' --enablerepo='rhscl-devtoolset-3' install devtoolset-3-gcc devtoolset-3-gcc-c++
```

启用SCL环境中新版本GCC

```
$ scl enable devtoolset-3 bash
```

验证GCC版本

```
$ gcc --version
gcc (GCC) 4.9.2 20150212 (Red Hat 4.9.2-6)
Copyright (C) 2014 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

- CentOS 7

安装软件源

```
$ wget https://copr.fedoraproject.org/coprs/rhscl/devtoolset-3-el7/repo/epel-7/rhscl-devtoolset-3-el7-epel-7.repo -O /etc/yum.repos.d/rhscl-devtoolset-3-el7-epel-7.repo
```

安装devtoolset-3

```
$ yum --disablerepo='*' --enablerepo='rhscl-devtoolset-3-el7' list
$ yum --disablerepo='*' --enablerepo='rhscl-devtoolset-3-el7' install devtoolset-3-gcc devtoolset-3-gcc-c++
```

启用SCL环境中新版本GCC

```
$ scl enable devtoolset-3 bash
```

验证GCC版本

```
$ gcc --version
gcc (GCC) 4.9.2 20150212 (Red Hat 4.9.2-6)
Copyright (C) 2014 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

##### devtoolset-4仓库

- CentOS 6

安装软件源

```
wget https://copr.fedoraproject.org/coprs/hhorak/devtoolset-4-rebuild-bootstrap/repo/epel-6/hhorak-devtoolset-4-rebuild-bootstrap-epel-6.repo -O /etc/yum.repos.d/hhorak-devtoolset-4-rebuild-bootstrap-epel-6.repo
```

安装devtoolset-4

```
yum --disablerepo='*' --enablerepo='hhorak-devtoolset-4-rebuild-bootstrap' list
yum --disablerepo='*' --enablerepo='hhorak-devtoolset-4-rebuild-bootstrap' install devtoolset-4-gcc devtoolset-4-gcc-c++
```
启用SCL环境中新版本GCC

```
$ scl enable devtoolset-4 bash
```

验证GCC版本

```
gcc --version
gcc (GCC) 5.2.1 20150902 (Red Hat 5.2.1-2)
Copyright (C) 2015 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

- CentOS 7

安装软件源

```
wget https://copr.fedoraproject.org/coprs/hhorak/devtoolset-4-rebuild-bootstrap/repo/epel-7/hhorak-devtoolset-4-rebuild-bootstrap-epel-7.repo -O /etc/yum.repos.d/hhorak-devtoolset-4-rebuild-bootstrap-epel-7.repo
```

安装devtoolset-4

```
yum --disablerepo='*' --enablerepo='hhorak-devtoolset-4-rebuild-bootstrap' list
yum --disablerepo='*' --enablerepo='hhorak-devtoolset-4-rebuild-bootstrap' install devtoolset-4-gcc devtoolset-4-gcc-c++
```

启用SCL环境中新版本GCC

```
$ scl enable devtoolset-4 bash
```

验证GCC版本

```
gcc --version
gcc (GCC) 5.2.1 20150902 (Red Hat 5.2.1-2)
Copyright (C) 2015 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

### 参考文档

http://www.google.com
https://www.softwarecollections.org/en/scls/rhscl/devtoolset-3/
http://m.blog.csdn.net/article/details?id=50474355