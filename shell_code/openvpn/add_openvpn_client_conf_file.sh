#! /bin/bash

# 获取公网IP地址
## -s: 静默模式，不输出进度等信息
## 使用 curl 获取外部 IP 地址，并将其赋值给变量 IP_ADD
IP_ADD=$(curl -s ipv4.icanhazip.com | xargs echo -n)

# $# 获取传递给脚本的参数数量
para_num=$#

# 第一个参数 是add 或del
# $1 表示第一个传入的参数，决定操作类型（添加用户或删除用户）
operation=$1

# 客户端名称
# $2 表示第二个传入的参数，指定 VPN 用户名
vpn_user=$2

# 客户端配置目录
# 定义客户端配置目录的路径，其中 $vpn_user 是用户目录的名称
user_path=/etc/openvpn/client/$vpn_user

# 客户端配置文件
# 定义客户端配置文件路径
client_conf_file=${user_path}/${vpn_user}.ovpn

# 定义客户端证书文件路径
client_crt_file=/etc/openvpn/easy-rsa/pki/issued/${vpn_user}.crt

# 定义客户端私钥文件路径
client_key_file=/etc/openvpn/easy-rsa/pki/private/${vpn_user}.key

# 定义 CA 证书文件路径
ca_crt_file=/etc/openvpn/easy-rsa/pki/ca.crt

# 定义 ta.key 文件路径（用于 tls-auth）
ta_crt_file=/etc/openvpn/ta.key

# 定义 easy-rsa 工具的安装目录
easyrsa_dir=/etc/openvpn/easy-rsa

# 定义 easy-rsa 可执行文件路径
easyrsa_exe=$easyrsa_dir/easyrsa

# 帮助信息
function help() {
    echo './openvpn_user.sh add username(vpn username)'
    # 提示添加用户的用法
    echo './openvpn_user.sh del username(vpn username)'
    # 提示删除用户的用法
}

# 添加用户方法
function add_user() {
    # 检查客户端证书文件是否存在
    if [ -f "$client_crt_file" ]; then
        # 如果存在，提示用户已存在
        echo "$vpn_user 已经存在!"
        # 退出脚本，返回错误状态 1
        exit 1

    else
        # 切换到 easy-rsa 目录，若失败则退出脚本
        cd $easyrsa_dir || exit

        # 使用 easy-rsa 工具生成客户端证书，无密码保护
        # --batch 非交互模式生成客户端证书
        $easyrsa_exe --batch build-client-full "$vpn_user" nopass

    fi
}

# 删除用户方法
function del_user() {
    # 切换到 easy-rsa 目录，若失败则退出脚本
    cd $easyrsa_dir || exit

    # 使用 easy-rsa 工具撤销客户端证书
    # --batch 非交互式撤销用户证书
    $easyrsa_exe --batch revoke "$vpn_user"

    # 删除客户端配置目录及其内容
    rm -rf "$user_path"

    echo "================================success================================"
    echo "del vpn user: $vpn_user success!"
    echo "================================success================================"
}

