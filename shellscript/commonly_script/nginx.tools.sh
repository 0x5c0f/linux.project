#!/bin/bash  

HOST="127.0.0.1"
PORT="87"
 
# Functions to return nginx stats
# 单位时间内服务器正在处理的连接数 
function active {  
/usr/bin/curl "http://$HOST:$PORT/nginxstatus" 2> /dev/null| grep 'Active' | awk '{print $NF}'  
} 
 
#nginx 读取到客户端的header信息数 
function reading {  
/usr/bin/curl "http://$HOST:$PORT/nginxstatus" 2> /dev/null| grep 'Reading' | awk '{print $2}'  
} 

#返回给客户端的header信息数 
function writing {  
/usr/bin/curl "http://$HOST:$PORT/nginxstatus" 2>/dev/null| grep 'Writing' | awk '{print $4}'  
} 
 
#此启动到现在一共处理的连接  
function server {  
/usr/bin/curl "http://$HOST:$PORT/nginxstatus" 2> /dev/null| awk NR==3 | awk '{print $1}'  
} 

# 从启动到现在成功创建多少次握手(和server相同表示没有失败)  
function accepts {  
/usr/bin/curl "http://$HOST:$PORT/nginxstatus" 2> /dev/null| awk NR==3 | awk '{print $2}'  
} 

# 已经处理完毕的请求数 
function requests {  
/usr/bin/curl "http://$HOST:$PORT/nginxstatus" 2> /dev/null| awk NR==3 | awk '{print $3}'  
} 
 
# Run the requested function  
$1
