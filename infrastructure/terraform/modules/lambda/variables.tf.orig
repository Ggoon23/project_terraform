# infrastructure/terraform/modules/lambda/variables.tf
# Lambda 모듈 변수 정의

# 필수 변수
variable "function_name" {
  description = "Lambda 함수 이름"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.function_name))
    error_message = "함수 이름은 알파벳, 숫자, 하이픈, 언더스코어만 포함할 수 있습니다."
  }
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
}

# 함수 설정
variable "runtime" {
  description = "Lambda 런타임"
  type        = string
  default     = "python3.9"
  validation {
    condition = contains([
      "python3.8", "python3.9", "python3.10", "python3.11",
      "nodejs14.x", "nodejs16.x", "nodejs18.x",
      "java8", "java8.al2", "java11", "java17",
      "dotnet6", "dotnetcore3.1",
      "go1.x", "ruby2.7", "ruby3.2",
      "provided", "provided.al2"
    ], var.runtime)
    error_message = "지원되지 않는 런타임입니다."
  }
}

variable "handler" {
  description = "Lambda 함수 핸들러"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "timeout" {
  description = "함수 실행 타임아웃 (초)"
  type        = number
  default     = 30
  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "타임아웃은 1-900초 사이여야 합니다."
  }
}

variable "memory_size" {
  description = "메모리 크기 (MB)"
  type        = number
  default     = 128
  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "메모리 크기는 128-10240MB 사이여야 합니다."
  }
}

variable "architectures" {
  description = "함수 아키텍처"
  type        = list(string)
  default     = ["x86_64"]
  validation {
    condition = alltrue([
      for arch in var.architectures :
      contains(["x86_64", "arm64"], arch)
    ])
    error_message = "아키텍처는 x86_64 또는 arm64여야 합니다."
  }
}

# 코드 소스 설정
variable "source_path" {
  description = "로컬 소스 코드 경로"
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 버킷 이름 (코드 업로드용)"
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 객체 키 (ZIP 파일)"
  type        = string
  default     = null
}

variable "s3_object_version" {
  description = "S3 객체 버전"
  type        = string
  default     = null
}

variable "source_code_hash" {
  description = "소스 코드 해시 (S3 사용 시)"
  type        = string
  default     = null
}

# 환경 변수
variable "environment_variables" {
  description = "Lambda 환경 변수"
  type        = map(string)
  default     = {}
  sensitive   = true
}

# VPC 설정
variable "vpc_config" {
  description = "VPC 설정"
  type = object({
    vpc_id                        = string
    subnet_ids                    = list(string)
    additional_security_group_ids = list(string)
  })
  default = null
}

variable "allow_http_outbound" {
  description = "HTTP 아웃바운드 트래픽 허용"
  type        = bool
  default     = false
}

# 암호화 설정 (ISMS-P 컴플라이언스)
variable "create_kms_key" {
  description = "Lambda 암호화용 KMS 키 생성 여부"
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "기존 KMS 키 ARN (create_kms_key가 false일 때 사용)"
  type        = string
  default     = null
}

variable "kms_deletion_window" {
  description = "KMS 키 삭제 대기 기간 (일)"
  type        = number
  default     = 7
}

# 로깅 설정 (ISMS-P 컴플라이언스)
variable "log_retention_days" {
  description = "CloudWatch 로그 보관 일수"
  type        = number
  default     = 30
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.log_retention_days)
    error_message = "유효하지 않은 로그 보관 일수입니다."
  }
}

# 추적 설정
variable "tracing_mode" {
  description = "X-Ray 추적 모드"
  type        = string
  default     = "Active"
  validation {
    condition     = contains(["Active", "PassThrough"], var.tracing_mode)
    error_message = "추적 모드는 Active 또는 PassThrough여야 합니다."
  }
}

# 동시 실행 제한
variable "reserved_concurrent_executions" {
  description = "예약된 동시 실행 수 (-1은 제한 없음)"
  type        = number
  default     = -1
}

# 별칭 설정
variable "create_alias" {
  description = "Lambda 별칭 생성 여부"
  type        = bool
  default     = false
}

variable "alias_name" {
  description = "Lambda 별칭 이름"
  type        = string
  default     = "current"
}

variable "alias_function_version" {
  description = "별칭이 가리킬 함수 버전"
  type        = string
  default     = "$LATEST"
}

variable "routing_config" {
  description = "별칭 라우팅 설정 (Blue/Green 배포)"
  type = object({
    additional_version_weights = map(number)
  })
  default = null
}

# 게시 설정
variable "publish" {
  description = "함수 버전 게시 여부"
  type        = bool
  default     = false
}

