#!/bin/bash
# last update 2019-04-23 1269505840@qq.com
# version: 3.2.2 
# discript : 
#     备份源定义,格式(["key"]="value") key: 备份名称   value: 备份路径(文件、目录）或数据库名称 , 多个由空格隔开  
#            code_path   : 代码备份定义，每天备份一次
#            app_path    : 应用备份定义,每2个月备份一次
#            config_path : 配置文件备份定义,每一个月备份一次
#            mysql_database: 数据库备份定义，每天备份一次
#     base_path     : 备份文件存放根路径
#     back_ignore   : 备份忽略配置文件，不存在自动创建并添加默认忽略内容( *.log *.bak *.back *-back *-bak log logs bak back temp tmp)
# use : bash web.backup.sh -h
# 00 01 * * * /bin/bash /opt/sh/web.backup.sh >> /var/log/backlogs.log 2>&1  
# yum install p7zip
# pip install awscli
# aws configure
# https://github.com/iikira/BaiduPCS-Go/releases 
# BaiduPCS-Go login 
#

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 是否取消时间限制，默认0 ，此参数此处禁止修改，但可通过参数传递进行变动
debug=0

# 使用7za对文件进行加密 为空则不加密 
encrypt=""

# mysql account
msyql_username=""
mysql_password=""
mysql_host=""

# 备份存放目录，必须以/结尾 
base_path="/data/backup/"

# 远程备份开关 0: ftp sync 1: aws sync  
# 默认ftp 远程同步，开启时需配置ftp帐号信息
# 1 : aws 远程同步配置，开启时需先配置aws相关信息
# 2 : 百度云 远程同步配置，开启时候需先配置百度云盘相关信息
ISSync=0

# aws sync path,default: s3://${aws_storage}/${aws_path}  
# aws_storage 存储桶名称
aws_storage=""
# aws_path 远程上传路径，以/结尾，代表上传到这个名字的文件夹中，没有/结尾，代表上传并重命名为这个名字的文件
aws_path=""

# ftp 帐号信息
ftp_host=""
ftp_port="21"
ftp_user=""
ftp_pass=""

# 百度云 sync ,default : BaiduPCS-Go upload <uploadfile> <target_path>
# 上传路径  例如: 云盘根目录下的backup目录，则配置为/backup/,必须以/开头，/结尾
bdy_path=""

# ignore config
back_ignore="${base_path}back_ignore.txt"

# current back time
time=$(date +"%Y%m%d%H")

### source path config start (default app 2 month once,config 1 month once ,other every day) ###
declare -A code_path=()
declare -A app_path=()
declare -A config_path=(["rc.local"]="/etc/rc.local" ["hosts"]="/etc/hosts")
declare -A mysql_database=()
### source path config stop ###

### target config start ###
codebak_path="${base_path}codeback"
dbback_path="${base_path}mysqlback"
appback_path="${base_path}appback"
configback_path="${base_path}configback"
### target config stop ###

color_info() {
    case "$1" in
    -h|--help)
      echo -e "Usg: color_info (flicker) red info "
      ;;
    red)
        echo -e "\033[31m$2 \033[0m"
        ;;
    green)
        echo -e "\033[32m$2 \033[0m"
        ;;
    yellow)
        echo -e "\033[33m$2 \033[0m"
        ;;
    flicker)
        color_info $2 "\033[05m$3 \033[0m"
        ;;
    *)
        echo -e "\033[37m$2 \033[0m"
        ;;
    esac
}

file_Compress(){
  _source=$1
  _target=$2
  if [ -n "${encrypt}" ]; then
    echo "current back file ===>: ${_target}.7z"
    7za a -t7z -p${encrypt} ${_target}.7z ${_source} -xr@${back_ignore}
  else
    echo "current back file ===>: ${_target}.tgz"
    tar czf ${_target}.tgz --exclude-from=${back_ignore} ${_source}
  fi
}

check_local_dir(){
  local_dir=$1
  [ -d ${local_dir} ] || {
    mkdir ${local_dir} -p
  }
}

check_arrslen(){
  let len=$1
  if [ ${len} -eq 0 ];then
    color_info red "No backup data defined" 
    return 1 
  fi
  return 0
}

code_back(){
  check_local_dir ${codebak_path}
  check_arrslen ${#code_path[@]} && {
    for key in ${!code_path[@]}; do
      file_Compress ${code_path[$key]} ${codebak_path}/${key}-${time}
      sleep 1
    done 
  }
}

