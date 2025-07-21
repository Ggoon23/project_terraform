# infrastructure/terraform/modules/security-log-collectors/variables.tf
# 보안 로그 수집기 모듈 변수 정의

# 필수 변수
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "s3_bucket_name" {
  description = "로그 저장용 S3 버킷 이름"
  type        = string
}

variable "kms_key_arn" {
  description = "암호화용 KMS 키 ARN"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID (VPC Flow Logs용)"
  type        = string
  default     = null
}

# CloudTrail 설정
variable "enable_cloudtrail" {
  description = "CloudTrail 활성화"
  type        = bool
  default     = true
}

variable "cloudtrail_s3_prefix" {
  description = "CloudTrail S3 로그 접두사"
  type        = string
  default     = "cloudtrail"
}

variable "cloudtrail_data_events_enabled" {
  description = "CloudTrail 데이터 이벤트 로깅 활성화"
  type        = bool
  default     = true
}

variable "cloudtrail_s3_data_events" {
  description = "모니터링할 S3 버킷 ARN 목록"
  type        = list(string)
  default     = ["arn:aws:s3:::*/*"]
}

variable "cloudtrail_lambda_data_events" {
  description = "모니터링할 Lambda 함수 ARN 목록"
  type        = list(string)
  default     = ["arn:aws:lambda:*:*:function:*"]
}

variable "cloudtrail_exclude_management_events" {
  description = "제외할 관리 이벤트 소스 목록"
  type        = list(string)
  default     = []
}

variable "cloudtrail_cloudwatch_logs_enabled" {
  description = "CloudTrail CloudWatch Logs 통합 활성화"
  type        = bool
  default     = true
}

variable "cloudtrail_log_retention_days" {
  description = "CloudTrail CloudWatch 로그 보관 일수"
  type        = number
  default     = 365
}

# GuardDuty 설정
variable "enable_guardduty" {
  description = "GuardDuty 활성화"
  type        = bool
  default     = true
}

variable "guardduty_s3_protection" {
  description = "GuardDuty S3 보호 활성화"
  type        = bool
  default     = true
}

variable "guardduty_kubernetes_protection" {
  description = "GuardDuty Kubernetes 보호 활성화"
  type        = bool
  default     = true
}

variable "guardduty_malware_protection" {
  description = "GuardDuty 맬웨어 보호 활성화"
  type        = bool
  default     = true
}

variable "guardduty_finding_publishing_frequency" {
  description = "GuardDuty Finding 게시 빈도"
  type        = string
  default     = "FIFTEEN_MINUTES"
  validation {
    condition = contains([
      "FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"
    ], var.guardduty_finding_publishing_frequency)
    error_message = "유효한 게시 빈도: FIFTEEN_MINUTES, ONE_HOUR, SIX_HOURS"
  }
}

variable "guardduty_export_findings_to_s3" {
  description = "GuardDuty Finding을 S3로 내보내기"
  type        = bool
  default     = false
}

# Security Hub 설정
variable "enable_security_hub" {
  description = "Security Hub 활성화"
  type        = bool
  default     = true
}

variable "security_hub_enable_default_standards" {
  description = "Security Hub 기본 표준 활성화"
  type        = bool
  default     = true
}

variable "security_hub_control_finding_generator" {
  description = "Security Hub 제어 Finding 생성기"
  type        = string
  default     = "SECURITY_CONTROL"
  validation {
    condition     = contains(["SECURITY_CONTROL", "STANDARD_CONTROL"], var.security_hub_control_finding_generator)
    error_message = "유효한 Finding 생성기: SECURITY_CONTROL, STANDARD_CONTROL"
  }
}

variable "security_hub_enable_aws_foundational" {
  description = "AWS Foundational Security Best Practices 표준 활성화"
  type        = bool
  default     = true
}

variable "security_hub_enable_cis" {
  description = "CIS AWS Foundations Benchmark 표준 활성화"
  type        = bool
  default     = true
}

variable "security_hub_enable_pci_dss" {
  description = "PCI DSS 표준 활성화"
  type        = bool
  default     = false
}

# AWS Config 설정
variable "enable_aws_config" {
  description = "AWS Config 활성화"
  type        = bool
  default     = true
}

variable "config_s3_prefix" {
  description = "AWS Config S3 로그 접두사"
  type        = string
  default     = "aws-config"
}

variable "config_delivery_frequency" {
  description = "AWS Config 스냅샷 전송 빈도"
  type        = string
  default     = "TwentyFour_Hours"
  validation {
    condition = contains([
      "One_Hour", "Three_Hours", "Six_Hours", "Twelve_Hours", "TwentyFour_Hours"
    ], var.config_delivery_frequency)
    error_message = "유효한 전송 빈도를 선택해주세요."
  }
}

# AWS Inspector 설정
variable "enable_inspector" {
  description = "AWS Inspector V2 활성화"
  type        = bool
  default     = true
}

variable "inspector_resource_types" {
  description = "Inspector가 스캔할 리소스 타입"
  type        = list(string)
  default     = ["ECR", "EC2"]
  validation {
    condition = alltrue([
      for type in var.inspector_resource_types :
      contains(["ECR", "EC2", "LAMBDA"], type)
    ])
    error_message = "유효한 리소스 타입: ECR, EC2, LAMBDA"
  }
}

