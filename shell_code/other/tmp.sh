#!/usr/bin/env bash

USER_IP=$(who -u am i 2>/dev/null | awk '{print $NF}' | sed -e 's/[()]//g')
if [ "$USER_IP"=="" ]; then
    USER_IP=$(hostname)
fi

export HISTTIMEFORMAT="%F %T $USER_IP $(whoami)"
#为防止会话退出时覆盖其他会话写到HISTFILE的内容
shopt -s histappend
export PROMPT_COMMAND="history -a"