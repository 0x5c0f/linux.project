#!/bin/bash
# Use : /bin/bash /opt/sh/cut_nginx_log.sh
# 1 0 * * * /bin/bash /opt/sh/cut_nginx_log.sh >> /dev/null 2>&1 
# 若服务负载高,日志量大建议使用cronlog工具进行切割 
# 

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

time=`date  +"%Y-%m-%d" -d "-1 days"`

BASE_DIR="/opt/apache-tomcat-9.0.19/"
LOG_PATH="${BASE_DIR}/logs"
NEW_DIR="/tmp/tomcatlog"

# 切割  只能cp
cd ${LOG_PATH} 

cp catalina.out catalina.out.${time}
echo "" > catalina.out

LOG_FILE=`ls *${time}*`

for log in ${LOG_FILE} ; do 
    tar -czf ${log}.tar.gz $log --remove-files 
    mv ${log}.tar.gz ${NEW_DIR} 
done

find ${NEW_DIR} -type f  -mtime +30 -exec rm -rf {} \;