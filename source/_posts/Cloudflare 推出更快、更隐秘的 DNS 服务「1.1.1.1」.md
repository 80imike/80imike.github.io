---
category: DNS
title: Cloudflare 推出更快、更隐秘的 DNS 服务「1.1.1.1」
date: 2018-04-04 09:00:00
tags: [Linux, DNS]
abbrlink:
updated:
toc_number: false
---

在这个网络隐私愈来愈被重视的时代，却有一个窥视你浏览习惯的重要来源，是被大家所忽视的，也就是「DNS」。DNS 的工作是将「域名」与「IP 位置」相对应，它是互联网的重要组成部分。

在解析的过程当中，DNS 服务器是可以看到你要前往的网站、你的 IP、你的 ISP 等信息。如果 DNS 提供商有不良意图，是可以收集不少关于你的使用习惯、地理位置等内容的。国内 ISP 提供的 DNS 通常速度慢且不可靠，甚至还会出现故意劫持 DNS 请求以牟利的事件发生。

4 月 1 日，全球顶级 CDN 提供商 Cloudflare 宣布其正式推出公共 DNS 服务。Cloudflare 与 APNIC 合作通过 1.1.1.1 和 1.0.0.1 两个 IP 提供 DNS 服务，用户可以使用它来加快互联网访问速度，同时保持连接的私密性。

Cloudflare 表示他们的目标是希望 1.1.1.1 能够成为全世界最快的 DNS 公共服务。Cloudflare 的 DNS 支持 DNS-over-TLS 和 DNS-over-HTTPS，全球平均响应时间为 14ms，而 OpenDNS 为 20ms，Google 的 DNS 为 34ms。

Cloudfare DNS 承诺在其内部每 24 小时就清除 DNS 查询日志一次，保障了用户的稳私和安全性。

<!-- more -->

Cloudflare 推出的公共 DNS 服务完全免费，如果您有兴趣启用 Cloudflare 的新 DNS，可以在其官主网站 `https://1.1.1.1` 找到各平台详细的配置说明。

Cloudflare DNS 不仅支持 IPv4，也支持 IPv6 。其地址如下：

```
For IPv4: 1.1.1.1,1.0.0.1
For IPv6: 2001:2001::,2001:2001:2001::
```

**全球各大公共 DNS 性能比较**

这里选择目前综合性能前 8 位免费 DNS 提供商来进行测试，下表为各 DNS 提供商的 IP 和其提供的功能：


DNS 服务商| DNS 对应的IP | DNS 提供的功能
---------|----------|---------
 Google | 8.8.8.8 | 私有和未过滤，目前最受欢迎。
 CloudFlare | 1.1.1.1 | 私有和未过滤的新玩家。
 Quad | 9 9.9.9.9 | 私有和安全意识很高的新玩家。
 OpenDNS | 208.67.222.222 | 阻止恶意网域并提供阻止成人内容。
 Norton DNS | 199.85.126.20 | 阻止恶意域名并与其防病毒软件集成。
 CleanBrowsing| 185.228.168.168 | 私有和阻止访问成人内容。
 Yandex DNS | 77.88.8.7 | 阻止恶意域名，在俄罗斯非常受欢迎。
 Comodo DNS| 8.26.56.26 | 阻止恶意域名。

各提供商的提供功能对比表如下：

![](https://www.hi-linux.com/img/linux/Cloudflaredns1.png)

经过测试后，CloudFlare 的服务平均速度最快。全球平均响应速度仅仅为 4.98 ms，Google 和 Quad9 位居第二和第三。Quad9 在北美和欧洲比 Google 快，但在亚洲和南美比较慢；Yandex 只在俄罗斯比较快，其它地方都很慢。

全球平均

```
＃1 CloudFlare：4.98 ms 
＃2 Google：16.44 ms 
＃3 Quad9：18.25 ms 
＃4 CleanBrowsing：19.14 ms 
＃5 Norton：34.75 ms 
＃6 OpenDNS：46.51 ms 
＃7 Comodo：71.90 
＃8 Yandex：169.91
```

北美平均水平

```
＃1 CloudFlare：3.93 ms 
＃2 Quad9：7.21 ms 
＃3 Norton：8.32 ms 
＃4 Google：8.53 ms 
＃5 CleanBrowsing：11.83 ms 
＃6 OpenDNS：14.66 ms 
＃7 Comodo：25.91 ms 
＃8 Yandex：119.09 ms
```

欧洲平均

```
＃1 CloudFlare：2.96 
＃2 Quad9：4.35 
＃3 CleanBrowsing：5.74 
＃4 Google：7.17 
＃5 OpenDNS：8.99 
＃6 Norton：10.35 
＃7 Comodo：13.06 
＃8 Yandex：35.74
```

**其它一些好记的公共 DNS 服务**

```
1.1.1.1 – APNIC 亚太互联网络信息中心
2.2.2.2 – 法国电信 / Orange
3.3.3.3 – 通用电气
4.4.4.4 – Level3 通信
5.5.5.5 – E-Plus (德国第三大的手机运营商)
6.6.6.6 – 美国陆军
7.7.7.7 – 美国国防部
8.8.8.8 – 谷歌
9.9.9.9 – IBM
```
> 实际测试 3.3.3.3 和 6.6.6.6 目前不可用。

### 参考文档

http://www.google.com
http://t.cn/RmPEZdK
http://t.cn/RnsZByp