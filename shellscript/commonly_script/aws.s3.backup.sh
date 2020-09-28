#!/bin/bash
# update by 2020-09-09 1269505840@qq.com
# version: 1.0
# 00 01 * * * /bin/bash /opt/sh/aws.s3.backup.sh >> /data/sharestore/backlogs.log 2>&1  
# pip install awscli
# aws configure

# aws sync path,default: s3://${aws_storage}/${aws_path}
# aws_storage 存储桶名称
aws_storage=""
# aws_path 远程上传路径
aws_path=""

<<EOF
目录结构  
sharestore
├── server1_dir
├── server2_dir
│   └── mysqlback
├── server3_dir
│   └── nginx.logs
├── server4_dir
├── server5_dir
│   ├── appback
│   ├── codeback
│   ├── configback
│   └── mysqlback
└── server6_dir
    └── backup1
EOF

# base back path; must / end
base_path="/data/sharestore/"

# current back time 
TIME=$(date +"%Y%m%d" -d "-2 days")

TIME_D=$(date +"%d")
IS_ASYNC=$(expr $TIME_D % 7)

awscli_sync(){
  if [ "$aws_path" == "" ];then 
    echo "You need to configure the S3 upload path !"
  else

    # 服务器存储扫描
    for _dir0 in $(ls ${base_path}); do
      # 防止意外生成的日志文件影响扫描
      if [[ -d "${base_path}${_dir0}" ]]; then
        cd ${base_path}${_dir0}
        # 压缩存储扫描(server)
        for _dir1 in $(ls ${base_path}${_dir0}); do
          # 存储目录扫描
          file_path="${base_path}${_dir0}/${_dir1}"
          if [ -d "${file_path}" ]; then
            for _file in $(ls ${file_path}|grep ${TIME}); do
              ## awscli sync 
              echo "====>: awscli ${file_path}/${_file} s3://${aws_storage}/${aws_path}/${_dir0}/${_dir1}/${file} "
              echo -e "$(md5sum ${file_path}/${_file})\n" >> ${file_path}/README.md5sum 
              #echo "/bin/aws s3 cp ${file_path}/${_file} s3://${aws_storage}/${aws_path}/${_dir0}/${_dir1}/"
              /bin/aws s3 cp ${file_path}/${_file} s3://${aws_storage}/${aws_path}/${_dir0}/${_dir1}/
            done
            echo -e "====== ${TIME} end ======\n" >> ${file_path}/README.md5sum
            #echo "/bin/aws s3 cp ${file_path}/README.md5sum s3://${aws_storage}/${aws_path}/${_dir0}/${_dir1}/"
            /bin/aws s3 cp ${file_path}/README.md5sum s3://${aws_storage}/${aws_path}/${_dir0}/${_dir1}/

            # 每隔7天 全部同步一次,sync不会删除本地不存在而云端存在的数据
            if [[ $IS_ASYNC -eq 0 ]]; then
              /bin/aws s3 sync ${file_path}/ s3://${aws_storage}/${aws_path}/${_dir0}/${_dir1}/
            fi
          fi
        done
      fi
    done
  fi
}

echo "Backup start TIME >:"$(date +"%s")

awscli_sync

echo "Backup end TIME >:"$(date +"%s")
