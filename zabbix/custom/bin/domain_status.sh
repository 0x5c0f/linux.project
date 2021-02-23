#!/bin/bash
#################################################
#   author      0x5c0f
#   date        2021-01-11
#   email       1269505840@qq.com
#   web         blog.cxd115.me
#   version     1.1.0
#   last update 2021-01-11
#   descript    Use : ./ssl.status.sh -h
#################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 当前目录
base_dir=$(dirname $(readlink -f "$0"))

siteStmp="/tmp/site.status.json"
domain_host_cfg="${base_dir}/../etc.d/domain_host.cfg"

check_ssl() {
    local domain_host="$1"
    local domain_port="$2"

    # openssl s_client -host ${domain_host} -port ${domain_port} -showcerts 2>/dev/null
    ssl_end_time=$(echo | openssl s_client -servername ${domain_host} -connect ${domain_host}:${domain_port} 2>/dev/null | openssl x509 -noout -dates | grep 'notAfter' | awk -F '=' '{print $2}' | awk '{print $1,$2,$3,$4 }')

    end_time=$(date +%s -d "${ssl_end_time}")
    now_time=$(date +%s)

    res=$(((end_time - now_time) / (60 * 60 * 24)))

    echo ${res}
}

_getCheckURes(){
    curl -L --connect-timeout 3 -m 9 -k -o /dev/null -s -w "{\"domain_host\":\"${1}\", \"http_code\": \"%{http_code}\",\"time_pretransfer\": \"%{time_pretransfer}\",\"time_starttransfer\":\"%{time_starttransfer}\",\"speed_download\":\"%{speed_download}\",\"time_namelookup\":\"%{time_namelookup}\",\"time_connect\":\"%{time_connect}\",\"time_total\":\"%{time_total}\"}\n" $1
}

_init() {

    if [[ -f "${siteStmp}.tmp" ]]; then
      # 上一次没有检查完就暂时不进行下次检测了
      exit 0
    fi

    # 重复的只需要检查一次就可以了,自动发现会传参数自行区分
    domain_hosts=($(awk '/^https?/{print $1}' ${domain_host_cfg} |sort | uniq ))   

    if [ -n "$1" ]; then
       echo $(_getCheckURes $1) 
    else
        for hosts in "${domain_hosts[@]}"; do
            echo $(_getCheckURes ${hosts}) >>"${siteStmp}.tmp" &
            sleep 0.3
        done
        # 等待检测完成
        while true; do
          res=$(ps -ef|grep "%\{http_code\}|grep -v grep")
          ps -ef|grep -E "[%]\{http_code}"  || {
            cat "${siteStmp}.tmp" > ${siteStmp}
            rm -rf "${siteStmp}.tmp"
            sleep 2
            break
          }
        done
    fi
}

_checkSiteInfo(){
    local domain_host="$1"
    local check_type="$2"

    resjson=$(grep -m 1 -E "${domain_host}" ${siteStmp})

    echo $resjson | jq ".${check_type}"| sed 's/\"//g'
}

main() {
    local domain_host="$1"
    local check_type="$2"

    if [ -z "${domain_host}" ]; then
        exit 2
    fi

    case "${check_type}" in
    "ssl")
        # $0 domain_host ssl
        ## 检查证书 https://example.com
        check_ssl $(echo "${domain_host}" |awk -F"[:/]" '{if ($NF !~ /^[0-9]+$/ ){print $NF,"443"}else{print $(NF-1),$NF}}')
        ;;
    "debug")
        _init "${domain_host}"
        ;;
    *)
        # $0 host port http_code
        ## 获取站点状态
        echo "功能禁用."
        # _checkSiteInfo "${domain_host}" "${check_type}"
        ;;
    esac
}

_help() {
    cat >/dev/stdout <<EOF
域名状态检测脚本  
  
读取站点访问结果并写入信息文件
  config  : ${domain_host_cfg} 
    - 配置检测域名的文件，自动去重(处理zabbix需要做证书检测也要做常规检测的)
  resjson : ${siteStmp} 
    - zabbix采集用的结果文件
        ----- 
  scripts : $0 init 
    - 初始化zabbix采集结果 
    - * * * * * $0 init >& /dev/null

获取域名证书到期时间(天): 
  $0 https://example.com ssl        # zabbix 采集需要增加下脚本执行时间Timeout=30

获取域名在线状态信息(ms|byte/s):

  单个域名检查,返回当前域名全部检查信息(实时检查) 
  $0 https?://example.com:<port> debug

  单个域名检查,返回当前域名单项检查信息(从init的配置文件中读取,用于zabbix采集)
  $0 https?://example.com:<port> http_code|time_pretransfer|time_starttransfer|speed_download|time_namelookup|time_connect|time_total 

  # key domain.status[https://blog.cxd115.me,ssl]  
  # key domain.status[http://www.baidu.com,http_code]

  # UserParameter=domain.status[*],$base_dir/$(basename $0) \$1 \$2
    
参数信息: 
  %{http_code}             :http 状态码
  %{time_pretransfer}      :从请求开始到响应开始传输的时间
  %{time_starttransfer}    :从请求开始到第一个字节将要传输的时间
  %{speed_download}        :下载速度  单位 byte/s
  %{time_namelookup}       :dns 解析时间
  %{time_connect}          :client和server端建立TCP 连接的时间(三次握手的时间)
  %{time_total}            :此次请求花费的全部时间

  %{time_total} - %{time_starttransfer}       =  内容传输时间
  %{time_starttransfer} - %{time_pretransfer} =  服务器处理时间
  %{time_pretransfer} - %{time_namelookup}    =  TCP 连接时间

EOF
}

if [ "$#" -ne 0 ]; then
    if [[ "$1" == "init" ]]; then
        # 定时任务模块
        _init
    elif [[ "$1" == "--help" || "$1" == "-h" ]]; then
        _help
    else
        main $@
    fi
else
    _help
fi

# key domain.status[https://blog.cxd115.me,ssl]
# key domain.status[http://www.baidu.com,http_code]