# VPC Flow Logs 설정
variable "enable_vpc_flow_logs" {
  description = "VPC Flow Logs 활성화"
  type        = bool
  default     = true
}

variable "vpc_flow_logs_traffic_type" {
  description = "VPC Flow Logs 트래픽 타입"
  type        = string
  default     = "ALL"
  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.vpc_flow_logs_traffic_type)
    error_message = "트래픽 타입: ACCEPT, REJECT, ALL"
  }
}

variable "vpc_flow_logs_destination_type" {
  description = "VPC Flow Logs 대상 타입"
  type        = string
  default     = "s3"
  validation {
    condition     = contains(["cloud-watch-logs", "s3"], var.vpc_flow_logs_destination_type)
    error_message = "대상 타입: cloud-watch-logs, s3"
  }
}

variable "vpc_flow_logs_s3_prefix" {
  description = "VPC Flow Logs S3 접두사"
  type        = string
  default     = "vpc-flow-logs"
}

variable "vpc_flow_logs_retention_days" {
  description = "VPC Flow Logs CloudWatch 보관 일수"
  type        = number
  default     = 30
}

variable "vpc_flow_logs_file_format" {
  description = "VPC Flow Logs 파일 형식 (S3용)"
  type        = string
  default     = "plain-text"
  validation {
    condition     = contains(["plain-text", "parquet"], var.vpc_flow_logs_file_format)
    error_message = "파일 형식: plain-text, parquet"
  }
}

variable "vpc_flow_logs_hive_compatible_partitions" {
  description = "Hive 호환 파티션 사용"
  type        = bool
  default     = false
}

variable "vpc_flow_logs_per_hour_partition" {
  description = "시간별 파티션 사용"
  type        = bool
  default     = false
}

# 이벤트 모니터링
variable "enable_security_event_monitoring" {
  description = "보안 이벤트 모니터링 활성화"
  type        = bool
  default     = true
}

variable "sns_topic_arn" {
  description = "보안 알람 전송용 SNS 토픽 ARN"
  type        = string
  default     = null
}

# 대시보드 설정
variable "create_security_dashboard" {
  description = "보안 CloudWatch 대시보드 생성"
  type        = bool
  default     = true
}

# 커스텀 이벤트 버스
variable "create_custom_event_bus" {
  description = "보안 이벤트용 커스텀 EventBridge 버스 생성"
  type        = bool
  default     = false
}

# 알람 설정
variable "enable_cloudtrail_alarms" {
  description = "CloudTrail 관련 CloudWatch 알람 활성화"
  type        = bool
  default     = true
}

variable "enable_guardduty_alarms" {
  description = "GuardDuty 관련 CloudWatch 알람 활성화"
  type        = bool
  default     = true
}

variable "enable_config_alarms" {
  description = "AWS Config 관련 CloudWatch 알람 활성화"
  type        = bool
  default     = true
}

# 고급 설정
variable "cloudtrail_insight_types" {
  description = "CloudTrail Insights 타입"
  type        = list(string)
  default     = ["ApiCallRateInsight"]
  validation {
    condition = alltrue([
      for type in var.cloudtrail_insight_types :
      contains(["ApiCallRateInsight"], type)
    ])
    error_message = "유효한 Insight 타입: ApiCallRateInsight"
  }
}

variable "cloudtrail_insights_enabled" {
  description = "CloudTrail Insights 활성화"
  type        = bool
  default     = false
}

# 멀티 리전 설정
variable "enable_multi_region_cloudtrail" {
  description = "멀티 리전 CloudTrail 활성화"
  type        = bool
  default     = true
}

variable "enable_global_service_events" {
  description = "글로벌 서비스 이벤트 포함"
  type        = bool
  default     = true
}

# 데이터 이벤트 세부 설정
variable "s3_bucket_arns_for_logging" {
  description = "로깅할 특정 S3 버킷 ARN 목록"
  type        = list(string)
  default     = []
}

variable "lambda_function_arns_for_logging" {
  description = "로깅할 특정 Lambda 함수 ARN 목록"
  type        = list(string)
  default     = []
}

# GuardDuty 멤버 계정 설정
variable "guardduty_member_accounts" {
  description = "GuardDuty 멤버 계정 목록"
  type = list(object({
    account_id = string
    email      = string
    invite     = bool
  }))
  default = []
}

variable "guardduty_master_account_id" {
  description = "GuardDuty 마스터 계정 ID (멤버 계정에서 설정)"
  type        = string
  default     = null
}

# Security Hub 멤버 계정 설정
variable "security_hub_member_accounts" {
  description = "Security Hub 멤버 계정 목록"
  type = list(object({
    account_id = string
    email      = string
  }))
  default = []
}

# 알람 임계값 설정
variable "cloudtrail_error_threshold" {
  description = "CloudTrail 에러 알람 임계값"
  type        = number
  default     = 1
}

