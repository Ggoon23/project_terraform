# infrastructure/terraform/modules/rds/variables.tf
# RDS 모듈 변수 정의

# 필수 변수
variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "database_subnet_ids" {
  description = "데이터베이스 서브넷 ID 목록"
  type        = list(string)
}

# 데이터베이스 기본 설정
variable "db_identifier" {
  description = "RDS 인스턴스 식별자"
  type        = string
  default     = "my-rds-database"
}

variable "engine" {
  description = "데이터베이스 엔진"
  type        = string
  default     = "mysql"
  validation {
    condition     = contains(["postgres", "mysql", "mariadb"], var.engine)
    error_message = "지원되는 엔진: postgres, mysql, mariadb"
  }
}

variable "engine_version" {
  description = "데이터베이스 엔진 버전"
  type        = string
  default     = "8.0.36"
}

variable "instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
  default     = "db.t3.medium"
}

variable "allocated_storage" {
  description = "할당된 스토리지 크기 (GB)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "최대 할당 스토리지 크기 (GB)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "스토리지 타입"
  type        = string
  default     = "gp2"
  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.storage_type)
    error_message = "유효한 스토리지 타입: gp2, gp3, io1, io2"
  }
}

# 데이터베이스 접속 정보
variable "database_name" {
  description = "초기 데이터베이스 이름"
  type        = string
  default     = "appdb"
}

variable "master_username" {
  description = "마스터 사용자 이름"
  type        = string
  default     = "admin"
}

variable "master_password" {
  description = "마스터 사용자 비밀번호"
  type        = string
  sensitive   = true
}

variable "port" {
  description = "데이터베이스 포트"
  type        = number
  default     = 3306
}

# 보안 설정
variable "allowed_security_groups" {
  description = "접근 허용할 보안 그룹 ID 목록"
  type        = list(string)
  default     = []
}

variable "allowed_cidr_blocks" {
  description = "접근 허용할 CIDR 블록 목록"
  type        = list(string)
  default     = []
}

# 고가용성 및 백업
variable "multi_az" {
  description = "Multi-AZ 배포 활성화"
  type        = bool
  default     = true
}

variable "availability_zone" {
  description = "단일 AZ 배포 시 사용할 가용영역"
  type        = string
  default     = null
}

variable "backup_retention_period" {
  description = "백업 보관 기간 (일)"
  type        = number
  default     = 7
  validation {
    condition     = var.backup_retention_period >= 0 && var.backup_retention_period <= 35
    error_message = "백업 보관 기간은 0-35일 사이여야 합니다."
  }
}

variable "backup_window" {
  description = "백업 시간 윈도우 (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "유지보수 시간 윈도우 (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "delete_automated_backups" {
  description = "인스턴스 삭제 시 자동 백업 삭제 여부"
  type        = bool
  default     = false
}

# 모니터링 설정 (ISMS-P 컴플라이언스)
variable "monitoring_interval" {
  description = "Enhanced Monitoring 간격 (초)"
  type        = number
  default     = 60
  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "유효한 모니터링 간격: 0, 1, 5, 10, 15, 30, 60"
  }
}

variable "performance_insights_enabled" {
  description = "Performance Insights 활성화"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights 데이터 보관 기간 (일)"
  type        = number
  default     = 7
  validation {
    condition     = contains([7, 731], var.performance_insights_retention_period)
    error_message = "Performance Insights 보관 기간: 7일 또는 731일"
  }
}

variable "enabled_cloudwatch_logs_exports" {
  description = "CloudWatch로 내보낼 로그 타입 목록"
  type        = list(string)
  default     = ["error", "general", "slowquery"]
}

variable "log_retention_days" {
  description = "CloudWatch 로그 보관 일수"
  type        = number
  default     = 30
}

# 암호화 설정
variable "create_kms_key" {
  description = "RDS 암호화용 KMS 키 생성 여부"
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
}

# 데이터베이스 파라미터
variable "db_family" {
  description = "DB 파라미터 그룹 패밀리"
  type        = string
  default     = "mysql8.0"
}

variable "db_parameters" {
  description = "데이터베이스 파라미터 목록"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

# 옵션 그룹
variable "create_option_group" {
  description = "DB 옵션 그룹 생성 여부"
  type        = bool
  default     = false
}

variable "major_engine_version" {
  description = "주요 엔진 버전 (옵션 그룹용)"
  type        = string
  default     = "8.0"
}

# 읽기 전용 복제본
variable "create_read_replica" {
  description = "읽기 전용 복제본 생성 여부"
  type        = bool
  default     = false
}

variable "replica_instance_class" {
  description = "읽기 전용 복제본 인스턴스 클래스"
  type        = string
  default     = "db.t3.micro"
}

# 기타 설정
variable "deletion_protection" {
  description = "삭제 보호 활성화"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "최종 스냅샷 건너뛰기"
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "자동 마이너 버전 업그레이드"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "변경사항 즉시 적용"
  type        = bool
  default     = false
}

variable "allow_major_version_upgrade" {
  description = "주요 버전 업그레이드 허용"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "공통 태그"
  type        = map(string)
  default     = {}
}