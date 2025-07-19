# infrastructure/terraform/modules/vpc/variables.tf
# VPC 모듈 변수 정의

variable "project_name" {
  description = "프로젝트 이름 (리소스 명명에 사용)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "프로젝트 이름은 소문자, 숫자, 하이픈만 포함할 수 있습니다."
  }
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

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "유효한 CIDR 블록 형식이어야 합니다."
  }
}

variable "public_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR 블록 목록"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "고가용성을 위해 최소 2개의 퍼블릭 서브넷이 필요합니다."
  }
}

variable "private_subnet_cidrs" {
  description = "프라이빗 서브넷 CIDR 블록 목록"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.20.0/24"]
  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "고가용성을 위해 최소 2개의 프라이빗 서브넷이 필요합니다."
  }
}

variable "database_subnet_cidrs" {
  description = "데이터베이스 서브넷 CIDR 블록 목록"
  type        = list(string)
  default     = ["10.0.100.0/24", "10.0.110.0/24"]
  validation {
    condition     = length(var.database_subnet_cidrs) >= 2
    error_message = "고가용성을 위해 최소 2개의 DB 서브넷이 필요합니다."
  }
}

variable "enable_nat_gateway" {
  description = "NAT Gateway 활성화 여부"
  type        = bool
  default     = true
}

variable "enable_vpc_flow_logs" {
  description = "VPC Flow Logs 활성화 여부 (보안 모니터링)"
  type        = bool
  default     = true
}

variable "flow_log_retention_days" {
  description = "VPC Flow Logs 보관 일수"
  type        = number
  default     = 30
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.flow_log_retention_days)
    error_message = "유효하지 않은 로그 보관 일수입니다."
  }
}

variable "common_tags" {
  description = "모든 리소스에 적용할 공통 태그"
  type        = map(string)
  default = {
    Terraform   = "true"
    Project     = "security-monitoring"
    Owner       = "Team2"
    Environment = "dev"
  }
}

# ISMS-P 컴플라이언스 관련 변수
variable "enable_isms_compliance" {
  description = "ISMS-P 컴플라이언스 보안 설정 활성화"
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "접근 허용할 CIDR 블록 목록 (보안 그룹용)"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

# 네트워크 ACL 관련 변수
variable "enable_network_acls" {
  description = "추가 네트워크 ACL 활성화 여부"
  type        = bool
  default     = true
}

# DNS 설정
variable "enable_dns_hostnames" {
  description = "VPC 내 DNS 호스트네임 활성화"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "VPC 내 DNS 해석 활성화"
  type        = bool
  default     = true
}