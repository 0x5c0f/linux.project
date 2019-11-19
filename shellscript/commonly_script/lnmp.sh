#!/bin/bash
#################################################
#   author      0x5c0f
#   date        2019-04-19
#   email       1269505840@qq.com
#   web         blog.cxd115.me
#   version     1.0.0
#   last update 2019-04-19
#   descript    Use : lnmp -h
#################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

#脚本目录,请不要修改
#BASE_DIR=$(cd `dirname $0`; pwd)
BASE_DIR=$(dirname $(readlink -f "$0"))

# 测试模式 0：当前为测试(默认) 1：当前为正式
debug=1

# 默认安装软件版本(php版本需要大于5.3)
ngx_version="1.14.2"
php_version="5.6.38"
mysql_version="5.6"

# current back time
time=$(date +"%Y%m%d%H")

flagFile="/tmp/server.init.executed"

color_info() {
    color="$1"
    info="$2"
    case $color in
    red)
        echo -e "\033[31m$info \033[0m"
        ;;
    green)
        echo -e "\033[32m$info \033[0m"
        ;;
    yellow)
        echo -e "\033[33m$info \033[0m"
        ;;
    *)
        echo -e "\033[37m$info \033[0m"
        ;;
    esac
}

precheck() {
    if [ $UID -ne 0 ]; then
        color_info red "please run this script as root ."
        exit 2
    fi

    if [ ! -f "$flagFile" ]; then
        color_info yellow "Warring: Recommended to optimize the server first,If it has been operated, please ignore this tip \n"
        read -p "press enter key to continue or press Ctrl+c to breake ... "
        touch $flagFile
        echo
    fi

    yum makecache

}

chk_install() {
    chk_name="$1"
    chk_ver="$2"

    color_info green "${chk_name} Installd Starting..."

    egrep "${chk_name}_${chk_ver}" $flagFile >&/dev/null && {
        color_info red "Ignore: current ${chk_name}_${chk_ver} already installd .."
        exit 2
    }
}

nginx_install() {

    # chk_install "nginx" "${ngx_version}"

    egrep "${chk_name}_${chk_ver}" $flagFile >&/dev/null && {
        color_info red "Ignore: current ${chk_name}_${chk_ver} already installd .."
    } || {
        egrep "^www" /etc/passwd >&/dev/null || {
            useradd -u 1010 -d /var/ftproot -s /sbin/nologin www
        }

        [ -e "/opt/software" -a -d "/opt/software" ] || {
            mkdir -p /opt/software
        }
        cd /opt/software

        yum install -y make gcc glibc gcc-c++ pcre-devel openssl-devel

        [ -e ${BASE_DIR}/../../software/nginx-${ngx_version}.tar.gz ] && {
            cp -v ${BASE_DIR}/../../software/nginx-${ngx_version}.tar.gz .
        } || {
            wget http://nginx.org/download/nginx-${ngx_version}.tar.gz
        }

        tar -xzvf nginx-${ngx_version}.tar.gz

        cd nginx-${ngx_version}
        sed -i 's#"1.14.2"#""#g' ./src/core/nginx.h
        sed -i 's#"NGINX"#"0x5c0f"#g' ./src/core/nginx.h
        sed -i 's#"nginx/"#"0x5c0f "#g' ./src/core/nginx.h
        sed -i 's#"Server: nginx"#"Server: 0x5c0f"#g' ./src/http/ngx_http_header_filter_module.c
        sed -i 's#<center>nginx</center>#<center>0x5c0f</center>#g' ./src/http/ngx_http_special_response.c
        grep "0x5c0f" ./src/http/ngx_http_header_filter_module.c ./src/http/ngx_http_special_response.c ./src/core/nginx.h 

        ./configure --user=www --group=www --with-http_ssl_module --with-http_stub_status_module --with-http_realip_module --prefix=/opt/nginx-${ngx_version}
        make && make install

        # update nginx version use
        ln -sf /opt/nginx-${ngx_version} /opt/nginxssl

        mkdir -p /opt/nginxssl/conf/conf.d -p

        cp -v ${BASE_DIR}/../../config/nginx/nginx.php.conf /opt/nginxssl/conf/conf.d/nginx.php.conf.default
        cp -v ${BASE_DIR}/../../config/nginx/nginx.ssl.conf /opt/nginxssl/conf/conf.d/nginx.ssl.conf.default
        cp -v ${BASE_DIR}/../../config/nginx/nginx.conf /opt/nginxssl/conf/

        /opt/nginxssl/sbin/nginx -t
        #echo "/opt/nginxssl/sbin/nginx" >>/etc/rc.local

        cp -v ${BASE_DIR}/../../config/nginx.service /usr/lib/systemd/system/
        systemctl daemon-reload
        systemctl enable nginx.service

        echo "${time} nginx_${ngx_version} " >>${flagFile}

        sleep 3
    }
}

