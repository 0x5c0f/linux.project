#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#################################################
#   author      0x5c0f
#   date        2021-01-11
#   email       1269505840@qq.com
#   web         blog.cxd115.me
#   version     1.0.0
#   last update 2021-02-02
#   descript    域名监控发现
#################################################

# 自动发现结果有两个种类 1.发现需要检测证书的域名 2.发现常规检测的域名
# type: ssl 需要检查证书的域名
# type: normal 需要常规检查的域名
#
# UserParameter=custom.domain.ssl.discovery,/opt/domain_ssl/domain_discovery.py ssl
# UserParameter=custom.domain.status.discovery,/opt/domain_ssl/domain_discovery.py normal

import os
import sys
import json

if __name__ == "__main__":
    
    # 切换至脚本目录
    os.chdir(os.path.split(os.path.realpath(__file__))[0])

    try:
        _check_type = sys.argv[1]
    except Exception:
        _check_type = "normal"

    try:
        file = open("../etc.d/domain_host.cfg")
        data = {"data": []}

        dataArrT = []

        lines = file.readlines()
        for line in lines:

            line = line.strip("\n")

            if line.startswith("#"): continue
            if not line: continue

            _line = line.split()
            domain_name = _line[0]

            if domain_name in dataArrT: continue

            try:
                check_type = _line[1]
            except Exception:
                check_type = "normal"

            if _check_type == check_type:
                dataArrT.append(domain_name)
                data["data"].append({
                    "#DOMAIN_NAME": domain_name,
                    "#CHECK_TYPE": check_type
                })

        json_data = json.dumps(data)
        print(json_data)

    finally:
        file.close()
