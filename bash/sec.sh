#!/bin/bash
# 基于阿里云最佳实践安全实践的CentOS Linux 7基线标准
# 系统-等保三级-CentOS Linux 7合规基线检查

# 修改密码最大有效期为180天
sed -i.bak -e 's/^\(PASS_MAX_DAYS\).*/\1   180/' /etc/login.defs
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi
chage --maxdays 180 root
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 修改两次修改密码的最小间隔时间为7天
sed -i.bak -e 's/^\(PASS_MIN_DAYS\).*/\1   7/' /etc/login.defs
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi
chage --mindays 7 root
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 修改密码必须包含四种字符
sed -i 's/# minclass = 0/minclass = 3/g' /etc/security/pwquality.conf
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 修改密码最短为9位
sed -i 's/# minlen = 9/minlen = 9/g' /etc/security/pwquality.conf
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 密码设置及登陆控制文件/etc/pam.d/password-auth 禁止使用最近用过的5个密码 remember=5
sed -i 's/password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok/password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=5/g' /etc/pam.d/password-auth
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 密码设置及登陆控制文件/etc/pam.d/system-auth 禁止使用最近用过的5个密码 remember=5
sed -i 's/password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok/password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok remember=5/g' /etc/pam.d/system-auth
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 用户重新尝试输入密码的次数设为4
sed -i 's/#MaxAuthTries 6/MaxAuthTries 4/g' /etc/ssh/sshd_config
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi
echo 'Protocol 2' >>/etc/ssh/sshd_config
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# ssh服务端每900秒向客户端发送一次消息,以保持长连接
sed -i 's/#ClientAliveInterval 0/ClientAliveInterval 900/g' /etc/ssh/sshd_config
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 客户端3次超时即断开客户端
sed -i 's/#ClientAliveCountMax 3/ClientAliveCountMax 3/g' /etc/ssh/sshd_config
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# SSH 日志级别设置为INFO,记录登录和注销活动
sed -i 's/#LogLevel INFO/LogLevel INFO/g' /etc/ssh/sshd_config
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi
service sshd restart
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

sed -i '/# User/a\auth        required      pam_tally2.so onerr=fail audit silent deny=5 unlock_time=900' /etc/pam.d/password-auth
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

sed -i '/# User/a\auth        required      pam_tally2.so onerr=fail audit silent deny=5 unlock_time=900' /etc/pam.d/system-auth
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi
echo 'TMOUT=900' >>/etc/profile
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 允许root登录
sed -i 's/PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi
service sshd restart
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 设置 主机允许策略文件/etc/hosts.allow 的属组和属主为root
chown root:root /etc/hosts.allow
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 设置 主机拒绝策略文件/etc/hosts.deny 的属组和属主为root
chown root:root /etc/hosts.deny
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 设置 主机允许策略文件/etc/hosts.allow的权限为644
chmod 644 /etc/hosts.allow
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 设置 主机拒绝策略文件/etc/hosts.deny的权限为644
chmod 644 /etc/hosts.deny
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 设置用户/组 的用户和密码文件属主属组为root
chown root:root /etc/passwd /etc/shadow /etc/group /etc/gshadow
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 设置组文件 的权限为0644
chmod 0644 /etc/group
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 设置用户文件 的权限为644
chmod 0644 /etc/passwd
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 设置用户的密码文件为0400只读,禁止修改用户密码
chmod 0400 /etc/shadow
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 设置组密码文件为0400制度, 禁止修改组密码
chmod 0400 /etc/gshadow
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 设置sshd主配置文件属主属组为root
chown root:root /etc/ssh/sshd_config
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 设置sshd主配置文件权限为0600
chmod 600 /etc/ssh/sshd_config
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 设置/etc/profile文件属主属组为root
chown root:root /etc/profile
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 设置/etc/profile文件权限为644
chmod 644 /etc/profile
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 开机自启安全审计服务并现在启动
systemctl enable --now auditd
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 开机自启日志服务并现在启动
systemctl enable --now rsyslog
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 定义安全审计规则
echo '-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete -a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete' >>/etc/audit/rules.d/audit.rules
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 定义安全设计规则
echo '-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete -a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete' >>/etc/audit/audit.rules
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 定义安全审计规则
echo ' -w /etc/group -p wa -k identity -w /etc/passwd -p wa -k identity -w /etc/gshadow -p wa -k identity -w /etc/shadow -p wa -k identity -w /etc/security/opasswd -p wa -k identity' >>/etc/audit/rules.d/audit.rules
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 定义安全审计规则
echo ' -w /etc/group -p wa -k identity -w /etc/passwd -p wa -k identity -w /etc/gshadow -p wa -k identity -w /etc/shadow -p wa -k identity -w /etc/security/opasswd -p wa -k identity' >>/etc/audit/audit.rules
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 定义安全审计规则
echo ' -w /etc/sudoers -p wa -k scope -w /etc/sudoers.d/ -p wa -k scope' >>/etc/audit/rules.d/audit.rules
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 定义安全审计规则
echo ' -w /etc/sudoers -p wa -k scope -w /etc/sudoers.d/ -p wa -k scope' >>/etc/audit/audit.rules
if [ "$?" == 0 ]; then
    echo -e "\033[32m True \033[0m"
else
    echo -e "\033[31m False \033[0m"
fi

# 暂停rpcbind服务--nfs需要依赖rpcbind服务来实现客户端和服务器的路由请求
systemctl disable --now rpcbind &>/dev/null
systemctl disable --now rpcbind.socket &>/dev/null
