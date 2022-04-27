#!/bin/bash

# 声明: 该脚本适用于升级Centos7的openssh到openssh-9.0p1版本

# 定义源码包版本号
OPENSSH_VERSION=openssh-9.0p1
OPENSSL_VERSION=openssl-1.1.1n
ZILB_VERSION=zlib-1.2.11

# 安装编译环境
yum -y install wget tar gcc make gcc-c++ kernel-devel

# 创建/opt/opensshUpgrade目录
mkdir -p /opt/opensshUpgrade

cd /opt/opensshUpgrade || exit

# 下载源码包
# 下载openssh源码包
wget -c https://ftp.riken.jp/pub/OpenBSD/OpenSSH/portable/$OPENSSH_VERSION.tar.gz
# 下载openssl源码包
wget -c https://www.openssl.org/source/$OPENSSL_VERSION.tar.gz
# 下载zlib源码包
wget -c https://nchc.dl.sourceforge.net/project/libpng/zlib/1.2.11/$ZILB_VERSION.tar.gz

# 解压安装包，我习惯将安装包解压到/usr/local/src
tar xf $OPENSSH_VERSION.tar.gz -C /usr/local/src/
tar xf $OPENSSL_VERSION.tar.gz -C /usr/local/src/
tar xf $ZILB_VERSION.tar.gz -C /usr/local/src/

# 卸载原openssh
yum autoremove openssh -y

# 安装zlib-1.2.11
cd /usr/local/src/$ZILB_VERSION/ || exit
./configure --prefix=/usr/local/zlib && make -j && make install

# 备份老板的openssl和动态库
mv /usr/bin/openssl /usr/bin/openssl.bak
mv /usr/include/openssl /usr/include/openssl.bak

# 安装 openssl
cd /usr/local/src/$OPENSSL_VERSION/ || exit
./config --prefix=/usr/local/openssl -d shared
make -j && make install

# 创建软连接到/usr/bin/openssl
ln -s /usr/local/openssl/bin/openssl /usr/bin/openssl
ln -s /usr/local/openssl/include/openssl /usr/include/openssl

echo '/usr/local/openssl/lib' >>/etc/ld.so.conf
ldconfig -v

# 安装openssh
mv /etc/ssh /etc/ssh.bak # 备用原ssh
cd /usr/local/src/$OPENSSH_VERSION/ || exit
./configure --prefix=/usr/local/openssh --sysconfdir=/etc/ssh --with-ssl-dir=/usr/local/openssl --with-zlib=/usr/local/zlib
make -j && make install

# 备份 /etc/ssh 原有文件，并将新的配置复制到指定目录
mv /usr/sbin/sshd /usr/sbin/sshd.bak &>/dev/null
cp -rf /usr/local/openssh/sbin/sshd /usr/sbin/sshd
mv /usr/bin/ssh /usr/bin/ssh.bak &>/dev/null
cp -rf /usr/local/openssh/bin/ssh /usr/bin/ssh

mv /usr/bin/ssh-keygen /usr/bin/ssh-keygen.bak &>/dev/null
cp -rf /usr/local/openssh/bin/ssh-keygen /usr/bin/ssh-keygen
mv /etc/ssh/ssh_host_ecdsa_key.pub /etc/ssh/ssh_host_ecdsa_key.pub.bak &>/dev/null

# 脚本实际执行结果是没有 /etc这个目录
cp /usr/local/openssh/etc/ssh_host_ecdsa_key.pub /etc/ssh/ssh_host_ecdsa_key.pub

# 复制文件到相应的系统文件夹
cd /usr/local/src/openssh-9.0p1/contrib/redhat || exit
cp sshd.init /etc/init.d/sshd


# 恢复原来的sshd_config配置
cp /etc/ssh.bak/sshd_config /etc/ssh/sshd_config

# sshd_config文件修改
# cp /usr/local/openssh/etc/sshd_config /etc/ssh/sshd_config
# 开启x11转发
# echo "X11Forwarding yes" >> /etc/ssh/sshd_config
# X11配置
# echo "X11UseLocalhost no" >> /etc/ssh/sshd_config
# X11认证配置
# echo "XAuthLocation /usr/bin/xauth" >> /etc/ssh/sshd_config
# 禁用DNS反查,加快ssh登录速度
# echo "UseDNS no" >>/etc/ssh/sshd_config
# # 允许root登录
# echo 'PermitRootLogin yes' >>/etc/ssh/sshd_config
# # 允许密钥登录
# echo 'PubkeyAuthentication yes' >>/etc/ssh/sshd_config
# # 允许密码登录
# echo 'PasswordAuthentication yes' >>/etc/ssh/sshd_config

# 启动 sshd 并将其加入开机自启
systemctl stop sshd.service &>/dev/null
rm -rf /lib/systemd/system/sshd.service
systemctl daemon-reload
cp /usr/local/src/$OPENSSH_VERSION/contrib/redhat/sshd.init /etc/init.d/sshd
/etc/init.d/sshd restart

# 添加开机自启动项
chkconfig --add sshd
systemctl enable --now sshd

# 查看sshd服务是否启动
systemctl status sshd | grep "Active: active (running)"

# 查看openssh版本和openssl版本
sshd -V
ssh -v
openssl version

if [ $? -eq 0 ]; then
    echo -e "\033[32m[INFO] OpenSSH upgraded to $OPENSSH_VERSION  successfully！\033[0m"
else
    echo -e "\033[31m[ERROR] OpenSSH upgraded to $OPENSSH_VERSION faild！\033[0m"
fi
