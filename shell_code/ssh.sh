#!/usr/bin/env bash

# 开启debug
set -ex

#安装OpenSSH

if [ $? -eq 0 ]; then
make > /dev/null 2>&1
make install> /dev/null 2>&1
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/ /etc/ssh/sshd_config> /dev/null 2>&1 cp af /tmp/SOPENSSH_VERSION/contrib/redhat/sshd.init /etc/init.d/sshd


chmod +x /etc/init.d/sshd
chmod 600 /etc/ssh/*
chkconfig-add sshd
chkconfig sshd on
else
echo -e "OpenSSHA "\033[31m Failure\033[0m"
echo ""
exit
fi
并启动OpenSSH
service sshd start > /dev/null 2>&1
if [ $? -eq 0 ]; then
echo -e "\033[32m Success\033[0m"
echo ""
ssh -V
else
echo -e "\033[31m Failure\033[0m"
exit
fi
echo ""
