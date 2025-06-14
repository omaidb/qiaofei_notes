#!/usr/bin/env bash

# 开启debug
set -ex

# 判断Linux发行版
check_os() {
    # 如果有yum包管理器，就是rhel系统发行版
    (
        which yum || echo "不是rhel发行版" && exit 1
    ) && os=rhel
    # 获取os的版本号
    os_version=$(grep -shoE '[0-9]+' /etc/redhat-release /etc/almalinux-release /etc/rocky-release /etc/centos-release | head -1)
}

# 判断Linux版本
check_os_ver() {
    if [[ "$os" && "$os_version" -lt 7 ]]; then
        echo "使用此安装程序需要 CentOS 7 或更高版本。
此版本的 CentOS 太旧且不受支持." && exit 1
    fi
}

# 0.安装前OS环境检查
check_os_env() {
    # 先检查系统发行版
    check_os
    # 检查Linux版本号
    check_os_ver

}

# 1. 关闭防火墙和SELinux
disable_firewalld() {
    ## 永久关闭防火墙
    systemctl disable --now firewalld
    ## 注销firewalld服务
    systemctl mask firewalld

    # 清空iptables规则
    iptables -F

    ## 永久关闭SELinux
    sed -ri 's#(SELINUX=).*#\1disabled#' /etc/selinux/config

    ## 立即临时关闭SELinux--退出码是1，所以强制为true
    setenforce 0 || true

    ## 查看SELinux永久策略是否关闭
    eval "grep 'SELINUX=' /etc/selinux/config"
}

# 2.内核参数调整
set_kernel_config() {
    echo "
# 关闭IPV6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1

# 开启内核开启数据包转发
# net.ipv4.ip_forward = 1 
# net.ipv4.conf.all.proxy_arp = 1" >>/etc/sysctl.conf && sysctl -p
}

# 3. PS1美化
set_PS1() {
    # 下载ps1脚本
    wget -cP /etc/profile.d/ https://raw.githubusercontent.com/omaidb/qiaofei_notes/main/config_bak/profile.d/ps1.sh
}

# 3.0开启history的时间记录
config_cmd_history_time() {
    wget -cP /etc/profile.d/ https://raw.githubusercontent.com/omaidb/qiaofei_notes/main/config_bak/profile.d/history.sh
}

# 3.1 配置vimrc
set_vimrc() {
    wget -cP /root/ https://raw.githubusercontent.com/omaidb/qiaofei_notes/main/config_bak/.vimrc 
}

# 3.2配置.bashrc
set_bashrc() {
    echo "
# 配置proxy变量
alias proxy='export all_proxy=socks5://admin:123@127.0.0.1:1080'
alias unproxy='unset all_proxy'

# 防止htop无任何输出
export TERM=xterm
    " >>/root/.bashrc
}

# 4.设置locale
set_locale_config() {
    # 安装语言包,防止出现locate错误
    yum install -q -y glibc-minimal-langpack glibc-locale-source glibc-langpack-zh glibc-langpack-en
    echo "
LC_ALL=zh_CN.UTF-8
LANG=zh_CN.UTF8
" >/etc/locale.conf
    # 现在生效locate
    source /etc/locale.conf
}

# 5. 优化ssh
optimization_ssh_config() {
    echo "
# ssh_config常用的参数

## 忽略第一次密钥检查
StrictHostKeyChecking no
## GSSAPI认证能优化ssh连接速度
GSSAPIAuthentication no
## 检查IP
CheckHostIP no
## 启用压缩
Compression yes
## 指定变量
SendEnv LANG zh_CN.UTF-8

# 配置1天(60秒*1440次)内ssh客户端不超时
## 服务器存活最大数值超过次1440次服务器无响应客户端会断掉
ServerAliveCountMax 1440
## 服务器存活时间间隔,60秒发送一次KeepAlive
ServerAliveInterval 60
## 发送TCP保活报文
TCPKeepAlive yes

# 重用相同的连接
ControlMaster auto
## 连接状态文件
ControlPath ~/.ssh/ssh_mux_%h_%p_%r
## 72小时内保持连接(只需要第一次输入密码)
ControlPersist 72h
" >/root/.ssh/config
}

