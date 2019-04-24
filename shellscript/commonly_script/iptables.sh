#!/bin/bash

######### ENV ####################
# env_start
# 英文ASCII编码，如中文的zh，防止出现乱码
export LANG=C
export LC_ALL=C
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
# env_over

### kernel modules ##############
# 使防火墙支持vsftpd被动模式
modules="ip_conntrack_ftp ip_conntrack_irc"
for mod in $modules
do
    testmod=`lsmod | grep "${mod}"`
    if [ "$testmod" == "" ]; then
        modprobe $mod
    fi
done

###### filter table ################

###### INPUT chains ######
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
# 清空所有规则，不会处理默认规则 
iptables -F
iptables -F -t nat
# 删除用户自定义的链
iptables -X

# prevent all Stealth Scans and TCP State FLags
iptables -A INPUT -p tcp --tcp-flags ALL ALL -j DROP 
# all of the bits are cleared 
iptables -A INPUT -p tcp --tcp-flags ALL NONE -j DROP
iptables -A INPUT -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
# sync and srt are both set 
iptables -A INPUT -p tcp --tcp-flags  SYN,RST SYN,RST -j DROP
# syn and fin are both set 
iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
#fin and rst are both set 
iptables -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
#find is th e only bit set ,without the expected accompanying ack 
iptables -A INPUT -p tcp --tcp-flags ACK,FIN FIN -j DROP
# PSH is the only bit set,without the expected accompanying ack
iptables -A INPUT -p tcp --tcp-flags ACK,PSH PSH -j DROP
#urg is the only bit set,without the expected accompanying ack
iptables -A INPUT -p tcp --tcp-flags ACK,URG URG -j DROP

# 允许关联的状态包通过(vsftpd)
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
# 允许所有ip  ping
iptables -A INPUT -p icmp -m icmp --icmp-type any -m limit --limit 100/s -j ACCEPT

#web 80
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

#iptables -A INPUT -s 0.0.0.0/32 -j ACCEPT
#iptables -I INPUT -s 0.0.0.0/32 -j DROP

### global ###
# 拒绝后续配置的DORP ACCEPT规则
#iptables -A INPUT -j REJECT --reject-with icmp-host-prohibited

iptables-save -c > /etc/sysconfig/iptables
# service iptables save

