---
title: Nginx与Lua的执行顺序和步骤说明
tags:
  - Nginx
  - Lua
categories: Nginx
abbrlink: 4336
date: 2016-03-21 09:00:00
updated:
---

### 一、Nginx执行步骤

Nginx处理每一个用户请求时，都是按照若干个不同阶段(phase)依次处理的，而不是根据配置文件上的顺序。

Nginx处理请求的过程一共划分为11个阶段，按照执行顺序依次是post-read、server-rewrite、find-config、rewrite、post-rewrite、 preaccess、access、post-access、try-files、content、log.

> 1、post-read
> 读取请求内容阶段，nginx读取并解析完请求头之后就立即开始运行；例如模块 ngx_realip 就在 post-read 阶段注册了处理程序，它的功能是迫使 Nginx 认为当前请求的来源地址是指定的某一个请求头的值。
> 
> 2、server-rewrite
> server请求地址重写阶段；当ngx_rewrite模块的set配置指令直接书写在server配置块中时，基本上都是运行在server-rewrite 阶段
> 
> 3、find-config
> 配置查找阶段，这个阶段并不支持Nginx模块注册处理程序，而是由Nginx核心来完成当前请求与location配置块之间的配对工作。
<!-- more -->
> 4、rewrite
> location请求地址重写阶段，当ngx_rewrite指令用于location中，就是再这个阶段运行的；另外ngx_set_misc(设置md5、encode_base64等)模块的指令，还有ngx_lua模块的set_by_lua指令和rewrite_by_lua指令也在此阶段。

> 5、post-rewrite
> 请求地址重写提交阶段，当nginx完成rewrite阶段所要求的内部跳转动作，如果rewrite阶段有这个要求的话；
> 
> 6、preaccess
> 访问权限检查准备阶段，ngx_limit_req和ngx_limit_zone在这个阶段运行，ngx_limit_req可以控制请求的访问频率，ngx_limit_zone可以控制访问的并发度；
> 
> 7、access
> 访问权限检查阶段，标准模块ngx_access、第三方模块ngx_auth_request以及第三方模块ngx_lua的access_by_lua指令就运行在这个阶段。配置指令多是执行访问控制相关的任务，如检查用户的访问权限，检查用户的来源IP是否合法；
> 
> 8、post-access
> 访问权限检查提交阶段；主要用于配合access阶段实现标准ngx_http_core模块提供的配置指令satisfy的功能。satisfy all(与关系),satisfy any(或关系)
> 
> 9、try-files
> 配置项try_files处理阶段；专门用于实现标准配置指令try_files的功能,如果前 N-1 个参数所对应的文件系统对象都不存在，try-files 阶段就会立即发起“内部跳转”到最后一个参数(即第 N 个参数)所指定的URI.
> 
> 10、content
> 内容产生阶段，是所有请求处理阶段中最为重要的阶段，因为这个阶段的指令通常是用来生成HTTP响应内容并输出 HTTP 响应的使命；
> 
> 11、log
> 日志模块处理阶段；记录日志


###  二、Nginx下Lua处理阶段与使用范围：

```bash
init_by_lua            http
set_by_lua             server, server if, location, location if
rewrite_by_lua         http, server, location, location if
access_by_lua          http, server, location, location if
content_by_lua         location, location if
header_filter_by_lua   http, server, location, location if
body_filter_by_lua     http, server, location, location if
log_by_lua             http, server, location, location if
timer
```

> init_by_lua:
> 在nginx重新加载配置文件时，运行里面lua脚本，常用于全局变量的申请。
> 例如lua_shared_dict共享内存的申请，只有当nginx重起后，共享内存数据才清空，这常用于统计。
> 
> set_by_lua:
> 设置一个变量，常用与计算一个逻辑，然后返回结果
> 该阶段不能运行Output API、Control API、Subrequest API、Cosocket API
> 
> rewrite_by_lua:
> 在access阶段前运行，主要用于rewrite
> 
> access_by_lua:
> 主要用于访问控制，能收集到大部分变量，类似status需要在log阶段才有。
> 这条指令运行于nginx access阶段的末尾，因此总是在 allow 和 deny 这样的指令之后运行，虽然它们同属 access 阶段。
> 
> content_by_lua:
> 阶段是所有请求处理阶段中最为重要的一个，运行在这个阶段的配置指令一般都肩负着生成内容(content)并输出HTTP响应。
> 
> header_filter_by_lua:
> 一般只用于设置Cookie和Headers等
> 该阶段不能运行Output API、Control API、Subrequest API、Cosocket API
> 
> body_filter_by_lua:
> 一般会在一次请求中被调用多次, 因为这是实现基于 HTTP 1.1 chunked 编码的所谓“流式输出”的。
> 该阶段不能运行Output API、Control API、Subrequest API、Cosocket API
> 
> log_by_lua:
> 该阶段总是运行在请求结束的时候，用于请求的后续操作，如在共享内存中进行统计数据,如果要高精确的数据统计，应该使用body_filter_by_lua。
> 该阶段不能运行Output API、Control API、Subrequest API、Cosocket API
> 
> timer:


