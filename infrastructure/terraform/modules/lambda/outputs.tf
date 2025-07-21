# infrastructure/terraform/modules/lambda/outputs.tf
# Lambda 모듈 출력값 정의

# 함수 기본 정보
output "function_name" {
  description = "Lambda 함수 이름"
  value       = aws_lambda_function.main.function_name
}

output "function_arn" {
  description = "Lambda 함수 ARN"
  value       = aws_lambda_function.main.arn
}

output "function_qualified_arn" {
  description = "Lambda 함수 정규화된 ARN (버전 포함)"
  value       = aws_lambda_function.main.qualified_arn
}

output "function_version" {
  description = "Lambda 함수 버전"
  value       = aws_lambda_function.main.version
}

output "function_last_modified" {
  description = "Lambda 함수 마지막 수정 시간"
  value       = aws_lambda_function.main.last_modified
}

output "function_source_code_hash" {
  description = "Lambda 함수 소스 코드 해시"
  value       = aws_lambda_function.main.source_code_hash
}

output "function_source_code_size" {
  description = "Lambda 함수 소스 코드 크기"
  value       = aws_lambda_function.main.source_code_size
}

# 호출 정보
output "invoke_arn" {
  description = "Lambda 함수 호출 ARN (API Gateway 등에서 사용)"
  value       = aws_lambda_function.main.invoke_arn
}

# 별칭 정보
output "alias_arn" {
  description = "Lambda 별칭 ARN"
  value       = var.create_alias ? aws_lambda_alias.main[0].arn : null
}

output "alias_name" {
  description = "Lambda 별칭 이름"
  value       = var.create_alias ? aws_lambda_alias.main[0].name : null
}

output "alias_invoke_arn" {
  description = "Lambda 별칭 호출 ARN"
  value       = var.create_alias ? aws_lambda_alias.main[0].invoke_arn : null
}

# IAM 역할 정보
output "execution_role_arn" {
  description = "Lambda 실행 역할 ARN"
  value       = aws_iam_role.lambda.arn
}

output "execution_role_name" {
  description = "Lambda 실행 역할 이름"
  value       = aws_iam_role.lambda.name
}

# 보안 그룹 정보
output "security_group_id" {
  description = "Lambda 보안 그룹 ID (VPC 배포 시)"
  value       = var.vpc_config != null ? aws_security_group.lambda[0].id : null
}

output "security_group_arn" {
  description = "Lambda 보안 그룹 ARN (VPC 배포 시)"
  value       = var.vpc_config != null ? aws_security_group.lambda[0].arn : null
}

# KMS 키 정보
output "kms_key_id" {
  description = "Lambda 암호화 KMS 키 ID"
  value       = var.create_kms_key ? aws_kms_key.lambda[0].key_id : var.kms_key_arn
}

output "kms_key_arn" {
  description = "Lambda 암호화 KMS 키 ARN"
  value       = var.create_kms_key ? aws_kms_key.lambda[0].arn : var.kms_key_arn
}

output "kms_alias_name" {
  description = "Lambda KMS 키 별칭"
  value       = var.create_kms_key ? aws_kms_alias.lambda[0].name : null
}

