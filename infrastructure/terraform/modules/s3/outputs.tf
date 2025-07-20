# infrastructure/terraform/modules/s3/outputs.tf
# S3 모듈 출력값 정의

# 로그 버킷 정보
output "logs_bucket_id" {
  description = "로그 버킷 ID"
  value       = aws_s3_bucket.logs.id
}

output "logs_bucket_arn" {
  description = "로그 버킷 ARN"
  value       = aws_s3_bucket.logs.arn
}

output "logs_bucket_domain_name" {
  description = "로그 버킷 도메인 이름"
  value       = aws_s3_bucket.logs.bucket_domain_name
}

output "logs_bucket_regional_domain_name" {
  description = "로그 버킷 리전별 도메인 이름"
  value       = aws_s3_bucket.logs.bucket_regional_domain_name
}

# 아티팩트 버킷 정보
output "artifacts_bucket_id" {
  description = "아티팩트 버킷 ID"
  value       = var.create_artifacts_bucket ? aws_s3_bucket.artifacts[0].id : null
}

output "artifacts_bucket_arn" {
  description = "아티팩트 버킷 ARN"
  value       = var.create_artifacts_bucket ? aws_s3_bucket.artifacts[0].arn : null
}

output "artifacts_bucket_domain_name" {
  description = "아티팩트 버킷 도메인 이름"
  value       = var.create_artifacts_bucket ? aws_s3_bucket.artifacts[0].bucket_domain_name : null
}

# 백업 버킷 정보
output "backups_bucket_id" {
  description = "백업 버킷 ID"
  value       = var.create_backups_bucket ? aws_s3_bucket.backups[0].id : null
}

output "backups_bucket_arn" {
  description = "백업 버킷 ARN"
  value       = var.create_backups_bucket ? aws_s3_bucket.backups[0].arn : null
}

output "backups_bucket_domain_name" {
  description = "백업 버킷 도메인 이름"
  value       = var.create_backups_bucket ? aws_s3_bucket.backups[0].bucket_domain_name : null
}

# 액세스 로그 버킷 정보
output "access_logs_bucket_id" {
  description = "액세스 로그 버킷 ID"
  value       = var.enable_access_logging ? aws_s3_bucket.access_logs[0].id : null
}

output "access_logs_bucket_arn" {
  description = "액세스 로그 버킷 ARN"
  value       = var.enable_access_logging ? aws_s3_bucket.access_logs[0].arn : null
}

# KMS 키 정보
output "kms_key_id" {
  description = "S3 암호화 KMS 키 ID"
  value       = var.create_kms_key ? aws_kms_key.s3[0].key_id : var.kms_key_id
}

output "kms_key_arn" {
  description = "S3 암호화 KMS 키 ARN"
  value       = var.create_kms_key ? aws_kms_key.s3[0].arn : null
}

output "kms_alias_name" {
  description = "S3 KMS 키 별칭"
  value       = var.create_kms_key ? aws_kms_alias.s3[0].name : null
}

# 버킷 이름 목록 (다른 서비스에서 참조용)
output "bucket_names" {
  description = "생성된 모든 버킷 이름 목록"
  value = compact([
    aws_s3_bucket.logs.id,
    var.create_artifacts_bucket ? aws_s3_bucket.artifacts[0].id : "",
    var.create_backups_bucket ? aws_s3_bucket.backups[0].id : "",
    var.enable_access_logging ? aws_s3_bucket.access_logs[0].id : ""
  ])
}

output "bucket_arns" {
  description = "생성된 모든 버킷 ARN 목록"
  value = compact([
    aws_s3_bucket.logs.arn,
    var.create_artifacts_bucket ? aws_s3_bucket.artifacts[0].arn : "",
    var.create_backups_bucket ? aws_s3_bucket.backups[0].arn : "",
    var.enable_access_logging ? aws_s3_bucket.access_logs[0].arn : ""
  ])
}