msyql_back(){
  check_local_dir ${dbback_path}
  check_arrslen ${#mysql_database[@]} && {
    for key in ${!mysql_database[@]}; do
      echo -e "current database backup >> : ${mysql_database[$key]} "
      /usr/bin/mysqldump -u${msyql_username} -p${mysql_password} -h${mysql_host} --default-character-set=utf8 --single-transaction -R -E ${mysql_database[$key]} | gzip > ${dbback_path}/${key}-${time}.sql.gz
    done
  }
}

app_back(){
  check_local_dir ${appback_path}
  check_arrslen ${#app_path[@]} && {
    res=$(expr $(date +"%m") % 2)
    if [ $res -eq 0 ] || [ ${debug} -eq 1 ];then
      day=$(date +"%d")
      if [ $day -eq 1 ] || [ ${debug} -eq 1 ]; then
        #every 6 month back
        for key in ${!app_path[@]}; do
          file_Compress ${app_path[$key]} ${appback_path}/${key}-${time} 
          sleep 1
        done  
      else
        color_info yellow "Ignore: Backups will be made on the first day only"
      fi
    else
    color_info yellow " Ignore: No backup this month "
    fi
  }
}

config_back(){
  check_local_dir ${configback_path}  
  check_arrslen ${#config_path[@]} && {
    day=$(date +"%d")
    if [ $day -eq 1 ] || [ ${debug} -eq 1 ]; then
      for key in ${!config_path[@]}; do
        #tar czf ${configback_path}/${key}-${time}.tgz --exclude-from=${back_ignore} ${config_path[$key]}
        file_Compress ${config_path[$key]} ${configback_path}/${key}-${time} 
        sleep 1
      done
    else
      color_info yellow "Ignore: Backups will be made on the first day only"
    fi
  }
}

awscli_sync(){
  if [ -z "${aws_path}" ];then 
  #if [ "${aws_path}" == "" ];then 
    color_info red " Warring: You need to configure the S3 upload path !"
  else
    for _dir in $(ls ${base_path}); do 
      file_path="${base_path}${_dir}"
      if [ -d ${file_path} ] ; then
        #cd ${file_path}
        for file in $(ls ${file_path}|grep ${time}); do
          ## awscli sync 
          echo "====>: awscli sync s3://${aws_storage}/${aws_path} "
          echo -e "$(md5sum ${file_path}/${file})\n" >> ${file_path}/README.md5sum 
          /bin/aws s3 cp ${file_path}/${file} s3://${aws_storage}/${aws_path}/${_dir}/
        done
        echo -e "====== ${time} end ======\n" >> ${file_path}/README.md5sum
        /bin/aws s3 cp ${file_path}/README.md5sum s3://${aws_storage}/${aws_path}/${_dir}/
      fi    
    done
  fi
}

baiduyun_sync(){
  if [ -z "${bdy_path}" ];then
  #if [ "${bdy_path}" == "" ];then 
    color_info red "Warring: You need to configure the baiduyun upload path !"
  else
    for _dir in $(ls ${base_path}); do 
      file_path="${base_path}${_dir}"
       if [ -d ${file_path} ] ; then
        #cd ${file_path}
        for file in $(ls ${file_path}|grep ${time}); do
          ## baiduyun sync 
          echo "====>: BaiduPCS-Go upload ${file_path}/${file}  ${bdy_path}${_dir}/"
          echo -e "$(md5sum ${file_path}/${file})\n" >> ${file_path}/README.md5sum 
          BaiduPCS-Go upload ${file_path}/${file}  ${bdy_path}${_dir}/
        done
        echo -e "====== ${time} end ======\n" >> ${file_path}/README.md5sum
          BaiduPCS-Go upload ${file_path}/README.md5sum ${bdy_path}${_dir}/
      fi
    done
  fi
}

FTP_TRANSFER(){
ftp -inv <<!!! >/tmp/FTPLOG.TXT
  open $ftp_host $ftp_port
  user ${ftp_user} ${ftp_pass}
  passive
  binary
  prompt
  cd $2
  put $1
  close
  bye
!!!
  if fgrep "$FTP_SUCCESS_MSG" /tmp/FTPLOG.TXT ; then
    color_info green "..............FTP OK!...$1"
    FTP_FLAG=1
  else
    color_info red "..............FTP Error!...$1"
    FTP_FLAG=0
  fi
}

