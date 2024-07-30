#!/usr/bin/env bash

# 服务端端口
Server_port=22

# 判断wireguard是否已经安装
check_if_wg_ok() {
    if [ -d "/etc/wireguard/" ]; then
        # 目录存在时运行的命令
        echo "发现/etc/wireguard/目录，可能已经安装过wireguard，请先清理环境。" && exit 1
    fi
    # 如果wg命令行存在，则停止安装
    if [ -f "/usr/bin/wg" ]; then
        # 如果文件存在则运行的命令
        echo "发现/usr/bin/wg命令，可能已经安装过wireguard，请先清理环境。" && exit 1
    fi

}

# 判断Linux发行版
check_os() {
    # 如果有yum包管理器,就是rhel系统发行版
    if which yum >/dev/null 2>&1; then
        os=rhel
    else
        echo "不是rhel发行版"
        exit 1
    fi

}

# 判断Linux版本
check_os_ver() {
    # 获取os的版本号
    os_version=$(grep -shoE '[0-9]+' /etc/redhat-release /etc/almalinux-release /etc/rocky-release /etc/centos-release | head -1)
    if [[ "$os" && "$os_version" -lt 7 ]]; then
        echo "使用此安装程序需要 CentOS 7 或更高版本.此版本的 CentOS 太旧且不受支持." && exit 1
    fi
}

# 检查iptables防火墙
function check_iptables_and_firewalld() {
    if [ "$os" = "rhel" ]; then
        if systemctl is-active --quiet iptables 2>/dev/null; then
            echo "此系统启用了iptables服务,停止并仅用iptables服务,wg-quick才能正常执行前置和后置脚本"
            systemctl disable --now iptables && systemctl mask --now iptables && systemctl mask --now ip6tables && systemctl mask --now ebtables && echo "自动停止iptables服务成功"
        fi
        if systemctl is-active --quiet firewalld 2>/dev/null; then
            echo "此系统启用了firewalld服务,停止并仅用firewalld服务,wg-quick才能正常执行前置和后置脚本"
            systemctl disable --now firewalld && echo "自动停止iptables服务成功"
        fi
    fi
}

# 检查nftables防火墙
function check_nftables() {
    if [ "$os" = "rhel" ]; then
        if grep -qs "hwdsl2 VPN script" /etc/sysconfig/nftables.conf ||
            systemctl is-active --quiet nftables 2>/dev/null; then
            exiterr "此系统启用了 nftables,但此安装程序不支持."
        fi
    fi
}

# 0.安装前环境检查
function check_install_env() {
    # 先检查系统发行版
    check_os
    # 检查Linux版本号
    check_os_ver
    # 检查iptabels服务是否停止
    check_iptables_and_firewalld
    # 检查是否不受支持的防火墙
    check_nftables
}

# 安装依赖包
function install_dependent_pkg() {
    yum install -y systemd-devel libevent-devel || dnf install -y systemd-devel libevent-devel
    echo "安装依赖包完成"
}

function install_wg_pkg() {
    # 检查wg是否已经安装
    check_if_wg_ok
    # 安装的依赖的repo
    rpm -q --quiet epel-release || yum install -y epel-release
    rpm -q --quiet elrepo-release || yum install -y elrepo-release
    # 安装wg内核模块和wg-quick命令行
    yum install -y kmod-wireguard wireguard-tools || dnf install -y wireguard-tools
    echo "安装wg工具完成"
}

# 加载内核模块
function load_the_wg_kernel_module() {

    # 在启动时自动加载wireguard模块
    echo wireguard >/etc/modules-load.d/wireguard.conf

    # 加载内核模块,查看模块是否加载成功
    modprobe wireguard && lsmod | grep wireguard --color=auto
}

