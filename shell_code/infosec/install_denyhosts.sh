#!/usr/bin/env bash

# 定义版本
pkg_version=2.10

## 检查依赖环境
check_pkg_env(){
    # 检查python3是否安装
    command -v python|| yum install -y python2
    command -v python3|| yum install -y python3
}

## 下载解压
down_unzip_pkg(){
    # https://blog.51cto.com/feko/2735467
    cd /usr/local/src/ || exit
    wget -P /usr/local/src/ https://github.com/denyhosts/denyhosts/archive/v$pkg_version.tar.gz
    tar xf /usr/local/src/v$pkg_version.tar.gz
}

## 安装
install_pkg(){
    cd /usr/local/src/denyhosts-$pkg_version || exit
    python setup.py install || python2 setup.py install
    # 创建PID文件
    touch /var/run/denyhosts.pid
    # 下载配置文件
    wget -P /etc/ -c https://raw.githubusercontent.com/omaidb/qiaofei_notes/main/config_bak/denyhosts.conf
    # 复制服务文件
    cp /usr/local/src/denyhosts-$pkg_version/denyhosts.service /etc/systemd/system/
    systemctl daemon-reload
}

## 执行主方法
main() {
    check_pkg_env
    down_unzip_pkg
    install_pkg
}

main