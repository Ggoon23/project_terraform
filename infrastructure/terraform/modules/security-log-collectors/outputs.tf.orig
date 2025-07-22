# infrastructure/terraform/modules/security-log-collectors/outputs.tf
# 보안 로그 수집기 모듈 출력값 정의

# CloudTrail 정보
output "cloudtrail_arn" {
  description = "CloudTrail ARN"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].arn : null
}

output "cloudtrail_home_region" {
  description = "CloudTrail 홈 리전"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].home_region : null
}

output "cloudtrail_s3_bucket_name" {
  description = "CloudTrail S3 버킷 이름"
  value       = var.enable_cloudtrail ? aws_cloudtrail.main[0].s3_bucket_name : null
}

output "cloudtrail_log_group_arn" {
  description = "CloudTrail CloudWatch 로그 그룹 ARN"
  value       = var.cloudtrail_cloudwatch_logs_enabled ? aws_cloudwatch_log_group.cloudtrail[0].arn : null
}

output "cloudtrail_log_group_name" {
  description = "CloudTrail CloudWatch 로그 그룹 이름"
  value       = var.cloudtrail_cloudwatch_logs_enabled ? aws_cloudwatch_log_group.cloudtrail[0].name : null
}

# GuardDuty 정보
output "guardduty_detector_id" {
  description = "GuardDuty 탐지기 ID"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].id : null
}

output "guardduty_detector_arn" {
  description = "GuardDuty 탐지기 ARN"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].arn : null
}

output "guardduty_account_id" {
  description = "GuardDuty 계정 ID"
  value       = var.enable_guardduty ? aws_guardduty_detector.main[0].account_id : null
}

output "guardduty_findings_bucket_name" {
  description = "GuardDuty Finding S3 버킷 이름"
  value       = var.guardduty_export_findings_to_s3 ? aws_s3_bucket.guardduty_findings[0].id : null
}

# Security Hub 정보
output "security_hub_account_id" {
  description = "Security Hub 계정 ID"
  value       = var.enable_security_hub ? aws_securityhub_account.main[0].id : null
}

output "security_hub_arn" {
  description = "Security Hub ARN"
  value       = var.enable_security_hub ? aws_securityhub_account.main[0].arn : null
}

output "security_hub_standards" {
  description = "활성화된 Security Hub 표준 목록"
  value = {
    aws_foundational = var.enable_security_hub && var.security_hub_enable_aws_foundational ? aws_securityhub_standards_subscription.aws_foundational[0].standards_arn : null
    cis             = var.enable_security_hub && var.security_hub_enable_cis ? aws_securityhub_standards_subscription.cis[0].standards_arn : null
    pci_dss         = var.enable_security_hub && var.security_hub_enable_pci_dss ? aws_securityhub_standards_subscription.pci_dss[0].standards_arn : null
  }
}

# AWS Config 정보
output "config_recorder_name" {
  description = "AWS Config 레코더 이름"
  value       = var.enable_aws_config ? aws_config_configuration_recorder.main[0].name : null
}

output "config_delivery_channel_name" {
  description = "AWS Config 전송 채널 이름"
  value       = var.enable_aws_config ? aws_config_delivery_channel.main[0].name : null
}

output "config_role_arn" {
  description = "AWS Config IAM 역할 ARN"
  value       = var.enable_aws_config ? aws_iam_role.config[0].arn : null
}

# AWS Inspector 정보
output "inspector_enabler_account_ids" {
  description = "Inspector가 활성화된 계정 ID 목록"
  value       = var.enable_inspector ? aws_inspector2_enabler.main[0].account_ids : null
}

output "inspector_resource_types" {
  description = "Inspector가 스캔하는 리소스 타입"
  value       = var.enable_inspector ? aws_inspector2_enabler.main[0].resource_types : null
}

# VPC Flow Logs 정보
output "vpc_flow_log_id" {
  description = "VPC Flow Log ID"
  value       = var.enable_vpc_flow_logs ? aws_flow_log.main[0].id : null
}

output "vpc_flow_log_arn" {
  description = "VPC Flow Log ARN"
  value       = var.enable_vpc_flow_logs ? aws_flow_log.main[0].arn : null
}

output "vpc_flow_logs_log_group_name" {
  description = "VPC Flow Logs CloudWatch 로그 그룹 이름"
  value       = var.enable_vpc_flow_logs && var.vpc_flow_logs_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.vpc_flow_logs[0].name : null
}

output "vpc_flow_logs_log_group_arn" {
  description = "VPC Flow Logs CloudWatch 로그 그룹 ARN"
  value       = var.enable_vpc_flow_logs && var.vpc_flow_logs_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.vpc_flow_logs[0].arn : null
}