ftp_sync(){
  if [ -z "$ftp_user" ]; then
  #if [ "$ftp_user" == "" ]; then
    color_info red "Warring: You need to configure the ftp account info !"
  else
    for _dir in $(ls ${base_path}); do 
      file_path="${base_path}${_dir}"
      if [ -d ${file_path} ] ; then
        #cd ${file_path}
        for file in $(ls ${file_path}|grep ${time}); do
          ##FTP  starting###
          echo "=======>: ${file_path}/${file}"
          echo -e "$(md5sum ${file_path}/${file})\n" >> ${file_path}/README.md5sum 
          FTP_TRANSFER "${file_path}/${file}" "${ftp_root_path}/${_dir}"
        done
        echo -e "====== ${time} end ======\n" >> ${file_path}/README.md5sum
        FTP_TRANSFER "${file_path}/README.md5sum" "${ftp_root_path}/${_dir}"
      fi
    done
  fi 
}

choose_fun(){
  case "$1" in
    "code_back")
      color_info green "###  code back   ###"
      code_back
    ;;
    "mysql_back") 
      color_info green "###   mysql back   ###"
      msyql_back
    ;;
    "app_back") 
      color_info green "###   app back   ###"
      app_back
    ;;
    "config_back") 
      color_info green "###   config back   ###"
      config_back
    ;;
    "awscli_sync") 
      color_info green "###   aws sync s3://${aws_storage}/${aws_path}   ###"
      awscli_sync
    ;;
    "baiduyun_sync")
      color_info green "###   baiduyun upload <file> ${bdy_path}   ###"
      baiduyun_sync
    ;;
    "ftp_sync") 
      color_info green "###   ftp upload ${ftp_host}   ###"
      ftp_sync
    ;;
    *) 
      echo "Usg : $0 (0|1) (code_back|msyql_back|app_back|config_back|awscli_sync|ftp_sync|baiduyun_sync)"
      echo -e "eg: $0 1 code_back "
      echo -e "eg: $0 code_back"
      echo -e "\t 可选参数: "
      echo -e "\t\t (0|1) debug参数(默认: 0)，是否取消备份时间限制，应用程序每六月备份一次，配置文件每月备份一次"
      echo -e "\t\t code_back|msyql_back|... 可选参数，选择后进行单个备份，未选择备份所有已配置项目"
    ;;
  esac
}

default_conf(){
  if [ ! -f ${back_ignore} ];then
    dir_path=$(dirname ${back_ignore})
    
    [ -d "${dir_path}" ] || {
       echo "create default backup dir: ${dir_path}"
       mkdir -p ${dir_path}
    }

    echo "create default ignore : *.log *.bak *.back *-back *-bak log logs bak back temp tmp"
    echo -e "*.log\n*.bak\n*.back\n*-back\n*-bak\nlog\nlogs\nbak\nback\ntemp\ntmp" >> ${back_ignore}
  fi

  rpm -q p7zip >& /dev/null || {
   echo -e "Adding encryption dependencies: p7zip\n"
   sleep 3
    yum install p7zip -y
  }    
}

main(){

  default_conf

  if [ -n "$1" ]; then
    if [ "$1" == "1" ]; then
      debug=1
      if [ -n "$2" ]; then
        choose_fun $2
        exit 0
      fi
      color_info yellow "Warring: debug, backup all info"
    elif [ "$1" == "-h" ]; then
      choose_fun
      exit 0
    else
      if [ -n "$2" ]; then
        choose_fun $2
        exit 0
      elif [ "$2" == "-h" ]; then
        choose_fun
        exit 0
      else
        choose_fun $1
        exit 0
      fi
    fi
  fi

  color_info green "### code back ###"
  code_back
  sleep 1
  color_info green "### mysql back ###"
  msyql_back
  sleep 1
  color_info green "### app back ###"
  app_back
  sleep 1
  color_info green "### config back ###"
  config_back
  sleep 1
  color_info green "### Start remote sync ###"
  if [ "$ISSync" -eq "1" ]; then
    awscli_sync
  elif [ "$ISSync" -eq "2" ]; then
    baiduyun_sync
  else
    ftp_sync 
  fi
}

echo "Backup start time >:"$(date +"%s")
main $1 $2
echo "Backup end time >:"$(date +"%s")