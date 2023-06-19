#!/bin/bash

#  本脚本适用于rhel8+iptables
# 自动拉黑ssh密码登录错误大约10次的ip

# 开启debug模式
# set -ex

function check() {
    # 初始化IP列表
    block_ip_list=""

    # 获取最近ssh密码错误登录的IP列表和次数
    failed_logins=$(journalctl _SYSTEMD_UNIT=sshd.service | grep 'Failed password' | awk '{print $(NF-3)}' | sort | uniq -c)

    # 遍历错误登录事件
    while read -r line; do
        # ssh登录错误次数 
        count=$(echo "$line" | awk '{print $1}')
        # ssh登录错误源ip
        ip=$(echo "$line" | awk '{print $2}')
        # ssh登录错误大于等于7次，就添加到黑名单IP列表中
        if [ "$count" -ge 7 ]; then
            echo "IP $ip failed $count times. Adding to block list."
            block_ip_list="$block_ip_list $ip"
        fi
    done <<< "$failed_logins"
}

# 定义函数
function block_ip() {
    local ip="$1"
    echo "Blocking IP: $ip"
    # 检查是否已有该IP的防火墙规则,存在则什么都不显示，不存在则报错
    if sudo iptables -C INPUT -s "$ip" -j DROP >/dev/null 2>&1; then
        echo "IP $ip is already blocked."
    else
        # 将IP添加到防火墙规则中
        sudo iptables -A INPUT -s "$ip" -j DROP
    fi
}

# 检查和禁用IP地址
function block_ips() {
    for ip in $block_ip_list; do
        block_ip "$ip"
    done
}

# 脚本退出前保存防火墙规则
function ipt_save(){
    # 退出前保存iptabels规则
    service iptables save || iptables-save > /etc/sysconfig/iptables
    echo "防火墙规则已保存"
}

# 间隔10s无限循环检查函数
while true; do
    check
    block_ips
    # 每隔10s检查一次，时间可根据需要自定义
    sleep 10
done

# 捕获脚本退出信号
# trap 退出时绑定的函数名 EXIT
# trap cleanup EXIT
# 捕获CTRL+C信号
# trap ipt_save INT
# 捕获所有信号
trap ipt_save SIGINT SIGTERM SIGHUP