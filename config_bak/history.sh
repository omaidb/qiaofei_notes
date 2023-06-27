#!/usr/bin/env bash

# 保存历史命令10万条
export HISTSIZE=100000

# 获取用户的登录IP
USER_IP=$(who -u am i 2>/dev/null | awk '{print $NF}' | sed -e 's/[()]//g')
if [[ "$USER_IP" == "" ]]; then
    USER_IP=$(hostname)
fi

# 配置history格式中显示用户的IP地址
## 显示history时间格式:2021-11-06_00:01:35
export HISTTIMEFORMAT="%F %T $USER_IP $(whoami) " 

# 设置history的时间记录格式 2023-03-10 17:10
# HISTTIMEFORMAT="%F %R "

# 为防止会话退出时覆盖其他会话写到HISTFILE的内容
## 查看打开的配置选项 https://www.linuxcool.com/shopt
shopt -s histappend

# 在执行PS1之前保存history记录
export PROMPT_COMMAND="history -a"

# 以空格开头的命令行不记录
export HISTCONTROL=ignorespace
