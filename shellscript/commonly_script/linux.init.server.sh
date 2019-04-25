#!/bin/bash 
################################################# 
#   author      0x5c0f 
#   date        2018-04-28 
#   email       1269505840@qq.com 
#   web         blog.cxd115.me 
#   version     3.3.0
#   last update 2019-03-27
#   descript    Use : linux.init.server.sh -h
################################################# 

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 主机名称
init_hostname="hostname001"

# 新建一个普通用户，默认不创建
default_user=""
default_pass=""

# 默认ftp账号(扩展模块)
default_ftp_user=""
default_ftp_pass=""
default_ftp_path=""

# 是否云主机(云主机不做ssh优化) 1: 是(默认)， 0: 否 
is_cloudServer=1

# zabbix 配置信息,默认从zabbix svn上获取对应版本编译
# 以下参数需要同时配置 
# zabbix 版本号，如: 3.2 
zbx_version=""
# zabbix server ip 
zbx_server=""

#初始目录,请不要修改
base_dir=$(cd `dirname $0`; pwd)

flagFile="/root/server.init.executed"

precheck(){ 
 
    if [[ "$(whoami)" != "root" ]]; then 
    echo "please run this script as root ." >&2 
    exit 1 
    fi 
 
    if [ -f "$flagFile" ]; then 
    echo "this script had been executed, please do not execute again!!" >&2 
    exit 1 
    fi 
 
    echo -e "\033[31m WARNING! THIS SCRIPT WILL \033[0m\n" 
    echo -e "\033[31m update the system source; \033[0m\n"
    echo -e "\033[31m update basic tools and packages; \033[0m\n" 
    echo -e "\033[31m close selinux ; \033[0m\n" 
    echo -e "\033[31m optimization system kernel; \033[0m\n" 
    echo -e "\033[31m update system time zone; \033[0m\n" 
    echo -e "\033[31m optimization bash; \033[0m\n" 
    echo -e "\033[31m optimization firewalld; \033[0m\n"  
    echo -e "\033[31m add zabbix agent monitor; \033[0m\n"  
    echo -e "\033[31m update the system ; \033[0m\n" 

    read -p "press any key to continue ..." 

    for i in `seq -w 8 -1 0`
    do 
    echo -en "Execution optimization after [ \e[0;31m$i\e[0m ] seconds ...\r"
    sleep 1
    done
 
} 

source_config(){
    # 正常情况下 不在替换为国内源 若实际yum更新慢，在手动替换
    cp -v /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup 
    #curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
    #curl -o /etc/yum.repos.d/docker-ce.repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    yum makecache 
    
    yum install -y epel-release 
}

selinux(){ 
    sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
    setenforce 0
} 

basic_install(){
    yum groupinstall "Compatibility libraries" "Base" "Development tools" "debugging Tools" -y
    yum install tree telnet dos2unix sysstat lrzsz net-tools htop bash-completion wget screen vim ftp -y
    chmod +x /etc/rc.d/rc.local
} 

sysctl_config(){     
cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_max_syn_backlog = 65536
net.core.netdev_max_backlog = 32768
net.core.somaxconn = 32768
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
#net.ipv4.ip_forward = 1
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 2
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.ip_local_port_range = 1024 65535
fs.file-max=6815744
net.nf_conntrack_max = 25000000
net.netfilter.nf_conntrack_max = 25000000
net.netfilter.nf_conntrack_tcp_timeout_established = 180
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120
net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 120
vm.max_map_count=655360
EOF
    sysctl -p

sed -i '60a *      soft    nofile      65535\n*      hard    nofile      65535' /etc/security/limits.conf
tail -n 4 /etc/security/limits.conf 
}

duser_config(){
    if [ -n "${default_user}" ]; then
        egrep "^${default_user}" /etc/passwd >& /dev/null  
        if [ $? -ne 0 ]; then 
            useradd ${default_user}
            echo "${default_pass}"|passwd --stdin ${default_user}
        fi
    fi
}

time_config(){
    # 国外服务器的话，一般是需要将时区改为中国时区，遇到过一些坑，这儿只要不是中国ip，时区强制改为中国时区 
    curl -s "https://api.ip.la/en?json" | grep "China" >& /dev/null
    if [ $? -ne 0 ];then
        ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    fi
    ntpdate ntp1.aliyun.com
    #echo "*/30 * * * * root /usr/sbin/ntpdate ntp1.aliyun.com &> /dev/null" >> /etc/crontab 
    #systemctl restart crond.service
} 

