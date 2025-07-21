# infrastructure/terraform/modules/security-log-collectors/main.tf
# 보안 로그 수집 서비스들을 위한 Terraform 모듈

# 데이터 소스
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# CloudTrail 설정
resource "aws_cloudtrail" "main" {
  count                          = var.enable_cloudtrail ? 1 : 0
  name                          = "${var.project_name}-cloudtrail"
  s3_bucket_name                = var.s3_bucket_name
  s3_key_prefix                 = var.cloudtrail_s3_prefix
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true

  # KMS 암호화 (ISMS-P 컴플라이언스)
  kms_key_id = var.kms_key_arn

  # 데이터 이벤트 로깅 (중요 S3 버킷)
  dynamic "event_selector" {
    for_each = var.cloudtrail_data_events_enabled ? [1] : []
    content {
      read_write_type                 = "All"
      include_management_events       = true
      exclude_management_event_sources = var.cloudtrail_exclude_management_events

      dynamic "data_resource" {
        for_each = var.cloudtrail_s3_data_events
        content {
          type   = "AWS::S3::Object"
          values = data_resource.value
        }
      }

      dynamic "data_resource" {
        for_each = var.cloudtrail_lambda_data_events
        content {
          type   = "AWS::Lambda::Function"
          values = data_resource.value
        }
      }
    }
  }

  # CloudWatch Logs 통합
  dynamic "cloud_watch_logs_group_arn" {
    for_each = var.cloudtrail_cloudwatch_logs_enabled ? [1] : []
    content {
      cloud_watch_logs_group_arn = aws_cloudwatch_log_group.cloudtrail[0].arn
      cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch[0].arn
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-cloudtrail"
    Type = "Security Audit Trail"
  })

  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket]
}

# CloudTrail용 CloudWatch 로그 그룹
resource "aws_cloudwatch_log_group" "cloudtrail" {
  count             = var.cloudtrail_cloudwatch_logs_enabled ? 1 : 0
  name              = "/aws/cloudtrail/${var.project_name}"
  retention_in_days = var.cloudtrail_log_retention_days

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-cloudtrail-logs"
  })
}

# CloudTrail CloudWatch 로그 IAM 역할
resource "aws_iam_role" "cloudtrail_cloudwatch" {
  count = var.cloudtrail_cloudwatch_logs_enabled ? 1 : 0
  name  = "${var.project_name}-cloudtrail-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  count = var.cloudtrail_cloudwatch_logs_enabled ? 1 : 0
  name  = "${var.project_name}-cloudtrail-cloudwatch-policy"
  role  = aws_iam_role.cloudtrail_cloudwatch[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
      }
    ]
  })
}

# S3 버킷 정책 (CloudTrail용)
resource "aws_s3_bucket_policy" "cloudtrail_bucket" {
  bucket = var.s3_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::${var.s3_bucket_name}"
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/${var.cloudtrail_s3_prefix}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# GuardDuty 설정
resource "aws_guardduty_detector" "main" {
  count  = var.enable_guardduty ? 1 : 0
  enable = true

  # S3 보호
  datasources {
    s3_logs {
      enable = var.guardduty_s3_protection
    }
    kubernetes {
      audit_logs {
        enable = var.guardduty_kubernetes_protection
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = var.guardduty_malware_protection
        }
      }
    }
  }

  # Finding 게시 빈도
  finding_publishing_frequency = var.guardduty_finding_publishing_frequency

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-guardduty"
    Type = "Threat Detection"
  })
}

# Splunk Forwarder용 IAM 역할 생성 (추가 필요)
resource "aws_iam_role" "splunk_forwarder" {
  name = "${var.project_name}-splunk-forwarder-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# S3/CloudWatch 읽기 권한 정책 추가
resource "aws_iam_role_policy" "splunk_forwarder_s3_cloudwatch" {
  name = "${var.project_name}-splunk-forwarder-policy"
  role = aws_iam_role.splunk_forwarder.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}


# GuardDuty용 S3 버킷 (선택사항)
resource "aws_s3_bucket" "guardduty_findings" {
  count  = var.guardduty_export_findings_to_s3 ? 1 : 0
  bucket = "${var.project_name}-guardduty-findings-${random_id.bucket_suffix.hex}"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-guardduty-findings"
    Type = "Security Findings"
  })
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Security Hub 설정
resource "aws_securityhub_account" "main" {
  count                    = var.enable_security_hub ? 1 : 0
  enable_default_standards = var.security_hub_enable_default_standards

  control_finding_generator = var.security_hub_control_finding_generator

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-security-hub"
    Type = "Security Hub"
  })
}

# Security Hub 표준 구독
resource "aws_securityhub_standards_subscription" "aws_foundational" {
  count         = var.enable_security_hub && var.security_hub_enable_aws_foundational ? 1 : 0
  standards_arn = "arn:aws:securityhub:::ruleset/finding-format/aws-foundational-security-best-practices/v/1.0.0"

  depends_on = [aws_securityhub_account.main]
}

resource "aws_securityhub_standards_subscription" "cis" {
  count         = var.enable_security_hub && var.security_hub_enable_cis ? 1 : 0
  standards_arn = "arn:aws:securityhub:::ruleset/finding-format/cis-aws-foundations-benchmark/v/1.2.0"

  depends_on = [aws_securityhub_account.main]
}

