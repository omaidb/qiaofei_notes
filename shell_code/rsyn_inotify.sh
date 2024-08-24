#!/usr/bin/env bash

# Filename: backrsync.sh
# 作者：omaidb@gmail.com
# 更新时间：2024年8月24日

# 使用方式及其相关备注：
# 本脚本采用rsync+ssh-keygen(免密)+inotify[监控文件系统操作] 进行时时备份数据至其它的服务器上面

# ssh-keygen 使用步骤
# 在需要备份数据的服务器上面运行
# ssh-keygen
# 然后一路回车
# 通过ssh-copy-id 将公钥复制到远程机器中
# ssh-copy-id -i ~/.ssh/id_rsa.pub 192.168.1.221
# 输入一下192.168.1.221的密码即可

# Inotify 使用步骤
# 使用前需要确保 Linux的内核高于2.6.13版本[目前使用的都是Centos 6.9/10及其7.*以上的版本，看都高于此版本]
# uname -r  【查看内核版本】
# wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
# yum -y install inotify-tools
# rpm -qa inotify-tools

# printlog 函数说明
# 两个参数，一，是否打印日志，二，日志内容
# 一参数可选，0表示不打印日志内容出来，1表示打印日志内容出来
LOGFILE_PATH="/var/log/zdrsynclog"
NOWTIME=$(date "+%Y-%m-%d %H:%M:%S")
function printlog() {
    LOG_CONTENT="$NOWTIME $2"
    #echo $LOG_CONTENT
    if [ $1 -ne 0 ]; then
        echo $LOG_CONTENT
        echo $LOG_CONTENT >>$LOGFILE_PATH
    else
        echo $LOG_CONTENT >>$LOGFILE_PATH
    fi
}

# 检查上一条命令执行是否正常，不正常退出
check_error_exit() {
    #echo $?"+++++++++++"
    RUSELT=$?
    if [ ${RUSELT} -ne 0 ]; then
        printlog 1 "#[ERROR] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
        printlog 1 "#[ERROR] 恭喜，光荣而伟大的报错了 : "$1
        printlog 1 "#[ERROR] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
        exit 1
    fi
}

# 输出颜色字体
function echo_colour() {
    if [ $1 -eq 0 ]; then
        echo -e "\033[41;37m ${2} \033[0m"
        return 0
    fi

    if [ $1 -eq 1 ]; then
        echo -e "\033[43;37m ${2} \033[0m"
        return 0
    fi

    if [ $1 -eq 2 ]; then
        echo -e "\033[47;30m ${2} \033[0m"
        return 0
    fi
}

# 打印结束符
print_end() {
    printlog 1 "<<<<<<<<<<<<<<<<<<<<<<END<<<<<<<<<<<<<<<<<<<<<<<<<<"
}

####################################################################
# 脚本即将开始运行
####################################################################
printlog 1 "<<<<<<<<<<<<<<<<<<<<<<Start<<<<<<<<<<<<<<<<<<<<<<<<<<"

# 定义目的服务器及其需要备份的文件夹、备份的目的路径
Backup_Server=192.168.1.221
Path=/root/aa_inotify
Backup_Server_Path=/test_inotify

# 以下语句带有--delete
rsync -Rraz --delete -e ssh $Path root@${backup_Server}:${Backup_Server_Path}
/usr/bin/inotifywait -mrq --format '%w%f' -e create,close_write,delete $Path | while read line; do
    rsync -Rraz --delete -e ssh ${line} root@${Backup_Server}:${Backup_Server_Path}
done

# 以下为旧版本的备份
# 主要是下面的这句了，检查一下有没有rsync进程，如果有就直接提示有在运行，写到日志中，然后再等下一步循环了
# ps -ef|grep 'rsync'|grep -v 'grep'|grep -v 'backrsync'
# if [ $? -ne 0 ]
# then
#    printlog 1 "start process..."
#    printlog 0 "$NOWTIME: crontab start"
#    /usr/bin/rsync -rav /home/mailbox /mailbackup/
#    printlog 0 "Success Rsync"
# else
#    printlog 1 "runing...."
#    printlog 0 "$NOWTIME: running... start"
# fi

print_end
