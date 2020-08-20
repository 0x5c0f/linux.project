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

declare -r VTSHOST="http://<server_ip>:<port>"
declare -r AUTH_USER="<user>"
declare -r AUTH_PASSWD='<passwd>'

ngxStmp="/tmp/nginx.status.json"

/usr/bin/curl -s -u "${AUTH_USER}:${AUTH_PASSWD}" "${VTSHOST}/vts-status/format/json" > ${ngxStmp}

function connections() {
    local result
    case $1 in
    active)
        # 单位时间内服务器正在处理的连接数  active
        result=$(cat ${ngxStmp} | jq ".connections.active")
        echo "$result"
        exit 0
        ;;
    reading)
        # nginx 读取到客户端的header信息数  reading
        result=$(cat ${ngxStmp} | jq ".connections.reading")
        echo "$result"
        exit 0
        ;;
    writing)
        # 返回给客户端的header信息数 writing
        result=$(cat ${ngxStmp} | jq ".connections.writing")
        echo "$result"
        exit 0
        ;;
    waiting)
        # 已经处理完正在等候下一次请求指令的驻留链接, 开启keep-alive的情况下，这个值等于 Active - (Reading+Writing) (waiting)
        result=$(cat ${ngxStmp} | jq ".connections.waiting")
        echo "$result"
        exit 0
        ;;
    accepted)
        # 从启动到现在成功创建多少次握手,和handled相同表示没有失败(accepts)
        result=$(cat ${ngxStmp} | jq ".connections.accepted")
        echo "$result"
        exit 0
        ;;
    handled)
        # 已经处理完毕的请求数(handled requests| vts:handled)
        result=$(cat ${ngxStmp} | jq ".connections.handled")
        echo "$result"
        exit 0
        ;;
    requests)
        # 此启动到现在一共处理的连接(server|vts:requests)
        result=$(cat ${ngxStmp} | jq ".connections.requests")
        echo "$result"
        exit 0
        ;;
    *)
        echo -e "$0 connections active|reading|writing|waiting|accepted|handled|requests "
        exit 0
        ;;
    esac
}

# $1: all|_|xxx.omoney.com
# $2: all|1xx|2xx|3xx|4xx|5xx
# 获取对应站点的httpcode
function serverZonesHttpCode() {
    local result

    case $1 in
    "all")
        # all 包含非法绑定和elb检测连接
        result=$(eval "cat ${ngxStmp} | jq '.serverZones.\"*\".responses.\"${2}\"'")
        echo $result
        exit 0
        ;;
    *)
        result=$(eval "cat ${ngxStmp} | jq '.serverZones.\"$1\".responses.\"$2\"'")
        if [[ "$result" == "null" ]]; then
            echo "Err: not fount ${1}" 
            echo $(cat ${ngxStmp} | jq '.serverZones|keys')
            exit 1
        else
            echo $result
            exit 0
        fi
        ;;
    esac
}

#connections $1

function main() {
    case $1 in
    "ping")
        systemctl is-active nginx.service >&/dev/null
        echo $?
        exit $?
        ;;
    "connections")
        connections "$2"
        ;;
    "httpcode")
        serverZonesHttpCode "$2" "$3"
        ;;
    "upstreams")
        echo "未实现 ... "
        exit 1
        ;;
    *)

        > /dev/stdout cat <<EOF
  $0 connections active|reading|writing|waiting|accepted|handled|requests
  $0 httpcode www.example.com all|_|1xx|2xx|3xx|4xx|5xx
  $0 upstreams www.example.com upstreamsip"
EOF
        ;;
    esac

}

main $@

# main "connections" "active"
# main "httpcode" "all" "2xx"
