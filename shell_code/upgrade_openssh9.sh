#!/usr/bin/env bash  # 指定脚本解释器为bash

# 声明: 该脚本适用于升级Centos7的默认openssh到openssh-9.0p1版本

set -e  # 脚本遇到错误立即退出

# 版本号
OPENSSH_VERSION=openssh-9.0p1  # OpenSSH版本号
OPENSSL_VERSION=openssl-1.1.1n # OpenSSL版本号
ZLIB_VERSION=zlib-1.2.11       # zlib版本号

SRC_DIR=/usr/local/src         # 源码存放目录
PKG_DIR=$SRC_DIR/opensshUpgrade_pkg  # 源码包下载目录

log() { echo -e "\033[36m[INFO]\033[0m $*"; }  # 信息日志输出函数
err() { echo -e "\033[31m[ERROR]\033[0m $*"; exit 1; }  # 错误日志输出并退出

install_build_env() {  # 安装编译环境
    log "安装编译环境"
    yum -y install wget tar gcc make gcc-c++ kernel-devel openssl-devel pam-devel
}

download_sources() {  # 下载源码包
    log "下载源码包"
    mkdir -p "$PKG_DIR"
    wget -c -P "$PKG_DIR" https://ftp.riken.jp/pub/OpenBSD/OpenSSH/portable/$OPENSSH_VERSION.tar.gz
    wget -c -P "$PKG_DIR" https://www.openssl.org/source/$OPENSSL_VERSION.tar.gz
    wget -c -P "$PKG_DIR" https://nchc.dl.sourceforge.net/project/libpng/zlib/1.2.11/$ZLIB_VERSION.tar.gz
}

extract_sources() {  # 解压源码包
    log "解压源码包"
    cd "$PKG_DIR"
    tar xf $OPENSSH_VERSION.tar.gz -C "$SRC_DIR"
    tar xf $OPENSSL_VERSION.tar.gz -C "$SRC_DIR"
    tar xf $ZLIB_VERSION.tar.gz -C "$SRC_DIR"
}

install_zlib() {  # 安装zlib库
    log "安装zlib"
    cd "$SRC_DIR/$ZLIB_VERSION"
    ./configure --prefix=/usr/local/zlib && make -j && make install
}

backup_openssl() {  # 备份旧版openssl
    log "备份旧版openssl"
    mv /usr/bin/openssl{,old} &>/dev/null || true
    mv /usr/include/openssl{,old} &>/dev/null || true
}

install_openssl() {  # 安装新版openssl
    log "安装openssl"
    cd "$SRC_DIR/$OPENSSL_VERSION"
    ./config --prefix=/usr/local/openssl -d shared
    make -j && make install
    ln -sf /usr/local/openssl/bin/openssl /usr/bin/openssl
    ln -sf /usr/local/openssl/include/openssl /usr/include/openssl
    echo '/usr/local/openssl/lib' >>/etc/ld.so.conf
    ldconfig -v
}

backup_openssh() {  # 备份原有openssh
    log "备份原有openssh"
    mv /etc/ssh{,old} &>/dev/null || true
    mv /usr/bin/ssh{,old} &>/dev/null || true
    mv /usr/sbin/sshd{,old} &>/dev/null || true
    mv /usr/bin/ssh-keygen{,old} &>/dev/null || true
}

remove_old_openssh() {  # 卸载原有openssh
    log "卸载原有openssh"
    yum erase -y openssh
}

install_openssh() {  # 编译安装openssh
    log "编译安装openssh"
    cd "$SRC_DIR/$OPENSSH_VERSION"
    ./configure --prefix=/usr/local/openssh \
        --sysconfdir=/etc/ssh \
        --mandir=/usr/share/man \
        --with-ssl-dir=/usr/local/openssl \
        --with-zlib=/usr/local/zlib
    make -j && make install
}

restore_sshd_config() {  # 恢复sshd配置文件
    log "恢复sshd_config"
    cp /etc/ssh.old/sshd_config /etc/ssh/sshd_config
    grep -Ev "^$|#" /etc/ssh.old/sshd_config >/etc/ssh/sshd_config
    sed -i 's/^GSSAPIAuthentication /# GSSAPIAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^GSSAPICleanupCredentials /# GSSAPICleanupCredentials no/' /etc/ssh/sshd_config
    sed -i 's/^UsePAM /# UsePAM yes/' /etc/ssh/sshd_config
}

setup_sshd_service() {  # 配置sshd systemd服务
    log "配置sshd systemd服务"
    systemctl disable sshd.service &>/dev/null || true
    systemctl stop sshd.service &>/dev/null || true
    mv /usr/lib/systemd/system/sshd.service{,old} 2>/dev/null || \
    mv /lib/systemd/system/sshd.service{,old} 2>/dev/null || \
    mv /etc/systemd/system/sshd.service{,old} 2>/dev/null || true

    cat >/usr/lib/systemd/system/sshd.service <<EOF
[Unit]
Description=OpenSSH server daemon
Documentation=man:sshd(8) man:sshd_config(5)
After=network.target sshd-keygen.service
Wants=sshd-keygen.service

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/sshd
ExecStart=/usr/local/openssh/sbin/sshd -D \$OPTIONS
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
RestartSec=42s

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl restart sshd
    systemctl enable --now sshd
}

check_status() {  # 检查sshd服务状态
    log "检查sshd服务状态"
    systemctl status sshd | grep "Active: active (running)" || err "sshd未正常启动"
    sshd -V || true
    ssh -v || true
    openssl version
    log "OpenSSH升级到 $OPENSSH_VERSION 成功！"
}

main() {  # 主流程函数
    install_build_env      # 安装编译环境
    download_sources       # 下载源码包
    extract_sources        # 解压源码包
    install_zlib           # 安装zlib
    backup_openssl         # 备份旧版openssl
    install_openssl        # 安装新版openssl
    backup_openssh         # 备份原有openssh
    remove_old_openssh     # 卸载原有openssh
    install_openssh        # 编译安装openssh
    restore_sshd_config    # 恢复sshd配置
    setup_sshd_service     # 配置sshd服务
    check_status           # 检查服务状态
}

main "$@"  # 执行主流程
