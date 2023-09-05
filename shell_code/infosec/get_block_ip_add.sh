#!/usr/bin/env bash

# IPv4 正则表达式
ipv4_regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"

# IPv6 正则表达式
ipv6_regex="^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$"

function download_blocklist() {
    # 下载最新的恶意IP数据库
    wget -O /tmp/all.txt https://lists.blocklist.de/lists/all.txt
}

# 方法：拉黑IP
function block_ipv4() {
    local ip="$1"
    # echo "Blocking IP: $ip"
    # 检查是否已有该IP的防火墙规则,存在则什么都不显示，不存在则报错
    if ! iptables -C INPUT -s "$ip" -j DROP >/dev/null 2>&1; then
        # 将IP添加到防火墙规则中
        echo "sshd:  $ip" >>/etc/hosts.deny
        # echo "Add ip $ip to /etc/hosts.deny"
        iptables -A INPUT -s "$ip" -j DROP
        # echo "iptabtles拉黑$ip"
    else
        # echo "IP $ip 已在被iptables封锁中。"
        :
    fi
}

# 方法：拉黑IP
function block_ipv6() {
    local ip="$1"
    # echo "Blocking IP: $ip"
    # 检查是否已有该IP的防火墙规则,存在则什么都不显示，不存在则报错
    if ! ip6tables -C INPUT -s "$ip" -j DROP >/dev/null 2>&1; then
        # 将IP添加到防火墙规则中
        echo "sshd:  $ip" >>/etc/hosts.deny
        # echo "Add ip $ip to /etc/hosts.deny"
        ip6tables -A INPUT -s "$ip" -j DROP
        # echo "iptabtles拉黑$ip"
    else
        # echo "IP $ip 已在被iptables封锁中。"
        :
    fi
}

main() {
    # 下载恶意IP库
    download_blocklist
    # 从恶意IP列表文件中循环读取IP
    while IFS= read -r ip; do
        # echo "$ip"
        # 判断字符串是 IPv4 还是 IPv6
        if [[ $ip =~ $ipv4_regex ]]; then
            # 拉黑检查到的ip
            block_ipv4 "$ip"
            # 捕获block_ipv4的异常
            trap block_ipv4 SIGINT SIGTERM SIGHUP
        elif [[ $ip_address =~ $ipv6_regex ]]; then
            block_ipv6 "$ip"
            # 捕获block_ipv6的异常
            trap block_ipv6 SIGINT SIGTERM SIGHUP
        else
            echo "无效地址"
        fi
    done </tmp/all.txt
    echo "ad Blocak IP list Done"
}

# 执行主方法
main
