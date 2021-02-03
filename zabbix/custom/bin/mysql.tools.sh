#!/bin/bash
#################################################
#   author      0x5c0f
#   date        2020-04-26
#   email       1269505840@qq.com
#   web         blog.cxd115.me
#   version     1.0.0
#   last update 2020-04-26
#   descript    Use : ./mysql.tools.sh -h
#################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 授权 
# GRANT Process,Replication client ON *.* TO 'zabbixm'@'127.0.0.1'  Identified by "<passwd>" WITH GRANT OPTION;
MYSQL_USER='zabbixm'
MYSQL_PWD='<passwd>'
MYSQL_HOST='127.0.0.1'
MYSQL_PORT='3306'

MYSQL_ADMIN_CONN="/usr/bin/mysqladmin -u${MYSQL_USER} -p${MYSQL_PWD} -h${MYSQL_HOST} -P${MYSQL_PORT}"
MYSQL_CONN="/usr/bin/mysql -u${MYSQL_USER} -p${MYSQL_PWD} -h${MYSQL_HOST} -P${MYSQL_PORT}"

case $1 in
ping)
    result=$(${MYSQL_ADMIN_CONN} ping 2>/dev/null | grep -c alive)
    echo $result
    ;;
Uptime)
    result=$(${MYSQL_ADMIN_CONN} status 2>/dev/null | cut -f2 -d":" | cut -f1 -d"T")
    echo $result
    ;;
Com_update)
    result=$(${MYSQL_ADMIN_CONN} extended-status 2>/dev/null | grep -w "Com_update" | cut -d"|" -f3)
    echo $result
    ;;
Slow_queries)
    result=$(${MYSQL_ADMIN_CONN} status 2>/dev/null | cut -f5 -d":" | cut -f1 -d"O")
    echo $result
    ;;
Com_select)
    result=$(${MYSQL_ADMIN_CONN} extended-status 2>/dev/null | grep -w "Com_select" | cut -d"|" -f3)
    echo $result
    ;;
Com_rollback)
    result=$(${MYSQL_ADMIN_CONN} extended-status 2>/dev/null | grep -w "Com_rollback" | cut -d"|" -f3)
    echo $result
    ;;
Questions)
    result=$(${MYSQL_ADMIN_CONN} status 2>/dev/null | cut -f4 -d":" | cut -f1 -d"S")
    echo $result
    ;;
Com_insert)
    result=$(${MYSQL_ADMIN_CONN} extended-status 2>/dev/null | grep -w "Com_insert" | cut -d"|" -f3)
    echo $result
    ;;
Com_delete)
    result=$(${MYSQL_ADMIN_CONN} extended-status 2>/dev/null | grep -w "Com_delete" | cut -d"|" -f3)
    echo $result
    ;;
Com_commit)
    result=$(${MYSQL_ADMIN_CONN} extended-status 2>/dev/null | grep -w "Com_commit" | cut -d"|" -f3)
    echo $result
    ;;
Bytes_sent)
    result=$(${MYSQL_ADMIN_CONN} extended-status 2>/dev/null | grep -w "Bytes_sent" | cut -d"|" -f3)
    echo $result
    ;;
Bytes_received)
    result=$(${MYSQL_ADMIN_CONN} extended-status 2>/dev/null | grep -w "Bytes_received" | cut -d"|" -f3)
    echo $result
    ;;
Com_begin)
    result=$(${MYSQL_ADMIN_CONN} extended-status 2>/dev/null | grep -w "Com_begin" | cut -d"|" -f3)
    echo $result
    ;;
Table_lock)
    result=$(${MYSQL_CONN} -e 'SHOW OPEN TABLES WHERE In_use > 0' 2>/dev/null | wc -l)
    echo $result
    ;;
Slave_status)
    slave_is=($(${MYSQL_CONN} -e 'show slave status\G' 2>/dev/null | grep "Running:" | awk -F ':' '{print $2}'))
    if [ "${slave_is[0]}" = "Yes" -a "${slave_is[1]}" = "Yes" ]; then
        result=0
    else
        result=1
    fi
    echo $result
    ;;
*)
    echo "Usage:$0 (Uptime|Com_update|Slow_queries|Com_select|Com_rollback|Questions|Com_insert|Com_delete|Com_commit|Bytes_sent|Bytes_received|Com_begin|Table_lock|Slave_status)"
    ;;
esac

