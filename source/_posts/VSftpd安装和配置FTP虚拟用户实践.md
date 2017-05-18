---
title: VSftpd安装和配置FTP虚拟用户实践
tags:
  - VSftpd
  - Linux
categories: VSftpd
abbrlink: 12477
date: 2016-07-25 09:00:00
updated:
toc_number:
---

VSftpd英文全称(Very Secure File Transfer Protocol Deamon)，正如VSftpd官方宣传中所说`Probably the most secure and fastest FTP server for UNIX-like systems`。我相信这是大多数人选择VSftpd来搭建Linux的FTP服务器的原因，当然ProFTPD用的人应该也不在少数。本文将以清晰直观的方式介绍安装VSftpd以及配置FTP虚拟用户的过程，希望对大家有帮助。


### 安装VSftpd及相关组件

```
$ yum -y install vsftpd* pam* db4* ftp
```

### 修改FTP相关帐户

- VSftpd服务的宿主用户

```
$ useradd vsftpd -s /sbin/nologin
```

默认的VSftpd的服务宿主用户是root，但是这不符合安全性的需要。这里建立名字为vsftpd的用户，用他来作为支持VSftpd的服务宿主用户。由于该用户仅用来支持VSftpd服务用，因此没有许可他登陆系统的必要，并设定他为不能登陆系统的用户。

<!-- more -->


- VSftpd的虚拟宿主用户

```
$ useradd virtual -d /home/ftpdata/ -s /sbin/nologin
$ chown -R virtual:virtual /home/ftpdata/
```

VSftpd的虚拟用户并不是系统用户，也就是说这些FTP的用户在系统中是不存在的。他们的总体权限其实是集中寄托在一个在系统中的某一个用户身上的，所谓VSftpd的虚拟宿主用户，就是这样一个支持着所有虚拟用户的宿主用户。由于他支撑了FTP的所有虚拟的用户，那么他本身的权限将会影响着这些虚拟的用户，因此出于安全性的考虑，也要非常注意对该用户的权限的控制，该用户也绝对没有登陆系统的必要，这里也设定他为不能登陆系统的用户。

### vsftpd.conf基本配置

- 一些基本配置选项说明

