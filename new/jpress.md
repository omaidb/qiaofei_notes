## 安装tomcat和mariadb
```bash
# 安装 maridb
yum install -y mariadb-server

# 启动maridb服务
systemctl enable --now mariadb
```

## 配置数据库
```bash
# 设置数据库密码
mysqladmin -uroot password

启动tomcat,将war包放在tomcat/webapps下,启动要等大约10秒钟
# 登录数据库
mysql -uroot -p

# 创建数据库用户
CREATE USER jpress@localhost IDENTIFIED BY 'S%$NPlCRt}ZjYAmDJ$AD';

# 授予jpress用户执行所有权限
grant all on jpress.* to 'jpress'@'%' identified by 'S%$NPlCRt}ZjYAmDJ$AD';

# 刷新权限
flush privileges;

# 查看jpress的权限
show GRANT FOR 'jpress'@'localhost';

# 使用jpressd登录用户
mysql -ujpress -p

# 创建数据库
create database jpress default character set utf8;
```

## 安装nginx
```bash
yum install 
```