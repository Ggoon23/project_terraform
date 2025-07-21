#!/bin/bash
# CloudWatch Logs에서 로그를 가져오는 스크립트

CLOUDWATCH_LOG_GROUPS=(
  "/aws/vpc/flowlogs/${var.project_name}"
  "/aws/cloudtrail/${var.project_name}"
)

LOCAL_LOG_DIR="/opt/splunk/var/log/cloudwatch-logs"
START_TIME=$(date -d '1 hour ago' -u +%s)000
END_TIME=$(date -u +%s)000

mkdir -p $LOCAL_LOG_DIR

for LOG_GROUP in "${CLOUDWATCH_LOG_GROUPS[@]}"; do
  LOG_GROUP_NAME=$(basename $LOG_GROUP)
  
  # CloudWatch Logs에서 로그 스트림 목록 가져오기
  aws logs describe-log-streams \
    --log-group-name "$LOG_GROUP" \
    --order-by LastEventTime \
    --descending \
    --max-items 10 \
    --query 'logStreams[*].logStreamName' \
    --output text | while read STREAM; do
    
    if [ ! -z "$STREAM" ]; then
      # 로그 이벤트 가져오기
      aws logs get-log-events \
        --log-group-name "$LOG_GROUP" \
        --log-stream-name "$STREAM" \
        --start-time $START_TIME \
        --end-time $END_TIME \
        --query 'events[*].[timestamp,message]' \
        --output text >> "$LOCAL_LOG_DIR/${LOG_GROUP_NAME}.log"
    fi
  done
done

# Splunk 사용자 권한 설정
chown -R splunk:splunk $LOCAL_LOG_DIR