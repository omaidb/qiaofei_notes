## 安装createrepo

```bash
yum install createrepo yum-utils -y
```



## 创建结构目录

```bash
# mkdir yum源名称/Packages
mkdir other/Packages
```





## 下载rpm包

```bash
yumdownloader --downloadonly --destdir=./yum-name/Packages/ telnet unzip libaio pcre-devel openssl openssl-devel
# --downloadonly  :只下载
# --downloaddir   :指定安装包下载的目录
```



## 创建yum源

```bash
# createrepo 源名称目录
createrepo ./other

# 等待创建respodata数据
Spawning worker 0 with 2 pkgs
Spawning worker 1 with 1 pkgs
Spawning worker 2 with 1 pkgs
Spawning worker 3 with 1 pkgs
Spawning worker 4 with 1 pkgs
Spawning worker 5 with 1 pkgs
Spawning worker 6 with 1 pkgs
Spawning worker 7 with 1 pkgs
Workers Finished
Saving Primary metadata
Saving file lists metadata
Saving other metadata
Generating sqlite DBs
Sqlite DBs complete
```



## 客户端配置yum源

```bash
[other]
name=other-CentOS-$releasever
enabled=1
baseurl=http://10.165.186.234/other
gpgcheck=0
```



测试安装

```bash
# 清理yum缓存
yum clean all

# 重新创建yum缓存
yum makecache

# 搜索包名
yum search 包名
```