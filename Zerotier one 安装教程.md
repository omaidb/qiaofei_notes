---
title: Zerotier one安装教程
date: 2022-03-10 23:37:51
tags: Zerotier one
---
## Windows版客户端安装

```bash
choco install zerotier-one -y
```

## Linux版客户端安装

```bash
curl -s https://install.zerotier.com | sudo bash

# 带gpg安装
curl -s 'https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact%40zerotier.com.gpg' | gpg --import && \
if z=$(curl -s 'https://install.zerotier.com/' | gpg); then echo "$z" | sudo bash; fi
```

Redhat系Linux直接下载rpm包

```bash
https://download.zerotier.com/redhat/el/7.9/
```

安装rpm包

```bash
rpm -ivh *.rpm 
```

来自 https://www.zerotier.com/download/

```bash
#安装完会自动运行,设置开机启动
sudo systemctl enable --now zerotier-one.service
```

```bash
#加入网络
sudo zerotier-cli join 9f77fc393e83973e

#离开网络
sudo zerotier-cli leave Network ID

#列出整个网络中的所有节点
sudo zerotier-cli listnetworks

#查看状态
sudo zerotier-cli status
```

### Centos6安装

```bash
# 安装
yum install https://download.zerotier.com/redhat/el/6.9/zerotier-one-1.6.6-1.el6.x86_64.rpm -y

# 启动程序
zerotier-one -d
## 或 
service zerotier-one start

# 设置服务开机自启
chkconfig zerotier-one on

# 查看开机自启是否成功
chkconfig zerotier-one --list

# 加入网络
sudo zerotier-cli join 9f77fc393e83973e
```

## Mac os安装

支持MacOS 10.10或更高版本。可以从终端使用以下命令来控制，重新启动或卸载服务。

```bash
#查看状态
sudo zerotier-cli status

##加入网络
sudo zerotier-cli join 9f77fc393e83973e

# 离开网络
sudo zerotier-cli leave ################

# 列出整个网络中的所有节点
sudo zerotier-cli listnetworks

#使用launchctl 添加启动服务
#添加启动服务
sudo launchctl load /Library/LaunchDaemons/com.zerotier.one.plist
#卸载启动服务
sudo launchctl unload /Library/LaunchDaemons/com.zerotier.one.plist

#卸载ZeroTier
sudo "/Library/Application Support/ZeroTier/One/uninstall.sh"
```