# 이벤트 모니터링 정보
output "security_event_rule_arn" {
  description = "보안 이벤트 CloudWatch 규칙 ARN"
  value       = var.enable_security_event_monitoring ? aws_cloudwatch_event_rule.security_events[0].arn : null
}

output "security_event_rule_name" {
  description = "보안 이벤트 CloudWatch 규칙 이름"
  value       = var.enable_security_event_monitoring ? aws_cloudwatch_event_rule.security_events[0].name : null
}

# 대시보드 정보
output "security_dashboard_url" {
  description = "보안 대시보드 URL"
  value       = var.create_security_dashboard ? "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#dashboards:name=${aws_cloudwatch_dashboard.security[0].dashboard_name}" : null
}

output "security_dashboard_name" {
  description = "보안 대시보드 이름"
  value       = var.create_security_dashboard ? aws_cloudwatch_dashboard.security[0].dashboard_name : null
}

# 커스텀 이벤트 버스 정보
output "custom_event_bus_name" {
  description = "커스텀 이벤트 버스 이름"
  value       = var.create_custom_event_bus ? aws_cloudwatch_event_bus.security[0].name : null
}

output "custom_event_bus_arn" {
  description = "커스텀 이벤트 버스 ARN"
  value       = var.create_custom_event_bus ? aws_cloudwatch_event_bus.security[0].arn : null
}

# Splunk 연동용 출력값 추가
output "splunk_forwarder_role_arn" {
  description = "Splunk Forwarder IAM 역할 ARN"
  value       = aws_iam_role.splunk_forwarder.arn
}

output "s3_log_paths" {
  description = "S3 로그 경로 목록"
  value = {
    cloudtrail = "s3://${var.s3_bucket_name}/${var.cloudtrail_s3_prefix}/"
    vpc_flow_logs = var.vpc_flow_logs_destination_type == "s3" ? "s3://${var.s3_bucket_name}/${var.vpc_flow_logs_s3_prefix}/" : null
  }
}

# IAM 역할 정보
output "cloudtrail_cloudwatch_role_arn" {
  description = "CloudTrail CloudWatch 로그 IAM 역할 ARN"
  value       = var.cloudtrail_cloudwatch_logs_enabled ? aws_iam_role.cloudtrail_cloudwatch[0].arn : null
}

output "vpc_flow_log_role_arn" {
  description = "VPC Flow Log IAM 역할 ARN"
  value       = var.enable_vpc_flow_logs ? aws_iam_role.flow_log[0].arn : null
}

# 로그 경로 정보
output "log_destinations" {
  description = "로그 저장 위치 정보"
  value = {
    cloudtrail_s3_path    = var.enable_cloudtrail ? "s3://${var.s3_bucket_name}/${var.cloudtrail_s3_prefix}/" : null
    config_s3_path        = var.enable_aws_config ? "s3://${var.s3_bucket_name}/${var.config_s3_prefix}/" : null
    vpc_flow_logs_s3_path = var.enable_vpc_flow_logs && var.vpc_flow_logs_destination_type == "s3" ? "s3://${var.s3_bucket_name}/${var.vpc_flow_logs_s3_prefix}/" : null
    guardduty_s3_path     = var.guardduty_export_findings_to_s3 ? "s3://${aws_s3_bucket.guardduty_findings[0].id}/" : null
  }
}

# 보안 서비스 상태
output "security_services_status" {
  description = "보안 서비스 활성화 상태"
  value = {
    cloudtrail     = var.enable_cloudtrail
    guardduty      = var.enable_guardduty
    security_hub   = var.enable_security_hub
    aws_config     = var.enable_aws_config
    inspector      = var.enable_inspector
    vpc_flow_logs  = var.enable_vpc_flow_logs
  }
}

# 컴플라이언스 정보
output "compliance_coverage" {
  description = "컴플라이언스 적용 범위"
  value = {
    frameworks_covered = var.compliance_frameworks
    isms_compliant = {
      audit_logging     = var.enable_cloudtrail
      threat_detection  = var.enable_guardduty
      security_monitoring = var.enable_security_hub
      log_retention     = var.security_log_retention_years >= 1
      network_monitoring = var.enable_vpc_flow_logs
    }
    iso27001_controls = {
      access_monitoring = var.enable_cloudtrail
      incident_management = var.enable_guardduty
      vulnerability_management = var.enable_inspector
      configuration_management = var.enable_aws_config
    }
  }
}

# 모니터링 메트릭
output "monitoring_metrics" {
  description = "주요 모니터링 메트릭 정보"
  value = {
    cloudtrail_metrics = {
      namespace = "AWS/CloudTrail"
      metrics   = ["DataEvents", "ManagementEvents", "ErrorCount"]
    }
    guardduty_metrics = {
      namespace = "AWS/GuardDuty"
      metrics   = ["FindingCount"]
    }
    config_metrics = {
      namespace = "AWS/Config"
      metrics   = ["ComplianceByConfigRule", "ComplianceByResourceType"]
    }
  }
}

