---
title: Vagrantfile配置技巧
tags:
  - Vagrant
  - 技巧
categories: Vagrant
abbrlink: 24777
date: 2016-03-15 09:51:54
---

Vagrantfile，官方解释是这样的：The primary function of the Vagrantfile is to describe the type of machine required for a project, and how to configure and provision these machines。简单来说就是配置这个虚拟主机网络连接方式，端口转发，同步文件夹，以及怎么和puppet，chef结合的一个配置文件。执行完$ vagrant init后,在工作目录中,你会发现此文件。

### 一、NOTE：配置版本说明：

```bash
Vagrant.configure("2") do |config|
  # ...
end
```
> 当前支持的两个版本:"1"和"2". "1"：描述是Vagrant 1.0.x的配置（如看到Vagrant::Config.run do |config| 此也为Vagrant 1.0.x 的配置）；"2"：描述的是1.1+ leading up to 2.0.x的配置。vagrant 1.1+ 的Vagrantfiles能够与vagrant 1.0.x的Vagrantfiles保持向后兼容，也大幅引入新的功能和配置选项。

### 二、Vagrant基本设定<!-- more -->

#### 设定VM的名称及记忆体

用你最喜欢的编辑器打开vagrantfile，vagrantfile是个有着详细解释的设定档，在这个档案中所有的设定都被Vagrant::Config.run的Block包起来，在一开始只会有box的设定：

```bash
config.vm.box = "ubuntu-12-10"
```

这告诉了Vagrant要去使用哪个Box作为环境，也就是你一开始输入varant init Box名称时所指定的Box，如果没有输入Box名称的话就会是预设的base，Virtual Box本身提供了VBoxManage这个command line tool让你可以设定你的VM，用modifyvm这个指令让你可以设定VM的名称及记忆体大小等等，这里说的名称指的是在Virtual Box中显示的名称，我们也可以在vagrantfile中进行设定，在你的vagrantfile中加入这行

```bash
config.vm.customize  [ "modifyvm" ,  :id ,  "--name" ,  "Mike" ,  "--memory" ,  "512" ]
```

这行设定档意思就是呼叫VBoxManage的modifyvm的指令，设定VM的名称为Mike，而设定VM的记忆体大小为512MB，你可以照这这种作法为你的VM设定好不同的设定。

#### 设定Hostname

设定hostname非常简单，设定中加入下面这行就好

```bash
config.vm.host_name = "Mike-App"
```

设定hostname非常重要，有很多服务都仰赖着hostname来做为辨识，例如Puppet或是Chef，一般一些监控服务像是New Relic之类的也都是以hostname来做为辨识。


### 三、配置网络（本文将提供2种版本的常用配置，其中版本2的配置经过实践验证）

#### 端口转发：(假设虚拟机的80端口提供web服务，此处将通过访问物理机的8080端口转发到虚拟机的80端口，来实现web的访。开启host_only可直接访问虚拟机端口。)

版本"2"：

```bash
Vagrant.configure("2") do |config|
  config.vm.network :forwarded_port, guest: 80, host: 8080
end
```
>guest:80 表示虚拟机中的80端口，host:8080表示映射到宿主机的8080端口。

版本"1":

```bash
Vagrant::Config.run do |config|
  # Forward guest port 80 to host port 8080
  config.vm.forward_port 80, 8080
end
```

#### 桥接网络(公共网络，局域网DHCP服务器自动分配IP）

如果需要将虚拟机作为当前局域网中的一台计算机，由局域网进行DHCP，那么在Vagrantfile中配置：

版本"2"

```bash
Vagrant.configure("2") do |config|
  config.vm.network :public_network
end
```

版本"1"

```bash
Vagrant::Config.run do |config|
  config.vm.network :bridged
end
  $ VBoxManage list bridgedifs | grep ^Name    #可通过此命令查看本机的网卡
    Name:            eth0

指定网卡，配置可写为如下：

Vagrant::Config.run do |config|
  config.vm.network :bridged, :bridge => "eth0"
end
```

#### 私有网络：允许多个虚拟机通过主机通过网络互相通信，vagrant允许用户分配一个静态IP，然后使用私有网络设置。

