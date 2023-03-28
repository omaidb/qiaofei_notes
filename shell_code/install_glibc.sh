#!/bin/bash

# 获取CPU总核心数
cpu_cpunt=$(grep processor -c /proc/cpuinfo)
# 总核心-1，防止make-j死机
cpu_cpunt=$((cpu_cpunt - 1))
# 编译安装glibc
make_install_glibc() {
    # 定义glibc版本
    glibc_version=2.18
    # 0.安装依赖环境
    # https://www.jianshu.com/p/9d31fe1b4ac7
    yum install -y bison gcc
    # 1、下载文件
    wget -c -P /usr/local/src https://ftp.gnu.org/gnu/glibc/glibc-${glibc_version}.tar.xz

    # 2、安装部署
    ## 解压
    cd /usr/local/src || exit 1
    tar xf /usr/local/src/glibc-${glibc_version}.tar.xz

    # 创建编译目录
    cd glibc-${glibc_version} && mkdir build

    # 必需进入build目录
    cd build/ || exit 1
    # 构建
    ../configure --prefix=/usr
    ## 参考云智库 https://kb.aliyun-inc.com/kb/206363
    # ../configure --prefix=/usr --disable-profile --enable-add-ons --with-headers=/usr/include --with-binutils=/usr/bin
    make
    make install

    # 查看libc版本
    strings /lib64/libc.so.6 | grep GLIBC

    # 可以看到2.1X的旧库文件还在，多了新安装${glibc_version}版本的库文件，而且软链接文件全部指向了新装的版本。
}
make_install_glibc
