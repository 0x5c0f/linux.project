#!/bin/bash
#################################################
#   author      0x5c0f
#   date        2019-04-11 收集整理
#   email       1269505840@qq.com
#   web         blog.cxd115.me
#   version     1.0
#   last update 2019-04-11
#   descript    Use : haproxy.init.sh -h
#################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

PROCESS_NAME=haproxy
BASE_DIR=/opt/haproxy
EXEC=$BASE_DIR/sbin/haproxy
PID_FILE=$BASE_DIR/haproxy.pid
DEFAULT_CONF=$BASE_DIR/etc/haproxy.cfg

# COLOR print
COLOR_RED=$(echo -e "\e[31;49m")
COLOR_GREEN=$(echo -e "\e[32;49m")
COLOR_RESET=$(echo -e "\e[0m")
info() { echo "${COLOR_GREEN}$*${COLOR_RESET}"; }
warn() { echo "${COLOR_RED}$*${COLOR_RESET}"; }

print_usage() {
    info " Usage: $(basename $0) [start|stop|restart|status|test]"
}

#get Expanding configuration
ext_configs() {
    CONFIGS=
    if [[ -d $BASE_DIR/etc/enabled ]]; then
        for FILE in $(find $BASE_DIR/etc/enabled -type l | sort -n); do
            CONFIGS="$CONFIGS -f $FILE"
        done
        echo $CONFIGS
    else
        echo
    fi
}
# check process status
check_process() {
    PID=$(get_pid)
    if ps aux | awk '{print $2}' | grep -qw $PID 2>/dev/null; then
        true
    else
        false
    fi

}
# check Configuration file
check_conf() {
    $EXEC -c -f $DEFAULT_CONF $(ext_configs) >/dev/null 2>&1
    return $?
}
get_pid() {
    if [[ -f $PID_FILE ]]; then
        cat $PID_FILE
    else
        warn " $PID_FILE not found!"
        exit 1
    fi
}
start() {
    if check_process; then
        warn " ${PROCESS_NAME} is already running!"
    else
        $EXEC -f $DEFAULT_CONF $(ext_configs) &&
            echo -e " ${PROCESS_NAME} start                        [ $(info OK) ]" ||
            echo -e " ${PROCESS_NAME} start                        [ $(warn Failed) ]"
    fi
}

stop() {
    if check_process; then
        PID=$(get_pid)
        kill -9 $PID >/dev/null 2>&1
        echo -e " ${PROCESS_NAME} stop                         [ $(info OK) ]"
    else
        warn " ${PROCESS_NAME} is not running!"
    fi
}

restart() {
    if ! check_process ; then
        warn " ${PROCESS_NAME} is not running! Starting Now..."
    fi
    if $(check_conf); then
        PID=$(get_pid)
        $EXEC -f $DEFAULT_CONF $(ext_configs) -st $PID &&
            echo -e " ${PROCESS_NAME} restart                      [ $(info OK) ]" ||
            echo -e " ${PROCESS_NAME} restart                      [ $(warn Failed) ]"
    else
        warn " ${PROCESS_NAME} Configuration file is not valid, plz check!"
        echo -e " ${PROCESS_NAME} restart                      [ $(warn Failed) ]"
    fi
}

if [[ $# != 1 ]]; then
    print_usage
    exit 1
else
    case $1 in
    "start" | "START")
        start
        ;;
    "stop" | "STOP")
        stop
        ;;
    "restart" | "RESTART" | "-r")
        restart
        ;;
    "status" | "STATUS")
        if check_process; then
            info "${PROCESS_NAME} is running OK!"
        else
            warn " ${PROCESS_NAME} not running, plz check"
        fi
        ;;
    "test" | "TEST" | "-t")
        if check_conf; then
            info " Configuration file test Successfully."
        else
            warn " Configuration file test failed."
        fi
        ;;
    *)
        print_usage
        exit 1
        ;;
    esac
fi