Vagrant默认是使用端口映射方式将虚拟机的端口映射本地从而实现类似<http://localhost:80>这种访问方式，这种方式比较麻烦。如果需要自己自由的访问虚拟机，但是别人不需要访问虚拟机，可以使用private_network，比起端口映射新开和修改端口的时候都得编辑相比较而言，host-only模式显得方便多了。

打开Vagrantfile，将下面这行的注释去掉(移除#)并保存：

版本"2"

```bash
Vagrant.configure("2") do |config|
  config.vm.network :private_network, ip: "192.168.50.4"
end
```

版本"1"

```bash
Vagrant::Config.run do |config|
  config.vm.network :hostonly, "192.168.50.4"
end
```

重启虚拟机，这样我们就能用 192.168.50.4访问这台机器了，你可以把IP 改成其他地址，只要不产生冲突就行。多台虚拟机的话需要互相访问的话，设置在相同网段即可。

### 四、同步文件夹

默认的，vagrant将共享你的工作目录(即Vagrantfile所在的目录)到虚拟机中的/vagrant,所以一般不需配置即可，如你需要可配置：

版本"1"

```bash
config.vm.share_folder "v-data", "/data", "data"   
```

> 把这一行的注释去掉，如上所说，第一个是个标志，第二个是你虚拟机里挂载的目录，第三个就是物理机的目录了，位置相对于Vagrantfile。这个目录是777的，可以随意修改删除，所有操作在虚拟机和本机都是同步的。

版本"2"

```bash
Vagrant.configure("2") do |config|
  # other config here
  config.vm.synced_folder "src/", "/srv/website"
end
```

> 第一个参数"src/"是你的宿主机目录，可以用相对目录(位置相对于Vagrantfile)，这里也可以使用绝对路径，比如："d:/www/"。第二个参数"/srv/website"是客户机的挂载的绝对目录。

### 五、vagrant和shell(实现在虚拟机启动的时候自运行需要的shell命令或脚本)

#### 版本"2"

- 内嵌脚本：

```bash
Vagrant.configure("2") do |config|
  config.vm.provision :shell,
    :inline => "echo Hello, World"
end

#复杂点的调用如下：
$script = <<SCRIPT
echo I am provisioning...
date > /etc/vagrant_provisioned_at
SCRIPT
Vagrant.configure("2") do |config|
  config.vm.provision :shell, :inline => $script
end
```

- 外部脚本:

```bash
Vagrant.configure("2") do |config|
  config.vm.provision :shell, :path => "script.sh"      #脚本的路径相对于项目根，也可使用绝对路径
end

#脚本可传递参数：
Vagrant.configure("2") do |config|
  config.vm.provision :shell do |s|
    s.inline = "echo $1"
    s.args   = "'hello, world!'"
  end
end
```

#### 版本"1":

- 内部脚本：

```bash
 Vagrant::Config.run do |config|
  config.vm.provision :shell, :inline => "echo abc > /tmp/test"
end
```

- 外部脚本：

```bash
Vagrant::Config.run do |config|
  config.vm.provision :shell, :path => "test.sh"
end
```

- 脚本可传递参数：

```bash
Vagrant::Config.run do |config|
  config.vm.provision :shell do |shell|
    shell.inline = "echo $1 > /tmp/test"
    shell.args = "'this is test'"
  end
end
```

#### 实例

虽然不是必须，但是如果有需要在启动时运行一些脚本(环境的安装或者有些服务的启动需要在完成目录映射之后进行)，可以编辑脚本，类似如下(摘自Vagrant Document)：

```bash
#!/usr/bin/env bash
	
apt-get update
apt-get install -y apache2
rm -rf /var/www
ln -fs /vagrant /var/www
```

保存在和Vagrantfile相同目录，文件名自取(如boot.sh），然后在Vagrantfile中添加：

```bash
config.vm.provision :shell, :path => "boot.sh"
```

当初次使用基本的设置都完成则之后，则可以使用 vagrant up启动虚拟机

```bash
Bringing machine 'default' up with 'virtualbox' provider...
[default] Setting the name of the VM...
[default] Clearing any previously set forwarded ports...
[default] Creating shared folders metadata...
[default] Clearing any previously set network interfaces...
[default] Preparing network interfaces based on configuration...
[default] You are trying to forward to privileged ports (ports < = 1024). Most operating systems restrict this to only privileged process (typicallyprocesses running as an administrative user). This is a warning in case
the port forwarding doesn't work. If any problems occur, please try a port higher than 1024.
[default] Forwarding ports...
[default] -- 22 => <strong>2222</strong> (adapter 1)
[default] -- 80 => 8080 (adapter 1)
[default] Booting VM...
[default] Waiting for VM to boot. This can take a few minutes.
[default] VM booted and ready for use!
[default] The guest additions on this VM do not match the installed version of VirtualBox! In most cases this is fine, but in rare cases it can cause things such as shared folders to not work properly. If you see shared folder errors, please update the guest additions within the virtual machine and reload your VM.
	
Guest Additions Version: 4.1.18
VirtualBox Version: 4.2
[default] Mounting shared folders...
[default] -- /var/www
[default] -- /vagrant
[default] Running provisioner: shell...
```
### 六、vagrant和puppet

puppet相关介绍:<http://xuclv.blog.51cto.com/blog/5503169/1154261>

- vagrant调用puppet单独使用

```bash
Vagrant.configure("2") do |config|
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "my_manifests"#路径相对于项目根，如无配置此项，默认为manifests
    puppet.manifest_file = "default.pp"      #如无配置此项，默认为default.pp
    puppet.module_path = "modules"        #路径相对于根
    puppet.options = "--verbose --debug"
  end
end

默认配置的目录结构：
 $ tree
  .
  |-- Vagrantfile
  |-- manifests
  |   |-- default.pp

```

- vagrant让puppet作为代理，连接Puppet master

```bash
Vagrant.configure("2") do|config|
config.vm.provision :puppet_server do|puppet|
puppet.puppet_server = "puppet.example.com"#master域名
puppet.puppet_node = "node.example.com"#传递给puppet服务器节点的名称。默认为”puppet“
puppet.options = "--verbose --debug"#选项
end
end
```

> NOTE：
> 版本1配置差别不大，不再详述，区别：`Vagrant.configure("2") do |config|`改为`Vagrant::Config.run do |config|`
> 以上Vagrantfile配置完毕后，可`$vagrant reload`重启虚拟机以来实现配置生效

- 官方实例：

1.进入工作目录
2.修改Vagrantfile
```bash
$vim Vagrantfile    
#启用或添加如下行：
Vagrant.configure("2") do |config|
  config.vm.provision :puppet    #这里没有配置pp文件等的路径，全部采用默认
  end
end
```
3.创建puppet的主目录
```bash
$mkdir manifests
```
4.配置pp文件
```bash
$ vim manifests/default.pp
# Basic Puppet Apache manifest
class apache {
  exec { 'apt-get update':
    command => '/usr/bin/apt-get update'
  }
  package { "apache2":
    ensure => present,
  }
  service { "apache2":
    ensure => running,
    require => Package["apache2"],
  }
  file { '/var/www':
    ensure => link,
    target => "/vagrant",
    notify => Service['apache2'],
    force  => true
  }
}
include apache
```
5.重启虚拟机
```bash
#重启后可看到虚拟机中已经安装好了apache
$ vagrant reload    
```
### 七、多虚拟机配置

- 配置语法

```bash
VAGRANTFILE_API_VERSION = "2"    #定义版本
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|  #使用内部2版本
  config.vm.define :debian1 do |debian1|   #定义第一台虚拟机，||里面就类似一个变量设置参数时使用 
     debian1.vm.box = "debian1"             #设置box名为debian1
     debian1.vm.host_name = "debian1"      #设置hostname为debian1
     debian1.vm.network :private_network, ip: "192.168.1.11" #设置网络为内部网络 ip为192.168.1.11
  end
  config.vm.define :debian2 do |debian2|
     debian2.vm.box = "debian2"
     debian2.vm.host_name = "debian2"
     debian2.vm.network :private_network, ip: "192.168.1.12"
  end
  config.vm.define :debian3 do |debian3|
     debian3.vm.box = "debian3"
     debian3.vm.host_name = "debian3"
     debian3.vm.network :private_network, ip: "192.168.1.13"
  end

end
```

> 这里定义一个debian1、debian2、debian3三个虚拟机，并设置主机名、私有网络和IP地址。
> 注意：配置前关闭虚拟机，配置完后打开虚拟机。注意define用法，原单台机器的设定必须先清除或是注解掉。

- 实例

让我们开始打造多机器环境

现在我们要建立多个VM，并且让他们互相沟通，一台Application、一台DB。

```bash
config.vm.define:app do |app_config| 
    app_config.vm.customize  [ "modifyvm" ,  :id ,  "--name" ,  "app" ,  "--memory" ,  "512" ] 
    app_config.vm.box  =  "ubuntu-12-10" 
    app_config.vm.host_name  =  "app" 
    app_config.vm.network  :hostonly ,  "33.33.13.10" 
end 
config.vm.define:db do |db_config| 
  db_config.vm.customize  [ "modifyvm" ,  :id ,  "--name" ,  "db" ,  "--memory" ,  "512" ] 
  db_config.vm.box  =  "ubuntu-12-10" 
  db_config.vm.host_name  =  "db" 
  db_config.vm.network  :hostonly ,  "33.33.13.11" 
end
```

这边的设定了app以及db两个VM的，并且给予不同的hostname和IP，设定好了以后再使用vagrant up将机器跑起来：

```bash
$vagrant  up 
[ app ]  Importing  base  box  'ubuntu-12-10' . . . 
[ app ]  Matching  MAC  address  for  NAT  networking . . . 
[ app ]  Clearing  any  previously  set  forwarded  ports . . . 
[ app ]  Forwarding  ports . . . 
[ app ]  --  22  =>  2222  ( adapter  1 ) 
[ app ]  --  80  =>  8080  ( adapter  1 ) 
[ app ]  Creating  shared  folders  metadata . . . 
[ app ]  Clearing  any  previously  set  network  interfaces . . . 
[ app ]  Preparing  network  interfaces  based  on  configuration . . . 
[ app ]  Running  any  VM  customizations . . . 
[ app ]  Booting  VM . . . 
[ app ]  Waiting  for  VM  to  boot .  This  can  take  a  few  minutes . 
[ app ]  VM  booted  and  ready  for  use! 
[ app ]  Configuring  and  enabling  network  interfaces . . . 
[ app ]  Setting  host  name . . . 
[ app ]  Mounting  shared  folders . . . 
[ app ]  --  v - root :  /vagrant 
[db] Importing base box 'ubuntu-12-10'... 
[db] Matching MAC address for NAT networking... 
[db] Clearing any previously set forwarded ports... 
[db] Fixed port collision for 22 => 2222. Now on port 2200. 
[db] Fixed port collision for 22 => 2222. Now on port 2201. 
[db] Forwarding ports... 
[db] -- 22 => 2201 (adapter 1) 
[db] Creating shared folders metadata... 
[db] Clearing any previously set network interfaces... 
[db] Preparing network interfaces based on configuration... 
[db] Running any VM customizations... 
[db] Booting VM... 
[db] Waiting for VM to boot . This can take a few minutes. 
[db] VM booted and ready for use! 
[db] Configuring and enabling network interfaces... 
[db] Setting host name... 
[db] Mounting shared folders... 
[db] -- v-root: / vagrant
```

看到上面的信息完后，你就可以跟刚刚一样使用ssh连到VM里，多虚拟机环境下须加上你所指定的角色告诉你要连线的机器是哪一台：

```bash
$vagrant ssh app 
vagrant@app :~ $ 

$vagrant ssh db 
vagrant@db :~ $
```

验证VM之间的访问，让我们使用ssh登入db的机器，然后在db的机器上使用ssh来连线到app的机器(预设密码就是vagrant)：
```bash
$vagrant ssh db 
vagrant @db :~ $  ssh  33 . 33 . 13 . 10 
The  authenticity  of  host  '33.33.13.10 (33.33.13.10)'  can 't be established. 
ECDSA key fingerprint is a7:71:36:4c: 01:4a:38:a2:fc:fa:ea:d7:67:63:3c:40. 
Are you sure you want to continue connecting (yes/no)? yes 
Warning: Permanently added ' 33 . 33 . 13 . 10 ' (ECDSA) to the list of known hosts. 
vagrant@33.33.13.10' s  password : 
vagrant @app :~ $
```

### 八、其它技巧

使用 Apache/Nginx 时会出现诸如图片修改后但页面刷新仍然是旧文件的情况，是由于静态文件缓存造成的。需要对虚拟机里的 Apache/Nginx 配置文件进行修改：

- Apache 配置添加:

```bash
EnableSendfile off
```

- Nginx 配置添加:

```bash
sendfile off;
```