```
anonymous_enable=YES|NO 
控制是否允许匿名用户登录，YES允许，NO不允许，默认值为YES。 

ftp_username= username
匿名用户所使用的系统用户名。默认下，此参数在配置文件中不出现，值为ftp

no_anon_password=YES|NO 
控制匿名用户登入时是否需要密码，YES不需要，NO需要。默认值为NO。 

anon_root=path
设定匿名用户的根目录，即匿名用户登入后，被定位到此目录下。主配置文件中默认无此项，默认值为/var/ftp/。 

anon_world_readable_only=YES|NO
控制是否只允许匿名用户下载可阅读文档。YES，只允许匿名用户下载可阅读的文件。NO，允许匿名用户浏览整个服务器的文件系统。默认值为YES。 

anon_upload_enable=YES|NO 
控制是否允许匿名用户上传文件，YES允许，NO不允许，默认是不设值，即为NO。除了这个参数外，匿名用户要能上传文件，还需要两个条件：一，write_enable参数为YES;二，在文件系统上，FTP匿名用户对某个目录有写权限。 
anon_mkdir_write_enable=YES|NO 
控制是否允许匿名用户创建新目录，YES允许，NO不允许，默认是不设值，即为NO。当然在文件系统上，FTP匿名用户必需对新目录的上层目录拥有写权限。 

anon_other_write_enable=YES|NO 
控制匿名用户是否拥有除了上传和新建目录之外的其他权限，如删除、更名等。YES拥有，NO不拥有，默认值为NO。 

chown_uploads=YES|NO 
是否修改匿名用户所上传文件的所有权。YES，匿名用户所上传的文件的所有权将改为另外一个不同的用户所有，用户由chown_username参数指定。此选项默认值为NO。 

chown_username=whoever
指定拥有匿名用户上传文件所有权的用户

local_enable=YES|NO 
控制vsftpd所在的系统的用户是否可以登录vsftpd。默认值为YES。 

local_root= 
定义所有本地用户的根目录。当本地用户登入时，将被更换到此目录下。默认值为无。 

user_config_dir= 
定义用户个人配置文件所在的目录。用户的个人配置文件为该目录下的同名文件

chroot_list_enable=YES|NO 
锁定某些用户在自家目录中。即当这些用户登录后，不可以转到系统的其他目录，只能在自家目录(及其子目录)下。具体的用户在chroot_list_file参数所指定的文件中列出。默认值为NO。 

chroot_list_file=/etc/vsftpd/chroot_list 
指出被锁定在自家目录中的用户的列表文件。文件格式为一行一用户。通常该文件是/etc/vsftpd/chroot_list。此选项默认不设置。 

chroot_local_users=YES|NO 
将本地用户锁定在自家目录中。当此项被激活时，chroot_list_enable和chroot_local_users参数的作用将发生变化，chroot_list_file所指定文件中的用户将不被锁定在自家目录。本参数被激活后，可能带来安全上的冲突，特别是当用户拥有上传、shell访问等权限时。因此，只有在确实了解的情况下，才可以打开此参数。默认值为NO。 

passwd_chroot_enable =YES|NO
当此选项激活时，与chroot_local_user选项配合，chroot()容器的位置可以在每个用户的基础上指定。每个用户的容器来源于/etc/passwd中每个用户的自家目录字段。默认值为NO。

listen_address=ip address 
定义了在主机的哪个IP地址上监听FTP请求

listen_port=port_value  
指定FTP服务器监听的端口号(控制端口)，默认值为21。此选项在standalone模式下生效

port_enable=YES|NO
指定数据连接时模式，默认值为YES（PORT模式，NO为PASV模式）

connect_from_port_20=YES|NO
控制以PORT模式进行数据传输时是否使用20端口(ftp-data）

ftp_data_port=port number 
设定ftp数据传输端口(ftp-data)值。默认值为20。此参数用于PORT FTP模式。 

pasv_enable=YES|NO
YES，允许数据传输时使用PASV模式。NO，不允许使用PASV模式。默认值为YES。

pasv_min_port=port number
pasv_max_port=port number
设定在PASV模式下，建立数据传输所可以使用port范围的下界和上界，0 表    示任意。默认值为0。把端口范围设在比较高的一段范围内，比如50000-60000，将有助于安全性的提高

pasv_address= ip address
此选项为一个数字IP地址，作为PASV命令的响应。默认值为none，即地址是从呼入的连接套接字(incoming connectd socket)中获取。

ascii_upload_enable=YES|NO
控制是否允许使用ascii模式上传文件，YES允许，NO不允许，默认为NO 

ascii_download_enable=YES|NO
控制是否允许使用ascii模式下载文件，YES允许，NO不允许，默认为NO。

idle_session_timeout= numerical value
空闲用户会话的超时时间，若是超出这时间没有数据的传送或是指令的输入，则会强迫断线。单位为秒，默认值为300。

data_connection_timeout= numerical value
空闲的数据连接的超时时间。默认值为300 秒。

accept_timeout=numerical value 
接受建立联机的超时设定，单位为秒。默认值为60。

connect_timeout=numerical value
响应PORT方式的数据联机的超时设定，单位为秒。默认值为60

max_clients=numerical value 
此参数在VSFTPD使用单独(standalone)模式下有效。此参数定义了FTP服务器最大的并发连接数，当超过此连接数时，服务器拒绝客户端连接。默认值为0，表示不限最大连接数。

max_per_ip=numerical value 
此参数在VSFTPD使用单独(standalone)模式下有效。此参数定义每个IP地址最大的并发连接数目。超过这个数目将会拒绝连接。此选项的设置将影响到象网际快车这类的多进程下载软件。默认值为0，表示不限制。 

anon_max_rate=value 
设定匿名用户的最大数据传输速度value，以Bytes/s为单位。默认无。 

local_max_rate=value 
设定用户的最大数据传输速度value，以Bytes/s为单位。默认无。

write_enable=YES
设定允许进行写操作(上传、删除)，默认为YES，可选值【yes,no】

local_umask=022
设定权限掩码，默认022，对应的文件上传权限644、目录权限755

dirmessage_enable=YES
设定开启目录标语功能

xferlog_enable=YES
设定开启日志记录功能

xferlog_file=/var/log/ftp/vsftpd.log
设置日志目录

xferlog_std_format=YES
设定日志使用标准的记录格式

nopriv_user=vsftpd
设定支撑Vsftpd服务的宿主用户为手动建立的Vsftpd用户。注意，一旦做出更改宿主用户后，必须注意一起与该服务相关的读写文件的读写赋权问题。比如日志文件就必须给与该用户写入权限等。

async_abor_enable=YES
设定支持异步传输功能。

ftpd_banner=This Vsftp server supports virtual users ^_^
设定Vsftpd的登陆标语。

deny_email_enable=YES
可将某些特殊的 email address 抵挡住。如果以anonymous 登录服务器时，会要求输入密码，也就是您的email address, 如果很讨厌某些email address ，就可以使用此设定来取消他的登录权限，但必须与下面的设置项配合

banned_email_file=/etc/vsftpd/banned_emails
当上面的 deny_email_enable=YES 时，可以利用这个设定项来规定那个email address 不可登录vsftpd 服务器，此文件需用户自己创建，一行一个email address 即可！

ls_recurse_enable=YES
是否允许递归查询 ， 大型站点的 FTP 服务器启用此项可以方便远程用户查询

chroot_local_user=YES

listen=YES
如果设置为 YES ， 则 vsftpd 将以独立模式运行，由vsftpd 自己监听和处理连接请求

listen_ipv6=YES
设定是否支持IPV6

pam_service_name=vsftpd
设置 PAM 外挂模块提供的认证服务所使用的配置文件名 ，即/etc/pam.d/vsftpd 文件，此文件中file=/etc/vsftpd/ftpusers 字段，说明了PAM 模块能抵挡的帐号内容来自文件/etc/vsftpd/ftpusers 中

userlist_enable=YES/NO
此选项默认值为NO , 此时ftpusers 文件中的用户禁止登录FTP 服务器；若此项设为YES ，则 user_list 文件中的用户允许登录 FTP 服务器，而如果同时设置了 userlist_deny=YES ，则 user_list 文件中的用户将不允许登录FTP 服务器，甚至连输入密码提示信息都没有，直接被FTP 服务器拒绝

userlist_deny=YES/NO
此项默认为YES ，设置是否阻扯user_list 文件中的用户登录FTP 服务器

tcp_wrappers=YES
表明服务器使用 tcp_wrappers 作为主机访问控制方式，tcp_wrappers 可以实现linux 系统中网络服务的基于主机地址的访问控制，在/etc 目录中的hosts.allow 和hosts.deny 两个文件用于设置tcp_wrappers 的访问控制，前者设置允许访问记录，后者设置拒绝访问记录。例如想限制某些主机对FTP 服务器192.168.57.2 的匿名访问，编缉/etc/hosts.allow 文件，如在下面增加两行命令：vsftpd:192.168.57.1:DENY 和vsftpd:192.168.57.9:DENY 表明限制IP 为192.168.57.1/192.168.57.9 主机访问IP 为192.168.57.2 的FTP 服务器，此时FTP 服务器虽可以PING 通，但无法连接
```

