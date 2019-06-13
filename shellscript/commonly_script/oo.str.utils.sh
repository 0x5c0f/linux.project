#!/bin/bash
################################################# 
#   author      0x5c0f 
#   date        2019-06-12 
#   email       1269505840@qq.com 
#   web         blog.cxd115.me 
#   version     1.0.0
#   last update 2019-06-12
#   descript    script --> ./oo.str.utils.sh 
################################################# 

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH


## 判断字符串是否为数字 
# $1 需要判断的值
function str_isNumber(){
    # [ "$1" -gt 0 ] >& /dev/null 
    expr "$1" "+" 0  >&  /dev/null
    return $?
}

## 将字符串转换为首字母/全大写 
# $1 需要处理的字符串 
# #2 是否全大写 0: 全部大写(默认) 1: 首字母大写 
function str_toUpperCase(){
    local sstr=$1
    local limit=$2

    [[ ${limit} -eq 1 ]] && {
        tgt=$(eval echo ${sstr^})
    } || {
        # local -u sstr=$1
        tgt=$(eval echo ${sstr^^})
    }
    echo $tgt

    unset sstr limit tgt
}

## 将字符串转换为首字母/全小写 
# $1 需要处理的字符串 
# #2 是否全小写 0: 全部小写(默认) 1: 首字母小写 
function str_toLowerCase(){
    local sstr=$1
    local limit=$2

    [[ ${limit} -eq 1 ]] && {
        tgt=$(eval echo ${sstr,})
    } || {
        # local -l sstr=$1
        tgt=$(eval echo ${sstr,,})
    }
    echo $tgt

    unset sstr limit tgt
}

## 将字符串转换为首字母/全反转 
# $1 需要处理的字符串 
# #2 是否全部反转 0: 全部反转(默认) 1: 首字母反转 
function str_toReverseCase(){
    local sstr=$1 
    local limit=$2 

    [[ ${limit} -eq 1 ]] && {
        tgt=$(eval echo ${sstr~})
    } || {
        tgt=$(eval echo ${sstr~~})
    }
    echo $tgt

    unset sstr limit tgt
}


## 获取字符串长度 
# $1 需要判断的字符串 
function str_length(){
    local sstr=$1
    #expr length $sstr  #不能判断长度为0的字符串 
    echo ${#sstr}
    unset sstr
} 

## 字符串分割,返回结果的$@,一般用于组合为数组
# $1 需要判断的字符串 
function str_toCharArr(){
    local sstr=$1 
    local regex=$2
    eval echo ${sstr//$regex/ }
    unset sstr regex 
}

## 字符串位置搜索,未搜索到返回 -1 
# $1 需要检索的字符串
# $2 需要检索的字符
function str_indexOf(){
    local sstr=$1
    local chr=$2
    
    len=$(expr index $sstr $chr)
    echo $(eval expr $len - 1)
    unset sstr chr len
}

## 以匹配字符串开始截取 
# $1 需要进行截取的字符串 
# $2 开始截取下标 0 开始
# $3 截取字符串长度 
function str_split(){
    local sstr=$1
    local sIndex=$2
    local len=$3

    str_isNumber $len && {
        tgt=$(eval echo ${sstr:$sIndex:$len})
    } || {
        tgt=$(eval echo ${sstr:$sIndex})
    }
    echo $tgt

    unset sstr sIndex len tgt 
}


## 删除以匹配规则开头的最短/长的匹配值, 成功匹配返回结果值,否则返回字符串本身 
# $1 需要进行删除的字符串 
# $2 匹配正则 
# $3 最长匹配还是最短匹配(0:最短匹配(默认) 1:最长匹配)
# 
function str_splitStart(){
    local sstr=$1
    local regex=$2
    local limit=$3 

    [[ ${limit} -eq 1 ]] && {
        tgt=$(eval echo ${sstr##$regex})
    } || {
        tgt=$(eval echo ${sstr#$regex})
    }
    
    echo "$tgt"

    unset sstr regex limit tgt
}


## 删除以匹配规则结尾的最短/长的匹配值, 成功匹配返回结果值,否则返回字符串本身 
# $1 需要进行删除的字符串 
# $2 匹配正则 
# $3 最长匹配还是最短匹配(0:最短匹配(默认) 1:最长匹配)
# 
function str_splitEnd(){
    local sstr=$1
    local regex=$2
    local limit=$3 

    [[ ${limit} -eq 1 ]] && {
        tgt=$(eval echo ${sstr%%$regex})
    } || {
        tgt=$(eval echo ${sstr%$regex})
    }
    
    echo "$tgt"
    unset sstr regex limit tgt
}

## 替换以匹配规则第一个或全部匹配的值,成功返回结果 ,否则返回本身
# $1 需要处理的字符串 
# $2 替换的正则 
# $3 需要替换为的值
# $4 是否全部替换(0: 替换第一个匹配的值(默认) 1: 全部替换 )
# 
function str_replaceAll(){
    local sstr=$1 
    local regex=$2
    local reval=$3
    local limit=$4

    [[ ${limit} -eq 1 ]] && {
        tgt=$(eval echo ${sstr//$regex/$reval})
    } || {
        tgt=$(eval echo ${sstr/$regex/$reval})
    }
    echo "$tgt"
    unset sstr regex reval limit tgt
}

## 替换以匹配规则开头或结尾的值,成功返回结果,否则返回本身
# $1 需要处理的字符串 
# $2 替换的正则 
# $3 需要替换为的值
# $4 是否全部替换(0: 匹配规则开头 1: 以匹配规则结尾 )
# 
function str_replace(){
    local sstr=$1 
    local regex=$2
    local reval=$3
    local limit=$4

    [[ ${limit} -eq 1 ]] && {
        tgt=$(eval echo ${sstr/%$regex/$reval})
    } || {
        tgt=$(eval echo ${sstr/#$regex/$reval})
    }
    echo "$tgt"
    unset sstr regex reval limit tgt 
}
