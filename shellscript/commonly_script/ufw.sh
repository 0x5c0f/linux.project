#!/bin/sh
IPTABLES="/usr/sbin/ufw"

#清空防火墙
$IPTABLES --force reset
#启动防火墙
$IPTABLES --force enable

# 允许所有传出，拒绝所有传入
#$IPTABLES default deny 
$IPTABLES default allow outgoing
$IPTABLES default deny incoming
#允许 80/tcp 接入
$IPTABLES allow 80/tcp
#$IPTABLES allow http/tcp
#允许22/tcp 接入
#$IPTABLES allow 22/tcp
#允许 443/tcp 接入
$IPTABLES allow 443/tcp
#公司信任ip
$IPTABLES allow from 113.204.136.66

$IPTABLES allow from 183.230.47.89 to any port 21 proto tcp
#$IPTABLES allow from 50.22.3.69 to any port 22 proto tcp
#$IPTABLES allow from 116.204.13.154 to any port 22 proto tcp
$IPTABLES allow from 103.14.34.55 to any port 22 proto tcp


# 允许特定ip+端口接入
#$IPTABLES allow from 113.204.136.66 to any port 22 proto tcp



$IPTABLES reload