# 접근 URL 정보
output "console_access_urls" {
  description = "AWS 콘솔 접근 URL"
  value = {
    cloudtrail_console = var.enable_cloudtrail ? "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudtrail/home?region=${data.aws_region.current.name}#/trails/${aws_cloudtrail.main[0].arn}" : null
    guardduty_console  = var.enable_guardduty ? "https://${data.aws_region.current.name}.console.aws.amazon.com/guardduty/home?region=${data.aws_region.current.name}#/findings" : null
    security_hub_console = var.enable_security_hub ? "https://${data.aws_region.current.name}.console.aws.amazon.com/securityhub/home?region=${data.aws_region.current.name}#/findings" : null
    config_console     = var.enable_aws_config ? "https://${data.aws_region.current.name}.console.aws.amazon.com/config/home?region=${data.aws_region.current.name}#/compliance/home" : null
    inspector_console  = var.enable_inspector ? "https://${data.aws_region.current.name}.console.aws.amazon.com/inspector/v2/home?region=${data.aws_region.current.name}#/findings" : null
  }
}

# Splunk 연동 정보
output "splunk_integration_config" {
  description = "Splunk 연동 설정 정보"
  value = var.enable_splunk_integration ? {
    enabled      = true
    hec_endpoint = var.splunk_hec_endpoint
    data_sources = [
      var.enable_cloudtrail ? aws_cloudwatch_log_group.cloudtrail[0].name : null,
      var.enable_vpc_flow_logs && var.vpc_flow_logs_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.vpc_flow_logs[0].name : null
    ]
  } : {
    enabled = false
    hec_endpoint = null
    data_sources = []
  }
}


# 보안 이벤트 정보
output "security_event_sources" {
  description = "보안 이벤트 소스 목록"
  value = compact([
    var.enable_guardduty ? "aws.guardduty" : "",
    var.enable_security_hub ? "aws.securityhub" : "",
    var.enable_aws_config ? "aws.config" : "",
    var.enable_cloudtrail ? "aws.cloudtrail" : "",
    var.enable_inspector ? "aws.inspector2" : ""
  ])
}

# 비용 최적화 정보
output "cost_optimization_settings" {
  description = "비용 최적화 설정"
  value = {
    log_archiving_enabled = var.enable_log_archiving
    archive_after_days    = var.log_archive_after_days
    compression_enabled   = var.enable_log_compression
    retention_years       = var.security_log_retention_years
  }
}

# 자동화 정보
output "automation_config" {
  description = "자동화 설정 정보"
  value = {
    automated_response_enabled = var.enable_automated_response
    auto_isolate_instances     = var.auto_isolate_compromised_instances
    auto_disable_users         = var.auto_disable_compromised_users
    real_time_monitoring       = var.enable_real_time_monitoring
    sensitivity_level          = var.monitoring_sensitivity_level
  }
}

# 알림 설정 정보
output "notification_config" {
  description = "알림 설정 정보"
  value = {
    sns_topic_arn        = var.sns_topic_arn
    emergency_contact    = var.emergency_contact_email
    notification_channels = var.notification_channels
    security_event_monitoring = var.enable_security_event_monitoring
  }
}

# 로그 필터 정보
output "log_filter_patterns" {
  description = "설정된 로그 필터 패턴"
  value = var.cloudtrail_log_filter_patterns
}

# 전체 보안 설정 요약
output "security_posture_summary" {
  description = "전체 보안 태세 요약"
  value = {
    services_enabled = {
      total_services = length([
        var.enable_cloudtrail ? "CloudTrail" : "",
        var.enable_guardduty ? "GuardDuty" : "",
        var.enable_security_hub ? "Security Hub" : "",
        var.enable_aws_config ? "Config" : "",
        var.enable_inspector ? "Inspector" : "",
        var.enable_vpc_flow_logs ? "VPC Flow Logs" : ""
      ])
      active_services = compact([
        var.enable_cloudtrail ? "CloudTrail" : "",
        var.enable_guardduty ? "GuardDuty" : "",
        var.enable_security_hub ? "Security Hub" : "",
        var.enable_aws_config ? "Config" : "",
        var.enable_inspector ? "Inspector" : "",
        var.enable_vpc_flow_logs ? "VPC Flow Logs" : ""
      ])
    }
    compliance_frameworks = var.compliance_frameworks
    security_level        = var.security_level
    environment          = var.environment
    multi_region_enabled = var.enable_multi_region_cloudtrail
  }
}