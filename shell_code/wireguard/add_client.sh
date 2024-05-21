#!/usr/bin/env bash

# 开启debug
# set -ex
# 传入客户端名称
client_name=$1
# 获取公网IP地址
server_public_ip=$(curl -s ipv4.icanhazip.com)
# 连接保活间隔
Persistent_Keepalive_time=1
# wg服务器监听的端口
Server_listen_port=$(wg show wg0 listen-port || echo 11194)

# 环境检查
function check_env() {
    ## 查看qrencode是否存在
    which qrencode &>/dev/null || yum install -y qrencode || apt install -y qrencode

    ## 检查user_conf目录，不存在就创建
    ls /etc/wireguard/user_conf/ &>/dev/null || mkdir -p /etc/wireguard/user_conf/
    # 增加配置之前要先确保启动wg服务端
    ## shell变量默认都是全局变量，local表示为局部变量
    local result
    result=$(systemctl is-active wg-quick@wg0)
    if [[ $result != "active" ]]; then
        echo "wg服务端未启动，现在启动wg服务端"
        (ls /etc/wireguard/wg0.conf && systemctl restart wg-quick@wg0.service) || (echo "wireguard服务启动失败，脚本停止" && exit 1)
    fi
}

# 设置客户端dns
function set_client_dns() {
    local result
    result=$(systemctl is-active dnsmasq.service)
    if [[ $result != "active" ]]; then
        echo "dnsmasq.service服务端未启动"
        client_dns="1.0.0.1"
    else
        client_dns=$(hostname -i)
    fi
}

# 生成客户端密钥文件
function gen_client_key() {
    # 判断同名密钥文件是否存在,，如存在停止脚本
    (ls /etc/wireguard/user_conf/"$client_name".privatekey &>/dev/null && ls /etc/wireguard/user_conf/"$client_name".publickey &>/dev/null) && echo "同名密钥文件已存在，脚本停止" && exit 1
    # 生成客户端密钥对文件
    umask 077 | wg genkey | tee /etc/wireguard/user_conf/"$client_name".privatekey | wg pubkey >/etc/wireguard/user_conf/"$client_name".publickey

    # 检查预共享密钥是否存在，如存在停止脚本
    ls /etc/wireguard/user_conf/"$client_name".PresharedKey &>/dev/null && echo "同名密钥文件已存在，脚本停止" && exit 1
    # 生成预共享密钥
    umask 077 | wg genpsk | tee /etc/wireguard/user_conf/"$client_name".PresharedKey
}

# 为用户分配IP地址
function gen_client_ip() {
    ## 统计目录下的配置名数量,+2就是已创建的ip数量
    ip_sum=$(find /etc/wireguard/user_conf/ -type f | wc -l)
    # 新增的ip地址=已创建的ip数量+2
    ip_add_host=$((ip_sum + 2))
    # shell脚本的变量默认是全局变量
    ip_add="10.89.64.$ip_add_host"
}

# 添加新客户端配置到wg服务端wg0.conf文件中
function add_client_to_server() {
    # 读取公钥字符串
    client_public=$(cat /etc/wireguard/user_conf/"$client_name".publickey)
    # 增加客户端的公钥到服务端(加载到内存队列中)
    ## set <interface>
    ## peer <base64 public key>
    ## preshared-key 用户的预共享密钥，这里必须传文件
    wg set wg0 peer "$client_public" preshared-key /etc/wireguard/user_conf/"$client_name".PresharedKey persistent-keepalive "$Persistent_Keepalive_time" allowed-ips "$ip_add"

    # 重启wg服务端，使新的客户端生效---不够优雅，会有秒级中断
    ## 一定要重启wg服务端,新的客户端配置才会被加载,加载完成后新客户端就可以接入到服务器了。
    systemctl restart wg-quick@wg0

    # 在不中断活动会话的情况下重新加载配置文件(比重启服务优雅)
    # wg syncconf wg0 <(wg-quick strip wg0)
    # wg syncconf wg0 <(wg-quick strip /etc/wireguard/user_conf/u1/u1.conf)
}

# 生成客户端的配置文件
function gen_new_user_profile() {
    cat <<EOF >/etc/wireguard/user_conf/"$client_name".conf
[Interface]
# name=$1
# 客户端的私匙
PrivateKey = $(cat /etc/wireguard/user_conf/"$client_name".privatekey)

# 客户端的内网IP地址
Address = $ip_add/24

# 客户端MTU配置,不设置,则为auto

# 解析域名用的DNS
DNS = $client_dns

[Peer]
# 服务器的公匙
PublicKey = $(cat /etc/wireguard/server.publickey)

# 预共享密钥
PresharedKey = $(cat /etc/wireguard/user_conf/"$client_name".PresharedKey)

# 因为是客户端，所以这个设置为全部IP段即可
AllowedIPs = 0.0.0.0/0

# 服务器地址和端口
Endpoint = $server_public_ip:$Server_listen_port

# 连接保活间隔
## PersistentKeepalive 参数只适用于 WireGuard 的客户端配置，而不是服务器配置
## 服务端和客户端一方没有公网IP，都是NAT，那么就需要添加这个参数定时连接服务端(单位：秒)
## 客户端和服务端都是公网,不建议使用该参数（设置为0，或客户端配置文件中删除这行）
PersistentKeepalive = $Persistent_Keepalive_time
EOF
}

# 清理客户端的密钥文件,防止密钥对丢失
function clear_user_key_file() {
    # 删除公钥文件
    rm -rf /etc/wireguard/user_conf/"$client_name".publickey &>/dev/null
    # 删除私钥文件
    rm -rf /etc/wireguard/user_conf/"$client_name".privatekey &>/dev/null
    # 删除共享密钥文件
    rm -rf /etc/wireguard/user_conf/"$client_name".PresharedKey &>/dev/null
}

# 在屏幕生成二维码
function gen_qrencode() {

    # 去除配置文件到注释和空行，防止生成的wg二维码不被识别
    # grep -Ev '^#|^$' /etc/wireguard/user_conf/"$client_name".conf >tmpfile && mv -f /etc/wireguard/user_conf/tmpfile /etc/wireguard/user_conf/"$client_name".conf
    grep -Ev '^#|^$' /etc/wireguard/user_conf/"$client_name".conf >/etc/wireguard/user_conf/tmpfile

    # 将这个客户端配置文件生成二维码,展示在终端中
    qrencode -t ansiutf8 </etc/wireguard/user_conf/tmpfile
}

#开始菜单
function main() {
    # 环境检查
    check_env
    # 生成客户端密钥文件
    gen_client_key
    # 为用户分配IP地址
    gen_client_ip
    # 配置客户端的DNS
    set_client_dns
    # 添加新客户端配置到wg服务端wg0.conf文件中
    add_client_to_server
    # 生成客户端的配置文件
    gen_new_user_profile "$@"
    # 删除客户端的密钥文件
    clear_user_key_file "$@"
    # 在屏幕生成二维码
    gen_qrencode
}

# main方法，显示菜单
main "$@"
