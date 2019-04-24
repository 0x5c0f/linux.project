#!/bin/bash 
################################################# 
#   author      0x5c0f 
#   date        2018-10-08
#   email       1269505840@qq.com
#   web         zblog.cxd115.me 
#   version     2.0 
#   last update 2019-02-12
#   discript    
################################################# 

#本脚本所在目录
shell_dir="/opt/sh/cc"
# CC 日志存放目录
logs_dir="blog.log"

#定义管理员邮箱，接收CC攻击的报警通知 多个空格隔开
admin_mail=(1269505840@qq.com)
# 定义邮件主题
MAIL_BODY="有人搞事情!"

# 定义当前服务器信息
SERVER_INFO="blog.cxd115.me"

#定义日期、时间，用于记录日志，以及清理历史数据
DAY=$(date "+%Y%m%d")
OLD_DAY=$(date -d '10 days ago' "+%Y%m%d")
TIME=$(date "+%Y%m%d %H:%M %z")


#脚本运行中的日志信息
shell_log_dir=${shell_dir}/${logs_dir}
shell_temp_dir=${shell_dir}/${logs_dir}/templog
#CC攻击日志单独记录于脚本根目录
cc_log=${shell_dir}/cc.log
error_log=/opt/sh/cc/iplog/error_$DAY.log

#每次截取的最大日志条数（考虑性能和每分钟的实际访问量因素）
web_log_num=800

#定义爬虫特征
spider_name="googlebot.com.$|yahoo.com.cn.$|msn.com.$|yandex.com.$|yahoo.net.$|google.com\/bot"
spider='DNSPod-Monitor|Sogou web spider|Sogou Push Spider|YodaoBot|Sosospider|Baiduspider|360Spider|Incapsula'
#封锁的爬虫特征定义
#'thinksearch|msnbot|Googlebot|YandexBot|msnbot-media|FatBot|AdsBot-Google|Yahoo! Slurp China|Yahoo! Slurp|askspider|Xingcloud Crawler|BingPreview|\ 403\ '
spider_drop=''


#排除图片\gettime等频繁包含页面特征，更精确的辨别恶意采集和攻击
#需要日常维护
nohtml='\.gif|\.css|\.txt|\.cur|\.js|\.png|\.jpg|\.ico|\.flv|\.swf|cart-ajaxTotalPrice|\.mp4'

#定义其他防CC规则 agent类型和请求状态
cc_agent='Googlebot|Java/1.6.0_20|Mozilla/4.0 (compatible; ICS)|Mozilla/4.0 (compatible;)|Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1; .NET CLR 1.1.4322; Netsparker)|Mozilla/5.0 \(compatible; MJ12bot/v1.4.3; http://www.majestic12.co.uk/bot.php|Python-urllib/2.7|okhttp/3.11.0'
agent_cc_analyse_num=250
default_agent=''
#排除agent
noagent='Go-http-client'

#标准日志截取的关键字
#用于截取标准日志格式*分钟内的日志
apache_now=$(date  +%Y:%H:%M)
apache_min_ago=$(date -d '1 minutes ago'  +%Y:%H:%M)

#haproxy日志截取的关键字
#用于截取haproxy日志格式*分钟内的日志
haproxy_now=$(date +%Y:%H:%M)
haproxy_min_ago=$(date -d '1 minutes ago'  +%Y:%H:%M)

#指定web日志
web_log="/opt/nginxssl/logs/blog.cxd115.me.log"
#指定web访问信任ip
trust_ip=""

#每分钟大于该值的访问，视为非法采集，其IP将会被屏蔽
default_drop_num=200
#大于该值，将会触发CC特征分析动作
cc_analyse_num=150
#确认属于CC攻击后，每肉鸡每秒访问大于该值，将会被封锁
cc_drop_num=2
#CC判断阀值:指IP/agent的比例,最高为0.999
cc_ratio=0.9

#动态定义IP白名单：提取防火墙中信任IP/汇总自定义的白名单
if [ ! -d "$shell_temp_dir" ]
then
        /bin/mkdir -p "$shell_temp_dir" ;
fi

touch "$shell_dir"/white.list
white_list="$shell_dir"/white.list


