#!/usr/bin/env bash

# 判断Linux发行版
function check_os() {
    if grep -qs "ubuntu" /etc/os-release; then
        os="ubuntu"
        os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
    elif [[ -e /etc/debian_version ]]; then
        os="debian"
        os_version=$(grep -oE '[0-9]+' /etc/debian_version | head -1)
    elif [[ -e /etc/almalinux-release || -e /etc/rocky-release || -e /etc/centos-release ]]; then
        os="centos"
        # grep参数
        ## -s 不显示错误信息
        ## -h 不标示该列所属的文件名称
        ## -o 只输出文件中匹配到的部分
        ## -E 使用正则表达式
        os_version=$(grep -shoE '[0-9]+' /etc/almalinux-release /etc/rocky-release /etc/centos-release | head -1)
    elif [[ -e /etc/fedora-release ]]; then
        os="fedora"
        os_version=$(grep -oE '[0-9]+' /etc/fedora-release | head -1)
    else
        echo "此安装程序似乎在不受支持的发行版上运行。
支持的发行版有 Ubuntu、Debian、AlmaLinux、Rocky Linux、CentOS 和 Fedora。" && exit 1
    fi
}

# 判断Linux版本
function check_os_ver() {
    if [[ "$os" == "ubuntu" && "$os_version" -lt 1804 ]]; then
        echo "使用此安装程序需要 Ubuntu 18.04 或更高版本。
此版本的 Ubuntu 太旧且不受支持." && exit 1
    fi

    if [[ "$os" == "debian" && "$os_version" -lt 10 ]]; then
        echo "使用此安装程序需要 Debian 10 或更高版本。
此版本的 Debian 太旧且不受支持." && exit 1
    fi

    if [[ "$os" == "centos" && "$os_version" -lt 7 ]]; then
        echo "使用此安装程序需要 CentOS 7 或更高版本。
此版本的 CentOS 太旧且不受支持." && exit 1
    fi
}

# 检查nftables防火墙
function check_nftables() {
    if [ "$os" = "centos" ]; then
        if grep -qs "hwdsl2 VPN script" /etc/sysconfig/nftables.conf ||
            systemctl is-active --quiet nftables 2>/dev/null; then
            exiterr "此系统启用了 nftables，但此安装程序不支持。"
        fi
    fi
}

# 安装前环境检查
function check_install_env() {
    # 先检查系统发行版
    check_os
    # 检查Linux版本号
    check_os_ver
    # 检查是否不受支持的防火墙
    check_nftables
}
# 安装ELRepo
function install_ELRepo() {
    (yum -y install epel-release elrepo-release || echo "yum源错误，请检查" && exit 1) &&
        sed -i "0,/enabled=0/s//enabled=1/" /etc/yum.repos.d/epel.repo
    sed -i "0,/enabled=0/s//enabled=1/" /etc/yum.repos.d/elrepo.repo
    yum repolist
}

function install_wg_pkg() {
    # 安装wg内核模块和wg-quick命令行
    yum install -y kmod-wireguard wireguard-tools || dnf install -y wireguard-tools
    echo "更新完成"
}

# 调整内核参数
function tune_kernel() {
    echo "
# 开启内核开启数据包转发
net.ipv4.ip_forward = 1 
net.ipv4.conf.all.proxy_arp = 1
" >>/etc/sysctl.conf && sysctl -p

}

# 加载内核模块
function load_the_wg_kernel_module() {

    # 在启动时自动加载wireguard模块
    echo wireguard >/etc/modules-load.d/wireguard.conf

    # 加载内核模块,查看模块是否加载成功
    modprobe wireguard && lsmod | grep wireguard --color=auto
}

# 生成服务端密钥对
function gen_server_key() {
    ls /etc/wireguard || mkdir -p /etc/wireguard
    cd /etc/wireguard/ || exit
    # 生成服务器的密钥对
    umask 077 | wg genkey | tee /etc/wireguard/server.privatekey | wg pubkey >/etc/wireguard/server.publickey
    # 锁定服务器的密钥对,防止误删
    chattr +i /etc/wireguard/server.privatekey /etc/wireguard/server.publickey
    lsattr /etc/wireguard/server.privatekey /etc/wireguard/server.publickey
}

