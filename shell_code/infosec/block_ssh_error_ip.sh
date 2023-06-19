#!/bin/bash

#  本脚本适用于rhel8+iptables
# 自动拉黑ssh密码登录错误大于7次的ip

# 开启debug模式
# set -ex

# 设置ssh密码错误阈值变量
threshold=7

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
        if [ "$count" -ge $threshold ]; then
            # echo "IP $ip failed $count times. Adding to block list."
            block_ip_list="$block_ip_list $ip"
        fi
    done <<< "$failed_logins"
}

# 方法：拉黑IP
function block_ip() {
    local ip="$1"
    echo "Blocking IP: $ip"
    # 检查是否已有该IP的防火墙规则,存在则什么都不显示，不存在则报错
    if sudo iptables -C INPUT -s "$ip" -j DROP >/dev/null 2>&1; then
        # echo "IP $ip 已在被iptables封锁中。"
        :
    else
        # 将IP添加到防火墙规则中
        sudo iptables -A INPUT -s "$ip" -j DROP
        echo "拉黑$ip"
    fi
}

# 脚本退出前保存防火墙规则
function ipt_save(){
    # 退出前保存iptabels规则
    service iptables save || iptables-save > /etc/sysconfig/iptables
    echo "防火墙规则已保存"
}

# 捕获脚本退出信号
# trap 退出时绑定的函数名 EXIT
# trap cleanup EXIT
# 捕获CTRL+C信号
# trap ipt_save INT
# 捕获所有信号
trap ipt_save SIGINT SIGTERM SIGHUP

# 设置退出信号处理方式
trap ipt_save EXIT

# 设置INT信号处理方式
# 在接收到INT信号时执行exit 2命令，即以退出状态码2退出当前脚本。
trap 'exit 2' INT

main() {
    # 间隔10s无限循环检查函数
    while true; do
        # 检查ssh登录错误的恶意IP
        check
        # 循化拉黑检查到的ip
        for ip in $block_ip_list; do
            block_ip "$ip"
        done
        # 每隔10s检查一次，时间可根据需要自定义
        sleep 10
    done
}

# 执行主方法
main