### 三、ngx_lua运行指令

ngx_lua属于nginx的一部分，它的执行指令都包含在nginx的11个步骤之中了，不过ngx_lua并不是所有阶段都会运行的；

1、init_by_lua、init_by_lua_file
语法：init_by_lua <lua-script-str>
语境：http
阶段：loading-config
当nginx master进程在加载nginx配置文件时运行指定的lua脚本，通常用来注册lua的全局变量或在服务器启动时预加载lua模块：
init_by_lua 'cjson = require "cjson"';
```bash
server {
    location = /api {
        content_by_lua '
            ngx.say(cjson.encode({dog = 5, cat = 6}))
        '
    }
}
```
或者初始化lua_shared_dict共享数据：
```bash
lua_shared_dict dogs 1m;
init_by_lua '
    local dogs = ngx.shared.dogs;
    dogs:set("Tom", 50)
'
server {
    location = /api {
        content_by_lua '
            local dogs = ngx.shared.dogs;
            ngx.say(dogs:get("Tom"))
        '
    }
}
```
但是，lua_shared_dict的内容不会在nginx reload时被清除。所以如果你不想在你的init_by_lua中重新初始化共享数据，那么你需要在你的共享内存中设置一个标志位并在init_by_lua中进行检查。
因为这个阶段的lua代码是在nginx forks出任何worker进程之前运行，数据和代码的加载将享受由操作系统提供的copy-on-write的特性，从而节约了大量的内存。
不要在这个阶段初始化你的私有lua全局变量，因为使用lua全局变量会照成性能损失，并且可能导致全局命名空间被污染。
这个阶段只支持一些小的LUA Nginx API设置：ngx.log和print、ngx.shared.DICT；

2、init_worker_by_lua、init_worker_by_lua_file
语法：init_worker_by_lua <lua-script-str>
语境：http
阶段：starting-worker
在每个nginx worker进程启动时调用指定的lua代码。如果master 进程不允许，则只会在init_by_lua之后调用。

这个hook通常用来创建每个工作进程的计时器(通过lua的ngx.timer API)，进行后端健康检查或者其它日常工作：
```bash
init_worker_by_lua:
    local delay = 3  -- in seconds
    local new_timer = ngx.timer.at
    local log = ngx.log
    local ERR = ngx.ERR
    local check
    check = function(premature)
        if not premature then
            -- do the health check other routine work
            local ok, err = new_timer(delay, check)
            if not ok then
                log(ERR, "failed to create timer: ", err)
                return
            end
        end
    end
    local ok, err = new_timer(delay, check)
    if not ok then
        log(ERR, "failed to create timer: ", err)
    end
```
3、set_by_lua、set_by_lua_file
语法：set_by_lua $res <lua-script-str> [$arg1 $arg2 …]
语境：server、server if、location、location if
阶段：rewrite
传入参数到指定的lua脚本代码中执行，并得到返回值到res中。<lua-script-str>中的代码可以使从ngx.arg表中取得输入参数(顺序索引从1开始)。

这个指令是为了执行短期、快速运行的代码因为运行过程中nginx的事件处理循环是处于阻塞状态的。耗费时间的代码应该被避免。
禁止在这个阶段使用下面的API：1、output api(ngx.say和ngx.send_headers)；2、control api(ngx.exit)；3、subrequest api(ngx.location.capture和ngx.location.capture_multi)；4、cosocket api(ngx.socket.tcp和ngx.req.socket)；5、sleep api(ngx.sleep)

此外注意，这个指令只能一次写出一个nginx变量，但是使用ngx.var接口可以解决这个问题：
```bash
location /foo {
    set $diff '';
    set_by_lua $num '
        local a = 32
        local b = 56
        ngx.var.diff = a - b; --写入$diff中
        return a + b;  --返回到$sum中
    '
    echo "sum = $sum, diff = $diff";
}
```
这个指令可以自由的使用HttpRewriteModule、HttpSetMiscModule和HttpArrayVarModule所有的方法。所有的这些指令都将按他们出现在配置文件中的顺序进行执行。