#日志截取与初步处理函数
#用法举例： CUTLOG "$web_log_num" "$web_log" "$apache_min_ago" "$apache_now" 
CUTLOG()
{
#常规日志提取,原始日志
/usr/bin/tail -"$1" "$2" | /bin/sed -n "/"$3"/"p > "$shell_temp_dir"/cutlog
#/usr/bin/tail -"$1" "$2" | /bin/sed -n "/"$3"/"p > "$shell_temp_dir"/cutlog.tmp

# 判断是否为cdn日志
:<<EOF
cat "$shell_temp_dir"/cutlog.tmp |while read all_url 
do 
    echo "$all_url" |awk '{print $NF}'|grep -E -o '([0-9]{1,3}\.){3}[0-9]{1,3}' > /dev/null
    if [ $? -eq 0 ]; then 
        # cdn 
        echo "$all_url" | awk '{a="\""$1"\"";$1=$NF;$NF=a;print $0}' >> "$shell_temp_dir"/cutlog
    else
        echo "$all_url" >> "$shell_temp_dir"/cutlog
    fi
done 
EOF


#排除静态文件、图片、正常爬虫的日志另存
/bin/cat "$shell_temp_dir"/cutlog | grep -Evi "$nohtml" | grep -Evi "$noagent"| grep -Evi "$spider|127.0.0.1|$trust_ip" > "$shell_temp_dir"/cutlog_analyse

#排除静态文件、图片、正常爬虫的日志分析结果：IP数量排序
/bin/cat "$shell_temp_dir"/cutlog_analyse | awk '{m[$1]+=1} END{for(i in m){print m[i]," "i}}' | sort -nr | uniq | head -20 | sed 's/"//g'> "$shell_temp_dir"/cutlog_ip_num

#非正常爬虫的日志分析结果：爬虫IP数量排序
#/bin/cat "$shell_temp_dir"/cutlog_analyse | egrep -i "$spider_drop" |awk '{m[$1]+=1} END{for(i in m){print m[i]," "i}}'| sort -nr | uniq | sed 's/"//g'> "$shell_temp_dir"/cutlog_spider_ip_num

#CC日志分析结果：访问量NO.1的IP
/bin/cat "$shell_temp_dir"/cutlog_analyse | awk '{m[$7]+=1} END{for(i in m){print m[i]," "i}}' | sort -nr | uniq | head -1 | sed 's/"//g'> "$shell_temp_dir"/cutlog_cc_ip_num

#CC日志分析结果：访问量NO.1的浏览器
/bin/cat "$shell_temp_dir"/cutlog_analyse | awk -F\" '{m[$(NF-3)]+=1} END{for(i in m){print m[i]," "i}}' | sort -nr | uniq | head -1 | sed 's/"//g'> "$shell_temp_dir"/cutlog_cc_agent_num

#用于监控服务器获取数据，绘图，定时删除日志
if [ ! -d "$shell_log_dir/min" ]
then
        /bin/mkdir -p "$shell_log_dir/min" ;
fi
cat "$shell_temp_dir"/cutlog | egrep -i  "HTTP\/1.1\"\ 50|HTTP\/1.0\"\ 50" > "$shell_log_dir"/min/error_num_$(date "+%Y%m%d")_$(date +%Y:%H:%M).log
cat "$shell_temp_dir"/cutlog | egrep -i "HTTP\/1.1\"\ 40|HTTP\/1.0\"\ 40" > "$shell_log_dir"/min/404_num_$(date "+%Y%m%d")_$(date +%Y:%H:%M).log 
touch "$shell_log_dir"/min/error_num_$(date "+%Y%m%d")_$(date +%Y:%H:%M).log 
touch "$shell_log_dir"/min/404_num_$(date "+%Y%m%d")_$(date +%Y:%H:%M).log 
rm -f "$shell_log_dir"/min/*_$(date -d '100  minutes ago' "+%Y%m%d")_$(date -d '100  minutes ago' +%Y:%H:%M).log
}


#日志记录函数


#邮件报警函数
#使用方法，在需要报警的模块后:
#for (( i = 0 ; i < ${#admin_mail[@]} ; i++ ))
#do
#MAIL "${admin_mail["$i"]}" "英文描述标题" "英文描述内文" 
#done

MAIL()
{
    to="$1"
    subject="$2"
    body="$3"
    PASSWORD=""
    #/opt/sendemail/sendEmail -f xxxxx@163.com  -t "$to" -s smtp.163.com -u "$subject" -o message-content-type=auto -o message-charset=gb2312  -xu xxxxx@163.com  -xp $PASSWORD -m "$body" 
    echo "$TIME____$to----$subject----$body----" >> /opt/sh/cc/sendmail.log
}

#采集及CC攻击分析函数
#重点分析agent头\Referrer来源\同一URL的访问这三类CC攻击异常点

CC_ANALYSE()
{
cat "$shell_temp_dir"/cutlog_cc_ip_num | while read urlnum url
do
    if [ "$urlnum" -gt "$cc_analyse_num" ]
    then
      echo -e "################ $TIME   $apache_min_ago #####################\n$urlnum   $url  " >> $cc_log
      cat "$shell_temp_dir"/cutlog_cc_agent_num | while read agentnum agent
  do

  ratio=`echo $agentnum / $urlnum | bc -l`
        if [ `echo "$ratio >= $cc_ratio" | bc` = 1 ]; 
  then
            cat "$shell_temp_dir"/cutlog | grep "$agent" | grep "$url" | awk '{m[$1]+=1} END{for(i in m){print m[i]," "i}}' | head -1000 | sed 's/"//g'>> "$shell_temp_dir"/cc-ip-temp
            echo -e "# $agentnum $agent" >> $cc_log

            for (( i = 0 ; i < ${#admin_mail[@]} ; i++ ))
            do
                MAIL "${admin_mail["$i"]}" "!!!NOW HAVE IP CC from $MAIL_BODY(page), TIME:$TIME!!! CC num>${agentnum}nums/m" "TIME:$TIME , NOW HAVE CC. CC num>${agentnum}nums/m,NUM and URL INFO: No.1 IP NUM/URL: `cat "$shell_temp_dir"/cutlog_cc_ip_num` ; NUM/AGENT:`tail -1 $cc_log`"
            done
        fi
        done
    fi
done

touch "$shell_temp_dir"/cc-ip-temp

cat "$shell_temp_dir"/cc-ip-temp | sort -nr | uniq > "$shell_temp_dir"/cc-ip
if [ $(cat "$shell_temp_dir"/cc-ip | wc -l) -gt 0 ]
then
    cat "$shell_temp_dir"/cc-ip >> $shell_log_dir/cc-ipnum-"$DAY".log
    cat "$shell_temp_dir"/cc-ip | while read ccnum ccip
    do      
  if [ "$ccnum" -gt "$cc_drop_num" ]
  then
      echo "$ccip" >> "$shell_temp_dir"/cc-drop-ip
  fi
    done
fi

touch "$shell_temp_dir"/cc-drop-ip

#针对agent分析的防CC策略
cat "$shell_temp_dir"/cutlog_analyse | grep -Ei "$cc_agent" | grep -Evi "bingbot\/2\.0" | awk '{m[$1]+=1} END{for(i in m){print m[i]," "i}}' | head -1000 | sed 's/"//g'>> "$shell_temp_dir"/cc-ip-temp

cat "$shell_temp_dir"/cutlog_cc_agent_num | while read agentnum agent
do
    if [ "$agentnum" -gt "$agent_cc_analyse_num" ]
    then
      echo -e "################ $TIME   $apache_min_ago #####################\n$urlnum   $url  " >> $cc_log
      cat "$shell_temp_dir"/cutlog_analyse | grep "$agent" | awk '{m[$1]+=1} END{for(i in m){print m[i]," "i}}' | head -1000 | sed 's/"//g'>> "$shell_temp_dir"/cc-ip-temp
            echo -e "$agentnum nums $agent" >> $cc_log
            for (( i = 0 ; i < ${#admin_mail[@]} ; i++ ))
            do
                MAIL "${admin_mail["$i"]}" "!!!NOW HAVE CC from $MAIL_BODY(agent), TIME:$TIME!!! CC num>${agentnum} nums/m" "TIME:$TIME , NOW HAVE CC. CC num>${agentnum}nums/m,NUM and URL INFO: No.1 IP NUM/URL: `cat "$shell_temp_dir"/cutlog_cc_ip_num` ; NUM/AGENT:`tail -1 $cc_log`"
            done
    fi
done


#
#"$shell_temp_dir"/cc-drop-ip
#
}   


#搜索引擎爬虫分析处理及屏蔽（禁止的爬虫）函数
SPIDER_ANALYSE()
{
#直接封锁明确禁止的spider
for i in $(cat "$shell_temp_dir"/cutlog_spider_ip_num | awk '{print $2}' )
do
  if $(cat $white_list | grep -Ev "^#|^$|^[a-z,A-Z]|^0" | awk -F. '{print $1"."$2"."$3}' | grep  "$(echo $i |awk -F. '{print $1"."$2"."$3}')" > /dev/null 2>&1)
  then 
        echo "$(date) $i" >> "$shell_log_dir"/white_list.block
  else
        echo "iptables -I INPUT  -s "$i"/32 -j DROP" >> $shell_log_dir/dropip.sh
        /sbin/iptables -I INPUT  -s "$i"/32 -j DROP
  fi
done

cat "$shell_temp_dir"/cutlog |egrep -i "$SPIDER" | awk '{m[$1]+=1} END{for(i in m){print m[i]," "i}}' | sort -nr | uniq | head -10 | sed 's/"//g'> "$shell_temp_dir"/spider.temp
cat "$shell_temp_dir"/spider.temp >> $shell_log_dir/spider-"$DAY".log

#常规爬虫如超出正常采集频率 将对其进行host验证，并记录备查
cat "$shell_temp_dir"/spider.temp | while read spidernum spiderip
do
  if [ "$spidernum" -gt "$default_drop_num" ]
  then
        host $spiderip  >> $shell_log_dir/spider-"$DAY".log
  fi
done
}


#常规采集分析处理
DEFAULT_ANALYSE()
{
echo -e "\n##$TIME   $apache_min_ago " >> "$shell_log_dir"/ipnum-"$DAY".log
echo -e "##URL NUM `/usr/bin/wc -l  "$shell_temp_dir/cutlog"` \n"  >> "$shell_log_dir"/ipnum-"$DAY".log
echo -e "\n##$TIME   $apache_min_ago \n" >>"$shell_log_dir"/ipnum-"$DAY".log

touch "$shell_log_dir"/dropip.sh
touch "$shell_temp_dir"/default_drop_ip_temp

cat "$shell_temp_dir"/cutlog_ip_num  >> "$shell_log_dir"/ipnum-"$DAY".log
       
cat "$shell_temp_dir"/cutlog_ip_num | while read num ip
do      
  if [ "$num" -gt "$default_drop_num" ]
  then
  echo "$ip" >> "$shell_temp_dir"/default_drop_ip_temp
  fi
done

cat "$shell_temp_dir"/default_drop_ip_temp | awk -F. '{print $1"."$2"."$3"."$4}' | sort | uniq >> $shell_temp_dir/default_drop_ip

} 


#统一封锁IP的动作函数
DROP_IP()
{

#黑名单IP池超过20000个需要先释放
if [ $(/sbin/iptables -vnL | grep "DROP" | wc -l) -gt 20000 ]
then
  /bin/bash /opt/sh/iptables.sh
fi

#封锁CC IP
if [ $(cat "$shell_temp_dir"/cc-drop-ip | wc -l) -gt 0 ]
then
  for i in $(cat "$shell_temp_dir"/cc-drop-ip )
  do
    if $(cat "$white_list" | awk -F. '{print $1"."$2"."$3}' | grep "$(echo $i | awk -F. '{print $1"."$2"."$3}')" > /dev/null 2>&1)
    then
        echo "$(date) CC $i" >> "$shell_log_dir"/white_list.block
    else
            echo "iptables -I INPUT  -s "$i"/32 -j DROP" >> "$shell_log_dir"/dropip.sh
        #输出到alldrop 进行历史记录
        echo -e "\n##$TIME   $apache_min_ago \n" >>"$shell_log_dir"/alldrop
        echo "iptables -I INPUT  -s "$i"/32 -j DROP" >>"$shell_log_dir"/alldrop
        grep $i $shell_temp_dir/cutlog_ip_num  >>"$shell_log_dir"/alldrop
        ##历史记录输出结束 
        echo "/sbin/iptables -I INPUT "$i"/32 -j DROP" |mutt -s "$SERVER_INFO封ccip封ccip" $admin_mail
        /sbin/iptables -I INPUT  -s "$i"/32 -j DROP
        grep $i $shell_temp_dir/cutlog >> $shell_log_dir/cc-url-$DAY.log
    fi
  done
fi


#封锁采集IP
if [ $(cat "$shell_temp_dir"/default_drop_ip | awk -F. '{print $1"."$2"."$3"."$4}' | sort | uniq | wc -l) -gt 0 ]
then
  for i in $(cat "$shell_temp_dir"/default_drop_ip  | awk -F. '{print $1"."$2"."$3"."$4}' | sort | uniq )
  do
    if $(cat $white_list | grep -Ev "^#|^$|^[a-z,A-Z]|^0" | awk -F. '{print $1"."$2"."$3}' | grep "$(echo $i | awk -F. '{print $1"."$2"."$3}')" > /dev/null 2>&1)
    then
        echo "$(date) default $i" >> "$shell_log_dir"/white_list.block
    else
        echo "iptables -I INPUT -s "$i"/32 -j DROP" >> "$shell_log_dir"/dropip.sh
		#输出到alldrop 进行历史记录
		echo -e "\n##$TIME   $apache_min_ago \n" >>"$shell_log_dir"/alldrop
		echo "iptables -I INPUT -s "$i"/32 -j DROP" >>"$shell_log_dir"/alldrop
        grep $i $shell_temp_dir/cutlog_ip_num  >>"$shell_log_dir"/alldrop
		##历史记录输出结束
		echo "/sbin/iptables -I INPUT  -s "$i"/32 -j DROP" |mutt -s "$SERVER_INFO封ccip封ccip" $admin_mail
        /sbin/iptables -I INPUT  -s "$i"/32 -j DROP
        grep $i $shell_temp_dir/cutlog >> $shell_log_dir/url-$DAY.log
    fi
  done
fi
}


#检查到web服务器报错增加，则重启
SERVER_RESTART()
{
if [ $(tail -5000 "$shell_temp_dir"/cutlog | grep "HTTP\/1.1\"\ 50" | wc -l ) -gt 3000 ]
then
  ulimit -SHn 65535

  case $1 in
  nginx)
        echo "nginx restart"
        ;;  
  haproxy)
        echo "haproxy" 
        ;;  
  varnish)
        echo "varnish"
        ;;  
  squid)
  echo "squid"
  #squid restart
  #/usr/sbin/squid -k shutdown
  #sleep 1
  #/usr/sbin/squid start
  ;;
  httpd|apache)
  echo "apache"
  ;;
  *)
  echo "nothing to do"
  ;;
  esac
fi
}


#动作流程

rm -f "$shell_log_dir"/dropip.sh

CUTLOG "$web_log_num" "$web_log" "$apache_min_ago" "$apache_now" ;
#测试用
#CUTLOG "$web_log_num" "$web_log" "2018:18:37" "2018:18:38" ;

DEFAULT_ANALYSE ;

CC_ANALYSE ;
#sleep 1000
DROP_IP ;

#SPIDER_ANALYSE ;

#SERVER_RESTART nginx ;

#sysctl -p > /dev/null 2>&1

#临时日志清理
cd $shell_log_dir
fdata=$(date +%F_%H%M%S)
if [ ! -d "${shell_log_dir}/old" ];
then
  mkdir ${shell_log_dir}/old
fi
tar czf old/${fdata}templog.tgz templog/
#rm -f "$shell_temp_dir"/*  ;

if [ -f "$shell_log_dir"/ipnum-$OLD_DAY.log ]
then
    rm -r "$shell_log_dir"/*$OLD_DAY*.log
fi


echo -e "\n##$TIME   $apache_min_ago \n" >> "$shell_log_dir"/dropip_history_"$DAY".sh
cat "$shell_log_dir"/dropip.sh >> "$shell_log_dir"/dropip_history_"$DAY".sh 