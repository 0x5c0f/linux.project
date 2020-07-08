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

iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p icmp -m icmp --icmp-type any -m limit --limit 100/s -j ACCEPT

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

# 单个IP在60秒内只允许新建20个连接
iptables -I  INPUT -i eth0 -p tcp -m tcp --dport 80 -m state --state NEW -m recent --update --seconds 60 --hitcount 20 --name DEFAULT --rsource -j DROP
iptables -I  INPUT -i eth0 -p tcp -m tcp --dport 443 -m state --state NEW -m recent --update --seconds 60 --hitcount 20 --name DEFAULT --rsource -j DROP
iptables -I  INPUT -i eth0 -p tcp -m tcp --dport 80 -m state --state NEW -m recent --set --name DEFAULT --rsource
iptables -I  INPUT -i eth0 -p tcp -m tcp --dport 443 -m state --state NEW -m recent --set --name DEFAULT --rsource

# 控制单个IP的最大并发连接数为20
iptables  -I INPUT -p tcp --dport 80 -m connlimit  --connlimit-above 20 -j REJECT
iptables  -I INPUT -p tcp --dport 443 -m connlimit  --connlimit-above 20 -j REJECT

# 每个IP最多20个初始连接
iptables -I  INPUT -p tcp --syn -m connlimit --connlimit-above 20 -j DROP

# 防止syn攻击(限制单个ip的最大syn连接数)
iptables -A INPUT -i eth0 -p tcp --syn -m connlimit --connlimit-above 15 -j DROP

# 单个ip对多连接3个会话
iptables -I INPUT -p tcp --dport 22 -m connlimit --connlimit-above 3 -j DROP

# 只要是新的连接请求，就把它加入到SSH列表中
iptables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --set --name SSH

# 5分钟内你的尝试次数达到3次，就拒绝提供SSH列表中的这个IP服务。5分钟后即可恢复
iptables -I INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 300 --hitcount 3 --name SSH -j DROP

# 防止单个IP访问量过大
iptables -I INPUT -p tcp --dport 80 -m connlimit --connlimit-above 30 -j DROP
iptables -I INPUT -p tcp --dport 443 -m connlimit --connlimit-above 30 -j DROP

# syn 防护
iptables -N syn-flood
iptables -A INPUT -p tcp --syn -j syn-flood
iptables -I syn-flood -p tcp -m limit --limit 3/s --limit-burst 6 -j RETURN
iptables -A syn-flood -j REJECT


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