# 6. 配置tuned自动调优
set_tunded_optimization() {
    sed -ri 's#(^dynamic_tuning).*#\1 = 1#' /etc/tuned/tuned-main.conf
    ## 查看是否修改成功
    eval "grep dynamic_tuning /etc/tuned/tuned-main.conf"
    ## 重启tuned服务
    systemctl restart tuned
    ## 使用虚拟机和低时延方案
    tuned-adm profile virtual-guest network-latency
    ## 查看当前生效的方案
    eval "tuned-adm active"
}

# 7. 禁用非必需的服务开机自启
disable_nonecessary_service() {
    # ## 创建一个不间断会话
    # screen -R NetworkManager;
    # ## 禁用network服务，启用NetworkManager服务
    # systemctl disable --now network && systemctl enable --now NetworkManager
    ## 禁用postfix服务
    systemctl disable --now postfix || true
    ## 注销postfix服务
    systemctl mask --now postfix || true

    # 精简开机自启动服务
    # https://blog.51cto.com/u_9625010/2385687
    ## 必须的服务启动列表
    # systemctl list-unit-files|grep enable 过滤查看启动项如下
    # abrt-ccpp.service                                enabled abrt为auto bug report的缩写 用于bug报告 关闭
    # abrt-oops.service                                enabled ----------------------
    # abrt-vmcore.service                              enabled ----------------------
    # abrt-xorg.service                                enabled ----------------------
    # abrtd.service                                      enabled   ----------------------
    # auditd.service                                   enabled 安全审计 保留
    # autovt@.service                               enabled 登陆相关 保留
    # crond.service                                          enabled 定时任务 保留
    # dbus-org.freedesktop.NetworkManager.service    enabled 桌面网卡管理 关闭
    # dbus-org.freedesktop.nm-dispatcher.service         enabled ----------------------
    # getty@.service                                enabled tty控制台相关 保留
    # irqbalance.service                          enabled 优化系统中断分配 保留
    # kdump.service                                enabled 内核崩溃信息捕获 自定
    # microcode.service                        enabled 处理器稳定性增强 保留
    # NetworkManager-dispatcher.service              enabled 网卡守护进程 关闭
    # NetworkManager.service                        enabled ----------------------
    # postfix.service                            enabled 邮件服务 关闭
    # rsyslog.service                              enabled 日志服务 保留
    # snmpd.service                                enabled snmp监控 数据抓取 保留
    # sshd.service                                  enabled ssh登陆 保留
    # systemd-readahead-collect.service             enabled 内核调用--预读取 保留
    # systemd-readahead-drop.service                enabled ----------------------
    # systemd-readahead-replay.service              enabled ----------------------
    # tuned.service                                     enabled
    # default.target                                 enabled 默认启动项 multi-user.target的软连接 保留
    # multi-user.target                             enabled 启动用户命令环境 保留
    # remote-fs.target                               enabled 集合远程文件挂载点 自定
    # runlevel2.target                              enabled 运行级别 用于兼容6的SysV 保留
    # runlevel3.target                              enabled ----------------------
    # runlevel4.target                              enabled ----------------------
    ## 除必须启动的服务外，禁用并现在停止其他服务。
    systemctl list-unit-files --state=enabled | grep -Ev "auditd.service|autovt@.service|crond.service|chronyd.service|getty@.service|irqbalance.service|microcode.service|rsyslog.service|NetworkManager.service|sshd.service|sysstat.service|systemd-readahead-collect.service|systemd-readahead-drop.service|systemd-readahead-replay.service|tuned.service|default.target|multi-user.target|runlevel2.target|runlevel3.target|runlevel4.target|unbound|wg-quick@wg0|edge|supernode.service|ocserv.service" | awk '{print "systemctl disable --now",$1}' | bash || true
    # 禁用后查看自启服务列表还剩哪些
    systemctl list-unit-files --state=enabled | grep enabled
}

