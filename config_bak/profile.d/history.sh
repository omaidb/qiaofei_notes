#!/usr/bin/env bash

# 参考：https://developer.aliyun.com/article/1094922

history

# 保存历史命令条数
export HISTSIZE=2705

# 获取用户的登录IP
USER_IP=$(who -u am i 2>/dev/null | awk '{print $NF}' | sed -e 's/[()]//g')

# 检查 USER_IP 变量是否为空
if [ -z "$USER_IP" ]; then
    # 如果为空则显示本主机名
    USER_IP=$(hostname)
fi

# 检查/var/log/history目录，没有则创建
## 该目录用来存储history命令记录
if [ ! -d /var/log/history ]; then
    mkdir /var/log/history
    chmod 777 /var/log/history
fi

# 检查当前用户名这个histor是否存在，没有则创建
if [ ! -d /var/log/history/"${LOGNAME}" ]; then
    mkdir /var/log/history/"${LOGNAME}"
    # 300权限只有root能进入这个目录，也就是普通用户只有写权限，没有读权限
    chmod 300 /var/log/history/"${LOGNAME}"
fi

# 显示history命令的时间格式:2023-08-17 10:24:46 root history
## $(whoami) 后面要加个空格
HISTTIMEFORMAT="%F %T $(whoami) "
export HISTTIMEFORMAT

# history文件的时间格式
Date_Framt=$(date +%Y%m%d_%H%M%S)

# 配置histfile路径
HISTFILE="/var/log/history/${LOGNAME}/$(whoami)@${USER_IP}_$Date_Framt"
export HISTFILE

# 将historyfile文件设为600
chmod 600 /var/log/history/"${LOGNAME}"/*history* 2>/dev/null
# 设置history的时间记录格式 2023-03-10 17:10
# HISTTIMEFORMAT="%F %R "

# 为防止会话退出时覆盖其他会话写到HISTFILE的内容
## 查看打开的配置选项 https://www.linuxcool.com/shopt
shopt -s histappend

# 在执行PS1之前保存history记录
export PROMPT_COMMAND="history -a"

# 同时忽略以空格开头和重复命令
export HISTCONTROL=ignoreboth

# 以空格开头的命令行不记录
# export HISTCONTROL=ignorespace
# 重复命令只记录一次
# export HISTCONTROL=ignoredups
# 删除重复命令
# export HISTCONTROL=erasedups
