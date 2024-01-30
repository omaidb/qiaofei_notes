#! /bin/bash

## 获取公网IP地址
IP_ADD=$(curl -s ipv4.icanhazip.com | xargs echo -n)
# 总共接受的参数数量
para_num=$#
# 第一个参数 是add 或del
operation=$1
# 客户端名称
vpn_user=$2
# 客户端配置目录
user_path=/etc/openvpn/client/$vpn_user
# 客户端配置文件
client_conf_file=${user_path}/${vpn_user}.ovpn
# 客户端证书文件
client_crt_file=/etc/openvpn/easy-rsa/pki/issued/${vpn_user}.crt
# 客户端私钥文件
client_key_file=/etc/openvpn/easy-rsa/pki/private/${vpn_user}.key
# CA证书文件
ca_crt_file=/etc/openvpn/easy-rsa/pki/ca.crt
# DH证书文件
# dh_crt_file=/etc/openvpn/easy-rsa/pki/dh.pem
# ta证书文件
ta_crt_file=/etc/openvpn/ta.key
# easyrsa程序目录
easyrsa_dir=/etc/openvpn/easy-rsa
# easyrsa程序路径
easyrsa_exe=$easyrsa_dir/easyrsa

# 帮助信息
function help() {
    echo './openvpn_user.sh add username(vpn username)'
    echo './openvpn_user.sh del username(vpn username)'
}

# 添加用户方法
function add_user() {
    if [ -f "$client_crt_file" ]; then
        echo "$vpn_user 已经存在!"
        exit 1
    else
        cd $easyrsa_dir || exit
        # 非交互模式生成客户端证书
        $easyrsa_exe --batch build-client-full "$vpn_user" nopass
    fi
}

# 删除用户方法
function del_user() {
    cd $easyrsa_dir || exit
    # 非交互式撤销用户证书
    $easyrsa_exe --batch revoke "$vpn_user"
    # 删除用户配置目录
    rm -rf "$user_path"
    echo "================================success================================"
    echo "del vpn user: $vpn_user success!"
    echo "================================success================================"
}

# 生成client.conf
function generate_client_conf() {
    # client配置文件路径
    mkdir -p "$user_path"
    cd "$user_path" || exit

    if [ -f "$client_conf_file" ]; then
        echo "$client_conf_file 已经存在!"
        exit 1

    fi

    # 生成客户端配置文件
    {
        echo "client"
        echo "dev tun"
        echo "proto udp"
        echo "explicit-exit-notify 1"
        echo "remote-random"
        # echo "resolv-retry infinite"
        econ "resolv-retry 20"
        echo "remote $IP_ADD 11194"
        echo "nobind"
        echo "user nobody"
        echo "group nobody"
        echo "persist-key"
        echo "persist-tun"
        echo "remote-cert-tls server"
        echo "auth SHA256"
        echo "cipher AES-128-GCM"
        echo "auth-nocache"
        echo "allow-compression yes"
        echo "compress lz4-v2"
        echo "verb 3"
        echo "key-direction 1"
        echo "dhcp-option DNS 8.8.4.4"
        echo "dhcp-option DNS 1.0.0.1"
        echo "redirect-gateway def1 bypass-dhcp"
        echo "route-method exe"
        echo "block-outside-dns"
        echo "route-delay 2"
        echo "keepalive 5 75"
        echo "mute-replay-warnings"
        echo "<tls-auth>"
        cat "${ta_crt_file} 1"
        echo "</tls-auth>"

        echo "<ca>"
        cat ${ca_crt_file}
        echo "</ca>"

        echo "<cert>"
        tail -n 31 "${client_crt_file}"
        echo "</cert>"

        echo "<key>"
        cat "${client_key_file}"
        echo "</key>"

    } >>"${client_conf_file}"
}

# 主方法
function main() {
    # 当参数不等于2
    if [ $para_num -ne 2 ]; then
        echo "参数非法!"
        help
        exit 1
    else
        if [ "$operation" = "add" ]; then
            add_user
            # 生成客户端配置文件
            generate_client_conf
            # 打印添加vpn客户端成功
            echo "===============================success=================================="
            echo "add vpn user: $vpn_user success!"
            echo "===============================success=================================="
        elif [ "$operation" = "del" ]; then
            del_user
        else
            echo '第一个参数仅支持 add 或 del'
            help
            exit 1
        fi
    fi
}

main
