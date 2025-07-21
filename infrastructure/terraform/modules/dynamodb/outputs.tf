# infrastructure/terraform/modules/dynamodb/outputs.tf
# DynamoDB 모듈 출력값 정의

# 테이블 기본 정보
output "table_name" {
  description = "DynamoDB 테이블 이름"
  value       = aws_dynamodb_table.main.name
}

output "table_id" {
  description = "DynamoDB 테이블 ID"
  value       = aws_dynamodb_table.main.id
}

output "table_arn" {
  description = "DynamoDB 테이블 ARN"
  value       = aws_dynamodb_table.main.arn
}

output "table_stream_arn" {
  description = "DynamoDB 테이블 스트림 ARN"
  value       = var.stream_enabled ? aws_dynamodb_table.main.stream_arn : null
}

output "table_stream_label" {
  description = "DynamoDB 테이블 스트림 레이블"
  value       = var.stream_enabled ? aws_dynamodb_table.main.stream_label : null
}

# 테이블 설정 정보
output "hash_key" {
  description = "테이블 해시 키"
  value       = aws_dynamodb_table.main.hash_key
}

output "range_key" {
  description = "테이블 범위 키"
  value       = aws_dynamodb_table.main.range_key
}

output "billing_mode" {
  description = "테이블 과금 모드"
  value       = aws_dynamodb_table.main.billing_mode
}

output "read_capacity" {
  description = "테이블 읽기 용량"
  value       = aws_dynamodb_table.main.read_capacity
}

output "write_capacity" {
  description = "테이블 쓰기 용량"
  value       = aws_dynamodb_table.main.write_capacity
}

# 글로벌 보조 인덱스 정보
output "global_secondary_indexes" {
  description = "글로벌 보조 인덱스 정보"
  value = [
    for gsi in aws_dynamodb_table.main.global_secondary_index : {
      name            = gsi.name
      hash_key        = gsi.hash_key
      range_key       = gsi.range_key
      projection_type = gsi.projection_type
    }
  ]
}

output "local_secondary_indexes" {
  description = "로컬 보조 인덱스 정보"
  value = [
    for lsi in aws_dynamodb_table.main.local_secondary_index : {
      name            = lsi.name
      range_key       = lsi.range_key
      projection_type = lsi.projection_type
    }
  ]
}

# KMS 암호화 정보
output "kms_key_id" {
  description = "DynamoDB 암호화 KMS 키 ID"
  value       = var.create_kms_key ? aws_kms_key.dynamodb[0].key_id : var.kms_key_arn
}

output "kms_key_arn" {
  description = "DynamoDB 암호화 KMS 키 ARN"
  value       = var.create_kms_key ? aws_kms_key.dynamodb[0].arn : var.kms_key_arn
}

output "kms_alias_name" {
  description = "DynamoDB KMS 키 별칭"
  value       = var.create_kms_key ? aws_kms_alias.dynamodb[0].name : null
}

# Auto Scaling 정보
output "autoscaling_read_target_arn" {
  description = "읽기 Auto Scaling 대상 ARN"
  value       = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? aws_appautoscaling_target.dynamodb_table_read_target[0].arn : null
}

output "autoscaling_write_target_arn" {
  description = "쓰기 Auto Scaling 대상 ARN"
  value       = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? aws_appautoscaling_target.dynamodb_table_write_target[0].arn : null
}

output "autoscaling_read_policy_arn" {
  description = "읽기 Auto Scaling 정책 ARN"
  value       = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? aws_appautoscaling_policy.dynamodb_table_read_policy[0].arn : null
}

output "autoscaling_write_policy_arn" {
  description = "쓰기 Auto Scaling 정책 ARN"
  value       = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? aws_appautoscaling_policy.dynamodb_table_write_policy[0].arn : null
}

# CloudWatch 알람 정보
output "cloudwatch_alarms" {
  description = "생성된 CloudWatch 알람 정보"
  value = var.enable_cloudwatch_alarms ? {
    read_throttled_requests = {
      name = aws_cloudwatch_metric_alarm.dynamodb_read_throttled_requests[0].alarm_name
      arn  = aws_cloudwatch_metric_alarm.dynamodb_read_throttled_requests[0].arn
    }
    write_throttled_requests = {
      name = aws_cloudwatch_metric_alarm.dynamodb_write_throttled_requests[0].alarm_name
      arn  = aws_cloudwatch_metric_alarm.dynamodb_write_throttled_requests[0].arn
    }
    high_read_capacity = var.billing_mode == "PROVISIONED" ? {
      name = aws_cloudwatch_metric_alarm.dynamodb_consumed_read_capacity[0].alarm_name
      arn  = aws_cloudwatch_metric_alarm.dynamodb_consumed_read_capacity[0].arn
    } : null
  } : null
}

# IAM 역할 정보
output "access_role_arn" {
  description = "DynamoDB 접근용 IAM 역할 ARN"
  value       = var.create_access_role ? aws_iam_role.dynamodb_access[0].arn : null
}

output "access_role_name" {
  description = "DynamoDB 접근용 IAM 역할 이름"
  value       = var.create_access_role ? aws_iam_role.dynamodb_access[0].name : null
}

# 백업 정보
output "backup_arn" {
  description = "DynamoDB 백업 ARN"
  value       = var.create_backup ? aws_dynamodb_backup.main[0].arn : null
}