# CloudTrail용 설정 정보
output "cloudtrail_s3_config" {
  description = "CloudTrail S3 설정 정보"
  value = {
    bucket_name = aws_s3_bucket.logs.id
    prefix      = "cloudtrail"
    kms_key_id  = var.create_kms_key ? aws_kms_key.s3[0].arn : var.kms_key_id
  }
}

# VPC Flow Logs용 설정 정보
output "vpc_flow_logs_s3_config" {
  description = "VPC Flow Logs S3 설정 정보"
  value = {
    bucket_name = aws_s3_bucket.logs.id
    prefix      = "vpc-flow-logs"
    kms_key_id  = var.create_kms_key ? aws_kms_key.s3[0].arn : var.kms_key_id
  }
}

# AWS Config용 설정 정보
output "aws_config_s3_config" {
  description = "AWS Config S3 설정 정보"
  value = {
    bucket_name = aws_s3_bucket.logs.id
    prefix      = "aws-config"
    kms_key_id  = var.create_kms_key ? aws_kms_key.s3[0].arn : var.kms_key_id
  }
}

# GuardDuty용 설정 정보
output "guardduty_s3_config" {
  description = "GuardDuty S3 설정 정보"
  value = {
    bucket_name = aws_s3_bucket.logs.id
    prefix      = "guardduty"
    kms_key_id  = var.create_kms_key ? aws_kms_key.s3[0].arn : var.kms_key_id
  }
}

# Security Hub용 설정 정보
output "security_hub_s3_config" {
  description = "Security Hub S3 설정 정보"
  value = {
    bucket_name = aws_s3_bucket.logs.id
    prefix      = "security-hub"
    kms_key_id  = var.create_kms_key ? aws_kms_key.s3[0].arn : var.kms_key_id
  }
}

# CloudWatch Logs 내보내기용 설정
output "cloudwatch_logs_export_config" {
  description = "CloudWatch Logs 내보내기 S3 설정"
  value = {
    bucket_name = aws_s3_bucket.logs.id
    prefix      = "cloudwatch-logs"
    kms_key_id  = var.create_kms_key ? aws_kms_key.s3[0].arn : var.kms_key_id
  }
}

# 라이프사이클 정책 정보
output "lifecycle_policies" {
  description = "적용된 라이프사이클 정책 정보"
  value = {
    logs_retention_days              = var.log_retention_days
    backup_retention_days           = var.backup_retention_days
    transition_to_ia_days           = var.transition_to_ia_days
    transition_to_glacier_days      = var.transition_to_glacier_days
    transition_to_deep_archive_days = var.transition_to_deep_archive_days
  }
}

# 보안 설정 정보
output "security_configuration" {
  description = "S3 보안 설정 정보"
  value = {
    encryption_enabled        = true
    versioning_enabled       = var.enable_versioning
    public_access_blocked    = true
    access_logging_enabled   = var.enable_access_logging
    mfa_delete_enabled       = var.enable_mfa_delete
    object_lock_enabled      = var.enable_object_lock
  }
}

# 모니터링 설정 정보
output "monitoring_configuration" {
  description = "S3 모니터링 설정 정보"
  value = {
    cloudwatch_events_enabled    = var.enable_cloudwatch_events
    cloudwatch_monitoring_enabled = var.enable_cloudwatch_monitoring
    access_logging_enabled       = var.enable_access_logging
    inventory_enabled           = var.enable_inventory
    analytics_enabled           = var.enable_analytics
  }
}

# 성능 설정 정보
output "performance_configuration" {
  description = "S3 성능 설정 정보"
  value = {
    transfer_acceleration_enabled = var.enable_transfer_acceleration
    intelligent_tiering_enabled   = var.enable_intelligent_tiering
    multipart_threshold_mb       = var.multipart_upload_threshold
    multipart_chunk_size_mb      = var.multipart_upload_chunk_size
  }
}

