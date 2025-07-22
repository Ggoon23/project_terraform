# =========================================
# Complete AWS Infrastructure Variables
# =========================================

# 기본 프로젝트 설정
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "WALB"
}

variable "environment" {
  description = "환경 (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "cost_center" {
  description = "비용 센터 태그"
  type        = string
  default     = "default-cost-center"  # 필요시 수정
}

# =========================================
# VPC 네트워크 설정
# =========================================
variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "퍼블릭 서브넷 CIDR 블록들"
  type        = list(string)
  default     = [
    "10.0.1.0/24",
    "10.0.2.0/24",
    "10.0.3.0/24"
  ]
}

variable "private_subnets" {
  description = "프라이빗 서브넷 CIDR 블록들"
  type        = list(string)
  default     = [
    "10.0.10.0/24",
    "10.0.11.0/24",
    "10.0.12.0/24"
  ]
}

variable "database_subnets" {
  description = "데이터베이스 서브넷 CIDR 블록들"
  type        = list(string)
  default     = [
    "10.0.20.0/24",
    "10.0.21.0/24",
    "10.0.22.0/24"
  ]
}

# =========================================
# RDS 데이터베이스 설정
# =========================================
variable "rds_instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "데이터베이스 이름"
  type        = string
  default     = "WALB_DB"
}

variable "db_username" {
  description = "데이터베이스 사용자명"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "데이터베이스 비밀번호"
  type        = string
  sensitive   = true
  default     = "password123!"
  validation {
    condition     = length(var.db_password) >= 8
    error_message = "Database password must be at least 8 characters long."
  }
}

# =========================================
# EKS 클러스터 설정
# =========================================
variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
  default     = ""  # 자동으로 project_name-environment-eks로 생성
}

variable "ec2_key_pair_name" {
  description = "EKS 노드 그룹 SSH 접근용 키 페어 이름"
  type        = string
  default     = null
}

variable "allowed_ssh_cidrs" {
  description = "SSH 접근을 허용할 CIDR 블록들"
  type        = list(string)
  default     = ["10.0.0.0/16"]  # VPC 내부만 허용
}

# =========================================
# Lambda 함수 설정
# =========================================
variable "lambda_runtime" {
  description = "Lambda 함수 런타임"
  type        = string
  default     = "python3.10"
}

variable "lambda_timeout" {
  description = "Lambda 함수 타임아웃 (초)"
  type        = number
  default     = 300
}

variable "lambda_memory_size" {
  description = "Lambda 함수 메모리 크기 (MB)"
  type        = number
  default     = 512
}

# =========================================
# S3 버킷 설정
# =========================================
variable "s3_bucket_prefix" {
  description = "S3 버킷 이름 prefix"
  type        = string
  default     = ""  # 자동으로 project_name-environment로 생성
}

variable "s3_lifecycle_glacier_days" {
  description = "Glacier로 이동할 일수"
  type        = number
  default     = 90
}

variable "s3_lifecycle_deep_archive_days" {
  description = "Deep Archive로 이동할 일수"
  type        = number
  default     = 365
}

# =========================================
# DynamoDB 설정
# =========================================
variable "dynamodb_billing_mode" {
  description = "DynamoDB 빌링 모드"
  type        = string
  default     = "PAY_PER_REQUEST"
  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.dynamodb_billing_mode)
    error_message = "Billing mode must be PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "dynamodb_read_capacity" {
  description = "DynamoDB 읽기 용량 (PROVISIONED 모드일 때)"
  type        = number
  default     = 5
}

variable "dynamodb_write_capacity" {
  description = "DynamoDB 쓰기 용량 (PROVISIONED 모드일 때)"
  type        = number
  default     = 5
}

# =========================================
# 보안 및 모니터링 설정
# =========================================
variable "enable_cloudtrail" {
  description = "CloudTrail 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "GuardDuty 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_security_hub" {
  description = "Security Hub 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "AWS Config 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_vpc_flow_logs" {
  description = "VPC Flow Logs 활성화 여부"
  type        = bool
  default     = true
}

