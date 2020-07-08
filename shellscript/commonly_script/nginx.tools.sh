#!/bin/bash
################################################# 
#   author      0x5c0f 
#   date        2020-04-24 
#   email       1269505840@qq.com 
#   web         blog.cxd115.me 
#   version     1.0.0
#   last update 2020-04-24
#   descript    Use : ./nginx.tools.sh -h
#   yum install jq -y
################################################# 

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

declare -r VTSHOST="https://logs.omoney.com"
declare -r AUTH_USER="omoney"
declare -r AUTH_PASSWD='i4Kzqvf!ry'

ngxStmp="/tmp/nginx.status.json"

/usr/bin/curl -s -u "${AUTH_USER}:${AUTH_PASSWD}" "${VTSHOST}/vts-status/format/json" > ${ngxStmp} 

# 单位时间内服务器正在处理的连接数  active 
# nginx 读取到客户端的header信息数  reading
# 返回给客户端的header信息数 writing
# 此启动到现在一共处理的连接(server|vts:requests)   
# 从启动到现在成功创建多少次握手,和server相同表示没有失败(accepts)  
# 已经处理完毕的请求数(handled requests| vts:handled) 
# 已经处理完正在等候下一次请求指令的驻留链接, 开启keep-alive的情况下，这个值等于 Active - (Reading+Writing) (waiting)
function connections {
    local result 
    result=`cat ${ngxStmp}|jq ".connections.${1}"` 
    echo $result 
}

# $1: all|omoneyxxx
# 获取对应站点的httpcode
function serverZonesHTTPCode(){
     :
}

#connections $1

function main {
    case $1 in
        "connections") 
            connections $2
        ;;
        "httpcode") 
            echo "构建中..."
            exit 1
        ;;
        "upstreams")
            echo "构建中..."
            exit 1
        ;;
        *) 
            echo "
    $0 'connections' 'active|reading|writing|waiting|accepted|handled|requests'
    $0 'httpcode' 'www.example.com' '1xx|2xx|3xx|4xx|5xx'
    $0 'upstreams' 'www.example.com' 'upstreamsip' 
            "
        ;;
    esac
    
}

main $@

# ./nginx.tools.sh "connections" "status"
# ./nginx.tools.sh "httpcode" "domain" "httpcode"
# ./nginx.tools.sh "upstreams" "domain" "ip" 

# key: ngx.status.connections[active]
# key: ngx.status.httpcode[core.omoney.com,2xx]
# key: ngx.status.upstreams[core.omoney.com,ip]


