---
title: Linux命令行学习神器tldr
tags:
  - tldr
  - Linux
categories: tldr
abbrlink: 16098
date: 2016-05-16 09:00:01
updated:
toc_number:
---
对于很多使用终端的Linux和Mac用户，使用Terminal最难的就是要记住众多的Linux命令了。比如：`ssh`，`curl`，`grep`等，经常会记不住参数的顺序。这个时候通常在使用的时候通过man阅读长长的文档，从中对比一个个参数，这样费时又费力。

今天要介绍的一个好用的工具叫`tldr`，tldr全称Too long, Don't read，翻译成中文就是[太长不读]。`tldr`根据二八原则将命令的常用场景给出示例，让人一看就懂。

tldr项目地址: https://github.com/tldr-pages/tldr
<!-- more -->

### tldr安装

tldr有很多种语言版本，安装也很简单，各种包管理工具都支持。


安装方式如下

**C++ client**

```
$ brew install tldr-pages/tldr/tldr
```
**Crystal client**

```
$ brew install porras/tap/tlcr
```

**Go client**

```
$ go get github.com/pranavraja/tldr (or platform binaries)
```

**Node.js client**

```
$ npm install -g tldr
```

**Perl5 client**

```
$ cpanm App::tldr
```

**Python clients**

- tldr-python-client

```
$ pip install tldr
```

- tldr.py

```
$ pip install tldr.py
```

**Ruby client**

```
$ gem install tldrb
```

**Bash client**

```
https://github.com/raylee/tldr
```

**Web client**

```
https://ostera.github.io/tldr.jsx
```


**Android clients**

- tldr-viewer, available on Google Play

```
https://github.com/gianasista/tldr-viewer
https://play.google.com/store/apps/details?id=de.gianasista.tldr_viewer
```

- tldroid, available on Google Play

```
https://github.com/hidroh/tldroid   
https://play.google.com/store/apps/details?id=io.github.hidroh.tldroid
```

**iOS clients**

- tldr-man-page, available on App Store

```
https://github.com/freesuraj/TLDR
https://itunes.apple.com/sg/app/tldr-man-page/id1073433250?mt=8
```

- tldr-pages, available on App Store

```
https://github.com/mflint/ios-tldr-viewer
https://itunes.apple.com/us/app/tldt-pages/id1071725095?ls=1&mt=8
```

更多客户端可参考: https://github.com/tldr-pages/tldr

### tldr使用

tldr命令格式

```
$ tldr -h 
usage: tldr [-h] [-o {linux,osx,sunos}] command [command ...]

Python command line client for tldr

positional arguments:
  command               command to lookup

optional arguments:
  -h, --help            show this help message and exit
  -o {linux,osx,sunos}, --os {linux,osx,sunos}
                        Override the operating system [linux, osx, sunos]
```

来看几个例子

```
$ tldr ssh
#SSH                                                                           
                                                                                
  Secure Shell is a protocol used to securely log onto remote systems.          
  It can be used for logging or executing commands on a remote server.          
                                                                                
- Connect to a remote server:                                                   
                                                                                
  ssh username@remote_host                                                      
                                                                                
- Connect to a remote server with a specific identity (private key):            
                                                                                
  ssh -i /path/to/key_file username@remote_host                                 
                                                                                
- Connect to a remote server using a specific port:                             
                                                                                
  ssh username@remote_host -p 2222                                              
                                                                                
- Run a command on a remote server:                                             
                                                                                
  ssh remote_host command -with -flags                                          
                                                                                
- SSH tunneling: Dynamic port forwarding (SOCKS proxy on localhost:9999):       
                                                                                
  ssh -D 9999 -C username@remote_host                                           
                                                                                
- SSH tunneling: Forward a specific port (localhost:9999 to slashdot.org:80):   
                                                                                
  ssh -L 9999:slashdot.org:80 username@remote_host                              
                                                                                
- SSH enable agent forward:                                                     
                                                                                
  ssh -A username@remote_host    

```

```
$ tldr curl
# curl                                                                          
                                                                                
  Transfers data from or to a server.                                           
  Supports most protocols including HTTP, FTP, POP.                             
                                                                                
- Download a URL to a file:                                                     
                                                                                
  curl "URL" -o filename                                                        
                                                                                
- Send form-encoded data:                                                       
                                                                                
  curl --data name=bob http://localhost/form                                    
                                                                                
- Send JSON data:                                                               
                                                                                
  curl -X POST -H "Content-Type: application/json" -d '{"name":"bob"}' http://localhost/login
                                                                                
- Specify an HTTP method:                                                       
                                                                                
  curl -X DELETE http://localhost/item/123                                      
                                                                                
- Head request:                                                                 
                                                                                
  curl --head http://localhost                                                  
                                                                                
- Include an extra header:                                                      
                                                                                
  curl -H "X-MyHeader: 123" http://localhost                                    
                                                                                
- Pass a user name and password for server authentication:                      
                                                                                
  curl -u myusername:mypassword http://localhost                                
```                                                   

怎么样，比man看起来舒服多了吧？还等什么，赶紧上手体验一下吧！


### 参考文档

http://www.google.com
https://github.com/tldr-pages/tldr
https://codingstyle.cn/topics/26