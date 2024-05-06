#!/usr/bin/env bash

# 开启debug
# set -ex

# 定义python版本
python3_version=3.9.9

makeinstall_python() {
    # 安装必要的依赖
    yum install -y yum-utils readline-devel gcc \
    	openssl-devel openssl openssl-devel openssl11 openssl11-devel \
     	bzip2 bzip2-devel zlib zlib-devel libffi libffi-devel ncurses-devel \
      	sqlite-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel    
    # 自动查找并安装构建 Python 所需的开发包和依赖库
    yum-builddep python
    yum-builddep python3
    # 安装openssl11，后期的pip3安装网络相关模块需要用到ssl模块。
    CFLAGS=$(pkg-config --cflags openssl11)
    export CFLAGS
    LDFLAGS=$(pkg-config --libs openssl11)
    export LDFLAGS

    # 下载Python3源码并解压
    cd /usr/local/src || exit
    wget -P /usr/local/src -c https://www.python.org/ftp/python/"${python3_version}"/Python-"${python3_version}".tgz
    tar xf Python-"${python3_version}".tgz

    # 编译并安装Python3
    cd /usr/local/src/Python-"${python3_version}" || exit
    ## --enable-optimizations 可以提高python10%-20%代码运行速度
    ## 安装pip需要用到ssl，否则会报错
    ./configure --enable-optimizations --with-ssl
    # 编译安装时间会持续几分钟
    make && make install
    # 创建软链接
    ln -sf /usr/local/bin/python3 /usr/bin/python3
    ln -sf /usr/local/bin/pip3 /usr/bin/pip3
}

uninstall_python() {
    # 检查Python3是否已安装
    if [ -f "/usr/local/bin/python3" ]; then
        # 删除Python3安装目录
        rm -rf "/usr/local/bin/python3"
        rm -rf "/usr/local/bin/pip3"
        rm -rf "/usr/local/lib/python${python3_version}/"

        # 删除环境变量配置
        sed -i "/export PATH=\/usr\/local\/bin:$PATH/d" ~/.bashrc
        source ~/.bashrc

        echo "Python ${python3_version}卸载成功！"
    else
        echo "Python ${python3_version}未安装，无需卸载。"
    fi
}

#开始菜单
function start_menu() {
    clear
    echo "========================="
    echo " 介绍：适用于CentOS7"
    echo " 作者：Miles"
    echo " 网站：https://blog.csdn.net/omaidb"
    echo "========================="
    echo "注意：本脚本只支持Centos7"
    echo "1. 安装Python3"
    echo "2. 卸载Python3"
    echo "0. 退出脚本"
    echo "请输入数字:"
    read -r num
    case "$num" in
    1)
        echo "开始安装Python3"
        makeinstall_python
        ;;
    2)
        echo "开始卸载Python3"
        uninstall_python
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

# main方法，显示菜单
start_menu