output "backup_name" {
  description = "DynamoDB 백업 이름"
  value       = var.create_backup ? aws_dynamodb_backup.main[0].name : null
}

# Global Tables 정보
output "global_table_arn" {
  description = "Global Table ARN"
  value       = var.enable_global_tables ? aws_dynamodb_global_table.main[0].arn : null
}

output "global_table_id" {
  description = "Global Table ID"
  value       = var.enable_global_tables ? aws_dynamodb_global_table.main[0].id : null
}

# 복제본 정보
output "replica_arn" {
  description = "테이블 복제본 ARN"
  value       = var.create_replica ? aws_dynamodb_table_replica.main[0].arn : null
}

# TTL 설정 정보
output "ttl_configuration" {
  description = "TTL 설정 정보"
  value = {
    enabled        = var.ttl_enabled
    attribute_name = var.ttl_enabled ? var.ttl_attribute_name : null
  }
}

# Point-in-time Recovery 정보
output "point_in_time_recovery" {
  description = "Point-in-time Recovery 설정"
  value = {
    enabled = var.point_in_time_recovery_enabled
  }
}

# 스트림 설정 정보
output "stream_configuration" {
  description = "DynamoDB Streams 설정 정보"
  value = {
    enabled   = var.stream_enabled
    view_type = var.stream_enabled ? var.stream_view_type : null
    arn       = var.stream_enabled ? aws_dynamodb_table.main.stream_arn : null
  }
}

# 보안 설정 정보
output "security_configuration" {
  description = "보안 설정 정보"
  value = {
    encryption_enabled           = true
    kms_encryption              = var.create_kms_key || var.kms_key_arn != null
    deletion_protection_enabled = var.deletion_protection_enabled
    point_in_time_recovery      = var.point_in_time_recovery_enabled
    data_classification         = var.data_classification
  }
}

# 성능 설정 정보
output "performance_configuration" {
  description = "성능 설정 정보"
  value = {
    billing_mode              = var.billing_mode
    autoscaling_enabled       = var.enable_autoscaling
    contributor_insights      = var.enable_contributor_insights
    table_class              = var.table_class
    global_tables_enabled    = var.enable_global_tables
  }
}

# 모니터링 설정 정보
output "monitoring_configuration" {
  description = "모니터링 설정 정보"
  value = {
    cloudwatch_alarms_enabled = var.enable_cloudwatch_alarms
    contributor_insights      = var.enable_contributor_insights
    streams_enabled          = var.stream_enabled
    point_in_time_recovery   = var.point_in_time_recovery_enabled
  }
}

# 컴플라이언스 정보
output "compliance_info" {
  description = "컴플라이언스 관련 정보"
  value = {
    data_classification      = var.data_classification
    compliance_requirements  = var.compliance_requirements
    encryption_at_rest      = true
    backup_enabled          = var.point_in_time_recovery_enabled
    audit_logging           = var.stream_enabled
    deletion_protection     = var.deletion_protection_enabled
  }
}

# 연결 정보 (애플리케이션용)
output "connection_info" {
  description = "애플리케이션 연결 정보"
  value = {
    table_name = aws_dynamodb_table.main.name
    region     = data.aws_region.current.name
    endpoint   = "https://dynamodb.${data.aws_region.current.name}.amazonaws.com"
  }
  sensitive = false
}

# 데이터 소스
data "aws_region" "current" {}

# SDK 설정 정보
output "sdk_configuration" {
  description = "AWS SDK 설정 정보"
  value = {
    table_name = aws_dynamodb_table.main.name
    region     = data.aws_region.current.name
    kms_key_id = var.create_kms_key ? aws_kms_key.dynamodb[0].key_id : var.kms_key_arn
  }
}

# 접근 경로 정보
output "access_paths" {
  description = "DynamoDB 접근 경로 정보"
  value = {
    console_url = "https://${data.aws_region.current.name}.console.aws.amazon.com/dynamodbv2/home?region=${data.aws_region.current.name}#table?name=${aws_dynamodb_table.main.name}"
    cli_command = "aws dynamodb describe-table --table-name ${aws_dynamodb_table.main.name} --region ${data.aws_region.current.name}"
  }
}

# 비용 최적화 정보
output "cost_optimization_info" {
  description = "비용 최적화 설정 정보"
  value = {
    billing_mode              = var.billing_mode
    table_class              = var.table_class
    autoscaling_enabled      = var.enable_autoscaling
    ttl_enabled             = var.ttl_enabled
    provisioned_capacity = var.billing_mode == "PROVISIONED" ? {
      read_capacity  = var.read_capacity
      write_capacity = var.write_capacity
    } : null
  }
}

# 속성 정보
output "table_attributes" {
  description = "테이블 속성 정보"
  value = [
    for attr in var.attributes : {
      name = attr.name
      type = attr.type
    }
  ]
}

# 인덱스 요약 정보
output "indexes_summary" {
  description = "인덱스 요약 정보"
  value = {
    global_secondary_indexes_count = length(var.global_secondary_indexes)
    local_secondary_indexes_count  = length(var.local_secondary_indexes)
    total_indexes_count           = length(var.global_secondary_indexes) + length(var.local_secondary_indexes)
  }
}