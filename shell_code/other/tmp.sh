#!/bin/bash

function check() {
    # 获取最近错误登录的IP列表
    ip_list=$(journalctl _SYSTEMD_UNIT=sshd.service | grep 'Failed password' | awk '{print $(NF-3)}' | sort | uniq)
}

# 拉黑IP
function block_ip() {
    local ip="$1"
    echo "Blocking IP: $ip"
    # 检查是否已有该IP的防火墙规则
    if sudo iptables -C INPUT -s "$ip" -j DROP >/dev/null 2>&1; then
        echo "IP $ip is already blocked."
    else
        # 将IP添加到防火墙规则中
        sudo iptables -A INPUT -s "$ip" -j DROP
    fi
}

#间隔10s无限循环检查函数
while true
do 
    check
    #每隔10s检查一次，时间可根据需要自定义
    sleep 10
    # 遍历IP列表并禁用
    for ip in $ip_list; do
        block_ip "$ip"
    done
done