# =========================================
# 알림 설정
# =========================================
variable "alert_email_addresses" {
  description = "보안 알림을 받을 이메일 주소 목록"
  type        = list(string)
  default     = []
}

variable "slack_webhook_url" {
  description = "Slack 웹훅 URL (옵션)"
  type        = string
  default     = ""
  sensitive   = true
}

# =========================================
# 로깅 및 백업 설정
# =========================================
variable "log_retention_days" {
  description = "CloudWatch 로그 보존 기간 (일)"
  type        = number
  default     = 30
}

variable "security_log_retention_days" {
  description = "보안 로그 보존 기간 (일)"
  type        = number
  default     = 90
}

variable "backup_retention_days" {
  description = "백업 보존 기간 (일)"
  type        = number
  default     = 7
}

# =========================================
# 성능 및 용량 설정
# =========================================
variable "eks_node_desired_capacity" {
  description = "EKS 노드 그룹 희망 용량"
  type        = number
  default     = 2
}

variable "eks_node_max_capacity" {
  description = "EKS 노드 그룹 최대 용량"
  type        = number
  default     = 4
}

variable "eks_node_min_capacity" {
  description = "EKS 노드 그룹 최소 용량"
  type        = number
  default     = 1
}

variable "eks_node_instance_types" {
  description = "EKS 노드 그룹 인스턴스 타입"
  type        = list(string)
  default     = ["t3.medium"]
}

# =========================================
# 개발/테스트 설정
# =========================================
variable "enable_dev_features" {
  description = "개발 환경 기능 활성화 (deletion protection 비활성화 등)"
  type        = bool
  default     = true
}

variable "create_test_data" {
  description = "테스트 데이터 생성 여부"
  type        = bool
  default     = false
}

# =========================================
# 비용 최적화 설정
# =========================================
variable "enable_spot_instances" {
  description = "EKS 노드 그룹에서 Spot 인스턴스 사용 여부"
  type        = bool
  default     = false
}

variable "spot_instance_types" {
  description = "Spot 인스턴스 타입 목록"
  type        = list(string)
  default     = ["t3.medium", "t3.large", "m5.large"]
}

variable "enable_auto_scaling" {
  description = "Auto Scaling 활성화 여부"
  type        = bool
  default     = true
}

# =========================================
# 컴플라이언스 및 거버넌스 설정
# =========================================
variable "compliance_standards" {
  description = "준수해야 할 컴플라이언스 표준"
  type        = list(string)
  default     = ["CIS", "AWS-Foundational"]
}

variable "data_classification" {
  description = "데이터 분류 레벨"
  type        = string
  default     = "internal"
  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "Data classification must be public, internal, confidential, or restricted."
  }
}

variable "enable_encryption_at_rest" {
  description = "저장 데이터 암호화 활성화"
  type        = bool
  default     = true
}

variable "enable_encryption_in_transit" {
  description = "전송 데이터 암호화 활성화"
  type        = bool
  default     = true
}

# =========================================
# 네트워크 보안 설정
# =========================================
variable "enable_network_acls" {
  description = "Network ACL 사용 여부"
  type        = bool
  default     = true
}

variable "allowed_external_cidrs" {
  description = "외부 접근을 허용할 CIDR 블록들"
  type        = list(string)
  default     = []  # 기본적으로 외부 접근 차단
}

variable "enable_waf" {
  description = "AWS WAF 활성화 여부"
  type        = bool
  default     = false  # 개발 환경에서는 비용 고려하여 기본 비활성화
}

# =========================================
# 모니터링 및 알람 설정
# =========================================
variable "enable_detailed_monitoring" {
  description = "상세 모니터링 활성화"
  type        = bool
  default     = true
}

variable "cpu_alarm_threshold" {
  description = "CPU 사용률 알람 임계값 (%)"
  type        = number
  default     = 80
}

variable "memory_alarm_threshold" {
  description = "메모리 사용률 알람 임계값 (%)"
  type        = number
  default     = 85
}