variable "guardduty_high_severity_threshold" {
  description = "GuardDuty 높은 심각도 Finding 임계값"
  type        = number
  default     = 1
}

variable "config_compliance_threshold" {
  description = "AWS Config 규정 준수 임계값 (%)"
  type        = number
  default     = 95
}

# 로그 필터링
variable "cloudtrail_log_filter_patterns" {
  description = "CloudTrail 로그 필터 패턴 목록"
  type = list(object({
    name    = string
    pattern = string
  }))
  default = [
    {
      name    = "RootAccountUsage"
      pattern = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
    },
    {
      name    = "UnauthorizedAPICalls"
      pattern = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
    },
    {
      name    = "ConsoleLoginWithoutMFA"
      pattern = "{ ($.eventName = \"ConsoleLogin\") && ($.additionalEventData.MFAUsed != \"Yes\") }"
    }
  ]
}

# 보고서 설정
variable "enable_security_reports" {
  description = "주기적 보안 보고서 생성 활성화"
  type        = bool
  default     = false
}

variable "security_report_frequency" {
  description = "보안 보고서 생성 주기"
  type        = string
  default     = "Weekly"
  validation {
    condition     = contains(["Daily", "Weekly", "Monthly"], var.security_report_frequency)
    error_message = "보고서 주기: Daily, Weekly, Monthly"
  }
}

# 자동 응답 설정
variable "enable_automated_response" {
  description = "자동화된 보안 응답 활성화"
  type        = bool
  default     = false
}

variable "auto_isolate_compromised_instances" {
  description = "침해된 인스턴스 자동 격리"
  type        = bool
  default     = false
}

variable "auto_disable_compromised_users" {
  description = "침해된 사용자 자동 비활성화"
  type        = bool
  default     = false
}

# 서드파티 통합
variable "enable_splunk_integration" {
  description = "Splunk 통합 활성화"
  type        = bool
  default     = false
}

variable "splunk_hec_endpoint" {
  description = "Splunk HEC 엔드포인트"
  type        = string
  default     = null
}

variable "splunk_hec_token" {
  description = "Splunk HEC 토큰"
  type        = string
  default     = null
  sensitive   = true
}

# 비용 최적화 설정
variable "enable_log_archiving" {
  description = "로그 아카이빙 활성화 (비용 절감)"
  type        = bool
  default     = true
}

variable "log_archive_after_days" {
  description = "로그 아카이빙까지 일수"
  type        = number
  default     = 90
}

variable "enable_log_compression" {
  description = "로그 압축 활성화"
  type        = bool
  default     = true
}

# 컴플라이언스 설정
variable "compliance_frameworks" {
  description = "준수할 컴플라이언스 프레임워크 목록"
  type        = list(string)
  default     = ["ISMS-P", "ISO27001", "CIS"]
  validation {
    condition = alltrue([
      for framework in var.compliance_frameworks :
      contains(["ISMS-P", "ISO27001", "CIS", "PCI-DSS", "SOC2", "NIST"], framework)
    ])
    error_message = "지원되는 프레임워크: ISMS-P, ISO27001, CIS, PCI-DSS, SOC2, NIST"
  }
}

variable "enable_compliance_monitoring" {
  description = "컴플라이언스 모니터링 활성화"
  type        = bool
  default     = true
}

# 데이터 보존 정책
variable "security_log_retention_years" {
  description = "보안 로그 보존 연수 (ISMS-P: 최소 1년)"
  type        = number
  default     = 3
  validation {
    condition     = var.security_log_retention_years >= 1
    error_message = "ISMS-P 컴플라이언스를 위해 최소 1년 보존 필요"
  }
}

# 모니터링 세부 설정
variable "enable_real_time_monitoring" {
  description = "실시간 보안 모니터링 활성화"
  type        = bool
  default     = true
}

variable "monitoring_sensitivity_level" {
  description = "모니터링 민감도 수준"
  type        = string
  default     = "HIGH"
  validation {
    condition     = contains(["LOW", "MEDIUM", "HIGH"], var.monitoring_sensitivity_level)
    error_message = "민감도 수준: LOW, MEDIUM, HIGH"
  }
}

# 알림 설정
variable "notification_channels" {
  description = "알림 채널 목록"
  type = list(object({
    type     = string
    endpoint = string
    severity = list(string)
  }))
  default = []
}

variable "emergency_contact_email" {
  description = "응급 상황 연락처 이메일"
  type        = string
  default     = null
}

# 태그
variable "common_tags" {
  description = "공통 태그"
  type        = map(string)
  default = {
    Terraform   = "true"
    Project     = "security-monitoring"
    Environment = "prod"
    Purpose     = "Security Logging"
  }
}

# 환경별 설정
variable "environment" {
  description = "환경 구분"
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "환경: dev, staging, prod"
  }
}

# 보안 등급
variable "security_level" {
  description = "보안 등급 (로깅 상세도 결정)"
  type        = string
  default     = "HIGH"
  validation {
    condition     = contains(["BASIC", "STANDARD", "HIGH", "MAXIMUM"], var.security_level)
    error_message = "보안 등급: BASIC, STANDARD, HIGH, MAXIMUM"
  }
}