bash_config(){
    # 命令审计
    [ -d "/var/log/commandAudit" ] || {
        mkdir /var/log/commandAudit -p
        touch /var/log/commandAudit/audit_`date '+%y-%m-%d'`.log
        chmod 622 /var/log/commandAudit/audit_`date '+%y-%m-%d'`.log
        chattr +a /var/log/commandAudit/audit_`date '+%y-%m-%d'`.log
    }

    echo "0 0 * * * root touch /var/log/commandAudit/audit_\`date '+\%y-\%m-\%d'\`.log && chmod 622 /var/log/commandAudit/audit_\`date '+\%y-\%m-\%d'\`.log && chattr +a /var/log/commandAudit/audit_\`date '+\%y-\%m-\%d'\`.log" >> /etc/crontab


    [ -f "${base_dir}/commanAdutid.sh" ]  && {
        cp -v ${base_dir}/commanAdutid.sh /etc/profile.d/ 
    } || {
        cat >> /etc/profile.d/commanAdutid.sh <<EOF
        # /etc/profile.d/commanAdutid.sh - set i18n stuff
        # mkdir /var/log/commandAudit -p
        # echo "0 0 * * * root touch /var/log/commandAudit/audit_\`date '+\%y-\%m-\%d'\`.log && chmod 622 /var/log/commandAudit/audit_\`date '+\%y-\%m-\%d'\`.log && chattr +a /var/log/commandAudit/audit_\`date '+\%y-\%m-\%d'\`.log" >> /etc/crontab
        #

        TMOUT=600
        HISTSIZE=1000
        HISTFILESIZE=1500
        HISTTIMEFORMAT="%Y%m%d-%H%M%S: "

        COMMANDAUDIT_FILE=/var/log/commandAudit/audit_\`date '+%y-%m-%d'\`.log
        PROMPT_COMMAND='{ date "+%y-%m-%d %T ### [\$(whoami)] ### \$(who am i |awk "{print \\\$1\" \"\\\$2\" \"\\\$5}") ### \$(pwd) ### \$(history 1 | { read x cmd; echo "\$cmd"; })"; } >> \$COMMANDAUDIT_FILE'
EOF
    }


}

firewalld_config(){
    # 重装防火墙为 iptables
    systemctl stop firewalld.service
    systemctl disable firewalld.service
    yum install iptables-services -y
    if [ ! -d "/opt/sh" ];then 
        mkdir -p /opt/sh
    fi
    systemctl enable iptables
}

zabbix_config(){
    if [ "$zbx_version" != "" ]; then
        rpm -q subversion >& /dev/null 
        if [ $? -ne 0 ]; then
          echo -e "Add subversion tools .."
          sleep 3
          yum install subversion -y
        fi

        rpm -q automake >& /dev/null 
        if [ $? -ne 0 ]; then
            echo -e "Add automake tools .."
            sleep 3 
            yum install automake -y 
        fi

        if [ ! -d "/opt/software" ]; then
          mkdir /opt/software/ -p 
        fi

        egrep "^zabbix" /etc/passwd >& /dev/null  
        if [ $? -ne 0 ]; then  
          useradd -u 1011 -d /opt/zabbix -s /sbin/nologin zabbix  
        fi
        svn co svn://svn.zabbix.com/branches/${zbx_version} /opt/software/zabbix_${zbx_version} 
        cd /opt/software/zabbix_${zbx_version} 
        ./bootstrap.sh 
        ./configure --enable-agent --prefix=/opt/zabbix  
        make install  
        
        sed -i "s/Hostname=Zabbix server/Hostname=${init_hostname}/" /opt/zabbix/etc/zabbix_agentd.conf
        sed -i "s/Server=127.0.0.1/Server=${zbx_server}/" /opt/zabbix/etc/zabbix_agentd.conf
        sed -i "s/ServerActive=127.0.0.1/ServerActive=${zbx_server}/" /opt/zabbix/etc/zabbix_agentd.conf
        
        echo "/opt/zabbix/sbin/zabbix_agentd -c /opt/zabbix/etc/zabbix_agentd.conf" >> /etc/rc.local 

    else 
        echo -e "\033[31m No default version is configured, manual installation is required ... \033[0m\n"
    fi
}

sshd_config(){
    if [ "$is_cloudServer" -eq "0" ]; then
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.$(date +"%F"-$RANDOM)
        #sed -i 's%#PermitRootLogin yes%PermitRootLogin no%' /etc/ssh/sshd_config
        #sed -i 's%#ClientAliveInterval 0%ClientAliveInterval 360%' /etc/ssh/sshd_config
        #sed -i 's%#ClientAliveCountMax 3%ClientAliveCountMax 3%' /etc/ssh/sshd_config
        #sed -i 's%PasswordAuthentication yes%PasswordAuthentication no%' /etc/ssh/sshd_config  

        sed -i 's%#PermitEmptyPasswords no%PermitEmptyPasswords no%' /etc/ssh/sshd_config
        sed -i 's%#UseDNS yes%UseDNS no%' /etc/ssh/sshd_config
        sed -i 's%GSSAPIAuthentication yes%GSSAPIAuthentication no%' /etc/ssh/sshd_config
        egrep "UseDNS|RootLogin|EmptyPass|GSSAPIAuthentication" /etc/ssh/sshd_config
    fi
}

vsftpd_config(){
if [ -n "${default_ftp_path}" ]; then
    egrep "^www" /etc/passwd >& /dev/null  
    if [ $? -ne 0 ]; then  
        useradd -u 1010 -d /var/ftproot -s /sbin/nologin www  
    fi

    if [ ! -d "${default_ftp_path}" ]; then
        mkdir -p ${default_ftp_path}
        chown www.www ${default_ftp_path}
    fi
    yum install vsftpd -y
    mv /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.$(date +"%F"-$RANDOM)
cat >> /etc/vsftpd/vsftpd.conf << EOF
anonymous_enable=NO
local_enable=YES
write_enable=NO
anon_upload_enable=NO
anon_mkdir_write_enable=NO
anon_other_write_enable=NO
anon_world_readable_only=NO
chroot_local_user=YES
allow_writeable_chroot=YES
guest_enable=YES
guest_username=www
pam_service_name=/etc/pam.d/vsftpd
user_config_dir=/etc/vsftpd/user_conf
xferlog_enable=YES
xferlog_file=/var/log/vsftpd.log
listen=YES
listen_port=21
pasv_min_port=30000
pasv_max_port=30020
use_localtime=yes
EOF
    mv /etc/pam.d/vsftpd /etc/pam.d/vsftpd.$(date +"%F"-$RANDOM)
cat >> /etc/pam.d/vsftpd << EOF
auth       required     pam_userdb.so db=/etc/vsftpd/vsftpd_login 
account    required     pam_userdb.so db=/etc/vsftpd/vsftpd_login
EOF
    mkdir -p /etc/vsftpd/user_conf
    touch /etc/vsftpd/user_conf/${default_ftp_user}
cat > /etc/vsftpd/user_conf/${default_ftp_user} << EOF
local_root=${default_ftp_path}
write_enable=YES
anon_world_readable_only=NO
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
EOF

cat > /etc/vsftpd/.vsftpd_login.list << EOF
${default_ftp_user}
${default_ftp_pass}
EOF
    # 加密
    db_load -T -t hash -f /etc/vsftpd/.vsftpd_login.list /etc/vsftpd/vsftpd_login.db
    #systemctl restart vsftpd
fi
}


choose_fun(){
  case "$1" in
    "duser_config")
      echo -e "###  \033[32m create default users \033[0m  ###"
      duser_config
    ;;
    "vsftpd_config") 
      echo -e "###  \033[32m create default vsftpd \033[0m  ###"
      vsftpd_config
    ;;
    "zabbix_config")
      echo -e "###  \033[32m config zabbix  \033[0m  ###"
      zabbix_config
    ;;
    *) 
      echo "Use : $0 (vsftpd_config|duser_config|zabbix_config)"
      echo -e "\t 可选参数: "
      echo -e "\t\t vsftpd_config|duser_config|zabbix_config|... 可选参数，选择后进行单个优化，未选择执行默认优化"
    ;;
  esac
}

main(){ 

    if [ ! -z "$1" ]; then
        if [ "$1" == "-h" ]; then
            choose_fun
            exit 0
        else
            choose_fun $1
            exit 0
        fi
    fi
    precheck 

    hostname ${init_hostname}
    echo "${init_hostname}" > /etc/hostname

    echo -e "###### \033[32m update the system source; \033[0m ######\n"
    source_config
    sleep 3  

    echo -e "###### \033[32m update basic tools and packages; \033[0m ######\n" 
    basic_install
    sleep 3

    echo -e "###### \033[32m close selinux ; \033[0m ######\n" 
    selinux
    sleep 3

    echo -e "###### \033[32m optimization firewalld; \033[0m ######\n" 
    firewalld_config
    sleep 3

    echo -e "###### \033[32m optimization system kernel; \033[0m ######\n" 
    sysctl_config
    sleep 3

    echo -e "###### \033[32m create default user; \033[0m ######\n" 
    duser_config
    sleep 3

    echo -e "###### \033[32m update system time zone; \033[0m ######\n" 
    time_config
    sleep 3

    echo -e "###### \033[32m optimization bash; \033[0m ######\n" 
    bash_config
    sleep 3

    echo -e "###### \033[32m config zabbix agent; \033[0m ######\n" 
    zabbix_config
    sleep 3

    echo -e "###### \033[32m update the system ; \033[0m ######\n" 
    yum update -y
    sleep 3 

    touch ${flagFile}

    for i in `seq -w 10 -1 0`
    do 
    echo -en "reboot after [ \e[0;31m$i\e[0m ] seconds ...\r"
    sleep 1
    done
    echo -e "###### \033[32m reboot system ; \033[0m ######\n" 
    reboot
} 

main $1
