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
        ## -w 5：等待锁的时间为 5 秒。如果在规定时间内无法获取到锁，将会报错。
        ## -W 100000：尝试获取锁的最大次数为 100,000 次。如果超过此次数仍无法获取到锁，将会报错。
        iptables -w 5 -W 100000 -A INPUT -s "$ip" -j DROP
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
        ## -w 5：等待锁的时间为 5 秒。如果在规定时间内无法获取到锁，将会报错。
        ## -W 100000：尝试获取锁的最大次数为 100,000 次。如果超过此次数仍无法获取到锁，将会报错。
        ip6tables -w 5 -W -A INPUT -s "$ip" -j DROP
        # echo "iptabtles拉黑$ip"
    else
        # echo "IP $ip 已在被iptables封锁中。"
        :
    fi
}

# 方法：添加IP到/etc/hosts.deny
function add_hosts_deny() {
    local ip="$1"
    # echo "Add ip $ip to /etc/hosts.deny"
    echo "sshd:  $ip" >>/etc/hosts.deny
}

main() {
    # 下载恶意IP库
    download_blocklist
    # 从恶意IP列表文件中循环读取IP
    while IFS= read -r ip; do
        # 添加IP到tcpd禁止列表
        add_hosts_deny "$ip"
        # echo "$ip"
        # 判断字符串是 IPv4 还是 IPv6
        if [[ $ip =~ $ipv4_regex ]]; then
            # 拉黑检查到的ip
            block_ipv4 "$ip"
            # 捕获block_ipv4的异常
            trap 'exit 2' INT
        elif [[ $ip_address =~ $ipv6_regex ]]; then
            block_ipv6 "$ip"
            # 捕获block_ipv6的异常
            trap 'exit 4' INT
        else
            # 文件不存在则创建
            test -e /tmp/hosts.error || touch /tmp/hosts.error
            # echo "无效地址"
            echo "sshd: $ip" >>/tmp/hosts.error >/dev/null 2>&1
        fi
    done </tmp/all.txt
    echo "ad Blocak IP list Done"
}

# 执行主方法
main
