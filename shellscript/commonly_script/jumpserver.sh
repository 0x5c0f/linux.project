#!/usr/bin/env bash
#   author      0x5c0f
#   date        2019-04-25
#   email       1269505840@qq.com
#   web         blog.cxd115.me
#   version     1.0.0
#   last update 2019-04-28
#   descript    跳板机程序  ./jumpserver.sh --help
#               1. 目前已知问题, 判断的正则存在不精准的问题  
#               2. 配置文件jumpserver.conf复制到/etc目录  
#                 2.1 内容格式按照默认内容配置  
#                 2.2 需以一条空行或注释行结束
#               3. 在/etc/profile 中添加 
#               [ $UID -ne 0 ] || {
#                   . /path/jumpserver.sh
#               }
#               4. 安全优化 
#                 4.1 配置远程主机设置免密登陆 
#                 4.2 取消远程主机的密码登陆
#                 4.3 限制远程主机访问ip
# 

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 远程连接配置文件
#CONF_PATH="../../config/jumpserver.conf"
CONF_PATH="/etc/jumpserver.conf"

# 临时状态文件
TMP_FILE="/tmp/connection_status.log"

# 是否显示用户
IS_SHOW_USER=0

declare -A IP_ARRAY

# 封禁键盘控制信号
trap '' 1 2 3 15 20

. /etc/init.d/functions

HELP() {
    echo "恭喜你,打开了隐藏的帮助栏目"
    echo
    echo "1. 输入主机对应编号,直接登陆主机或更新程序"
    echo "2. 可输入命令exit/reload/showUser/closeUser/clear以执行退出重载等功能"
    echo "3. 输入ip，可直接登陆主机(仅限已配置主机)"
    echo "4. 若需新增登陆主机,需联系管理员将主机添加至配置文件"
    echo "5. ..."
}

