---
title: JBOSS 6中发布数据源
tags:
  - Linux
  - JBoss
  - 技巧
categories: JBoss
abbrlink: 10407
date: 2016-03-15 09:51:54
---
 
本文介绍了在JBOSS服务器中发布数据源的方法，使用的JBOSS版本为6.0.0 Final。

以MySQL为例(其他数据库方法不变)，发布数据源的步骤如下：

1.将MySQL的数据库连接文件mysql-connector-java-5.1.22-bin.jar复制到%JBOSS_HOME%\server\default\lib目录下。

2.修改%JBOSS_HOME%\docs\examples\jca目录下的MySQL的数据源模板mysql-ds.xml文件，以下是我修改好的数据源配置文件，可作参考：<!-- more -->

```
<?xml version="1.0" encoding="UTF-8"?>

<!-- See http://www.jboss.org/community/wiki/Multiple1PC for information about local-tx-datasource -->
<!-- $Id: mysql-ds.xml 97536 2009-12-08 14:05:07Z jesper.pedersen $ -->
<!--  Datasource config for MySQL using 3.0.9 available from:
http://www.mysql.com/downloads/api-jdbc-stable.html
-->

<datasources>
  <local-tx-datasource>
    <jndi-name>MySqlDS</jndi-name>
    <connection-url>jdbc:mysql://localhost:3306/titan</connection-url>
    <driver-class>com.mysql.jdbc.Driver</driver-class>
    <user-name>root</user-name>
    <password>123123</password>
    <exception-sorter-class-name>org.jboss.resource.adapter.jdbc.vendor.MySQLExceptionSorter</exception-sorter-class-name>
    <!-- should only be used on drivers after 3.22.1 with "ping" support
    <valid-connection-checker-class-name>org.jboss.resource.adapter.jdbc.vendor.MySQLValidConnectionChecker</valid-connection-checker-class-name>
    -->
    <!-- sql to call when connection is created
    <new-connection-sql>some arbitrary sql</new-connection-sql>
      -->
    <!-- sql to call on an existing pooled connection when it is obtained from pool - MySQLValidConnectionChecker is preferred for newer drivers
    <check-valid-connection-sql>some arbitrary sql</check-valid-connection-sql>
      -->

    <!-- corresponding type-mapping in the standardjbosscmp-jdbc.xml (optional) -->
    <metadata>
       <type-mapping>mySQL</type-mapping>
    </metadata>
  </local-tx-datasource>
</datasources>
```

如果要给连接池加上自动重连功能，加入以下段

```
<exception-sorter-class-name>org.jboss.resource.adapter.jdbc.vendor.MySQLExceptionSorter</exception-sorter-class-name>
<!--<new-connection-sql>select 1 from dual</new-connection-sql>-->
<check-valid-connection-sql>select 1 from dual</check-valid-connection-sql>
```

注意，修改好的数据源配置文件名必须以"-ds.xml"结尾。

3.将修改好的数据源配置文件mysql-ds.xml发布到JBOSS中，即将其拷贝至%JBOSS_HOME%\server\default\deploy目录下。

至此，经过以上三步，成功地在JBOSS服务器中发布了一个数据源。

注意：使用数据源时，需要在persistence.xml文件的<persistence-unit>元素中增加如下语句：

```xml
<jta-data-source>java:MySqlDS</jta-data-source>
```

这里"java:"是JBOSS默认的命名空间，其后的"MySqlDS"对应上文mysql-ds.xml文件中的<jndi-nami>MySqlDS</jndi-name>。