# 配置服务端
function init_wg_server() {

    # 网卡名
    eth=$(ls /sys/class/net | awk '/^e/{print}')
    # 如果已经存在wg0.conf文件，就退出代码
    ls /etc/wireguard/wg0.conf &>/dev/null && echo "wg0.conf文件已经存在" && exit 1

    # 生成服务端密钥对
    gen_server_key

    # 生成wg服务端配置文件
    cat <<EOF >/etc/wireguard/wg0.conf
[Interface]
# 服务器的私匙，对应客户端配置中的公匙（自动读取上面刚刚生成的密匙内容）
PrivateKey = $(cat /etc/wireguard/server.privatekey)
# 本机的内网IP地址，一般默认即可，除非和你服务器或客户端设备本地网段冲突
Address = 10.89.64.1/24

# 运行WireGuard时要执行的iptables防火墙规则，用于打开NAT转发之类的。
## 如果不是Ubuntu系统,就注释掉ufw防火墙
#PostUp = ufw route allow in on wg0 out on $eth
PostUp = iptables -t nat -I POSTROUTING -o $eth -j MASQUERADE
# 自动调整mss，防止某些网站打不开
PostUp = iptables -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# 停止WireGuard时要执行的iptables防火墙规则，用于关闭NAT转发之类的。
## 如果不是Ubuntu系统,就注释掉ufw防火墙
# PreDown = ufw route delete allow in on wg0 out on $eth
PreDown = iptables -t nat -D POSTROUTING -o $eth -j MASQUERADE
# 删除自动调整mss
PostDown = iptables -D FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# 服务端监听端口，可以自行修改
ListenPort = 51820
# SaveConfig确保当WireGuard接口关闭时,任何更改都将保存到配置文件中
SaveConfig = true
# 服务端请求域名解析DNS,可以在本机搭建dns服务加快解析
DNS = 1.0.0.1,8.8.4.4
# 服务端mtu不设置,为自动mtu(默认)
EOF

    # 修改配置文件和密钥文件为600
    chmod 600 /etc/wireguard/wg0.conf
}

# Centos7安装wireguard
function install_wireguard() {
    # 安装ELRepo
    install_ELRepo
    # 安装wg的模块和包
    install_wg_pkg
    # 调整内核参数
    tune_kernel
    # 加载wg内核模块
    load_the_wg_kernel_module
    # 配置服务端
    init_wg_server
    # 启动wg-quick@wg0服务
    systemctl enable --now wg-quick@wg0
}

# Centos7卸载wireguard
function remove_wireguard() {
    # 禁用wireguard开机自启服务
    systemctl disable --now wg-quick@wg0
    # 解锁服务器的密钥对文件
    chattr -i /etc/wireguard/server.privatekey /etc/wireguard/server.publickey

    # 删除wireguard配置即可
    rm -rf /etc/wireguard/*

    # 取消开机自动加载wg内核模块
    rm -rf /etc/modules-load.d/wireguard.conf

    # 取消sysctl配置--关闭数据包转发
    ## 删除net.ipv4.ip_forward行
    sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf &>/dev/null
    ## 删除net.ipv4.conf.all.proxy_arp行
    sed -i '/net.ipv4.conf.all.proxy_arp/d' /etc/sysctl.conf &>/dev/null
    # 数据包转发--热生效
    ## 1为开启；0为关闭
    echo 0 >/proc/sys/net/ipv4/ip_forward
    echo 0 >/proc/sys/net/ipv4/conf/all/proxy_arp

    echo "卸载完成"
}

#开始菜单
function start_menu() {
    # 先进行安装前环境检查
    check_install_env
    clear
    echo "========================="
    echo " 介绍：适用于CentOS7"
    echo " 作者：Miles"
    echo " 网站：https://blog.csdn.net/omaidb"
    echo "========================="
    echo "注意：本脚本只支持Centos7"
    echo "1. 安装wireguard"
    echo "2. 卸载wireguard"
    echo "0. 退出脚本"
    echo "请输入数字:"
    read -r num
    case "$num" in
    1)
        echo "开始安装wireguard"
        install_wireguard
        ;;
    2)
        echo "开始卸载wireguard"
        remove_wireguard
        ;;
    0)
        exit 1
        ;;
    *)
        clear
        echo "请输入正确数字"
        sleep 5s
        start_menu
        ;;
    esac
}

# main方法，显示菜单
start_menu