# CORS 설정 정보
output "cors_configuration" {
  description = "CORS 설정 정보"
  value = {
    enabled = var.enable_cors
    rules   = var.cors_rules
  }
}

# 웹사이트 호스팅 정보
output "website_configuration" {
  description = "웹사이트 호스팅 설정 정보"
  value = var.enable_website_hosting ? {
    enabled        = true
    index_document = var.index_document
    error_document = var.error_document
    website_endpoint = aws_s3_bucket.logs.website_endpoint
  } : {
    enabled = false
  }
}

# 복제 설정 정보
output "replication_configuration" {
  description = "교차 리전 복제 설정 정보"
  value = {
    enabled                = var.enable_cross_region_replication
    destination_bucket_arn = var.replication_destination_bucket
    replication_role_arn   = var.replication_role_arn
  }
}

# 컴플라이언스 정보
output "compliance_info" {
  description = "컴플라이언스 관련 정보"
  value = {
    data_classification      = var.data_classification
    compliance_requirements  = var.compliance_requirements
    retention_policy_applied = true
    encryption_at_rest      = true
    access_audit_enabled    = var.enable_access_logging
    isms_compliant          = var.log_retention_days >= 365
  }
}

# CloudWatch 알람 정보
output "cloudwatch_alarms" {
  description = "생성된 CloudWatch 알람 정보"
  value = var.enable_cloudwatch_monitoring ? [
    for alarm in aws_cloudwatch_metric_alarm.s3_bucket_size :
    {
      name      = alarm.alarm_name
      threshold = alarm.threshold
      metric    = alarm.metric_name
    }
  ] : []
}

# 이벤트 알림 설정
output "event_notification_config" {
  description = "S3 이벤트 알림 설정"
  value = {
    eventbridge_enabled   = var.enable_cloudwatch_events
    lambda_function_arn   = var.lambda_function_arn
    sqs_queue_arn        = var.sqs_queue_arn
  }
}

# 비용 최적화 정보
output "cost_optimization_info" {
  description = "비용 최적화 설정 정보"
  value = {
    intelligent_tiering_enabled = var.enable_intelligent_tiering
    lifecycle_transitions_configured = true
    requester_pays_enabled = var.enable_requester_pays
    storage_class_analysis_enabled = var.enable_analytics
  }
}

# 백업 관련 정보
output "backup_configuration" {
  description = "백업 관련 설정 정보"
  value = {
    backup_bucket_created     = var.create_backups_bucket
    cross_account_backup     = var.enable_cross_account_backup
    backup_account_id        = var.backup_account_id
    backup_retention_days    = var.backup_retention_days
    versioning_enabled       = var.enable_versioning
  }
}

# 접근 경로 정보
output "s3_access_paths" {
  description = "S3 버킷 접근 경로 정보"
  value = {
    logs_bucket = {
      console_url = "https://s3.console.aws.amazon.com/s3/buckets/${aws_s3_bucket.logs.id}"
      s3_uri      = "s3://${aws_s3_bucket.logs.id}"
      https_url   = "https://${aws_s3_bucket.logs.bucket_domain_name}"
    }
    artifacts_bucket = var.create_artifacts_bucket ? {
      console_url = "https://s3.console.aws.amazon.com/s3/buckets/${aws_s3_bucket.artifacts[0].id}"
      s3_uri      = "s3://${aws_s3_bucket.artifacts[0].id}"
      https_url   = "https://${aws_s3_bucket.artifacts[0].bucket_domain_name}"
    } : null
    backups_bucket = var.create_backups_bucket ? {
      console_url = "https://s3.console.aws.amazon.com/s3/buckets/${aws_s3_bucket.backups[0].id}"
      s3_uri      = "s3://${aws_s3_bucket.backups[0].id}"
      https_url   = "https://${aws_s3_bucket.backups[0].bucket_domain_name}"
    } : null
  }
}