resource "aws_securityhub_standards_subscription" "pci_dss" {
  count         = var.enable_security_hub && var.security_hub_enable_pci_dss ? 1 : 0
  standards_arn = "arn:aws:securityhub:::ruleset/finding-format/pci-dss/v/3.2.1"

  depends_on = [aws_securityhub_account.main]
}

# AWS Config 설정
resource "aws_config_configuration_recorder" "main" {
  count    = var.enable_aws_config ? 1 : 0
  name     = "${var.project_name}-config-recorder"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  count           = var.enable_aws_config ? 1 : 0
  name            = "${var.project_name}-config-delivery-channel"
  s3_bucket_name  = var.s3_bucket_name
  s3_key_prefix   = var.config_s3_prefix
  snapshot_delivery_properties {
    delivery_frequency = var.config_delivery_frequency
  }
}

# AWS Config IAM 역할
resource "aws_iam_role" "config" {
  count = var.enable_aws_config ? 1 : 0
  name  = "${var.project_name}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "config" {
  count      = var.enable_aws_config ? 1 : 0
  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigServiceRolePolicy"
}

resource "aws_iam_role_policy" "config_s3" {
  count = var.enable_aws_config ? 1 : 0
  name  = "${var.project_name}-config-s3-policy"
  role  = aws_iam_role.config[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketAcl",
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/${var.config_s3_prefix}/*"
      }
    ]
  })
}

# AWS Inspector V2 설정
resource "aws_inspector2_enabler" "main" {
  count           = var.enable_inspector ? 1 : 0
  account_ids     = [data.aws_caller_identity.current.account_id]
  resource_types  = var.inspector_resource_types
}

# VPC Flow Logs 설정
resource "aws_flow_log" "main" {
  count           = var.enable_vpc_flow_logs ? 1 : 0
  iam_role_arn    = aws_iam_role.flow_log[0].arn
  log_destination = var.vpc_flow_logs_destination_type == "s3" ? "arn:aws:s3:::${var.s3_bucket_name}/${var.vpc_flow_logs_s3_prefix}" : aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  traffic_type    = var.vpc_flow_logs_traffic_type
  vpc_id          = var.vpc_id

  # S3 또는 CloudWatch 로그 설정
  log_destination_type = var.vpc_flow_logs_destination_type

  # S3 설정
  dynamic "destination_options" {
    for_each = var.vpc_flow_logs_destination_type == "s3" ? [1] : []
    content {
      file_format                = var.vpc_flow_logs_file_format
      hive_compatible_partitions = var.vpc_flow_logs_hive_compatible_partitions
      per_hour_partition         = var.vpc_flow_logs_per_hour_partition
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpc-flow-logs"
    Type = "Network Security Logs"
  })
}

# VPC Flow Logs용 CloudWatch 로그 그룹
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count             = var.enable_vpc_flow_logs && var.vpc_flow_logs_destination_type == "cloud-watch-logs" ? 1 : 0
  name              = "/aws/vpc/flowlogs/${var.project_name}"
  retention_in_days = var.vpc_flow_logs_retention_days

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpc-flow-logs"
  })
}

# VPC Flow Logs IAM 역할
resource "aws_iam_role" "flow_log" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  name  = "${var.project_name}-vpc-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy" "flow_log" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  name  = "${var.project_name}-vpc-flow-log-policy"
  role  = aws_iam_role.flow_log[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:GetBucketAcl",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

# CloudWatch 이벤트 규칙 (보안 이벤트 감지)
resource "aws_cloudwatch_event_rule" "security_events" {
  count       = var.enable_security_event_monitoring ? 1 : 0
  name        = "${var.project_name}-security-events"
  description = "Capture security-related events"

  event_pattern = jsonencode({
    source      = ["aws.guardduty", "aws.securityhub", "aws.config"]
    detail-type = ["GuardDuty Finding", "Security Hub Findings - Imported", "Config Configuration Item Change"]
  })

  tags = var.common_tags
}

# CloudWatch 이벤트 대상 (SNS)
resource "aws_cloudwatch_event_target" "security_events_sns" {
  count     = var.enable_security_event_monitoring && var.sns_topic_arn != null ? 1 : 0
  rule      = aws_cloudwatch_event_rule.security_events[0].name
  target_id = "SendToSNS"
  arn       = var.sns_topic_arn
}

# CloudWatch 대시보드 (보안 메트릭)
resource "aws_cloudwatch_dashboard" "security" {
  count          = var.create_security_dashboard ? 1 : 0
  dashboard_name = "${var.project_name}-security-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/CloudTrail", "ErrorCount", "TrailName", var.enable_cloudtrail ? aws_cloudtrail.main[0].name : ""],
            ["AWS/GuardDuty", "FindingCount"],
            ["AWS/Config", "ComplianceByConfigRule", "RuleName", "ALL"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Security Service Metrics"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 6
        width  = 24
        height = 6

        properties = {
          query   = "SOURCE '/aws/cloudtrail/${var.project_name}' | fields @timestamp, eventName, sourceIPAddress, userIdentity.type\n| filter eventName != \"AssumeRole\"\n| sort @timestamp desc\n| limit 20"
          region  = data.aws_region.current.name
          title   = "Recent CloudTrail Events"
        }
      }
    ]
  })
}

# EventBridge 커스텀 버스 (보안 이벤트용)
resource "aws_cloudwatch_event_bus" "security" {
  count = var.create_custom_event_bus ? 1 : 0
  name  = "${var.project_name}-security-events"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-security-event-bus"
    Type = "Security Event Bus"
  })
}