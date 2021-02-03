#!/bin/bash
################################################# 
#   author      0x5c0f 
#   date        2021-02-02 
#   email       1269505840@qq.com 
#   web         blog.cxd115.me 
#   version     1.0.0
#   last update 2021-02-02
#   descript    Use : ./init.sh -h
################################################# 

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# base script dir 
BASEDIR=$(dirname $(readlink -f "$0"))

# Zabbix-Directory
ZBXBASEDIR=/opt/zabbix-server

# 初始话的基础目录
SCRIPTSBDIR=$ZBXBASEDIR/scripts

# 程序二进制目录
SCRIPTSBINDIR=$SCRIPTSBDIR/bin

# zabbix agentd conf 目录 
SCRIPTSCONFDDIR=$SCRIPTSBDIR/conf.d

if [[ ! -d $SCRIPTSBDIR ]]; then
    mkdir -p $SCRIPTSBDIR
else
    echo "目录${SCRIPTSBDIR}已存在(非首次初始请手动调整)!"    
    exit 35
fi

# 初始化到定制目录中 
cp -a $BASEDIR/* $SCRIPTSBDIR/ 

# 域名监控
sed -i "s#{{SCRIPTSBINDIR}}#${SCRIPTSBINDIR}#g" ${SCRIPTSCONFDDIR}/domain.status.conf

# mysql 监控
sed -i "s#{{SCRIPTSBINDIR}}#${SCRIPTSBINDIR}#g" ${SCRIPTSCONFDDIR}/mysql.status.conf

# nginx 监控
sed -i "s#{{SCRIPTSBINDIR}}#${SCRIPTSBINDIR}#g" ${SCRIPTSCONFDDIR}/nginx.status.conf

# tcp 监控
sed -i "s#{{SCRIPTSBINDIR}}#${SCRIPTSBINDIR}#g" ${SCRIPTSCONFDDIR}/tcp.status.conf

# 磁盘 监控
sed -i "s#{{SCRIPTSBINDIR}}#${SCRIPTSBINDIR}#g" ${SCRIPTSCONFDDIR}/diskstats.conf

# 初始化 zabbix_agentd.conf.d 
sed -i "266a Include=${SCRIPTSCONFDDIR}/*.conf" $ZBXBASEDIR/etc/zabbix_agentd.conf 