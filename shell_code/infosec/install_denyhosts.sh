#!/usr/bin/env bash

# 定义版本
pkg_version=2.10

## 检查依赖环境
check_pkg_env() {
    # 检查python2是否安装
    command -v python2 || yum install -y python2
}

## 下载解压
down_unzip_pkg() {
    # https://blog.51cto.com/feko/2735467
    cd /usr/local/src/ || exit
    wget -P /usr/local/src/ https://github.com/denyhosts/denyhosts/archive/v$pkg_version.tar.gz
    tar xf /usr/local/src/v$pkg_version.tar.gz
}

## 安装解压包
install_pkg() {
    cd /usr/local/src/denyhosts-$pkg_version || exit
    # 安装并记录好安装文件
    python2 setup.py install --record install_pkg_list.txt
    # 创建PID文件
    touch /var/run/denyhosts.pid
    # 备份配置
    mv /etc/denyhosts.conf /etc/denyhosts.conf.bak
    # 下载正式配置文件
    wget -P /etc/ -c https://raw.githubusercontent.com/omaidb/qiaofei_notes/main/config_bak/denyhosts.conf
    # 复制服务文件
    cp /usr/local/src/denyhosts-$pkg_version/denyhosts.service /etc/systemd/system/
    systemctl daemon-reload
}

## 执行完整安装denyhosts主方法
install_denyhosts() {
    check_pkg_env
    down_unzip_pkg
    install_pkg
}

## 卸载denyhosts
remove_denyhosts() {
    # 停止禁用服务
    systemctl disable --now denyhosts
    # 删除服务
    rm -rf /etc/systemd/system/denyhosts.service
    # 删除所有已安装的文件
    while IFS= read -r exe_file; do
        rm -rf "$exe_file"
        # 从安装文件的历史记录中删除每一个已安装的文件
    done </usr/local/src/denyhosts-"$pkg_version"/install_pkg_list.txt
    # 删除安装包
    rm -rf /usr/local/src/v$pkg_version.tar.gz
    # 删除解压的目录
    rm -rf /usr/local/src/denyhosts-"$pkg_version"
}

#开始菜单
function start_menu() {
    # 先进行安装前环境检查
    check_install_env
    clear
    echo "========================="
    echo " 介绍:适用于RHEL7"
    echo " 作者:Miles"
    echo " 网站:https://blog.csdn.net/omaidb"
    echo "========================="
    echo "注意:本脚本只支持Centos7"
    echo "1. 安装denyhosts"
    echo "2. 卸载denyhosts"
    echo "0. 退出脚本"
    echo "请输入数字:"
    read -r num
    case "$num" in
    1)
        echo "开始安装denyhosts"
        install_denyhosts
        ;;
    2)
        echo "开始卸载denyhosts"
        remove_denyhosts
        ;;
    0)
        exit 1
        ;;
    *)
        clear
        echo "请输入正确数字"
        sleep 5s
        start_menu
        ;;
    esac
}

# 启动选择菜单
start_menu