- 关于userlist_enable、userlist_deny的设置，ftpusers和user_list文件的区别

> ftpusers：禁止user_list列表中的用户访问FTP
> userlist_enable=YES，userlist_deny=YES，禁止user_list列表中的用户访FTP
> userlist_enable=YES，userlist_deny=NO，只允许user_list列表中的用户FTP。
> userlist_enable=NO，userlist_deny=YES，因设定userlist_enable=NO，忽略user_list文件，user_list不启作用
> userlist_enable=NO，userlist_deny=NO，因设定userlist_enable=NO，忽略user_list文件，user_list不启作用
> ftpusers禁止的优先级更高。假设ftpusers禁止woodie用户访问，userlist允许woodie用户访问，则在运行时，用户woodie不能访问ftp。

- 配置范例


```
$ vim /etc/vsftpd/vsftpd.conf


# Example config file /etc/vsftpd/vsftpd.conf
#
# The default compiled in settings are fairly paranoid. This sample file
# loosens things up a bit, to make the ftp daemon more usable.
# Please see vsftpd.conf.5 for all compiled in defaults.
#
# READ THIS: This example file is NOT an exhaustive list of vsftpd options.
# Please read the vsftpd.conf.5 manual page to get a full idea of vsftpd's
# capabilities.
#
# Allow anonymous FTP? (Beware - allowed by default if you comment this out).
anonymous_enable=NO
#
# Uncomment this to allow local users to log in.
local_enable=YES
#
# Uncomment this to enable any form of FTP write command.
write_enable=YES
#
# Default umask for local users is 077. You may wish to change this to 022,
# if your users expect that (022 is used by most other ftpd's)
local_umask=022
#
# Uncomment this to allow the anonymous FTP user to upload files. This only
# has an effect if the above global write enable is activated. Also, you will
# obviously need to create a directory writable by the FTP user.
#anon_upload_enable=YES
#
# Uncomment this if you want the anonymous FTP user to be able to create
# new directories.
#anon_mkdir_write_enable=YES
#
# Activate directory messages - messages given to remote users when they
# go into a certain directory.
dirmessage_enable=YES
#
# The target log file can be vsftpd_log_file or xferlog_file.
# This depends on setting xferlog_std_format parameter
xferlog_enable=YES
#
# Make sure PORT transfer connections originate from port 20 (ftp-data).
connect_from_port_20=YES
#
# If you want, you can arrange for uploaded anonymous files to be owned by
# a different user. Note! Using "root" for uploaded files is not
# recommended!
#chown_uploads=YES
#chown_username=whoever
#
# The name of log file when xferlog_enable=YES and xferlog_std_format=YES
# WARNING - changing this filename affects /etc/logrotate.d/vsftpd.log
#xferlog_file=/var/log/xferlog
#
# Switches between logging into vsftpd_log_file and xferlog_file files.
# NO writes to vsftpd_log_file, YES to xferlog_file
xferlog_std_format=YES
#
# You may change the default value for timing out an idle session.
#idle_session_timeout=600
#
# You may change the default value for timing out a data connection.
#data_connection_timeout=120
#
# It is recommended that you define on your system a unique user which the
# ftp server can use as a totally isolated and unprivileged user.
#nopriv_user=ftpsecure
#
# Enable this and the server will recognise asynchronous ABOR requests. Not
# recommended for security (the code is non-trivial). Not enabling it,
# however, may confuse older FTP clients.
#async_abor_enable=YES
#
# By default the server will pretend to allow ASCII mode but in fact ignore
# the request. Turn on the below options to have the server actually do ASCII
# mangling on files when in ASCII mode.
# Beware that on some FTP servers, ASCII support allows a denial of service
# attack (DoS) via the command "SIZE /big/file" in ASCII mode. vsftpd
# predicted this attack and has always been safe, reporting the size of the
# raw file.
# ASCII mangling is a horrible feature of the protocol.
#ascii_upload_enable=YES
#ascii_download_enable=YES
#
# You may fully customise the login banner string:
#ftpd_banner=Welcome to blah FTP service.
#
# You may specify a file of disallowed anonymous e-mail addresses. Apparently
# useful for combatting certain DoS attacks.
#deny_email_enable=YES
# (default follows)
#banned_email_file=/etc/vsftpd/banned_emails
#
# You may specify an explicit list of local users to chroot() to their home
# directory. If chroot_local_user is YES, then this list becomes a list of
# users to NOT chroot().
#chroot_list_enable=YES
# (default follows)
#chroot_list_file=/etc/vsftpd/chroot_list
#
# You may activate the "-R" option to the builtin ls. This is disabled by
# default to avoid remote users being able to cause excessive I/O on large
# sites. However, some broken FTP clients such as "ncftp" and "mirror" assume
# the presence of the "-R" option, so there is a strong case for enabling it.
#ls_recurse_enable=YES
#
# When "listen" directive is enabled, vsftpd runs in standalone mode and
# listens on IPv4 sockets. This directive cannot be used in conjunction
# with the listen_ipv6 directive.
listen=YES
#listen_port=56880
pasv_min_port=30000
pasv_max_port=35000

#
# This directive enables listening on IPv6 sockets. To listen on IPv4 and IPv6
# sockets, you must run two copies of vsftpd whith two configuration files.
# Make sure, that one of the listen options is commented !!
#listen_ipv6=YES

pam_service_name=vsftpd.vu
#pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES

chroot_local_user=YES
guest_enable=YES
guest_username=virtual

virtual_use_local_privs=YES
#reverse_lookup_enable=NO
user_config_dir=/etc/vsftpd/vsftpd_user_conf
```