# 生成client.conf
function generate_client_conf() {
    # client配置文件路径
    # 创建客户端配置目录，若已存在则忽略
    mkdir -p "$user_path"
    # 切换到客户端配置目录，若失败则退出脚本
    cd "$user_path" || exit
    # 检查客户端配置文件是否存在
    if [ -f "$client_conf_file" ]; then
        # 如果存在，提示配置文件已存在
        echo "$client_conf_file 已经存在!"
        # 退出脚本，返回错误状态 1
        exit 1

    fi

    # 生成客户端配置文件
    {
        # 指定 OpenVPN 模式为客户端
        echo "client"
        # 使用 TUN 设备（虚拟网络接口）
        echo "dev tun"
        # 使用 UDP 协议
        echo "proto udp"
        # 设置显式退出通知（仅适用于客户端）
        echo "explicit-exit-notify 1"
        # 无限重试解析主机名
        echo "resolv-retry infinite"
        # 远程服务器地址和端口
        echo "remote $IP_ADD 11194"
        # 不绑定特定的本地端口
        echo "nobind"
        # 以 nobody 用户身份运行（安全考虑）
        echo "user nobody"
        # 以 nobody 组身份运行（安全考虑）
        echo "group nobody"
        # 保持密钥文件，即使重新启动也不重新读取
        echo "persist-key"
        # 保持 TUN 设备，即使重新启动也不重新创建
        echo "persist-tun"
        # 要求远程服务器提供证书链
        echo "remote-cert-tls server"
        # 使用 SHA256 进行 HMAC 身份验证
        echo "auth SHA256"
        # 使用 AES-128-GCM 进行加密
        echo "cipher AES-128-GCM"
        # 不缓存身份验证信息
        echo "auth-nocache"
        # 使用 lz4-v2 压缩
        echo "compress lz4-v2"
        # 设置日志详细程度为 3
        echo "verb 3"
        # 定义密钥方向（1 表示客户端到服务器）
        echo "key-direction 1"
        # 设置客户端使用 Google DNS 8.8.4.4
        echo "dhcp-option DNS 8.8.4.4"
        # 设置客户端使用 Cloudflare DNS 1.0.0.1
        echo "dhcp-option DNS 1.0.0.1"
        # 将所有流量重定向到 VPN（忽略本地 DHCP）
        echo "redirect-gateway def1 bypass-dhcp"
        # 使用 exe 方法添加路由(Windows专用)
        echo "route-method exe"
        # 阻止外部 DNS（Windows 专用）
        echo "block-outside-dns"
        # 路由延迟 2 秒
        echo "route-delay 2"
        # 保持连接，5 秒发送一次心跳包，25 秒无响应则重新连接
        echo "keepalive 5 25"
        # 静默重放攻击警告
        echo "mute-replay-warnings"
        # 开始 tls-auth 密钥部分
        echo "<tls-auth>"
        # 读取 ta.key 文件内容
        cat ${ta_crt_file}
        # 结束 tls-auth 密钥部分
        echo "</tls-auth>"

        # 开始 CA 证书部分
        echo "<ca>"
        # 读取 ca.crt 文件内容
        cat ${ca_crt_file}
        # 结束 CA 证书部分
        echo "</ca>"
        # 开始客户端证书部分
        echo "<cert>"
        # 读取客户端证书文件内容
        cat "${client_crt_file}"
        # 结束客户端证书部分
        echo "</cert>"
        # 开始客户端私钥部分
        echo "<key>"
        # 读取客户端私钥文件内容
        cat "${client_key_file}"
        # 结束客户端私钥部分
        echo "</key>"
        # 将生成的配置内容追加到客户端配置文件
    } >>"${client_conf_file}"

}

# 主方法
function main() {
    # 当参数不等于2
    # 检查参数数量是否等于 2
    if [ $para_num -ne 2 ]; then
        # 如果不是 2 个参数，提示非法参数
        echo "参数非法!"
        # 调用帮助信息
        help
        # 退出脚本，返回错误状态 1
        exit 1

    else
        # 如果参数数量正确
        if [ "$operation" = "add" ]; then
            # 检查第一个参数是否为 "add"
            # 调用添加用户函数
            add_user
            # 生成客户端配置文件
            generate_client_conf

            # 打印添加vpn客户端成功
            echo "===============================success=================================="
            echo "add vpn user: $vpn_user success!"
            echo "===============================success=================================="
        # 检查第一个参数是否为 "del"
        elif [ "$operation" = "del" ]; then
            # 调用删除用户函数
            del_user

        else
            # 如果第一个参数不是 "add" 或 "del"
            # 提示仅支持 "add" 或 "del"
            echo '第一个参数仅支持 add 或 del'
            # 调用帮助信息
            help
            # 退出脚本，返回错误状态 1
            exit 1

        fi
    fi
}

# 调用主方法，启动脚本逻辑
main