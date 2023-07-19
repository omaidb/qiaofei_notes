#!/usr/bin/env bash

# !!!声明:该脚本仅适用于Centos7安装kcptun、
# KCPTUN项目地址 https://github.com/xtaci/kcptun

# 定义kcptun版本
KCPTUN_VERSION=20230214

# ifCMD函数,判断上一条命令(不等于0)没执行成就停止,成功就继续运行
function ifcmd() {
    if [ $? -ne 0 ]; then
        exit
    fi
}

# 判断wget是否存在,如果不存在就安装wget
which wget || yum install wget -y

ifcmd

# 如果下载出错,就使用镜像站下载
if [ $? -ne 0 ]; then
    # 下载二进制包
    wget -cO /usr/local/src/kcptun-linux-amd64-$KCPTUN_VERSION.tar.gz https://github.com/xtaci/kcptun/releases/download/v$KCPTUN_VERSION/kcptun-linux-amd64-$KCPTUN_VERSION.tar.gz --no-check-certificate

else
    # 从镜像站下载
    wget -cO /usr/local/src/kcptun-linux-amd64-$KCPTUN_VERSION.tar.gz https://ghproxy.com/https://github.com/xtaci/kcptun/releases/download/v$KCPTUN_VERSION/kcptun-linux-amd64-$KCPTUN_VERSION.tar.gz --no-check-certificate
fi

# 如果二进制包没下载下来,退出
ifcmd

# 解压kcptun.gz
cd /usr/local/src/ || exit

# 如果gzip不支持-k参数就不执行-k参数了
tar xvf kcptun-linux-amd64-$KCPTUN_VERSION.tar.gz

# 重命名kcp-tun服务端
mv server_linux_amd64 kcptun-server && chmod +x kcptun-server

# 重命名kcp-tun客户端
mv client_linux_amd64 kcptun-client && chmod +x kcptun-client

# 检查/usr/local/kcptun目录，不存在则创建
[ -d /usr/local/kcptun ] || mkdir -p /usr/local/kcptun

# 将kcptun可执行文件移动到/usr/local/kcptun/
mv kcptun-server kcptun-client /usr/local/kcptun/

# 检查/etc/kcptun目录，不存在则创建
[ -d /etc/kcptun ] || mkdir -p /etc/kcptun

# 将服务端配置文件写入kcptun-server.json文件
echo '{
    "listen": ":29900-29909",
    "target": "127.0.0.1:1081",
    "key": "1",
    "crypt": "none",
    "mode": "fast3",
    "mtu": 1350,
    "datashard": 27,
    "parityshard": 9,
    "interval": 10,
    "resend": 1,
    "nc": 1,
    "dscp": 46,
    "pprof": false,
    "nocomp": true,
    "quiet": true,
    "acknodelay": false,
    "nodelay": 1,
    "smuxver": 2,
    "keepalive": 2,
    "conn": 7,
    "signal": true,
    "tcp":true
}' >/etc/kcptun/kcptun-server.json


# 将客户端配置文件写入kcptun-client.json文件
echo '{
    "remoteaddr": "remote.site:29900-29909",
    "localaddr": "127.0.0.1:1081",
    "key": "1",
    "crypt": "none",
    "mode": "fast3",
    "mtu": 1350,
    "datashard": 27,
    "parityshard": 9,
    "interval": 10,
    "resend": 1,
    "nc": 1,
    "dscp": 46,
    "pprof": false,
    "nocomp": true,
    "autoexpire": 86400,
    "quiet": true,
    "acknodelay": false,
    "nodelay": 1,
    "smuxver": 2,
    "keepalive": 2,
    "conn": 2,
    "signal": true,
    "tcp": true
}' >/etc/kcptun/kcptun-client.json

# 创建kcptun-client.service文件
echo "
[Unit]
Description=kcptun service
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/kcptun/kcptun-client -c /etc/kcptun/kcptun-client.json
ExecReload=/bin/kill -HUP 
KillMode=control-group
RestartSec=10s
Restart=always

[Install]
WantedBy=multi-user.target
" >/etc/systemd/system/kcptun-client.service


# 创建kcptun-server.service文件
echo "
[Unit]
Description=kcptun service
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/kcptun/kcptun-server -c /etc/kcptun/kcptun-server.json
ExecReload=/bin/kill -HUP 
KillMode=control-group
RestartSec=10s
Restart=always

[Install]
WantedBy=multi-user.target
" >/etc/systemd/system/kcptun-server.service

# 重载systemctl 设置kcptun服务开机自启
systemctl daemon-reload