### 生成vsftpd虚拟用户数据库文件

- 建立虚拟用户名单文件

```
$ vim /etc/vsftpd/ftpuser.txt

ftpupload
12345678
```

格式很简单："一行用户名，一行密码！"。

- 生成虚拟用户数据文件

> db_load命令可以将用户文本信息文件转换为db数据库并使用hash加密。
> 
> 选项-T允许应用程序能够将文本文件转译载入进数据库。由于我们之后是将虚拟用户的信息以文件方式存储在文件里的，为了让Vsftpd这个应用程序能够通过文本来载入用户数据，必须要使用这个选项。
> 
> 指定了选项-T，那么一定要追加子选项-t ; 子选项-t，追加在在-T选项后，用来指定转译载入的数据库类型。hash就是使用hash码加密。
> 
> -f参数后面接包含用户名和密码的文本文件，文件的内容是:奇数行用户名、偶数行密码；

```
$ db_load -T -t hash -f /etc/vsftpd/ftpuser.txt /etc/vsftpd/vsftpd_login.db
$ chmod 600 /etc/vsftpd/vsftpd_login.db
```

- 特别注意

> 如果要删除掉一个虚拟用户，先在ftpuser.txt中删除用户对应的用户名和密码，然后删除vsftpd_login.db,重新运行`db_load -T -t hash -f /etc/vsftpd/ftpuser.txt /etc/vsftpd/vsftpd_login.db`