variable "disk_alarm_threshold" {
  description = "디스크 사용률 알람 임계값 (%)"
  type        = number
  default     = 90
}

# =========================================
# 백업 및 재해복구 설정
# =========================================
variable "enable_multi_az" {
  description = "Multi-AZ 배포 활성화 (RDS)"
  type        = bool
  default     = false  # 개발 환경에서는 비용 고려
}

variable "enable_cross_region_backup" {
  description = "교차 리전 백업 활성화"
  type        = bool
  default     = false  # 개발 환경에서는 비용 고려
}

variable "backup_schedule" {
  description = "백업 스케줄 (cron 표현식)"
  type        = string
  default     = "cron(0 2 * * ? *)"  # 매일 오전 2시
}

# =========================================
# 로드 밸런서 설정
# =========================================
variable "enable_load_balancer" {
  description = "Application Load Balancer 활성화"
  type        = bool
  default     = true
}

variable "lb_type" {
  description = "로드 밸런서 타입"
  type        = string
  default     = "application"
  validation {
    condition     = contains(["application", "network"], var.lb_type)
    error_message = "Load balancer type must be application or network."
  }
}

variable "ssl_certificate_arn" {
  description = "SSL 인증서 ARN (HTTPS 사용 시)"
  type        = string
  default     = ""
}

# =========================================
# 애플리케이션 설정
# =========================================
variable "application_port" {
  description = "애플리케이션 포트"
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "헬스 체크 경로"
  type        = string
  default     = "/health"
}

variable "application_image" {
  description = "EKS에 배포할 애플리케이션 컨테이너 이미지"
  type        = string
  default     = ""
}

# =========================================
# 외부 서비스 연동 설정
# =========================================
variable "splunk_hec_endpoint" {
  description = "Splunk HEC 엔드포인트 URL"
  type        = string
  default     = ""
  sensitive   = true
}

variable "splunk_hec_token" {
  description = "Splunk HEC 토큰"
  type        = string
  default     = ""
  sensitive   = true
}

variable "external_siem_endpoint" {
  description = "외부 SIEM 시스템 엔드포인트"
  type        = string
  default     = ""
}

# =========================================
# 태그 설정
# =========================================
variable "additional_tags" {
  description = "추가 태그"
  type        = map(string)
  default     = {}
}

variable "owner" {
  description = "리소스 소유자"
  type        = string
  default     = "DevSecOps Team"
}

# =========================================
# 개발자 설정
# =========================================
variable "developer_access_cidrs" {
  description = "개발자 접근을 허용할 CIDR 블록들"
  type        = list(string)
  default     = []
}

variable "enable_bastion_host" {
  description = "Bastion Host 생성 여부"
  type        = bool
  default     = false  # 보안상 기본 비활성화
}

variable "bastion_instance_type" {
  description = "Bastion Host 인스턴스 타입"
  type        = string
  default     = "t3.nano"
}

# =========================================
# 환경별 설정 오버라이드
# =========================================
locals {
  # 환경별 기본값 설정
  environment_defaults = {
    dev = {
      instance_class           = "db.t3.micro"
      node_desired_capacity   = 1
      node_max_capacity       = 2
      enable_deletion_protection = false
      backup_retention_days   = 3
      log_retention_days      = 7
    }
    staging = {
      instance_class           = "db.t3.small"
      node_desired_capacity   = 2
      node_max_capacity       = 3
      enable_deletion_protection = false
      backup_retention_days   = 7
      log_retention_days      = 14
    }
    prod = {
      instance_class           = "db.t3.medium"
      node_desired_capacity   = 3
      node_max_capacity       = 10
      enable_deletion_protection = true
      backup_retention_days   = 30
      log_retention_days      = 90
    }
  }

  # 현재 환경의 설정 적용
  current_env_config = local.environment_defaults[var.environment]
}

variable "availability_zones" {
  description = "사용할 가용 영역 목록"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2b"]
}

variable "db_user" {
  description = "데이터베이스 사용자명"
  type        = string
  default     = "dbadmin"
}