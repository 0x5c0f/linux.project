#!/bin/bash
# update by 2020-09-09 1269505840@qq.com
# version: 1.0
# 00 01 * * * /bin/bash /opt/sh/aws.cloudtrail.export.sh >> /data/sharestore/aws.cloudtrail.export.log 2>&1  
# pip install awscli
# aws configure

# aws sync path,default: s3://${aws_storage}/${aws_path}
# aws_storage 存储桶名称
aws_storage=""
# aws_path 远程上传路径
aws_path=""

# base back path; must / end
base_path="/data/sharestore/"

_TODAY=$(date +"%s")
_YESTERDAY=$(( ${_TODAY} - 86700 ))

cloud_trail_sync(){
  /bin/aws cloudtrail lookup-events --start-time ${_YESTERDAY} --end-time ${_TODAY} --lookup-attributes AttributeKey=ReadOnly,AttributeValue=false | gzip > /tmp/${_TODAY}_cloud_trail.txt.gz
  # # sync 
  /bin/aws s3 cp /tmp/${_TODAY}_cloud_trail.txt.gz s3://${aws_storage}/${aws_path}/
  sleep 2 
  rm -rf /tmp/${_TODAY}_cloud_trail.txt.gz
}

cloud_trail_sync
echo "Current TIME >:"$(date +"%s")