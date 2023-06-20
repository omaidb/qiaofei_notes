#!/usr/bin/env bash

# 定义检查 glibc 版本的函数
check_glibc_version() {
  # 获取当前 glibc 版本号
  glibc_version=$(ldd --version | awk '/ldd/{print $NF}')

  # 将版本号转换为数值比较
  glibc_major=$(echo "$glibc_version" | cut -d. -f1)
  glibc_minor=$(echo "$glibc_version" | cut -d. -f2)
  glibc_patch=$(echo "$glibc_version" | cut -d. -f3)
  glibc_version_num=$((glibc_major * 10000 + glibc_minor * 100 + glibc_patch))

  # 检查版本是否低于 2.18
  if [ $glibc_version_num -lt 23800 ]; then
    echo "glibc 版本低于2.18，脚本停止."
    exit 1
  fi

  # 输出当前 glibc 版本号
  echo "glibc version is $glibc_version."
}

# 安装指定版本二进制包
install_realm() {
    v=2.4.6
    wget -c -P /usr/local/src https://github.com/zhboner/realm/releases/download/v${v}/realm-x86_64-unknown-linux-gnu.tar.gz
    tar zxvf /usr/local/src/realm-x86_64-unknown-linux-gnu.tar.gz -C /usr/local/bin/
    # 查看是否安装好
    which realm && ln -s $(which realm) /usr/bin/realm
    # 查看realm版本
    realm -v
}

# 创建配置文件
create_config() {
    # 创建配置文件目录
    mkdir -p /etc/realm/
    # 创建空的配置文件
    cat >/etc/realm/realm.toml <<END
    # 完整配置
[dns]
# 指定DNS模式
mode = "ipv4_only"
# 指定DNS协议
protocol = "tcp_and_udp"
# DNS服务器和端口
nameservers = ["8.8.4.4:53","1.0.0.1:53"]
min_ttl = 600
max_ttl = 3600
cache_size = 256

[network]
# 禁用TCP
no_tcp = false
# 使用UDP
use_udp = true
# 零拷贝
zero_copy = true
# TCP快速打开
fast_open = true
# 指定 tcp 超时
tcp_timeout = 300
# 指定 udp 超时
udp_timeout = 30
# 发送代理协议头
send_proxy = false
# 发送代理协议版本
send_proxy_version = 2
# 接受代理协议头
accept_proxy = false
# 接受代理协议超时
accept_proxy_timeout = 5

[[endpoints]]
listen = "0.0.0.0:443"
remote = "10.187.71.4:443"

[[endpoints]]
listen = "0.0.0.0:26000"
remote = "10.187.71.5:8000"
END
}

# 3.1 获取service文件目录
get_service_dir() {
    ## 服务文件目录
    service_dir=' '

    ## 判断/usr/lib/systemd/system/目录是否存在
    if [ -d /usr/lib/systemd/system/ ]; then
        # Centos7的service目录是这个
        service_dir=/usr/lib/systemd/system/
    else
        # 如果没有/usr/lib这个目录,就是Ubuntu系统
        service_dir=/lib/systemd/system/
    fi
}

# 3.2生成service文件
create_realm_service() {
    # 获取service文件目录
    get_service_dir
    # 判断service文件是否存在
    ls ${service_dir}realm.service &>/dev/null && echo "realm服务文件已经存在" && exit 1
    # 创建realm.service文件
    cat >${service_dir}realm.service <<END
[Unit]
Description=realm service
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/realm -c /etc/realm/realm.toml
# \是反转义符
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=control-group
Restart=always
# 最大运行秒数(7天自动重启)
RuntimeMaxSec=604800
RestartSec=2s

[Install]
WantedBy=multi-user.target
END
    # 重载服务
    systemctl daemon-reload
}


main() {
    # 1.检查 glibc 版本
    check_glibc_version
    # 2.安装二进制包
    install_realm
    # 3.创建配置文件
    create_config
    # 4.创建服务自启动
    create_realm_service
    # 5.设置开机启动
    systemctl enable --now realm
}

# 执行安装
main