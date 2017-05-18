---
title: Linux安装CLI的字典sdcv
tags:
  - Linux
  - 技巧
categories: Linux
abbrlink: 7215
date: 2016-03-18 09:00:00
updated:
---

sdcv全称为stardict console version，是终端下的词典。

### 安装sdcv

```bash
#CentOS, RHEL, Fedora (need EPEL repo)
#yum install sdcv
#sudo apt-get install sdcv
```

### 安装字典

#### 下载字典
简体中文: http://download.huzheng.org/zh_CN/
繁体中文: http://download.huzheng.org/zh_TW/
<!-- more -->

```bash
#cd /tmp #
#朗道英汉字典
#wget http://download.huzheng.org/zh_CN/stardict-langdao-ec-gb-2.4.2.tar.bz2
#朗道汉英字典
#wget http://download.huzheng.org/zh_CN/stardict-langdao-ce-gb-2.4.2.tar.bz2
```

#### 安装字典
```bash
mkdir -p ~/.stardict/dic
cd ~/.stardict/dic
tar xvf /tmp/stardict-langdao-ec-gb-2.4.2.tar.bz2
tar xvf /tmp/stardict-langdao-ce-gb-2.4.2.tar.bz2
```

### 实例

#### 查看字典字库数量

```bash
# sdcv -l
Dictionary's name   Word count
朗道汉英字典5.0    405719
朗道英汉字典5.0    435468
```

#### 单字查询(只查一个单字)。

```bash
#sdcv hello
发现 1 条记录和 hello 相似。
-->朗道英汉字典5.0
-->hello

*[hә'lәu]
interj. 喂, 嘿
```

#### 多重查询 (进入无限查询状态)，使用 Ctrl + C 或 D 离开

```bash
#sdcv
请输入单词或短语：企鹅
发现 1 条记录和 企鹅 相似。
-->朗道汉英字典5.0
-->企鹅

penguin

请输入单词或短语：hello
发现 1 条记录和 hello 相似。
-->朗道英汉字典5.0
-->hello

*[hә'lәu]
interj. 喂, 嘿

请输入单词或短语：红色气球
发现 10 条记录和 红色气球 相似。
0)朗道汉英字典5.0-->变色细球菌
1)朗道汉英字典5.0-->堇色细球菌
2)朗道汉英字典5.0-->探空气球
3)朗道汉英字典5.0-->气球
4)朗道汉英字典5.0-->测风气球
5)朗道汉英字典5.0-->灰色细球菌
6)朗道汉英字典5.0-->灰色链球菌
7)朗道汉英字典5.0-->白色小球菌
8)朗道汉英字典5.0-->白色细球菌
9)朗道汉英字典5.0-->白色链球菌
Your choice[-1 to abort]: 3
-->朗道汉英字典5.0
-->气球

air balloon; balloon
【医】 balloon
相关词组:
  测风气球
  探空气球
  系留气球

请输入单词或短语：
```

### 观看历史查询记录

```bash
#cat $HOME/.sdcv_history|tail
clear
clean
hello
hello
```

### 参考资料
https://blog.longwin.com.tw/2015/11/linux-install-cli-dictionary-sdcv-2015/
https://chusiang.gitbooks.io/working-on-gnu-linux/content/15.sdcv.html