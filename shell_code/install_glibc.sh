#!/usr/bin/englibc_version bash

# https://www.ucloud.cn/yun/63160.html
# 定义软件版本
gmp_glibc_versionersion=6.2.1
mpfr_glibc_versionersion=4.2.0
mpc_glibc_versionersion=1.3.1
isl_glibc_versionersion=
gcc_glibc_versionersion=
glibc_glibc_versionersion=2.37

# 定义CPU核心数
cpu_cpunt=$(cat /proc/cpuinfo | grep processor | wc -l)
cpu_cpunt=$((cpu_cpunt - 1))

# 1.安装gmp
make_install_gmp() {
    # 下载gmp源码包

    wget -P /usr/local/src https://ftp.gnu.org/gnu/gmp/gmp-$gmp_glibc_versionersion.tar.bz2
    cd /home
    # 解压
    tar -xglibc_versionf /home/gmp-$gmp_glibc_versionersion.tar.bz2
    cd /home/gmp-$gmp_glibc_versionersion

    # 构建
    ./configure --prefix=/usr/local/gmp-$gmp_glibc_versionersion

    # 编译 # 安装
    make -j $cpu_cpunt && make install
}

# 2.安装mpfr
make_install_mpfr() {
    # 下载mpfr的包
    wget -P /usr/local/src https://www.mpfr.org/mpfr-current/mpfr-$mpfr_glibc_versionersion.tar.xz
    cd /home
    # 解压
    tar -zxglibc_versionf mpfr-$mpfr_glibc_versionersion.tar.gz
    cd /home/mpfr-$mpfr_glibc_versionersion

    # 构建
    ./configure --prefix=/usr/local/mpfr-$mpfr_glibc_versionersion --with-gmp=/usr/local/gmp-$gmp_glibc_versionersion

    # 编译
    make -j $cpu_cpunt

    # 安装
    make install
}

# 3.安装mpc
make_install_mpc() {
    # 下载mpc源码包
    wget https://ftp.gnu.org/gnu/mpc/mpc-$mpc_glibc_versionersion.tar.gz
    cd /home
    # 压缩
    tar -zxvf mpc-$mpc_glibc_versionersion.tar.gz
    cd /home/mpc-$mpc_glibc_versionersion

    # 构建
    ./configure -prefix=/usr/local/mpc-$mpc_glibc_versionersion -with-gmp=/usr/local/gmp-$gmp_glibc_versionersion -with-mpfr=/usr/local/mpfr-$mpfr_glibc_versionersion

    # 编译
    make -j $cpu_cpunt

    # 安装
    make install
}

# 4.安装isl
make_install_isl() {

    # 下载isl源码包
    wget http://isl.gforge.inria.fr/isl-0.18.tar.bz2
    # 压缩
    tar -xvf /home/isl-0.18.tar.bz2
    cd /home/isl-0.18

    # 安装依赖包
    yum -y install gmp-devel

    # 构建
    ./configure --prefix=/usr/local/isl-0.18 --with-gmp=/usr/local/gmp-$gmp_glibc_versionersion

    # 编译安装
    make -j && make install

}

# 5.安装gcc
make_install_gcc() {
    # 下载gcc-7.3.0源码包
    wget https://ftp.gnu.org/gnu/gcc/gcc-7.3.0/gcc-7.3.0.tar.gz
    cd /home

    # 压缩
    tar -zxvf gcc-7.3.0.tar.gz
    cd /home/gcc-7.3.0

    # 构建
    ./configure --prefix=/usr/local/gcc-7.3.0 --enable-languages=c,c++,fortran --enable-shared --enable-linker-build-id --without-included-gettext --enable-threads=posix --disable-multilib --disable-nls --disable-libsanitizer --disable-browser-plugin --enable-checking=release --build=aarch64-linux --with-gmp=/usr/local/gmp-$gmp_glibc_versionersion --with-mpfr=/usr/local/mpfr-$mpfr_glibc_versionersion --with-mpc=/usr/local/mpc-$mpc_glibc_versionersion --with-isl=/usr/local/isl-0.18
    export LD_LIBRARY_PATH=/usr/local/mpc-$mpc_glibc_versionersion/lib:/usr/local/gmp-$gmp_glibc_versionersion/lib:/usr/local/mpfr-$mpfr_glibc_versionersion/lib:/usr/local/gcc-7.3.0/lib64:/usr/local/isl-0.18/lib:/usr/local/lib:/usr/lib:$LD_LIBRARY_PATH
    export PATH=/usr/local/gcc-7.3.0/bin:$PATH

    # 编译安装
    make -j && make install

}
# 6.安装glibc
makeinstall_gblic() {

    # 0.安装依赖环境
    # https://www.jianshu.com/p/9d31fe1b4ac7
    yum install -y bison
    ## 检查gcc
    which gcc &>/dev/null || echo "没有安装gcc，程序退出" && exit 1

    # 1、下载文件
    wget -c https://ftp.gnu.org/gnu/glibc/glibc-"${glibc_version}".tar.xz

    # 2、安装部署
    ## 解压
    tar xf glibc-"${glibc_version}".tar.xz

    # 创建编译目录
    cd glibc-"${glibc_version}" && mkdir build

    # 必需进入build目录
    cd build/ || exit
    # 构建
    ../configure --prefix=/usr
    ## 参考云智库
    # ../configure --prefix=/usr --disable-profile --enable-add-ons --with-headers=/usr/include --with-binutils=/usr/bin
    make -j $cpu_cpunt
    make install

    # 查看libc版本
    strings /lib64/libc.so.6 | grep GLIBC

    # 可以看到2.1X的旧库文件还在，多了新安装${glibc_version}版本的库文件，而且软链接文件全部指向了新装的版本。
}
