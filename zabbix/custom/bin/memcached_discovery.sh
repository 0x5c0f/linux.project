#!/bin/bash
################################################# 
#   author      0x5c0f 
#   date        2020-11-26 
#   email       1269505840@qq.com 
#   web         blog.cxd115.me 
#   version     1.0.0
#   last update 2020-11-26
#   descript    Use : ./memcached_discovery.sh
#   need /etc/sudoers add 
#   zabbix  ALL=(root)      NOPASSWD:/bin/netstat
################################################# 

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

CHECKRES=($(sudo netstat -l4ntp|awk -F '[ :]+' '/[m]emcached/ {print $4"_"$5}'))
printf '{\n'
printf '\t"data":[\n'

Flag=1
for key in ${CHECKRES[@]}; do
      IP_PORT=(${key//_/ })
           
       if [[ "${IP_PORT[0]}" == "0.0.0.0" ]]; then 
         _ip="127.0.0.1"
       fi

      printf '\t\t {\n'
      printf "\t\t\t\"{#MEMIP}\":\"${_ip:=${IP_PORT[0]}}\",\n"
      printf "\t\t\t\"{#MEMPORT}\":\"${IP_PORT[1]}\"\n"

      if [[ "${Flag}" -ne "${#CHECKRES[@]}" ]]; then
        printf '\t\t },\n'
      else
        printf '\t\t }\n'
      fi

      (( Flag ++ ))
      unset _ip IP_PORT
done

printf '\t ]\n'
printf '}\n'