# 스케줄링 설정
variable "schedule_expression" {
  description = "EventBridge 스케줄 표현식 (cron 또는 rate)"
  type        = string
  default     = null
}

variable "schedule_enabled" {
  description = "스케줄 활성화 여부"
  type        = bool
  default     = true
}

variable "schedule_input_transformer" {
  description = "스케줄 입력 변환기 설정"
  type = object({
    input_paths    = map(string)
    input_template = string
  })
  default = null
}

# 트리거 권한 설정
variable "trigger_permissions" {
  description = "Lambda 트리거 권한 목록"
  type = list(object({
    statement_id = string
    principal    = string
    source_arn   = string
  }))
  default = []
}

# Dead Letter Queue 설정
variable "dead_letter_config" {
  description = "Dead Letter Queue 설정"
  type = object({
    target_arn = string
  })
  default = null
}

# 파일 시스템 설정 (EFS)
variable "file_system_config" {
  description = "EFS 파일 시스템 설정"
  type = object({
    arn              = string
    local_mount_path = string
  })
  default = null
}

# 이미지 설정 (컨테이너 사용 시)
variable "image_config" {
  description = "컨테이너 이미지 설정"
  type = object({
    command           = list(string)
    entry_point       = list(string)
    working_directory = string
  })
  default = null
}

# IAM 정책 설정
variable "additional_policy_arns" {
  description = "추가로 연결할 IAM 정책 ARN 목록"
  type        = list(string)
  default     = []
}

variable "custom_policy_json" {
  description = "커스텀 IAM 정책 JSON"
  type        = string
  default     = null
}

variable "enable_default_permissions" {
  description = "기본 권한 활성화 (CloudWatch, X-Ray, KMS)"
  type        = bool
  default     = true
}

# 성능 모니터링
variable "enable_insights" {
  description = "Lambda Insights 활성화"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_alarms" {
  description = "CloudWatch 알람 활성화"
  type        = bool
  default     = true
}

variable "duration_alarm_threshold" {
  description = "실행 시간 알람 임계값 (밀리초)"
  type        = number
  default     = 10000
}

variable "error_alarm_threshold" {
  description = "에러 알람 임계값"
  type        = number
  default     = 1
}

variable "throttle_alarm_threshold" {
  description = "스로틀 알람 임계값"
  type        = number
  default     = 1
}

variable "sns_topic_arn" {
  description = "알람 전송용 SNS 토픽 ARN"
  type        = string
  default     = null
}

# 레이어 설정
variable "layers" {
  description = "Lambda 레이어 ARN 목록"
  type        = list(string)
  default     = []
}

# 보안 설정
variable "enable_code_signing" {
  description = "코드 서명 활성화"
  type        = bool
  default     = false
}

variable "code_signing_config_arn" {
  description = "코드 서명 구성 ARN"
  type        = string
  default     = null
}

# 네트워크 설정
variable "ephemeral_storage_size" {
  description = "임시 스토리지 크기 (MB)"
  type        = number
  default     = 512
  validation {
    condition     = var.ephemeral_storage_size >= 512 && var.ephemeral_storage_size <= 10240
    error_message = "임시 스토리지 크기는 512-10240MB 사이여야 합니다."
  }
}

# 배포 설정
variable "deployment_package_type" {
  description = "배포 패키지 타입"
  type        = string
  default     = "Zip"
  validation {
    condition     = contains(["Zip", "Image"], var.deployment_package_type)
    error_message = "패키지 타입은 Zip 또는 Image여야 합니다."
  }
}

variable "image_uri" {
  description = "컨테이너 이미지 URI (Image 패키지 타입 사용 시)"
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
    Environment = "dev"
  }
}

# 고급 설정
variable "provisioned_concurrency_config" {
  description = "프로비저닝된 동시 실행 설정"
  type = object({
    provisioned_concurrent_executions = number
  })
  default = null
}

variable "event_source_mappings" {
  description = "이벤트 소스 매핑 설정 목록"
  type = list(object({
    event_source_arn                   = string
    function_response_types           = list(string)
    starting_position                 = string
    starting_position_timestamp       = string
    batch_size                        = number
    maximum_batching_window_in_seconds = number
    parallelization_factor            = number
    maximum_record_age_in_seconds     = number
    bisect_batch_on_function_error    = bool
    maximum_retry_attempts            = number
    tumbling_window_in_seconds        = number
    topics                            = list(string)
    queues                            = list(string)
    source_access_configurations = list(object({
      type = string
      uri  = string
    }))
    self_managed_event_source = object({
      endpoints = map(string)
    })
    filter_criteria = object({
      filters = list(object({
        pattern = string
      }))
    })
  }))
  default = []
}