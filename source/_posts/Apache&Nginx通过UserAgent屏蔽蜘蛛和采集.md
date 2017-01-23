---
title: Apache/Nginx通过UserAgent屏蔽蜘蛛和采集
tags:
  - Nginx
  - Apache
  - Linux
categories: Nginx
abbrlink: 5492
date: 2016-07-19 09:00:00
updated:
toc_number:
---

正规的搜索引擎的蜘蛛爬行我们的网站对于网站来说是有利的，但垃圾爬虫我们就需要屏蔽掉它们的访问，因为它们有的是人为来采集我们网站内容的，有的是SEO以及其他工具索引我们的网站数据建库进行分析的。它们不仅对网站内容不利，而且对于网站服务器也是一种负担。

即便bot支持,但实际情况是robots.txt 根本无法阻止那些垃圾蜘蛛的，好在垃圾爬虫基本上还是有一定特征的，比如可以根据UA分析。即可使用少量代码屏蔽掉。不过，如果UA伪造或UA变化等其他情况，可使用crontab对日志里面IP频率进行分析和屏蔽了。

### Apache

- 通过修改.htaccess文件

修改网站目录下.htaccess文件，添加如下代码即可(二种代码任选其一)。

**方法一**

```
RewriteEngine On
RewriteCond %{HTTP_USER_AGENT} (^$|FeedDemon|Indy Library|Alexa Toolbar|AskTbFXTV|AhrefsBot|CrawlDaddy|CoolpadWebkit|Java|Feedly|UniversalFeedParser|ApacheBench|Microsoft URL Control|Swiftbot|ZmEu|oBot|jaunty|Python-urllib|lightDeckReports Bot|YYSpider|DigExt|HttpClient|MJ12bot|heritrix|EasouSpider|Ezooms) [NC]
RewriteRule ^(.*)$ - [F]
```
<!-- more -->

**方法二 **

```
SetEnvIfNoCase ^User-Agent$ .*(FeedDemon|Indy Library|Alexa Toolbar|AskTbFXTV|AhrefsBot|CrawlDaddy|CoolpadWebkit|Java|Feedly|UniversalFeedParser|ApacheBench|Microsoft URL Control|Swiftbot|ZmEu|oBot|jaunty|Python-urllib|lightDeckReports Bot|YYSpider|DigExt|HttpClient|MJ12bot|heritrix|EasouSpider|Ezooms) BADBOT
Order Allow,Deny
Allow from all
Deny from env=BADBOT
```

- 通过修改httpd.conf配置文件

找到如下类似位置，根据以下代码新增/修改，然后重启Apache即可。

**方法一**

```
DocumentRoot /var/www/html
<Directory "/var/www/html">
SetEnvIfNoCase User-Agent ".*(FeedDemon|Indy Library|Alexa Toolbar|AskTbFXTV|AhrefsBot|CrawlDaddy|CoolpadWebkit|Java|Feedly|UniversalFeedParser|ApacheBench|Microsoft URL Control|Swiftbot|ZmEu|oBot|jaunty|Python-urllib|lightDeckReports Bot|YYSpider|DigExt|HttpClient|MJ12bot|heritrix|EasouSpider|Ezooms)" BADBOT
        Order allow,deny
        Allow from all
        Deny from env=BADBOT
</Directory>
```

**方法二**

根据UA,REFERER禁止爬虫，[G]返回410页面，[F]返回403页面。

```
<IfModule mod_rewrite.c>
 RewriteCond %{HTTP_USER_AGENT} (wget|curl|AhrefsBot|DotBot|MJ12bot|httrack|Findxbot|BLEXBot|WinHttpRequest|Go\s1.1\spackage\shttp|megaindex|BIDUBrowser|FunWebProducts|MSIE\s5|Add\sCatalog|SeznamBot|KomodiaBot|aiHitBot|MojeekBot|PhantomJS|SiteSucker|HTTrack|MegaIndex|BLEXBot|LinkpadBot|Findxbot|SEOkicks|OpenLinkProfiler|PhantomJS|Xenu|007ac9|sistrix|spbot|SiteExplorer|wotbox|ZumBot|ltx71|memoryBot|WBSearchBot|DomainAppender|Python|Aboundex|-crawler|WinHttpRequest|NerdyBot|ZmEu|xovibot) [NC,OR]
 RewriteCond %{HTTP_USER_AGENT} ^$ [NC,OR] 
 RewriteCond %{HTTP_USER_AGENT} ^-$ [NC,OR]
 RewriteCond %{HTTP_REFERER} .ru/$ [NC,OR]
 RewriteCond %{HTTP_REFERER} (example.com) [NC]
 RewriteRule .* - [G]
</IfModule>
```

### Nginx

进入到Nginx配置目录下(默认为/etc/nginx/conf.d目录)，将如下代码保存为agent_deny.conf

