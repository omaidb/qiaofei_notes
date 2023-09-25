#!/usr/bin/env bash

# 监控数据变化命令
## -m 持续监视模式运行，不会退出，并实时显示事件
## -r 递归地监视目录及其子目录中的文件
## -q 不显示详细输出信息，仅显示事件
## --format "%w%f"：指定输出格式为 "目录路径+文件名"，即 %w 代表目录路径，%f 代表文件名
## /data：指定要监视的目录路径
## -e "close_write,move,create,delete"：指定要监视的事件类型，包括文件关闭写入（close_write）、文件移动（move）、文件创建（create）和文件删除（delete）等
inotifywait -mrq --format "%w%f" /data -e "close_write,move,create,delete" |
    while read -r data_info; do
        rsync -az /data/ --delete rsync_backup@172.16.1.41::backup --password-file=/etc/rsync.password
    done
