## mvn常用

### mvn打包java程序



```bash
# 打包一定要和src目录在同一个目录下才可以
mvn clean package

# 解压war包到tomcat的ROOT目录下
unzip target/*.war -d target/ROOT
```