> 如果更改密码，更改文件内容后还需重新运行db_load就可以，并重启ftp服务使其生效。
 
> 如果要改变用户的其它配置，只需修改用户的配置文件。


### 配置PAM验证文件

```
$ vim /etc/pam.d/vsftpd.vu
```

将以下内容加入到文件最前面(在后面加入无效)

- 32位系统

```
auth required /lib/security/pam_userdb.so db=/etc/vsftpd/vsftpd_login
account required /lib/security/pam_userdb.so db=/etc/vsftpd/vsftpd_login
```

- 64位系统

```
auth required /lib64/security/pam_userdb.so db=/etc/vsftpd/vsftpd_login
account required /lib64/security/pam_userdb.so db=/etc/vsftpd/vsftpd_login
```

上一步建立的数据库vsftpd_login在此处被使用，建立的虚拟用户将采用PAM进行验证，这是通过`/etc/vsftpd/vsftpd.conf`文件中的语句`pam_service_name=vsftpd.vu`来启用的。

### VSftpd虚拟用户的独立配置

```
$ mkdir -p /etc/vsftpd/vsftpd_user_conf
$ vim /etc/vsftpd/vsftpd_user_conf/ftpupload

anon_world_readable_only=NO
write_enable=YES
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
local_root=/home/ftpdata/
```

### VSftpd服务器之间的站点对传

有时候可能需要开启VSftpd服务器之间的站点对传功能，只需在主配置文件`/etc/vsftpd/vsftpd.conf`里加入如下参数即可

```
pasv_promiscuous=YES
port_promiscuous=YES
```

说明

> port_promiscuous=YES|NO
> 默认值为NO。为YES时，取消PORT安全检查。该检查确保外出的数据只能连接到客户端上。小心打开此选项。
> 
> pasv_promiscuous=YES|NO
> 默认值为NO。为YES时，将关闭PASV模式的安全检查。该检查确保数据连接和控制连接是来自同一个IP地址。小心打开此选项。此选项唯一合理的用法是存在于由安全隧道方案构成的组织中。

由于取消了数据包的安全检查，允许数据流向非客户端，所以站点对传成功。

配置修改完成后，重启vsftpd服务生效

```
$ /etc/init.d/vsftpd restart
```

### VSftpd的一些配置技巧

- 配置VSftpd服务器的日志功能

VSftpd与log有关的选项

```
vsftpd_log_file
xferlog_enable
xferlog_std_format
xferlog_file
dual_log_enable
syslog_enable
log_ftp_protocol
no_log_lock
```

这里主要要到下面几个参数控制

> log_ftp_protocol
> 如果启用, 假若选项xferlog_std_format没有启用, 所有的FTP请求和应答都会被记录。 此选项将对调试很有用。
> 默认: YES
> 
> dual_log_enable
> 如果启用, 将生成两个相似的日志文件, 默认在/var/log/xferlog和/var/log/vsftpd.log目录下。 前者是wu-ftpd类型的传输日志, 可以用于标准工具分析。 后者是vsftpd自己类型的日志。
> 
> xferlog_enable
> 如果启用, 将会维护一个日志文件, 用于详细记录上载和下载. 默认情况下, 这个日志文件是/var/log/vsftpd.log。 但是也可以通过配置文件中的vsftpd_log_file选项来指定。
> 默认: NO(但是在示例设置中启用了这个选项)
> 
> xferlog_std_format
> 如果启用, 传输日志文件将以标准xferlog的格式书写, 如同wu-ftpd一样. 这可以用于重新使用传输统计生成器. 然而, 默认格式更注重可读性。 此格式的日志文件默认为/var/log/xferlog, 但是您也可以通过xferlog_file选项来设定。
> 默认: NO

