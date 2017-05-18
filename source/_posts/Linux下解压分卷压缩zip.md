---
title: Linux下解压分卷压缩zip
tags:
  - Linux
  - 技巧
categories: Linux
abbrlink: 56582
date: 2016-03-15 09:51:54
---
####问题如题，解决方法：

> 假设要解压的分卷文件是file.zip file.z01, file.z02 file.z03，(其他情况可类推)
将分卷文件合成一个完整的压缩文件hana.zip，然后在使用unzip解压file.zip即可。
注意：cat里面文件顺序不能乱，不然解压会失败。

```bash
cat file.z01 file.z02 file.z03 file.zip > hana.zip
unzip hana.zip
```

