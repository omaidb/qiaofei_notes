#!/bin/bash

## 使用全球已知的攻击者更新fail2ban iptables。
## 独立运行，不需要安装fail2ban。
## /etc/cron.daily/sync-fail2ban
##
## 作者：Marcos Kobylecki <fail2ban.globalBlackList@askmarcos.com>
## http://www.reddit.com/r/linux/comments/2nvzur/shared_blacklists_from_fail2ban/


## 如果fail2ban丢失则退出。 也许这个虚假的要求可以被跳过？ 是的。

#PROGRAM=/etc/init.d/fail2ban
#[ -x $PROGRAM ] || exit 0

datadir=/etc/fail2ban
[[ -d "$datadir" ]] || datadir=/tmp

## 获取fail2ban的默认设置（可选？）
[ -r /etc/default/fail2ban ] && . /etc/default/fail2ban

umask 000
blacklistf=$datadir/blacklist.blocklist.de.txt

mv -vf  $blacklistf  $blacklistf.last

badlisturls="http://antivirus.neu.edu.cn/ssh/lists/base_30days.txt http://lists.blocklist.de/lists/ssh.txt  http://lists.blocklist.de/lists/bruteforcelogin.txt"


 iptables -vN fail2ban-ssh   # 如果链不存在，则创建该链。 如果有的话也无害。
  
# 从这里获取Block列表 https://www.blocklist.de/en/export.html
echo "Adding new blocks:"
 time  curl -s http://lists.blocklist.de/lists/ssh.txt  http://lists.blocklist.de/lists/bruteforcelogin.txt \
  |sort -u \
  |tee $blacklistf \
  |grep -v '^#\|:' \
  |while read IP; do iptables -I fail2ban-ssh 1 -s $IP -j DROP; done 



# 自上次以来哪些列表已被删除--解锁。
echo "Removing old blocks:"
if [[ -r  $blacklistf.diff ]]; then
  #       comm  is brittle, cannot use sort -rn 
 time  comm -23 $blacklistf.last  $blacklistf \
   |tee $blacklistf.delisted \
   |grep -v '^#\|:' \
   |while read IP; do  iptables -w -D fail2ban-ssh -s $IP -j DROP || iptables -wv -D fail2ban-ssh -s $IP -j LOGDROP; done 

fi


# 为下次做准备。
	diff -wbay $blacklistf.last $blacklistf  > $blacklistf.diff 


# 保存当前 iptables 规则的副本，以便您稍后查看。
(set -x; iptables -wnv -L --line-numbers; iptables -wnv -t nat -L --line-numbers) &> /tmp/iptables.fail2ban.log &


exit 

# iptables v1.4.21: host/network `2a00:1210:fffe:145::1' not found
# So weed out IPv6, try |grep -v ':' 

## http://ix.io/fpC

 
# Option:  actionban
# Notes.:  command executed when banning an IP. Take care that the
#          command is executed with Fail2Ban user rights.
# Tags:    参阅 jail.conf(5) 手册页
# Values:  CMD
#
actionban = iptables -I fail2ban-<name> 1 -s <ip> -j <blocktype># Option:  actionunban
# Notes.:  command executed when unbanning an IP. Take care that the
#          command is executed with Fail2Ban user rights.
# Tags:    See jail.conf(5) man page
# Values:  CMD
#
actionunban = iptables -D fail2ban-<name> -s <ip> -j <blocktype>
