# infrastructure/terraform/modules/eks/variables.tf
# EKS 모듈 변수 정의

# 필수 변수
variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "EKS 클러스터용 서브넷 ID 목록 (퍼블릭 + 프라이빗)"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "노드 그룹용 프라이빗 서브넷 ID 목록"
  type        = list(string)
}

# 클러스터 설정
variable "cluster_version" {
  description = "EKS 클러스터 버전"
  type        = string
  default     = "1.28"
}

variable "cluster_endpoint_private_access" {
  description = "프라이빗 API 서버 엔드포인트 활성화"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "퍼블릭 API 서버 엔드포인트 활성화"
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "퍼블릭 API 엔드포인트 접근 허용 CIDR 목록"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_endpoint_private_access_cidrs" {
  description = "프라이빗 API 엔드포인트 접근 허용 CIDR 목록"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

# 로깅 설정 (ISMS-P 컴플라이언스)
variable "cluster_enabled_log_types" {
  description = "활성화할 클러스터 로그 타입 목록"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  validation {
    condition = alltrue([
      for log_type in var.cluster_enabled_log_types :
      contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "유효한 로그 타입: api, audit, authenticator, controllerManager, scheduler"
  }
}

variable "log_retention_days" {
  description = "CloudWatch 로그 보관 일수"
  type        = number
  default     = 30
}

# 암호화 설정
variable "kms_deletion_window" {
  description = "KMS 키 삭제 대기 기간 (일)"
  type        = number
  default     = 7
}

# 노드 그룹 설정
variable "node_group_name" {
  description = "EKS 노드 그룹 이름"
  type        = string
  default     = "main"
}

variable "instance_types" {
  description = "노드 그룹 인스턴스 타입 목록"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "capacity_type" {
  description = "노드 그룹 용량 타입"
  type        = string
  default     = "ON_DEMAND"
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "용량 타입은 ON_DEMAND 또는 SPOT이어야 합니다."
  }
}

variable "ami_type" {
  description = "노드 그룹 AMI 타입"
  type        = string
  default     = "AL2_x86_64"
  validation {
    condition = contains([
      "AL2_x86_64", "AL2_x86_64_GPU", "AL2_ARM_64",
      "CUSTOM", "BOTTLEROCKET_ARM_64", "BOTTLEROCKET_x86_64"
    ], var.ami_type)
    error_message = "유효하지 않은 AMI 타입입니다."
  }
}

variable "disk_size" {
  description = "노드 디스크 크기 (GB)"
  type        = number
  default     = 20
}

# 스케일링 설정
variable "desired_size" {
  description = "노드 그룹 원하는 크기"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "노드 그룹 최대 크기"
  type        = number
  default     = 4
}

variable "min_size" {
  description = "노드 그룹 최소 크기"
  type        = number
  default     = 1
}

variable "max_unavailable_percentage" {
  description = "업데이트 시 사용 불가능한 노드 최대 비율"
  type        = number
  default     = 25
}

# 원격 접근 설정
variable "enable_ssh_access" {
  description = "SSH 접근 활성화"
  type        = bool
  default     = false
}

variable "key_name" {
  description = "EC2 키 페어 이름 (SSH 접근용)"
  type        = string
  default     = null
}

variable "ssh_access_cidrs" {
  description = "SSH 접근 허용 CIDR 목록"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

# 시작 템플릿 설정
variable "create_launch_template" {
  description = "시작 템플릿 생성 여부"
  type        = bool
  default     = false
}

variable "ami_id" {
  description = "사용자 정의 AMI ID"
  type        = string
  default     = null
}

variable "ebs_volume_type" {
  description = "EBS 볼륨 타입"
  type        = string
  default     = "gp3"
}

variable "ebs_volume_size" {
  description = "EBS 볼륨 크기 (GB)"
  type        = number
  default     = 20
}

# 노드 그룹 테인트
variable "node_group_taints" {
  description = "노드 그룹 테인트 목록"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

# EKS 애드온 설정
variable "enable_vpc_cni_addon" {
  description = "VPC CNI 애드온 활성화"
  type        = bool
  default     = true
}

variable "vpc_cni_addon_version" {
  description = "VPC CNI 애드온 버전"
  type        = string
  default     = null
}

variable "enable_coredns_addon" {
  description = "CoreDNS 애드온 활성화"
  type        = bool
  default     = true
}

variable "coredns_addon_version" {
  description = "CoreDNS 애드온 버전"
  type        = string
  default     = null
}

variable "enable_kube_proxy_addon" {
  description = "kube-proxy 애드온 활성화"
  type        = bool
  default     = true
}

variable "kube_proxy_addon_version" {
  description = "kube-proxy 애드온 버전"
  type        = string
  default     = null
}

# IRSA (IAM Roles for Service Accounts)
variable "enable_irsa" {
  description = "IRSA 활성화 (OIDC Provider 생성)"
  type        = bool
  default     = true
}

# 보안 설정
variable "enable_pod_security_policy" {
  description = "Pod Security Policy 활성화"
  type        = bool
  default     = false
}

variable "enable_network_policy" {
  description = "네트워크 정책 활성화"
  type        = bool
  default     = true
}

# 모니터링 설정
variable "enable_cluster_autoscaler" {
  description = "Cluster Autoscaler 활성화"
  type        = bool
  default     = true
}

variable "enable_metrics_server" {
  description = "Metrics Server 활성화"
  type        = bool
  default     = true
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

# 네트워크 정책 설정
variable "enable_calico" {
  description = "Calico 네트워크 정책 엔진 활성화"
  type        = bool
  default     = false
}

# 컴플라이언스 설정
variable "enable_isms_compliance" {
  description = "ISMS-P 컴플라이언스 설정 활성화"
  type        = bool
  default     = true
}

# Fargate 프로파일 설정
variable "create_fargate_profile" {
  description = "Fargate 프로파일 생성 여부"
  type        = bool
  default     = false
}

variable "fargate_namespaces" {
  description = "Fargate에서 실행할 네임스페이스 목록"
  type        = list(string)
  default     = ["kube-system", "default"]
}

# 보안 그룹 추가 규칙
variable "additional_security_group_rules" {
  description = "추가 보안 그룹 규칙"
  type = list(object({
    type        = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}