echo_success() {
    MOVE_TO_COL="echo -en \\033[51G"
    [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
    echo -n "["
    [ "$BOOTUP" = "color" ] && $SETCOLOR_SUCCESS
    echo -n $"  $1  "
    [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
    echo -n "]"
    echo -ne "\r"
    return 0
}

echo_failure() {
    MOVE_TO_COL="echo -en \\033[51G"
    [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
    echo -n "["
    [ "$BOOTUP" = "color" ] && $SETCOLOR_FAILURE
    echo -n $" $1 "
    [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
    echo -n "]"
    echo -ne "\r"
    return 1
}

echo_warning() {
    MOVE_TO_COL="echo -en \\033[20G"
    [ "$BOOTUP" = "color" ] && $MOVE_TO_COL
    echo -n ">>>>>>>>>"
    [ "$BOOTUP" = "color" ] && $SETCOLOR_WARNING
    echo -n $" $1 "
    [ "$BOOTUP" = "color" ] && $SETCOLOR_NORMAL
    echo -n "<<<<<<<<<"
    echo -ne "\r"
    return 1
}

check_online() {
    $(ping -w 2 -c 1 $1 >&/dev/null) && echo_success "Online" || echo_failure "Offline"
}

#
CFG_LOAD() {
    local num=1
    while read line; do
        #if [[ $line =~ ^[a-z]+@([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$ ]]; then
        if [[ $line =~ ^[a-zA-Z] ]]; then
            IP_ARRAY[$num]=$line
            ((num++))
        fi
    done <$CONF_PATH

}

CON_STATUS() {
    len=${#IP_ARRAY[@]}
    for ((i = 1; i <= $len; i++)); do
        local SHOWINFO
        [ $IS_SHOW_USER -eq 0 ] && {
            # 隐藏
            SHOWINFO=${IP_ARRAY[$i]#*@}
        } || {
            # 显示
            SHOWINFO=${IP_ARRAY[$i]}
        }
        echo -e "  $i.  ${SHOWINFO}" $(check_online ${IP_ARRAY[$i]#*@})
        echo -e "  $i.  ${SHOWINFO}" $(check_online ${IP_ARRAY[$i]#*@}) >>${TMP_FILE}
    done
}

SHOW_USER_INFO() {
    clear
    [ $IS_SHOW_USER -eq 0 ] && {
        IS_SHOW_USER=1
        echo "$(echo_warning "Open User Info,Please Reload ")"
    } || {
        IS_SHOW_USER=0
        echo "$(echo_warning "Close User Info,Please Reload ")"
    }
}

RELOAD_CON() {
    CON_STATUS >&/dev/null && {
        echo $(echo_success "Reload successfully")
        return $(/bin/true)
    } || {
        echo $(echo_failure "Reload failed")
        return $(/bin/false)
    }
}

GET_CON_STATUS() {
    if [ -s "${TMP_FILE}" ]; then
        if [[ "$1" == "0" ]]; then
            clear
            >${TMP_FILE}
            for i in {1..3}; do
                echo -n ">>>>>>"
                sleep 1
            done
            RELOAD_CON
        else
            while read line; do
                echo -e "  $line"
            done <"${TMP_FILE}"
        fi
    else
        CON_STATUS
    fi
    return
}

REMOTE_HOST() {
    # 此处传入的只有正确的下标或者正常的ip地址
    VAR=$1
    case "$VAR" in
    0)
        clear
        #echo "$(echo_warning 'Invalid number...')"
        HELP
        read -p "press any key to continue..."
        clear
        return 1
        ;;
    [1-9] | [1-9]? | [1-9]??)
        ssh ${IP_ARRAY[$VAR]}
        ;;
    *)
        if [[ "$VAR" =~ ^([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$ ]]; then
            local CONN
            for v in ${IP_ARRAY[@]}; do
                if [[ "${v#*@}" == "$1" ]]; then
                    CONN=$v
                    break
                fi
            done
            [ -z $CONN ] && {
                echo "$(echo_warning "Invalid IP Address")"
                read -p "press any key to continue..."
            } || {
                ssh $CONN
            }
        fi
        ;;
    esac

}

main() {

    [[ -z "$1" ]] || {
        [[ "$1" == "help" || "$1" == "--help" ]] && {
            HELP
            exit 0
        }
    }

    CFG_LOAD
    local RETVAL=$?
    while true; do
        echo -e "#.#.#.#.#.#.#.#.#.#.#.# >> 当 前 主 机 状 态 << #.#.#.#.#.#.#.#.#.#.#\n>>>"
        GET_CON_STATUS
        echo -e ">>>\n#.#.#.#.#.#.#.#.#.#.#.# >> 当 前 主 机 状 态 << #.#.#.#.#.#.#.#.#.#.#\n<<<"
        echo -e "  $((${#IP_ARRAY[@]} + 1)).  reload"
        echo -e "  $((${#IP_ARRAY[@]} + 2)).  show/closeUser"
        echo -e "  $((${#IP_ARRAY[@]} + 3)).  exit\n<<<"
        read -p "Please enter the number (ip or operation command) you want to log in to the host. >> " choose

        if [[ "$choose" == "reload" ]]; then
            GET_CON_STATUS "0"
            RETVAL=$?
        elif [[ "$choose" == "clear" ]]; then
            clear
        elif [[ "$choose" =~ (show|close)User ]]; then
            SHOW_USER_INFO
        elif [[ "$choose" == "$((${#IP_ARRAY[@]} + 3))" || "$choose" == "exit" ]]; then
            exit $RETVAL
        elif [[ "$choose" =~ ^[0-9]+$ ]]; then
            if [[ "$choose" -gt "$((${#IP_ARRAY[@]} + 3))" ]]; then
                clear
                echo "$(echo_warning "Invalid number")"
                read -p "press any key to continue..."
                RETVAL=$?
            elif [[ "$choose" == "$((${#IP_ARRAY[@]} + 2))" ]]; then
                SHOW_USER_INFO
            else
                REMOTE_HOST "$choose"
                RETVAL=$?
            fi
        elif [[ "$choose" =~ ^([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.([0-9]{1,2}|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$ ]]; then
            REMOTE_HOST "$choose"
            RETVAL=$?
        else
            continue
        fi
        echo
    done
}

main $1