# 调整内核参数
function tune_kernel() {

    if [[ "$os" = "rhel" && "$os_version" -eq 7 ]]; then
        # 下载适用于wg的sysctl配置
        wget -P /etc/sysctl.d -c https://raw.githubusercontent.com/omaidb/qiaofei_notes/main/shell_code/wireguard/sysctl_vpn_rhel7.conf

    elif [[ "$os" = "rhel" && "$os_version" -eq 8 ]]; then
        # 下载适用于wg的sysctl配置
        wget -P /etc/sysctl.d -c https://raw.githubusercontent.com/omaidb/qiaofei_notes/main/shell_code/wireguard/sysctl_vpn_rhel8.conf
    else
        echo "使用此安装程序需要 CentOS7 或RHEL8.此版本的Linux不受支持." && exit 1
    fi

    # 使sysctl配置生效
    sysctl --system

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
    # 如果已经存在wg0.conf文件,就退出代码
    ls /etc/wireguard/wg0.conf &>/dev/null && echo "wg0.conf文件已经存在" && exit 1

    # 生成服务端密钥对
    gen_server_key

    # 生成wg服务端配置文件
    cat <<EOF >/etc/wireguard/wg0.conf
[Interface]
# 服务器的私匙,对应客户端配置中的公匙(自动读取上面刚刚生成的密匙内容)
PrivateKey = $(cat /etc/wireguard/server.privatekey)
# 本机的内网IP地址,一般默认即可,除非和你服务器或客户端设备本地网段冲突
Address = 10.89.64.1/24

# 运行WireGuard时要执行的iptables防火墙规则,用于打开NAT转发之类的.
## 如果不是Ubuntu系统,就注释掉ufw防火墙
# PreUp:在建立 VPN 连接之前执行的命令或脚本
# PostUp:在成功建立 VPN 连接后执行的命令或脚本
# 放行wg的udp端口
PreUp = iptables -w -I INPUT -p udp --dport $Server_port -j ACCEPT -m comment --comment "放行 udp/$Server_port端口"
#PostUp = ufw route allow in on wg0 out on $eth
PostUp = iptables -w -t nat -I POSTROUTING -o $eth -j MASQUERADE -m comment --comment '开启地址转换'
# 自动调整mss,防止某些网站打不开
PostUp = iptables -w -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu -m comment --comment '自动调整mss,防止某些网站打不开'
# 调整DSCP值
PostUp = iptables -w -t mangle -I OUTPUT -p tcp -s 10.89.64.0/24 -j DSCP --set-dscp 46 -m comment --comment '出方向TCP流量的DSCP值设为46'
PostUp = iptables -w -t mangle -I OUTPUT -p udp -s 10.89.64.0/24 -j DSCP --set-dscp 46 -m comment --comment '入方向UDP流量的DSCP值为46'


# PreDown:在断开 VPN 连接之前 执行的命令或脚本
# PostDown:在成功断开 VPN 连接之后 执行的命令或脚本
# 停止WireGuard时要执行的iptables防火墙规则,用于关闭NAT转发之类的.
## 如果不是Ubuntu系统,就注释掉ufw防火墙
# PreDown = ufw route delete allow in on wg0 out on $eth
PreDown = iptables -w -t nat -D POSTROUTING -o $eth -j MASQUERADE -m comment --comment '开启地址转换'
# 删除自动调整mss
PostDown = iptables -w -D FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu -m comment --comment '自动调整mss,防止某些网站打不开'
# 删除DSCP值
PostDown = iptables -w -t mangle -D OUTPUT -p tcp -s 10.89.64.0/24 -j DSCP --set-dscp 46 -m comment --comment '出方向TCP流量的DSCP值设为46'
PostDown = iptables -w -t mangle -D OUTPUT -p udp -s 10.89.64.0/24 -j DSCP --set-dscp 46 -m comment --comment '入方向UDP流量的DSCP值为46'
# 删除放行端口
PostDown = iptables -w -D INPUT -p udp --dport $Server_port -j ACCEPT -m comment --comment "放行 udp/$Server_port端口"


# 服务端监听端口,可以自行修改
ListenPort = $Server_port
# SaveConfig确保当WireGuard接口关闭时,任何更改都将保存到配置文件中
SaveConfig = true
# 服务端请求域名解析DNS,可以在本机搭建dns服务加快解析
DNS = 1.0.0.1,8.8.4.4
# 服务端mtu不设置,为自动mtu(默认)
# 连接保活间隔PersistentKeepalive 参数只适用于 WireGuard 的客户端配置,而不是服务器配置
EOF

    # 修改配置文件和密钥文件为600
    chmod 600 /etc/wireguard/wg0.conf
}

# Centos7安装wireguard
function install_wireguard() {

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

    # 删除wireguard配置
    rm -rf /etc/wireguard/*

    # 取消开机自动加载wg内核模块
    rm -rf /etc/modules-load.d/wireguard.conf

    # 卸载wg-quick命令行
    yum remove -y wireguard-tools || dnf remove -y wireguard-tools

    # 取消sysctl配置--关闭数据包转发

    # 数据包转发--热生效
    ## 1为开启;0为关闭
    echo 0 >/proc/sys/net/ipv4/ip_forward
    echo 0 >/proc/sys/net/ipv4/conf/all/proxy_arp

    echo "卸载完成"
}

#开始菜单
function start_menu() {
    # 先进行安装前环境检查
    check_install_env
    echo "========================="
    echo " 介绍:适用于RHEL7和RHEL8"
    echo " 作者:Miles"
    echo " 网站:https://blog.csdn.net/omaidb"
    echo "========================="
    echo "注意:本脚本只支持Centos7"
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

# main方法,显示菜单
start_menu