php_install() {
    chk_install "php" ${php_version}

    egrep "^www" /etc/passwd >&/dev/null || {
        useradd -u 1010 -d /var/ftproot -s /sbin/nologin www
    }

    [ -e "/opt/software" -a -d "/opt/software" ] || {
        mkdir -p /opt/software
    }

    cd /opt/software

    yum install -y zlib-devel libxml2-devel \
        libjpeg-devel libjpeg-turbo-devel \
        freetype-devel libpng-devel gd-devel \
        libcurl-devel libxslt-devel openssl \
        openssl-devel mhash libmcrypt-devel \
        mcrypt gcc glibc gcc-c++ make

    # libiconv
    wget https://ftp.gnu.org/pub/gnu/libiconv/libiconv-1.15.tar.gz --no-check-certificate
    tar xzf libiconv-1.15.tar.gz
    cd libiconv-1.15
    ./configure --prefix=/usr/local/libiconv
    make && make install
    # php install
    cd /opt/software
    wget http://mirrors.sohu.com/php/php-${php_version}.tar.gz
    tar -xzf php-${php_version}.tar.gz
    cd php-${php_version}

    ./configure \
        --prefix=/opt/php${php_version} \
        --with-config-file-path=/opt/php${php_version}/etc \
        --with-mysql=mysqlnd \
        --with-mysqli=mysqlnd \
        --with-pdo-mysql=mysqlnd \
        --with-iconv-dir=/usr/local/libiconv \
        --with-freetype-dir \
        --with-jpeg-dir \
        --with-png-dir \
        --with-zlib \
        --with-libxml-dir \
        --enable-xml \
        --disable-rpath \
        --disable-debug \
        --enable-bcmath \
        --enable-shmop \
        --enable-sysvsem \
        --enable-inline-optimization \
        --with-curl \
        --enable-mbregex \
        --enable-fpm \
        --enable-mbstring \
        --with-mcrypt \
        --with-gd \
        --enable-gd-native-ttf \
        --with-openssl \
        --with-mhash \
        --enable-pcntl \
        --enable-sockets \
        --with-xmlrpc \
        --enable-zip \
        --enable-soap \
        --enable-short-tags \
        --enable-static \
        --with-xsl \
        --with-fpm-user=www \
        --with-fpm-group=www \
        --enable-ftp \
        --enable-opcache=no

    make -j 8 && make install

    ln -sf /opt/php${php_version} /opt/php-server

    # config
    [ -d "/opt/php-server/etc/php-fpm.d" ] || {
        mkdir /opt/php-server/etc/php-fpm.d -p
    }

    #    cp -v ${BASE_DIR}/../../config/php.ini /opt/php-server/etc
    #    cp -v ${BASE_DIR}/../../config/php-fpm.conf /opt/php-server/etc/php-fpm.d
    #    cp -v ${BASE_DIR}/../../config/php-fpm.www.conf /opt/php-server/etc/php-fpm.d
    cp -v php.ini-production /opt/php-server/etc/php.ini
    #sed -i 's#disable_functions =#disable_functions = phpinfo#g' /opt/php-server/etc/php.ini
    #sed -i 's#expose_php = On#expose_php = Off#g' /opt/php-server/etc/php.ini

    cp -v /opt/php-server/etc/php-fpm.conf.default /opt/php-server/etc/php-fpm.conf
    #sed -i 's#;rlimit_files = 1024#rlimit_files = 10240#g' /opt/php-server/etc/php-fpm.conf
    #sed -i 's#;events.mechanism = epoll#events.mechanism = epoll#g' /opt/php-server/etc/php-fpm.conf
    
    cp -v /opt/php-server/etc/php-fpm.d/www.conf.default /opt/php-server/etc/php-fpm.d/www.conf
    # sed -i 's#pm.max_children = 5#pm.max_children = 50#g' /opt/php-server/etc/php-fpm.d/www.conf
    # sed -i 's#pm.start_servers = 2#pm.start_servers = 3#g' /opt/php-server/etc/php-fpm.d/www.conf
    # sed -i 's#pm.min_spare_servers = 1#pm.min_spare_servers = 3#g' /opt/php-server/etc/php-fpm.d/www.conf
    # sed -i 's#pm.max_spare_servers = 3#pm.max_spare_servers = 6#g' /opt/php-server/etc/php-fpm.d/www.conf
    # sed -i 's#;pm.process_idle_timeout = 10s;#pm.process_idle_timeout = 10s;#g' /opt/php-server/etc/php-fpm.d/www.conf
    # sed -i 's#;pm.max_requests = 500#pm.max_requests = 10240#g' /opt/php-server/etc/php-fpm.d/www.conf
    # sed -i 's#;rlimit_files = 1024#rlimit_files = 10240#g' /opt/php-server/etc/php-fpm.d/www.conf


    cp -v ${BASE_DIR}/../../config/php-fpm.service /usr/lib/systemd/system/
    systemctl daemon-reload
    systemctl enable php-fpm.service

    echo "${time} php_${php_version} " >>${flagFile}

}

mysql_install() {
    echo mysql
}

all_install() {
    nginx_install
    php_install
}

help() {
    case $1 in
    "-h")
        echo "Usg : $0 (-a|-n|-m|-p|--help)"
        ;;
    "--help")
        echo "Usg : lnmp - install lnmp  "
        echo -e "\t-a, --all "
        echo -e "\t\tdefault install nginx php mysql "
        echo -e "\t-n, --nginx_install "
        echo -e "\t\tinstall nginx (default: 1.14.2)"
        echo -e "\t-p, --php_install "
        echo -e "\t\tinstall php (default: 5.6)"
        echo -e "\t-m, --mysql_install"
        echo -e "\t\tinstall mysql (default: 5.6)"
        echo -e "\t(version) "
        echo -e "\t\t install version(Available)"
        ;;
    *)
        echo "Usg : $0 (-a|-n|-m|-p|--help)"
        ;;
    esac

    exit 0
}

choose_fun() {
    choose=$1
    case $choose in
    "-h" | "--help")
        help $choose
        ;;
    "-a" | "--all")
        all_install
        ;;
    "-n" | "--nginx_install")
        nginx_install
        ;;
    "-p" | "--php_install")
        php_install
        ;;
    "-m" | "--mysql_install")
        mysql_install
        ;;
    *)
        help
        ;;
    esac
}

main() {

    precheck

    choose_fun $1

    echo "install complete,View https://blog.cxd115.me/115/62.html for related optimizations"
}

main $1
