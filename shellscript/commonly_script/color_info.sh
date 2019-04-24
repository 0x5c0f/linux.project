#!/bin/bash

color_info() {
    choose="$1"
    _color="$2"
    [ -n "$3" ] && info="$3" || info="$2" 
    case "$choose" in
    flicker)
        color_info $_color "\033[05m$info \033[0m"
        ;;
    black)
        echo -e "\033[30m $info \033[0m"
        ;;
    red)
        echo -e "\033[31m $info \033[0m"
        ;;
    green)
        echo -e "\033[32m $info \033[0m"
        ;;
    yellow)
        echo -e "\033[33m $info \033[0m"
        ;;
    blue)
        echo -e "\033[34m $info \033[0m"
        ;;
    violet)
        echo -e "\033[35m $info \033[0m"
        ;;
    blue_sky)
        echo -e "\033[36m $info \033[0m"
        ;;
    white)
        echo -e "\033[37m $info \033[0m"
        ;;
    black_white)
        echo -e "\033[40;37m $info \033[0m"
        ;;
    Red_white)
        echo -e "\033[41;37m $info \033[0m"
        ;;
    Green_white)
        echo -e "\033[42;37m $info \033[0m"
        ;;
    yellow_white)
        echo -e "\033[43;37m $info \033[0m"
        ;;
    Blue_white)
        echo -e "\033[44;37m $info \033[0m"
        ;;
    Violet_white)
        echo -e "\033[45;37m $info \033[0m"
        ;;
    blue_sky_white)
        echo -e "\033[46;37m $info \033[0m"
        ;;
    White_black)
        echo -e "\033[47;30m $info \033[0m"
        ;;
    *)
        echo "Usg: $0 (flicker) {black|red|green|yellow|blue_sky|white|black_white|Red_white|...} info"
        echo -e "\t$0 read \"info\""
        echo -e "\t$0 flicker red \"info\""
        ;;
    esac
}

color_info "$1" "$2" "$3"