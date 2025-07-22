# infrastructure/terraform/modules/lambda/main.tf
# Lambda 함수 구성을 위한 Terraform 모듈

# KMS 키 (Lambda 환경 변수 암호화용)
resource "aws_kms_key" "lambda" {
  count                   = var.create_kms_key ? 1 : 0
  description             = "Lambda Function Encryption Key - ${var.project_name}"
  deletion_window_in_days = var.kms_deletion_window

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-lambda-kms-key"
    Use  = "Lambda Encryption"
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_kms_alias" "lambda" {
  count         = var.create_kms_key ? 1 : 0
  name          = "alias/${var.project_name}-lambda"
  target_key_id = aws_kms_key.lambda[0].key_id
}

# Lambda 함수 실행 역할
resource "aws_iam_role" "lambda" {
  name = "${var.function_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# Lambda 기본 실행 정책 연결
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda.name
}

# VPC 접근 정책 (VPC 내 배포 시)
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count      = var.vpc_config != null ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.lambda.name
}

# 추가 정책 연결
resource "aws_iam_role_policy_attachment" "lambda_additional" {
  count      = length(var.additional_policy_arns)
  policy_arn = var.additional_policy_arns[count.index]
  role       = aws_iam_role.lambda.name
}

# 커스텀 정책 (필요한 권한들)
resource "aws_iam_role_policy" "lambda_custom" {
  count = var.custom_policy_json != null ? 1 : 0
  name  = "${var.function_name}-custom-policy"
  role  = aws_iam_role.lambda.id

  policy = var.custom_policy_json
}

# S3, DynamoDB, CloudWatch 등 기본 정책
resource "aws_iam_role_policy" "lambda_default" {
  count = var.enable_default_permissions ? 1 : 0
  name  = "${var.function_name}-default-policy"
  role  = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch Logs 권한
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      # X-Ray 추적 권한
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      },
      # KMS 권한 (환경 변수 암호화)
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = var.create_kms_key ? aws_kms_key.lambda[0].arn : var.kms_key_arn
      }
    ]
  })
}

# Lambda 함수용 보안 그룹 (VPC 배포 시)
resource "aws_security_group" "lambda" {
  count       = var.vpc_config != null ? 1 : 0
  name_prefix = "${var.function_name}-lambda-"
  vpc_id      = var.vpc_config.vpc_id
  description = "Security group for Lambda function ${var.function_name}"

  # 아웃바운드 트래픽 허용
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  # HTTPS (443) - API 호출용
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound"
  }

  # HTTP (80) - 필요시
  dynamic "egress" {
    for_each = var.allow_http_outbound ? [1] : []
    content {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP outbound"
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.function_name}-lambda-sg"
    Type = "Lambda Security Group"
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [tags_all]
  }

}

# Lambda 함수 코드 압축 (로컬 파일일 경우)
data "archive_file" "lambda_zip" {
  count       = var.source_path != null ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/src"   
  output_path = "${path.module}/lambda_function.zip"
}

# Lambda 함수
resource "aws_lambda_function" "main" {
  function_name = var.function_name
  role         = aws_iam_role.lambda.arn
  handler      = var.handler
  runtime      = var.runtime
  timeout      = var.timeout
  memory_size  = var.memory_size

  # 코드 소스
  filename         = var.source_path != null ? data.archive_file.lambda_zip[0].output_path : null
  s3_bucket        = var.s3_bucket
  s3_key           = var.s3_key
  s3_object_version = var.s3_object_version
  source_code_hash = var.source_path != null ? data.archive_file.lambda_zip[0].output_base64sha256 : var.source_code_hash

  # 아키텍처
  architectures = var.architectures

  # 환경 변수 (암호화 적용)
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  # KMS 키 (환경 변수 암호화)
  kms_key_arn = var.create_kms_key ? aws_kms_key.lambda[0].arn : var.kms_key_arn

  # VPC 설정
  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = concat([aws_security_group.lambda[0].id], vpc_config.value.additional_security_group_ids)
    }
  }

  # Dead Letter Queue 설정
  dynamic "dead_letter_config" {
    for_each = var.dead_letter_config != null ? [var.dead_letter_config] : []
    content {
      target_arn = dead_letter_config.value.target_arn
    }
  }

  # 추적 설정 (X-Ray)
  tracing_config {
    mode = var.tracing_mode
  }

  # 파일 시스템 설정 (EFS)
  dynamic "file_system_config" {
    for_each = var.file_system_config != null ? [var.file_system_config] : []
    content {
      arn              = file_system_config.value.arn
      local_mount_path = file_system_config.value.local_mount_path
    }
  }

  # 이미지 설정 (컨테이너 이미지 사용 시)
  dynamic "image_config" {
    for_each = var.image_config != null ? [var.image_config] : []
    content {
      command           = image_config.value.command
      entry_point       = image_config.value.entry_point
      working_directory = image_config.value.working_directory
    }
  }

  # 예약된 동시 실행 수
  reserved_concurrent_executions = var.reserved_concurrent_executions

  # 게시 설정
  publish = var.publish

  tags = merge(var.common_tags, {
    Name = var.function_name
    Type = "Lambda Function"
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_cloudwatch_log_group.lambda
  ]
}

