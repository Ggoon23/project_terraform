#!/bin/bash
# S3에서 로그 파일을 동기화하는 스크립트

S3_BUCKET="${var.s3_bucket_name}"
LOCAL_LOG_DIR="/opt/splunk/var/log/aws-logs"
SPLUNK_USER="splunk"

# 로그 디렉토리 생성
mkdir -p $LOCAL_LOG_DIR
chown $SPLUNK_USER:$SPLUNK_USER $LOCAL_LOG_DIR

# S3에서 로그 동기화
aws s3 sync s3://$S3_BUCKET/cloudtrail/ $LOCAL_LOG_DIR/cloudtrail/ --delete
aws s3 sync s3://$S3_BUCKET/vpc-flow-logs/ $LOCAL_LOG_DIR/vpc-flow-logs/ --delete
aws s3 sync s3://$S3_BUCKET/guardduty/ $LOCAL_LOG_DIR/guardduty/ --delete

# 권한 설정
chown -R $SPLUNK_USER:$SPLUNK_USER $LOCAL_LOG_DIR