# CloudWatch 로그 그룹 정보
output "log_group_name" {
  description = "CloudWatch 로그 그룹 이름"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "log_group_arn" {
  description = "CloudWatch 로그 그룹 ARN"
  value       = aws_cloudwatch_log_group.lambda.arn
}

# 스케줄 정보
output "eventbridge_rule_arn" {
  description = "EventBridge 스케줄 규칙 ARN"
  value       = var.schedule_expression != null ? aws_cloudwatch_event_rule.lambda_schedule[0].arn : null
}

output "eventbridge_rule_name" {
  description = "EventBridge 스케줄 규칙 이름"
  value       = var.schedule_expression != null ? aws_cloudwatch_event_rule.lambda_schedule[0].name : null
}

# CloudWatch 알람 정보
output "cloudwatch_alarms" {
  description = "생성된 CloudWatch 알람 정보"
  value = var.enable_cloudwatch_alarms ? {
    duration = {
      name = aws_cloudwatch_metric_alarm.lambda_duration[0].alarm_name
      arn  = aws_cloudwatch_metric_alarm.lambda_duration[0].arn
    }
    errors = {
      name = aws_cloudwatch_metric_alarm.lambda_errors[0].alarm_name
      arn  = aws_cloudwatch_metric_alarm.lambda_errors[0].arn
    }
    throttles = {
      name = aws_cloudwatch_metric_alarm.lambda_throttles[0].alarm_name
      arn  = aws_cloudwatch_metric_alarm.lambda_throttles[0].arn
    }
  } : null
}

# 함수 설정 정보
output "function_configuration" {
  description = "Lambda 함수 설정 정보"
  value = {
    runtime      = aws_lambda_function.main.runtime
    handler      = aws_lambda_function.main.handler
    timeout      = aws_lambda_function.main.timeout
    memory_size  = aws_lambda_function.main.memory_size
    architectures = aws_lambda_function.main.architectures
  }
}

# VPC 설정 정보
output "vpc_configuration" {
  description = "VPC 설정 정보"
  value = var.vpc_config != null ? {
    vpc_id             = var.vpc_config.vpc_id
    subnet_ids         = aws_lambda_function.main.vpc_config[0].subnet_ids
    security_group_ids = aws_lambda_function.main.vpc_config[0].security_group_ids
  } : null
}

# 환경 변수 정보 (민감하지 않은 정보만)
output "environment_variables_count" {
  description = "설정된 환경 변수 개수"
  value       = length(var.environment_variables)
}

# 추적 설정 정보
output "tracing_config" {
  description = "X-Ray 추적 설정"
  value = {
    mode = aws_lambda_function.main.tracing_config[0].mode
  }
}

# 동시 실행 설정
output "reserved_concurrent_executions" {
  description = "예약된 동시 실행 수"
  value       = aws_lambda_function.main.reserved_concurrent_executions
}

# 데드레터 설정
output "dead_letter_config" {
  description = "Dead Letter Queue 설정"
  value = var.dead_letter_config != null ? {
    target_arn = aws_lambda_function.main.dead_letter_config[0].target_arn
  } : null
}

# 파일 시스템 설정
output "file_system_config" {
  description = "EFS 파일 시스템 설정"
  value = var.file_system_config != null ? {
    arn              = aws_lambda_function.main.file_system_config[0].arn
    local_mount_path = aws_lambda_function.main.file_system_config[0].local_mount_path
  } : null
}

# 레이어 정보
output "layers" {
  description = "연결된 Lambda 레이어"
  value       = var.layers
}

# Insights 레이어 정보
output "insights_layer_arn" {
  description = "Lambda Insights 레이어 ARN"
  value       = var.enable_insights ? aws_lambda_layer_version.insights[0].arn : null
}

# 코드 소스 정보
output "code_source_info" {
  description = "코드 소스 정보"
  value = {
    source_type = var.source_path != null ? "local" : (var.s3_bucket != null ? "s3" : "unknown")
    s3_bucket   = var.s3_bucket
    s3_key      = var.s3_key
    s3_version  = var.s3_object_version
  }
}

# 함수 URL 정보 (Lambda Function URLs)
output "function_url" {
  description = "Lambda 함수 URL (활성화된 경우)"
  value       = null # Function URL은 별도 리소스로 생성 필요
}

# 성능 메트릭 정보
output "performance_config" {
  description = "성능 관련 설정"
  value = {
    memory_size                    = aws_lambda_function.main.memory_size
    timeout                       = aws_lambda_function.main.timeout
    reserved_concurrent_executions = aws_lambda_function.main.reserved_concurrent_executions
    ephemeral_storage_size        = var.ephemeral_storage_size
  }
}

# 보안 설정 정보
output "security_configuration" {
  description = "보안 설정 정보"
  value = {
    kms_encryption_enabled = var.create_kms_key || var.kms_key_arn != null
    tracing_enabled       = var.tracing_mode == "Active"
    vpc_enabled           = var.vpc_config != null
    code_signing_enabled  = var.enable_code_signing
  }
}

# 모니터링 설정 정보
output "monitoring_configuration" {
  description = "모니터링 설정 정보"
  value = {
    cloudwatch_logs_enabled   = true
    cloudwatch_alarms_enabled = var.enable_cloudwatch_alarms
    x_ray_tracing_enabled    = var.tracing_mode == "Active"
    insights_enabled         = var.enable_insights
    log_retention_days       = var.log_retention_days
  }
}

# 트리거 정보
output "trigger_configuration" {
  description = "트리거 설정 정보"
  value = {
    schedule_enabled      = var.schedule_expression != null
    schedule_expression   = var.schedule_expression
    trigger_permissions_count = length(var.trigger_permissions)
  }
}

# 라우팅 설정 (Blue/Green 배포)
output "routing_configuration" {
  description = "라우팅 설정 정보"
  value = var.create_alias && var.routing_config != null ? {
    alias_name                    = aws_lambda_alias.main[0].name
    additional_version_weights    = var.routing_config.additional_version_weights
  } : null
}

# 컴플라이언스 정보
output "compliance_info" {
  description = "컴플라이언스 관련 정보"
  value = {
    encryption_at_rest    = var.create_kms_key || var.kms_key_arn != null
    encryption_in_transit = var.tracing_mode == "Active"
    logging_enabled      = true
    vpc_isolation        = var.vpc_config != null
    access_control       = true
  }
}

# AWS CLI 명령어
output "aws_cli_commands" {
  description = "유용한 AWS CLI 명령어"
  value = {
    invoke_function = "aws lambda invoke --function-name ${aws_lambda_function.main.function_name} response.json"
    get_function    = "aws lambda get-function --function-name ${aws_lambda_function.main.function_name}"
    list_versions   = "aws lambda list-versions-by-function --function-name ${aws_lambda_function.main.function_name}"
    get_logs        = "aws logs describe-log-streams --log-group-name ${aws_cloudwatch_log_group.lambda.name}"
  }
}

# 접근 경로 정보
output "access_info" {
  description = "Lambda 함수 접근 정보"
  value = {
    console_url = "https://${data.aws_region.current.name}.console.aws.amazon.com/lambda/home?region=${data.aws_region.current.name}#/functions/${aws_lambda_function.main.function_name}"
    logs_url    = "https://${data.aws_region.current.name}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.name}#logsV2:log-groups/log-group/${replace(aws_cloudwatch_log_group.lambda.name, "/", "$252F")}"
  }
}

# 비용 최적화 정보
output "cost_optimization_info" {
  description = "비용 최적화 관련 정보"
  value = {
    memory_size                    = aws_lambda_function.main.memory_size
    timeout                       = aws_lambda_function.main.timeout
    reserved_concurrent_executions = aws_lambda_function.main.reserved_concurrent_executions
    provisioned_concurrency       = var.provisioned_concurrency_config != null
    architecture                  = aws_lambda_function.main.architectures[0]
  }
}

# 연동 정보
output "integration_endpoints" {
  description = "다른 서비스와의 연동 엔드포인트"
  value = {
    function_arn    = aws_lambda_function.main.arn
    invoke_arn     = aws_lambda_function.main.invoke_arn
    alias_arn      = var.create_alias ? aws_lambda_alias.main[0].arn : null
    execution_role = aws_iam_role.lambda.arn
  }
}