4、rewrite_by_lua、rewrite_by_lua_file
语法：rewrite_by_lua <lua-script-str>
语境：http、server、location、location if
阶段：rewrite tail
作为rewrite阶段的处理，为每个请求执行指定的lua代码。注意这个处理是在标准HtpRewriteModule之后进行的：
```bash
location /foo {
    set $a 12;
    set $b "";
    rewrite_by_lua 'ngx.var.b = tonumber(ngx.var.a) + 1';
    echo "res = $b";
}
```
如果这样的话将不会按预期进行工作：
```bash
location /foo {
    set $a 12;
    set $b '';
    rewrite_by_lua 'ngx.var.b = tonumber(ngx.var.a) + 1';
    if($b = '13') {
        rewrite ^ /bar redirect;
        break;
    }
    echo "res = $b"
}
```
因为if会在rewrite_by_lua之前运行，所以判断将不成立。正确的写法应该是这样：
```bash
location /foo {
    set $a 12;
    set $b '';
    rewrite_by_lua '
        ngx.var.b = tonumber(ngx.var.a) + 1
        if tonumber(ngx.var.b) == 13 then
            return ngx.redirect("/bar");
        end
    '
    echo "res = $b";
}
```
注意ngx_eval模块可以近似于使用rewite_by_lua，例如：
```bash
location / {
    eval $res {
        proxy_pass http://foo,com/check-spam;
    }
    if($res = 'spam') {
        rewrite ^ /terms-of-use.html redirect;
    }
    fastcgi_pass .......
}
```
可以被ngx_lua这样实现：
```bash
location = /check-spam {
    internal;
    proxy_pass http://foo.com/check-spam;
}

location / {
    rewrite_by_lua '
        local res = ngx.location.capture("/check-spam")
        if res.body == "spam" then
            return ngx.redirect("terms-of-use.html")
    '
    fastcgi_pass .......
}
```
和其它的rewrite阶段的处理程序一样，rewrite_by_lua在subrequests中一样可以运行。

请注意在rewrite_by_lua内调用ngx.exit(ngx.OK)，nginx的请求处理流程将继续进行content阶段的处理。从rewrite_by_lua终止当前的请求，要调用ngx.exit返回status大于200并小于300的成功状态或ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)的失败状态。
如果HttpRewriteModule的重写指令被用来改写URI和重定向，那么任何rewrite_by_lua和rewrite_by_lua_file的代码将不会执行，例如：
```bash
location /foo {
    rewrite ^ /bar;
    rewrite_by_lua 'ngx.exit(503)'
}
location /bar {
    .......
}
```
在这个例子中ngx.exit(503)将永远不会被执行，因为rewrite修改了location，请求已经跳入其它location中了。

5、access_by_lua，access_by_lua_file
语法：access_by_lua <lua-script-str>
语境：http,server,location,location if
阶段：access tail
为每个请求在访问阶段的调用lua脚本进行处理。主要用于访问控制，能收集到大部分的变量。

注意access_by_lua和rewrite_by_lua类似是在标准HttpAccessModule之后才会运行，看一个例子：
```bash
location / {
    deny 192.168.1.1;
    allow 192.168.1.0/24;
    allow 10.1.1.0/16;
    deny all;
    access_by_lua '
        local res = ngx.location.capture("/mysql", {...})
        ....
    '
}
```
如果client ip在黑名单之内，那么这次连接会在进入access_by_lua调用的mysql之前被丢弃掉。

ngx_auth_request模块和access_by_lua的用法类似：

```bash
location / {
    auth_request /auth;
}
```
可以用ngx_lua这么实现：
```bash
location / {
    access_by_lua '
        local res = ngx.location.capture("/auth")
        if res.status == ngx.HTTP_OK then
            return
        end
        if res.status == ngx.HTTP_FORBIDDEN then
            ngx.exit(res.status)
        end
        ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
    '
}
```
和其它access阶段的模块一样，access_by_lua不会在subrequest中运行。
请注意在access_by_lua内调用ngx.exit(ngx.OK)，nginx的请求处理流程将继续进行后面阶段的处理。从rewrite_by_lua终止当前的请求，要调用ngx.exit返回status大于200并小于300的成功状态或ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)的失败状态。

6、content_by_lua，content_by_lua_file
语法：content_by_lua <lua-script-str>
语境：location，location if
阶段：content
作为"content handler"为每个请求执行lua代码，为请求者输出响应内容。

不要将它和其它的内容处理指令在同一个location内使用如proxy_pass。

7、header_filter_by_lua，header_filter_by_lua_file
语法：header_filter_by_lua <lua-script-str>
语境：http，server，location，location if
阶段：output-header-filter

