#!/usr/bin/env bash

# 安装epel源
install_epel_repo() {
    # 判断epel源是否存在
    ls /etc/yum.repos.d/epel.repo ||
        dnf install -y epel-release
}

# 安装ocserv主程序
install_ocserv_pkg() {
    which ocserv || dnf install -y ocserv
    # 安装lz4压缩支持
    which lz4 || dnf install -y lz4 lz4-devel
    # 安装公网证书签发工具
    which certbot || dnf install certbot -y
    # 开机自启动ocserv服务
    systemctl enable --now ocserv
}

# 安装certtool证书自签发工具
install_certtool() {
    ## 先判断有没有python3
    which python3 &>/dev/null || (yum install -y python3 && which python3 || exit 1)
    ## 判断certtool有无安装
    which certtool &>/dev/null || (yum install -y gnutls* gnutls-utils gnutls-devel libev-devel && which certtool || exit 1)
    # 创建libgnutls.so的软链接
    ls /usr/include/gnutls/x509.h &>/dev/null || ln -s /usr/lib64/libgnutls.so.30.28.2 /lib/libgnutls.so
    ln -s /usr/lib64/libgnutls.so.30 /usr/lib/
}

# 启动firewalld防火墙服务
start_firewall() {
    # 注销iptables服务
    systemctl mask iptables

    # # 注销ip6tables服务
    systemctl mask ip6tables

    # 注销ebtables服务
    systemctl mask ebtables

    # 开机自启firewalld服务并现在启动
    systemctl enable --now firewalld

    # 将默认zone切换到"外部"模式,会放行所有流量
    ## external(外部) ：使用防火墙作为网关时的外部网络。它配置为 NAT 伪装，以便你的内部网络保持私有但可访问。
    firewall-cmd --set-default-zone=external

    # 设置DNAT
    firewall-cmd --add-masquerade
    firewall-cmd --add-masquerade --per

    # 为VPN网段10.89.64.0/24启用IP伪装
    firewall-cmd --add-rich-rule='rule family="ipv4" source address="10.89.64.0/24" masquerade'
    firewall-cmd --add-rich-rule='rule family="ipv4" source address="10.89.64.0/24" masquerade' --permanent
}

# 配置内核ip转发
set_ip_forward() {
    echo "
net.ipv4.ip_forward = 1 
net.ipv6.conf.all.forwarding = 1
net.ipv4.conf.all.proxy_arp = 1
# 开启快速tcp
net.ipv4.tcp_fastopen = 3" >>/etc/sysctl.conf && sysctl -p
}

# 基本配置文件
bak_ocserv_config() {
    # 备份不存在先备份配置
    ls /etc/ocserv/ocserv.conf.bak || cp /etc/ocserv/ocserv.conf{,.bak}
    # 如果备份存在就按时间戳备份
    ls /etc/ocserv/ocserv.conf.bak && cp /etc/ocserv/ocserv.conf{,.$(date +%F_%T).bak}
}

# 安装ocserv完整步骤
install_full_ocserv() {
    # 安装epel源
    install_epel_repo
    # 安装ocserv软件包
    install_ocserv_pkg
    # 安装证书自签发工具
    install_certtool
    # 启用防火墙
    start_firewall
    # 开启内核IP转发
    set_ip_forward
    # 备份配置文件
    bak_ocserv_config
}

# 安装
install_full_ocserv
