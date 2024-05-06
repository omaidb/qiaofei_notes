#!/usr/bin/env bash

# 开启debug
# set -ex

# 参考：
# https://tommy.net.cn/2021/09/12/build-your-own-sd-lan-by-nebula/
# https://nebula.defined.net/docs/guides/quick-start/

# 定义版本
nebula_VERSION=1.8.2
# 安装nebula
install_nebula() {
    # 下载并安装nebula, nebula是个golang的二进制工具，直接下载拷贝到bin目录即可, release页面也可下载
    wget -c -P /usr/local/src/ https://github.com/slackhq/nebula/releases/download/v$nebula_VERSION/nebula-linux-amd64.tar.gz --no-check-certificate
    # 创建nebula程序目录和配置目录
    mkdir -p /usr/local/nebula /etc/nebula/
    # 解压nebula到指定路径
    ls /usr/local/nebula/nebula &>/dev/null && echo 'nebula已存在，请先删除旧版' && exit 1
    ls /usr/local/nebula/nebula-cert &>/dev/null && echo 'nebula已存在，请先删除旧版' && exit 1
    tar xvf /usr/local/src/nebula-linux-amd64.tar.gz -C /usr/local/nebula/ && chmod +x /usr/local/nebula/nebula && chmod +x /usr/local/nebula/nebula-cert &&
        ln -s /usr/local/nebula/nebula /usr/local/bin/nebula && ln -s /usr/local/nebula/nebula-cert /usr/local/bin/nebula-cert && which nebula && which nebula-cert
}

# 创建服务文件
create_nebula_service_file() {
    cat <<EOF >/usr/lib/systemd/system/nebula.service
[Unit]
Description=Nebula Network
Wants=basic.target
After=basic.target network.target

[Service]
SyslogIdentifier=nebula
StandardOutput=syslog
StandardError=syslog
ExecReload=/bin/kill -HUP \$MAINPID
ExecStart=/usr/local/nebula/nebula -config /etc/nebula/config.yml
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    # 重载服务
    systemctl daemon-reload
    systemctl enable nebula
}

# 安装二进制程序
install_nebula
# 创建服务文件
create_nebula_service_file