一般用来设置cookie和headers，在该阶段不能使用如下几个API：
1、output API(ngx.say和ngx.send_headers)
2、control API(ngx.exit和ngx.exec)
3、subrequest API(ngx.location.capture和ngx.location.capture_multi)
4、cosocket API(ngx.socket.tcp和ngx.req.socket)

有一个例子是 在你的lua header filter里添加一个响应头标头：
```bash
location / {
    proxy_pass http://mybackend;
    header_filter_by_lua 'ngx.header.Foo = "blah"';
}
```
8、body_filter_by_lua，body_filter_by_lua_file
语法：body_filter_by_lua <lua-script-str>
语境：http，server，location，location if
阶段：output-body-filter
输入的数据时通过ngx.arg[1](作为lua的string值)，通过ngx.arg[2]这个bool类型表示响应数据流的结尾。

基于这个原因，'eof'只是nginx的链接缓冲区的last_buf(对主requests)或last_in_chain(对subrequests)的标记。
运行以下命令可以立即终止运行接下来的lua代码：
return ngx.ERROR
这会将响应体截断导致无效的响应。lua代码可以通过修改ngx.arg[1]的内容将数据传输到下游的nginx output body filter阶段的其它模块中去。例如，将response body中的小写字母进行反转，我们可以这么写：
```bash
location / {
    proxy_pass http://mybackend;
    body_filter_by_lua 'ngx.arg[1] = string.upper(ngx.arg[1])'
}
```
当将ngx.arg[1]设置为nil或者一个空的lua string时，下游的模块将不会收到数据了。

同样可以通过修改ngx.arg[2]来设置新的”eof“标记，例如：
```bash
location /t {
    echo hello world;
    echo hiya globe;
    body_filter_by_lua '
        local chunk = ngx.arg[1]
        if string.match(chunk, "hello") then
            ngx.arg[2] = true --new eof
            return
        end
        --just throw away any remaining chunk data
        ngx.arg[1] = nil
    '
}
```
那么GET /t的请求只会回复：hello world

这是因为，当body filter看到了一块包含”hello“的字符块后立即将”eof“标记设置为了true，从而导致响应被截断了但仍然是有效的回复。
当lua代码中改变了响应体的长度时，应该要清除content-length响应头部的值，例如：
```bash
location /foo {
    header_filter_by_lua 'ngx.header.content_length = nil'
    body_filter_by_lua 'ngx.arg[1] = string.len(ngx.arg[1]) .. "\\n"'
}
```
在该阶段不能使用如下几个API：
1、output API(ngx.say和ngx.send_headers)
2、control API(ngx.exit和ngx.exec)
3、subrequest API(ngx.location.capture和ngx.location.capture_multi)
4、cosocket API(ngx.socket.tcp和ngx.req.socket)
nginx output filters可能会在一次请求中被多次调用，因为响应体可能是以chunks方式传输的。因此这个指令一般会在一次请求中被调用多次。

9、log_by_lua，log_by_lua_file
语法：log_by_lua <lua-script-str>
语境：http，server，location，location if
阶段：log
在log阶段调用指定的lua脚本，并不会替换access log，而是在那之后进行调用。

在该阶段不能使用如下几个API：
1、output API(ngx.say和ngx.send_headers)
2、control API(ngx.exit和ngx.exec)
3、subrequest API(ngx.location.capture和ngx.location.capture_multi)
4、cosocket API(ngx.socket.tcp和ngx.req.socket)

一个收集upstream_response_time的平均数据的例子：
```bash
lua_shared_dict log_dict 5M

server{
    location / {
        proxy_pass http;//mybackend
        log_by_lua '
            local log_dict = ngx.shared.log_dict
            local upstream_time = tonumber(ngx.var.upstream_response_time)
            local sum = log_dict:get("upstream_time-sum") or 0
            sum = sum + upstream_time
            log_dict:set("upsteam_time-sum", sum)
            local newval, err = log_dict:incr("upstream_time-nb", 1)
            if not newval and err == "not found" then
                log_dict:add("upstream_time-nb", 0)
                log_dict:incr("upstream_time-nb", 1)
            end
        '
    }
    location = /status {
        content_by_lua '
            local log_dict = ngx.shared.log_dict
            local sum = log_dict:get("upstream_time-sum")
            local nb = log_dict:get("upstream_time-nb")

            if nb and sum then
                ngx.say("average upstream response time:  ", sum/nb, " (", nb, " reqs)")
            else
                ngx.say("no data yet")
            end
        '
    }
}
```