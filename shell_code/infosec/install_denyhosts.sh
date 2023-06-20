#!/usr/bin/env bash

# 定义版本
pkg_version=2.10

## 检查依赖环境
check_pkg_env(){
    # 检查python3是否安装
    command -v python3|| yum install -y python3
}

## 下载解压
down_unzip_pkg(){
    # https://blog.51cto.com/feko/2735467
    wget -P /usr/local/src/ https://github.com/denyhosts/denyhosts/archive/v$pkg_version.tar.gz
    tar xf /usr/local/src/v$pkg_version.tar.gz
}

## 安装
install_pkg(){
    cd /usr/local/src/denyhosts-$pkg_version
    python setup.py install
}