```
$ cd /etc/nginx/conf.d
$ vi agent_deny.conf


#禁止Scrapy等工具的抓取
if ($http_user_agent ~* (Scrapy|Curl|HttpClient)) {
     return 403;
}

#禁止指定UA及UA为空的访问
if ($http_user_agent ~* "WinHttp|WebZIP|FetchURL|node-superagent|java/|FeedDemon|Jullo|JikeSpider|Indy Library|Alexa Toolbar|AskTbFXTV|AhrefsBot|CrawlDaddy|Java|Feedly|Apache-HttpAsyncClient|UniversalFeedParser|ApacheBench|Microsoft URL Control|Swiftbot|ZmEu|oBot|jaunty|Python-urllib|lightDeckReports Bot|YYSpider|DigExt|HttpClient|MJ12bot|heritrix|EasouSpider|Ezooms|BOT/0.1|YandexBot|FlightDeckReports|Linguee Bot|^$" ) {
     return 403;             
}

#禁止非GET|HEAD|POST方式的抓取
if ($request_method !~ ^(GET|HEAD|POST)$) {
    return 403;
}
```

然后，在网站相关配置中的server段插入如下代码

```
include agent_deny.conf;
```

保存后，执行如下命令，平滑重启nginx即可

```
/etc/init.d/nginx reload
```

注：这里介绍的是通过判断UserAgent的方法进行限制，Nginx还可以通过`ngx_http_limit_conn_module`和`ngx_http_limit_req_module`模块来进行访问限制，在以后的文档中会进行这种方法的介绍。

### PHP

将如下方法放到贴到网站入口文件index.php中的第一个`<?php`之后即可

```
//获取UA信息
$ua = $_SERVER['HTTP_USER_AGENT'];
//将恶意USER_AGENT存入数组
$now_ua = array('FeedDemon ','BOT/0.1 (BOT for JCE)','CrawlDaddy ','Java','Feedly','UniversalFeedParser','ApacheBench','Swiftbot','ZmEu','Indy Library','oBot','jaunty','YandexBot','AhrefsBot','MJ12bot','WinHttp','EasouSpider','HttpClient','Microsoft URL Control','YYSpider','jaunty','Python-urllib','lightDeckReports Bot');
//禁止空USER_AGENT，dedecms等主流采集程序都是空USER_AGENT，部分sql注入工具也是空USER_AGENT
if(!$ua) {
header("Content-type: text/html; charset=utf-8");
wp_die('请勿采集本站，因为采集的站长木有小JJ！');
}else{
    foreach($now_ua as $value )
//判断是否是数组中存在的UA
    if(eregi($value,$ua)) {
    header("Content-type: text/html; charset=utf-8");
    wp_die('请勿采集本站，因为采集的站长木有小JJ！');
    }
}
```

### 附录：UA收集

#### 常见搜索引擎爬虫的User-Agent

百度爬虫

- Baiduspider+(+http://www.baidu.com/search/spider.htm”)

Google爬虫

- Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)
- Googlebot/2.1 (+http://www.googlebot.com/bot.html)
- Googlebot/2.1 (+http://www.google.com/bot.html)

雅虎爬虫(分别是雅虎中国和美国总部的爬虫)

- Mozilla/5.0 (compatible; Yahoo! Slurp China; http://misc.yahoo.com.cn/help.html”)
- Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp”)

新浪爱问爬虫

- iaskspider/2.0(+http://iask.com/help/help_index.html”)
- Mozilla/5.0 (compatible; iaskspider/1.0; MSIE 6.0)

搜狗爬虫

- Sogou web spider/3.0(+http://www.sogou.com/docs/help/webmasters.htm#07″)
- Sogou Push Spider/3.0(+http://www.sogou.com/docs/help/webmasters.htm#07″)

网易爬虫

- Mozilla/5.0 (compatible; YodaoBot/1.0; http://www.yodao.com/help/webmaster/spider/”; )

MSN爬虫

- msnbot/1.0 (+http://search.msn.com/msnbot.htm”)


#### 网络上常见的垃圾UA列表

内容采集

- FeedDemon				
- Java                  内容采集
- Jullo                 内容采集
- Feedly                内容采集
- UniversalFeedParser   内容采集

SQL注入

- BOT/0.1 (BOT for JCE) 
- CrawlDaddy      

无用爬虫      

- EasouSpider           
- Swiftbot              
- YandexBot             
- AhrefsBot             
- jikeSpider            
- MJ12bot               
- YYSpider              
- oBot                  

CC攻击器

- ApacheBench           
- WinHttp               

TCP攻击

- HttpClient            

扫描

- Microsoft URL Control 
- ZmEu phpmyadmin       
- jaunty                

### 参考文档

http://www.google.com
http://zhangge.net/4458.html
https://seonoco.com/apache-nginx-shielded-spider-and-collection