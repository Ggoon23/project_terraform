# infrastructure/terraform/modules/s3/variables.tf
# S3 모듈 변수 정의

# 필수 변수
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "environment" {
  description = "환경 구분 (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "환경은 dev, staging, prod 중 하나여야 합니다."
  }
}

# 버킷 생성 옵션
variable "create_artifacts_bucket" {
  description = "아티팩트 버킷 생성 여부"
  type        = bool
  default     = true
}

variable "create_backups_bucket" {
  description = "백업 버킷 생성 여부"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "버킷 강제 삭제 허용 (개발 환경용)"
  type        = bool
  default     = false
}

# 암호화 설정
variable "create_kms_key" {
  description = "S3 암호화용 KMS 키 생성 여부"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "기존 KMS 키 ID (create_kms_key가 false일 때 사용)"
  type        = string
  default     = null
}

variable "kms_deletion_window" {
  description = "KMS 키 삭제 대기 기간 (일)"
  type        = number
  default     = 7
  validation {
    condition     = var.kms_deletion_window >= 7 && var.kms_deletion_window <= 30
    error_message = "KMS 키 삭제 대기 기간은 7-30일 사이여야 합니다."
  }
}

# 버전 관리
variable "enable_versioning" {
  description = "S3 버킷 버전 관리 활성화"
  type        = bool
  default     = true
}

# 라이프사이클 정책 (로그 버킷)
variable "transition_to_ia_days" {
  description = "Standard-IA로 전환할 일수"
  type        = number
  default     = 30
}

variable "transition_to_glacier_days" {
  description = "Glacier로 전환할 일수"
  type        = number
  default     = 90
}

variable "transition_to_deep_archive_days" {
  description = "Deep Archive로 전환할 일수"
  type        = number
  default     = 180
}

variable "log_retention_days" {
  description = "로그 보관 일수 (ISMS-P 컴플라이언스: 최소 365일)"
  type        = number
  default     = 365
  validation {
    condition     = var.log_retention_days >= 365
    error_message = "ISMS-P 컴플라이언스를 위해 로그는 최소 365일 보관해야 합니다."
  }
}

variable "backup_retention_days" {
  description = "백업 보관 일수"
  type        = number
  default     = 2555  # 7년
}

# 액세스 로깅 (ISMS-P 컴플라이언스)
variable "enable_access_logging" {
  description = "S3 액세스 로깅 활성화"
  type        = bool
  default     = true
}

# CloudWatch 연동
variable "enable_cloudwatch_events" {
  description = "CloudWatch Events 연동 활성화"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_monitoring" {
  description = "CloudWatch 메트릭 모니터링 활성화"
  type        = bool
  default     = true
}

variable "s3_size_alarm_threshold" {
  description = "S3 버킷 크기 알람 임계값 (바이트)"
  type        = number
  default     = 107374182400  # 100GB
}

variable "sns_topic_arn" {
  description = "알람 전송용 SNS 토픽 ARN"
  type        = string
  default     = null
}

# 버킷 정책 설정
variable "allowed_principals" {
  description = "버킷 접근 허용할 IAM 주체 목록"
  type        = list(string)
  default     = []
}

variable "enable_cross_region_replication" {
  description = "교차 리전 복제 활성화"
  type        = bool
  default     = false
}

variable "replication_destination_bucket" {
  description = "복제 대상 버킷 ARN"
  type        = string
  default     = null
}

variable "replication_role_arn" {
  description = "복제용 IAM 역할 ARN"
  type        = string
  default     = null
}

# 보안 설정
variable "enable_mfa_delete" {
  description = "MFA 삭제 보호 활성화 (루트 계정 전용)"
  type        = bool
  default     = false
}

variable "enable_object_lock" {
  description = "S3 Object Lock 활성화 (백업 보호)"
  type        = bool
  default     = false
}

variable "object_lock_days" {
  description = "Object Lock 보관 일수"
  type        = number
  default     = 365
}

# 성능 설정
variable "enable_transfer_acceleration" {
  description = "전송 가속화 활성화"
  type        = bool
  default     = false
}

variable "enable_requester_pays" {
  description = "요청자 지불 활성화"
  type        = bool
  default     = false
}

# CORS 설정
variable "enable_cors" {
  description = "CORS 설정 활성화"
  type        = bool
  default     = false
}

variable "cors_rules" {
  description = "CORS 규칙 목록"
  type = list(object({
    allowed_headers = list(string)
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = list(string)
    max_age_seconds = number
  }))
  default = []
}

# 웹사이트 호스팅
variable "enable_website_hosting" {
  description = "웹사이트 호스팅 활성화"
  type        = bool
  default     = false
}

variable "index_document" {
  description = "인덱스 문서"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "에러 문서"
  type        = string
  default     = "error.html"
}

# 인벤토리 설정
variable "enable_inventory" {
  description = "S3 인벤토리 활성화"
  type        = bool
  default     = false
}

variable "inventory_frequency" {
  description = "인벤토리 생성 주기"
  type        = string
  default     = "Daily"
  validation {
    condition     = contains(["Daily", "Weekly"], var.inventory_frequency)
    error_message = "인벤토리 주기는 Daily 또는 Weekly여야 합니다."
  }
}

# 분석 설정
variable "enable_analytics" {
  description = "S3 스토리지 클래스 분석 활성화"
  type        = bool
  default     = false
}

# 지능형 계층화
variable "enable_intelligent_tiering" {
  description = "S3 Intelligent Tiering 활성화"
  type        = bool
  default     = true
}

# 멀티파트 업로드 설정
variable "multipart_upload_threshold" {
  description = "멀티파트 업로드 임계값 (MB)"
  type        = number
  default     = 64
}

variable "multipart_upload_chunk_size" {
  description = "멀티파트 업로드 청크 크기 (MB)"
  type        = number
  default     = 16
}

# 태그
variable "common_tags" {
  description = "공통 태그"
  type        = map(string)
  default = {
    Terraform   = "true"
    Project     = "security-monitoring"
    Environment = "dev"
  }
}

# 특수 설정
variable "enable_event_notifications" {
  description = "S3 이벤트 알림 활성화"
  type        = bool
  default     = true
}

variable "lambda_function_arn" {
  description = "이벤트 처리용 Lambda 함수 ARN"
  type        = string
  default     = null
}

variable "sqs_queue_arn" {
  description = "이벤트 처리용 SQS 큐 ARN"
  type        = string
  default     = null
}

# 데이터 분류 태그
variable "data_classification" {
  description = "데이터 분류 (public, internal, confidential, restricted)"
  type        = string
  default     = "internal"
  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "유효한 데이터 분류: public, internal, confidential, restricted"
  }
}

# 컴플라이언스 설정
variable "compliance_requirements" {
  description = "컴플라이언스 요구사항 목록"
  type        = list(string)
  default     = ["ISMS-P", "ISO27001"]
}

# 백업 설정
variable "enable_cross_account_backup" {
  description = "교차 계정 백업 활성화"
  type        = bool
  default     = false
}

variable "backup_account_id" {
  description = "백업 대상 AWS 계정 ID"
  type        = string
  default     = null
}