# 8. 安装常用repo源
install_repo() {
    # 如果epel.repo文件不存在就安装epel源
    if [ -f /etc/yum.repos.d/epel.repo ] || [ -f /etc/yum.repos.d/oracle-epel-ol8.repo ]; then
        echo "本地已有epel.repo"
    else
        dnf install -y epel-release
    fi
    # 安装elrepo源
    ls /etc/yum.repo.d/elrepo.repo ||
        dnf install -y elrepo-release

    # 如果系统版本号==7,就安装SCL源和IUS源
    if $os_version -eq 7; then
        ## centos-release-scl centos-release-scl-rh是SCL源
        ## scl-utils scl-utils-build是SCL-utils工具
        yum install -q -y centos-release-scl centos-release-scl-rh scl-utils scl-utils-build
        # 安装IUS源(依赖依赖epel源)
        ## 导入IUS源gpg key
        rpm --import https://repo.ius.io/RPM-GPG-KEY-IUS-7

        ## 安装IUS源
        yum install -q -y https://repo.ius.io/ius-release-el7.rpm
    fi

    # 安装REMi源
    yum install -q -y http://rpms.famillecollet.com/enterprise/remi-release-"$os_version".rpm

    # 查看repolist
    yum repolist
}
# 9. 安装常用必装软件 例如：bash-completion-extras vim
install_necessary_pkg() {
    # 安装终端自动补全 pip3 dnf 虚拟机增强插件 linux核心标准
    yum install -q -y bash-completion python3-pip dnf open-vm-tools redhat-lsb
    yum install -q -y bash-completion-extras
    ## 9.1 安装wireguard内核模块
    # yum install -y kmod-wireguard
    ### 在启动时自动加载wireguard模块
    # echo wireguard >/etc/modules-load.d/wireguard.conf
    # 安装wg-quick
    yum install -q -y wireguard-tools

    ## 9.2 安装常用软件
    yum install -q -y pv net-tools vim lrzsz curl wget tree screen socat lsof telnet tcpdump iperf3 qrencode proxychains-ng traceroute bind-utils
    yum install -q -y conntrack jq sysstat libseccomp git chrony

    ## 9.3 卸载不常用软件nano
    yum autoremove -q -y nano
}

# 10.配置xsync工具
create_xsync() {
    # 检查目录是否存在
    ls ~/bin &>/dev/null || mkdir -p ~/bin
    # 下载xsync脚本
    wget -cP "$HOME"/bin/ https://raw.githubusercontent.com/omaidb/qiaofei_notes/main/shell_code/other/xsync

    # 赋予~/bin/xsync可执行权限
    chmod +x ~/bin/xsync
}

# 11. 阻止内核更新
prevent_kernel_upgrade() {
    # 安装versionlock工具
    yum install -q -y 'dnf-command(versionlock)'
    yum install -q -y yum-plugin-versionlock
    # 备份原配置
    cp /etc/yum.conf /etc/yum.conf.bak

    # 禁止yum升级内核-可能会造成软件包的依赖问题
    yum versionlock kernel* centos-release* initscripts*

    # 添加排除的包前缀,如果过滤规则存在就不添加
    if ! grep "exclude=kernel*" /etc/yum.conf &>/dev/null; then
        # 添加禁止升级的包
        sed -i '$a exclude=kernel* centos-release* initscripts*' /etc/yum.conf
    fi
}

main() {
    # 0.安装前OS环境检查
    check_os_env
    # 1. 关闭防火墙和SELinux
    disable_firewalld
    # 2.内核参数调整
    set_kernel_config
    # 3. PS1美化
    set_PS1
    # 3.0开启history的时间记录
    config_cmd_history_time
    # 3.1 美化vim
    set_vimrc
    # 3.2 设置bashrc
    set_bashrc
    # 4.设置locale
    set_locale_config
    # 5. 优化ssh
    optimization_ssh_config
    # 6. 配置tuned自动调优
    set_tunded_optimization
    # 7. 禁用非必需的postfix服务,启用NetworkManager服务
    disable_nonecessary_service
    # 8. 安装常用repo源
    install_repo
    # 9. 安装常用必装软件
    install_necessary_pkg
    # 10 创建同步工具xsync
    create_xsync
    # 11. 阻止内核升级
    #prevent_kernel_upgrade
}

# 启动主方法
main
