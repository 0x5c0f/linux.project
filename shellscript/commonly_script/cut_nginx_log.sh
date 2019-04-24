#!/bin/bash
# 40 23 * * * /bin/bash /opt/sh/cut_nginx_log.sh >> /dev/null 2>&1 
time=`date +"%Y-%m-%d"`
BASE_DIR="/opt/nginxssl"
LOG_PATH="${BASE_DIR}/logs"
NEW_DIR="/opt/logs/nginxlogs"
# 后缀 默认 .log 不添加
logs_names=(www www1)
cd $NEW_DIR
num=${#logs_names[@]} 
for((i=0;i<num ;i++));do
  mv ${LOG_PATH}/${logs_names[i]}.log ${NEW_DIR}/${logs_names[i]}_${time}.log
  tar czf ${logs_names[i]}_${time}.tar.gz ${logs_names[i]}_${time}.log
  rm ${logs_names[i]}_${time}.log
done

${BASE_DIR}/sbin/nginx -s reopen

#find /home/logs/nginxlog -mtime +30 -exec rm -rf {} \;