> xferlog_file
> xferlog 日志文件所在位置，默认为/var/log/xferlog。
> 
> vsftpd_log_file
> 指定VSFTPd日志文件位置，默认为/var/log/vsftpd.log，xferlog_enable的默认值为no(VSFTPd提供的配置文件模版将其值改为了yes)，dual_log_enable的默认值也为no，就是说默认情况下VSFTPd是不记录日志的。我们也可以将日志信息写入系统日志/var/log/messages中，使用如下参数：syslog_enable=yes/no

配置VSftpd传输日志

将xferlog_file前面的#号对掉，也就是把VSftpd的Log功能打开，这样我们就能在/var/log目录下查看xferlog。这是VSftpd日志功能，这对于我们来说是极为重要的。

```
##################log settings###################
# Activate logging of uploads/downloads.
xferlog_enable=YES
#
# You may override where the log file goes if you like. The default is shown
# below.
xferlog_file=/var/log/xferlog
#
#log in two files /var/log/xferlog and /var/log/vsftpd.log
dual_log_enable=YES
vsftpd_log_file=/var/log/vsftpd.log
#log time setting
use_localtime=YES
#
###################end of log####################
```

- 配置VSftpd限制同一个IP地址的同时连接数量

VSftpd对同一个IP地址的同时连接数量默认是没有限制的。在VSftpd中的max_per_ip选项是0，代表没有限制。

如果你想限制同一个IP地址的同时连接数量，你需要修改`/etc/vsftpd/vsftpd.conf`文件。以下是一个例子

```
pam_service_name=vsftpd
userlist_enable=YES
#enable for standalone mode
listen=YES
tcp_wrappers=YES
max_per_ip=2
```

在这个例子中，每一个主机最多只能有两个连接。修改vsftpd.conf之后，你需要重启VSftpd来让它生效。

一旦达到最大连接数，同一个主机下对这个FTP服务器的其他连接会出现以下的错误信息。

```
421 There are too many connections from your internet address.
```

- VSftpd与TCP_wrapper结合限制用户的IP地址登录

通过`/etc/hosts.allow`定义允许的来源地址，`/etc/hosts.deny`定义拒绝的来源地址。


配置示例

/etc/hosts.allow

```
#
# hosts.allow This file describes the names of the hosts which are
# allowed to use the local INET services, as decided
# by the ‘/usr/sbin/tcpd’ server.
#
vsftpd: 123.103.47.0/255.255.255.0 218.240.63.0/255.255.255.0 59.46.172.0/255.255.255.0 10.0.0.0/255.0.0.0 60.2.80.0/255.255.255.0 218.249.230.0/255.255.255.0 160.10.0.0/255.255.0.0 218.246.69.0/255.255.255.0 125.35.3.0/255.255.255.0 : allow
```

/etc/hosts.deny

```
#
# hosts.deny This file describes the names of the hosts which are
# *not* allowed to use the local INET services, as decided
# by the ‘/usr/sbin/tcpd’ server.
#
# The portmap line is redundant, but it is left to remind you that
# the new secure portmap uses hosts.deny and hosts.allow. In particular
# you should know that NFS uses portmap!
vsftpd : ALL : DENY
```

将tcp_wrappers=yes添加至`/etc/vsftpd/vsftpd.conf`中

```
$ vi /etc/vsftpd/vsftpd.conf
tcp_wrappers=YES
```

重新启动VSftpd

```
$ service vsftpd restart
Shutting down vsftpd: OK ]
Starting vsftpd for vsftpd: OK ]
```

### 故障排除

如果配置中出现问题，请从以下几方面检查

- 文件权限和文件属主问题
- 防火墙iptables没开放相关的端口
- SELinux导致的权限问题，建议先关闭SELinux再配置VSftp，之后再开启到permissive模式。或者运行这条命令：`setsebool -P ftp_home_dir=1` 。


### 参考文档

http://www.google.com
http://www.ha97.com/4113.html
http://www.cnblogs.com/sztsian/archive/2011/08/23/2204102.html