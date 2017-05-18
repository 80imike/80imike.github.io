---
title: Python基础-import与from...import....
tags:
  - Python
  - 技巧
categories: Python
abbrlink: 53412
date: 2016-03-15 09:51:54
---

#### 简单说说python import与from...import....

在python用import或者from...import来导入相应的模块。模块其实就一些函数和类的集合文件，它能实现一些相应的功能，当我们需要使用这些功能的时候，直接把相应的模块导入到我们的程序中，我们就可以使用了。这类似于C语言中的include头文件，Python中我们用import导入我们需要的模块。

```python
import sys
print('================Python import mode==========================');
print ('The command line arguments are:')
for i in sys.argv:
    print (i)
print ('\n The python path',sys.path)

from sys import argv,path #导入特定的成员
print('================python from import===================================')
print('path:',path)

如果你要使用所有sys模块使用的名字，你可以这样：

from sys import *
print('path:',path)
```
<!-- more -->
>从以上我们可以简单看出：
>导入mode，import与from...import的不同之处在于，简单说：
>如果你想要直接输入argv变量到你的程序中而每次使用它时又不想打sys，
>则可使用：from sys import argv
>一般说来，应该避免使用from..import而使用import语句，
>因为这样可以使你的程序更加易读，也可以避免名称的冲突

在使用 from xxx import * 时，如果想精准的控制模块导入的内容，可以使用 __all__ = [xxx,xxx] 来实现，例如：

```python
two.py

__all__ = ['a','b'] #__为双横线
class two():
    def __init__(self):
        print('this is two')
a = 'this is two a'
b = 'this is two b'
if __name__=='__main__':
    t = two()
```


```python
one.py

from two import *
print a
print b
t = two()
```

这时，类two() 将不会被import * 导入进来

#### 关于Import中的路径搜索问题

类似于头文件，模块也是需要系统的搜索路径的，下面的命令即是系统默认的搜索路径，当你导入一个模块时，系统就会在下面的路径列表中搜索相应的文件。

```python
print(sys.path)

['/home/python/code', '/usr/lib64/python26.zip', '/usr/lib64/python2.6', '/usr/lib64/python2.6/plat-linux2', '/usr/lib64/python2.6/lib-tk', '/usr/lib64/python2.6/lib-old', '/usr/lib64/python2.6/lib-dynload', '/usr/lib64/python2.6/site-packages', '/usr/lib/python2.6/site-packages'] 


```

(从例表中，我们可以看到python会首先在当前工作目录里去找)

如果没有找到相应的内容，则报错：

```python
import syss

Traceback (most recent call last):
  File "D:/xxx/xxx/xx/Code/test.py", line 19, in <module>
    import syss
ImportError: No module named syss
```

当然，我们也可以自行添加要搜索路径。调用列表的append方法即可：

```python
import sys
sys.path.append('/home/python/newcode')
```

#### 创建自己的模块

在创建之前，有一点需要说明一下：每个Python模块都有它的__name__（就每个对象都自己的__doc__一样）。通过__name__我们可以找出每一个模块的名称，一般__name__的值有两种：1 一是主模块名称为："__main__"(可以理解为直接运行的那个文件)，2 那些被主模块导入的模块名称为：文件名字（不加后面的.py）。有__name__是很有用的，因为我们可以通过 if __name__  == 'xxx' 判断来执行那些模块，那些模块不被执行。另外：每个Python程序也是一个模块。它扩展名为：.py扩展名。

下面，我们通过例子来说明：
首先：我们创建模块：mymodel.py

```python
#!/user/bin/python
#Filename:mymodel.py
version = '1.0'
def sayHello():
    print ('Hello world')

def modelName():
    return __name__#返回它自己的名称
#end of model
```

以上语句注意：
>1.这个模块应该被放置在我们输入它的程序的同一个目录中，或者在sys.path所列目录之一。
>2.你已经看到，它与我们普通的Python程序相比并没有什么特别之处

然后：我们在test.py中来调用此模块：test.py

```python
import sys,mymodel
sys.path.append('/home/python/newcode')#提供搜索路径
print(__name__) #此处打印主模块的名称：__main__
mymodel.sayHello()
print('Version',mymodel.version)
print('Model Name',mymodel.modelName())#打印被导入模块的名称: mymodel
```
我们使用from..import...

```python
print('======================from.....import=====================================')
from mymodel import *
print(__name__)#此处打印主模块的名称：__main__
sayHello()
print('Version',version)
print('Model Name',modelName()) #打印被导入模块的名称: mymodel
```
以上语句注意：

>1.我们可以通过import来导入多个模块，用“,”（逗号）分隔。
>2.注意import与from..import.....



#### 创建自己的包

##### 1.一个包的基本组织如下：

```python
FC/
  __init__.py
  Libr/
    __init__.py
    one.py
    two.py
    ....
  Model/
    __init__.py
    one.py
    ....
```

>在外部加载调用时，有以下方式：
>coding:utf-8
>加载方式一
>import Fc.Libr.one
>print Fc.Libr.one.a
>加载方式二
>from Fc.Libr import one
>print one.a
>加载方式三
>from Fc.Libr.one import a
>print a
>加载方式四
>from Fc.Libr import *
>print one.a

>注意直接使用第四种方式是不能正确导入Libr下的one子模块的，这就需要在Fc目录下的__init__.py文件中定义好需要加载子模块的名称

```python
Fc/Libr/__init__.py
__all__=['one','two'] #定义加载子模块的名称
````

>在加载包模块时，在import语句执行期时，遇到的所有__init__.py文件都会被执行，在上面代码中
>首先会执行Fc目录中的__int__.py，然后执行Libr目录中的__init__.py

##### 2.子模块加子模块问题

同一包的相同目录中：

```python
#coding:utf-8
#加载方式一:使用完全限定名称
from Fc.Libr import one
aa = 'libr two load one---'+one.a

#加载方式二:使用相对导入
from . import one
bb = 'libr two load one----'+one.b
方二中使用.来表示在同一级目录中。


#加载方式三:(这种方式应当避免:最后找不到会转移到标准库)
import Fc.Libr.one
cc = 'libr two load one---'+Fc.Libr.one.a

在外部使用时：
#coding:utf-8
from Fc.Libr import *
print two.aa
print two.bb
```

同一包的不同目录中：

```python
#coding:utf-8
from ..Model import one
a = 'libr two load mode one---'+one.a

使用时：
#coding:utf-8
from Fc.Libr import *
print two.a
将输出：libr two load mode one---fc model one

另外在导入一个包时，会定义一个特殊的变量__path__，该变量包含一个目录列表。
__path__可通过__init__.py文件中包含的代码访问，最初包含的一项具有包的目录名称。我们可以
向__path__列表提供更多的目录，以更改查找子模块时使用的搜索路径，大型项目中这个很有用。
```
 

>特别说明
>1.import执行加载源文件中所有语名（所以模块是一个文件）。
>2.import语句可以出现在程序中的任何位置。但是有一点是：无论import语句被使用了多少次，每个模块中的代码仅加载和执行一次，后续的import语句仅将模块名称绑定到前一次导入所创建的模块对象上。
>3.值有种使用sys.modules可查看当前加载的所有模块。

 