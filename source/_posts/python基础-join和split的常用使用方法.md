---
title: Python基础-join和split的常用使用方法
tags:
  - Python
  - 技巧
categories: Python
abbrlink: 31739
date: 2016-03-15 09:51:54
---

### 一、关于split 和 join 方法

1. 只针对字符串进行处理。split:拆分字符串、join连接字符串
1. string.join(sep):以string作为分割符，将sep中所有的元素(字符串表示)合并成一个新的字符串
1. string.split(str=' ',num=string.count(str)):以str为分隔，符切片string，如果num有指定值，则仅分隔num个子字符串。
1. 对导入os模块进行os.path.splie()/os.path.join() 貌似是处理机制不一样，但是功能上一样。
<!-- more -->
### 二、join方法

```python
1 a='abcd'
2 print '.'.join(a)   
3 print '|'.join(['a','b','c'])　　#可以把['a','b','c']看做是 a='abcd';下面同理
4 print '.'.join({'a':1,'b':2,'c':3,'d':4})

对应输出：
2 a.b.c.d
3 a|b|c
4 a.c.b.d
```
> 注意：'.'等做分隔符，将join里的所有元素(字符串)通过分隔符连接成一个新的字符串
可能有人像我一样咬文嚼字，针对string.join()的定义爱钻牛角尖，硬生生地将['a','b','c']先转换为字符串，然后在join

如：
```python
1 b=str(['a','b','c'])
2 print '|'.join(b)
```

我以为这样是正解，但是不然。输出结果是：[|'|a|'|,| |'|b|'|,| |'|c|'|]，而导致与上面不一致的原因就是画蛇添足了，把['a','b','c']转换成了字符串，在Python中，我们发现字符串、元祖、列表它们是序列类型，有着相同的访问方式，可以以下标来访问其中的元素。


**其它实例**

*实例一*

os.path.join(path1[,path2[,......]])

```python
 1 os.path.join(path1[, path2[, ...]])
 2 
 3 将多个路径组合后返回，第一个绝对路径之前的参数将被忽略。
 4 
 5 >>> os.path.join('c:\\', 'csv', 'test.csv')
 6 
 7 'c:\\csv\\test.csv'
 8 
 9 >>> os.path.join('windows\temp', 'c:\\', 'csv', 'test.csv')
10 
11 'c:\\csv\\test.csv'
12 
13 >>> os.path.join('/home/aa','/home/aa/bb','/home/aa/bb/c')
14 
15 '/home/aa/bb/c'
```

*实例二*

```python
>>>li = ['my','name','is','bob'] 
>>>' '.join(li) 
'my name is bob' 
 
>>>'_'.join(li) 
'my_name_is_bob' 
 
>>> s = ['my','name','is','bob'] 
>>> ' '.join(s) 
'my name is bob' 
 
>>> '..'.join(s) 
'my..name..is..bob' 
```

### 三、split方法


>split(…)
>S.split([sep [,maxsplit]]) -> 由字符串分割成的列表
>返回一组使用分隔符（sep）分割字符串形成的列表。如果指定最大分割数，则在最大分割时结束。如果分隔符未指定或者为none，则分隔符默认为空格。

*实例一*

```python
1 s='a b c'
2 print s.split(' ')
3 st='hello world'
4 print st.split('o')
5 print st.split('o',1)
6 
7 --------output---------
8 ['a', 'b', 'c']
9 ['hell', ' w', 'rld']
10 ['hell', ' world']
```

注意：分隔符不能为空，否则会出错如下：

```python
Traceback (most recent call last):
  File "<pyshell#12>", line 1, in <module>
    s.split('')
ValueError: empty separator
```

```python
#但是可以有不含其中的分隔符
>>> s.split('x')
['a b c']
>>> s.split('xsdfadsf')
['a b c']
```

>os.path.split()
>os.path.split是按照路径将文件名和路径分割开，比如d:\\python\\python.ext，可分割为['d:\\python', 'python.exe']，示例如下：

```python
1 import os
2 print os.path.split('c:\\Program File\\123.doc')
3 print os.path.split('c:\\Program File\\')
4 -----------------output---------------------
5 ('c:\\Program File', '123.doc')
6 ('c:\\Program File', '')
```

*实例二*

```python

>>> b = 'my..name..is..bob' 
 
>>> b.split() 
['my..name..is..bob'] 
 
>>> b.split("..") 
['my', 'name', 'is', 'bob'] 
 
>>> b.split("..",0) 
['my..name..is..bob'] 
 
>>> b.split("..",1) 
['my', 'name..is..bob'] 
 
>>> b.split("..",2) 
['my', 'name', 'is..bob'] 
 
>>> b.split("..",-1) 
['my', 'name', 'is', 'bob'] 
```
 
可以看出 b.split("..",-1)等价于b.split("..") 