# CloudWatch 로그 그룹 (ISMS-P 컴플라이언스)
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name = "${var.function_name}-logs"
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
}

# Lambda 별칭 (버전 관리)
resource "aws_lambda_alias" "main" {
  count            = var.create_alias ? 1 : 0
  name             = var.alias_name
  description      = "Alias for ${var.function_name}"
  function_name    = aws_lambda_function.main.function_name
  function_version = var.alias_function_version

  # 가중치 기반 라우팅 (Blue/Green 배포)
  dynamic "routing_config" {
    for_each = var.routing_config != null ? [var.routing_config] : []
    content {
      additional_version_weights = routing_config.value.additional_version_weights
    }
  }
}

# Lambda 권한 설정 (트리거용)
resource "aws_lambda_permission" "triggers" {
  count         = length(var.trigger_permissions)
  statement_id  = var.trigger_permissions[count.index].statement_id
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = var.trigger_permissions[count.index].principal
  source_arn    = var.trigger_permissions[count.index].source_arn
  qualifier     = var.create_alias ? aws_lambda_alias.main[0].name : null
}

# EventBridge (CloudWatch Events) 트리거
resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  count               = var.schedule_expression != null ? 1 : 0
  name                = "${var.function_name}-schedule"
  description         = "Schedule for ${var.function_name}"
  schedule_expression = var.schedule_expression
  state              = var.schedule_enabled ? "ENABLED" : "DISABLED"

  tags = var.common_tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  count     = var.schedule_expression != null ? 1 : 0
  rule      = aws_cloudwatch_event_rule.lambda_schedule[0].name
  target_id = "LambdaTarget"
  arn       = var.create_alias ? aws_lambda_alias.main[0].arn : aws_lambda_function.main.arn

  # 입력 변환
  dynamic "input_transformer" {
    for_each = var.schedule_input_transformer != null ? [var.schedule_input_transformer] : []
    content {
      input_paths    = input_transformer.value.input_paths
      input_template = input_transformer.value.input_template
    }
  }
}

resource "aws_lambda_permission" "eventbridge" {
  count         = var.schedule_expression != null ? 1 : 0
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule[0].arn
  qualifier     = var.create_alias ? aws_lambda_alias.main[0].name : null
}

# Lambda Insights (성능 모니터링)
resource "aws_lambda_layer_version" "insights" {
  count                = var.enable_insights ? 1 : 0
  layer_name           = "${var.function_name}-insights"
  compatible_runtimes  = [var.runtime]
  compatible_architectures = var.architectures

  s3_bucket = "prod-${data.aws_region.current.name}-starport-layer-bucket"
  s3_key    = "lambda-insights-extension.zip"

  description = "Lambda Insights Extension"
}

# 데이터 소스
data "aws_region" "current" {}

# CloudWatch 알람 (성능 모니터링)
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.function_name}-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = var.duration_alarm_threshold
  alarm_description   = "This metric monitors Lambda function duration"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []

  dimensions = {
    FunctionName = aws_lambda_function.main.function_name
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.function_name}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.error_alarm_threshold
  alarm_description   = "This metric monitors Lambda function errors"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []

  dimensions = {
    FunctionName = aws_lambda_function.main.function_name
  }

  tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.function_name}-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = var.throttle_alarm_threshold
  alarm_description   = "This metric monitors Lambda function throttles"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []

  dimensions = {
    FunctionName = aws_lambda_function.main.function_name
  }

  tags = var.common_tags
}