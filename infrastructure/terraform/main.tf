# =========================================
# Complete AWS Infrastructure Configuration
# =========================================

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# =========================================
# VPC Module - 네트워크 기반 구성
# =========================================
module "vpc" {
  source = "./modules/vpc"

  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnets
  private_subnet_cidrs = var.private_subnets
  database_subnet_cidrs = var.database_subnets

  enable_nat_gateway     = true
  enable_dns_hostnames   = true
  enable_dns_support     = true
  enable_vpc_flow_logs   = true

  common_tags = {
    Component = "Networking"
  }
}

# =========================================
# S3 Module - 스토리지 및 로깅
# =========================================
module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment

  # 로깅용 S3 버킷들
  create_logging_bucket     = true
  create_backup_bucket      = true
  create_application_bucket = true

  # 보안 설정
  enable_versioning           = true
  enable_server_side_encryption = true
  enable_mfa_delete          = false
  enable_public_access_block = true

  # 라이프사이클 정책
  lifecycle_rules = [
    {
      id     = "security_logs"
      status = "Enabled"
      transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        },
        {
          days          = 365
          storage_class = "DEEP_ARCHIVE"
        }
      ]
    }
  ]

  tags = {
    Component = "Storage"
  }
}

# =========================================
# DynamoDB Module - NoSQL 데이터베이스
# =========================================

# 보안 로그 메타데이터 테이블
module "dynamodb_security_logs" {
  source = "./modules/dynamodb"

  project_name = var.project_name
  environment  = var.environment

  # 테이블 기본 설정
  table_name   = "security-logs-metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "log_id"
  range_key    = "timestamp"
  
  # 속성 정의
  attributes = [
    {
      name = "log_id"
      type = "S"
    },
    {
      name = "timestamp"
      type = "S"
    },
    {
      name = "source_service"
      type = "S"
    }
  ]

  # 글로벌 보조 인덱스
  global_secondary_indexes = [
    {
      name               = "source-service-index"
      hash_key           = "source_service"
      range_key          = "timestamp"
      projection_type    = "ALL"
      read_capacity      = null
      write_capacity     = null
      non_key_attributes = []
    }
  ]

  # 보안 및 백업 설정
  point_in_time_recovery_enabled = true
  stream_enabled                 = true
  stream_view_type              = "NEW_AND_OLD_IMAGES"
  ttl_enabled                   = true
  ttl_attribute_name            = "expiry_time"
  
  # 암호화 설정
  create_kms_key = true
  
  # 태그
  common_tags = {
    Component = "Database"
    DataType  = "SecurityLogs"
  }
}

# 사용자 세션 테이블
module "dynamodb_user_sessions" {
  source = "./modules/dynamodb"

  project_name = var.project_name
  environment  = var.environment

  # 테이블 기본 설정
  table_name   = "user-sessions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "session_id"
  range_key    = null
  
  # 속성 정의
  attributes = [
    {
      name = "session_id"
      type = "S"
    },
    {
      name = "user_id"
      type = "S"
    }
  ]

  # 글로벌 보조 인덱스
  global_secondary_indexes = [
    {
      name               = "user-id-index"
      hash_key           = "user_id"
      range_key          = null
      projection_type    = "ALL"
      read_capacity      = null
      write_capacity     = null
      non_key_attributes = []
    }
  ]

  # 보안 및 백업 설정
  point_in_time_recovery_enabled = true
  stream_enabled                 = false
  ttl_enabled                   = true
  ttl_attribute_name            = "expires_at"
  
  # 암호화 설정
  create_kms_key = true
  
  # 태그
  common_tags = {
    Component = "Database"
    DataType  = "UserSessions"
  }
}

# =========================================
# RDS Module - 관계형 데이터베이스
# =========================================
module "rds" {
  source = "./modules/rds"

  project_name = var.project_name
  environment  = var.environment

  # 네트워크 설정
  vpc_id                = module.vpc.vpc_id
  database_subnet_ids   = module.vpc.database_subnet_ids
  
  # 보안 그룹 설정
  allowed_security_group_ids = [
    module.eks.cluster_security_group_id,
    module.lambda.security_group_id
  ]

  # 데이터베이스 설정
  engine                 = "postgres"
  engine_version         = "15.4"
  instance_class         = var.rds_instance_class
  allocated_storage      = 20
  max_allocated_storage  = 100
  storage_encrypted      = true

  # 인증 설정
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password  # 실제 환경에서는 AWS Secrets Manager 사용 권장

  # 백업 설정
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # 모니터링 설정
  monitoring_interval = 60
  enabled_cloudwatch_logs_exports = ["postgresql"]

  # Multi-AZ 설정 (운영 환경에서는 true 권장)
  multi_az = false

  tags = {
    Component = "Database"
  }
}

# =========================================
# Lambda Module - 서버리스 함수
# =========================================
module "lambda" {
  source = "./modules/lambda"

  project_name = var.project_name
  environment  = var.environment

  # 네트워크 설정
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # Lambda 함수들
  functions = [
    {
      function_name = "log-processor"
      description   = "Process security logs from various sources"
      runtime       = "python3.9"
      handler       = "handler.lambda_handler"
      source_path   = "../lambda/log-processor"
      timeout       = 300
      memory_size   = 512

      environment_variables = {
        DYNAMODB_TABLE = module.dynamodb.table_names["security-logs-metadata"]
        S3_BUCKET      = module.s3.logging_bucket_name
        RDS_ENDPOINT   = module.rds.db_instance_endpoint
      }

      # 트리거 설정
      s3_trigger = {
        bucket = module.s3.logging_bucket_name
        events = ["s3:ObjectCreated:*"]
        filter_prefix = "logs/"
      }
    },
    {
      function_name = "security-alert"
      description   = "Send security alerts based on log analysis"
      runtime       = "python3.9"
      handler       = "handler.lambda_handler"
      source_path   = "../lambda/security-alert"
      timeout       = 60
      memory_size   = 256

      environment_variables = {
        SLACK_WEBHOOK_URL = var.slack_webhook_url
        EMAIL_TOPIC_ARN   = aws_sns_topic.security_alerts.arn
      }
    }
  ]

  # IAM 권한
  additional_policies = [
    {
      policy_name = "DynamoDBAccess"
      policy_json = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "dynamodb:GetItem",
              "dynamodb:PutItem",
              "dynamodb:UpdateItem",
              "dynamodb:DeleteItem",
              "dynamodb:Query",
              "dynamodb:Scan"
            ]
            Resource = module.dynamodb.table_arns["*"]
          }
        ]
      })
    },
    {
      policy_name = "S3Access"
      policy_json = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Action = [
              "s3:GetObject",
              "s3:PutObject",
              "s3:DeleteObject"
            ]
            Resource = "${module.s3.logging_bucket_arn}/*"
          }
        ]
      })
    }
  ]

  tags = {
    Component = "Serverless"
  }
}

# =========================================
# EKS Module - Kubernetes 클러스터
# =========================================
module "eks" {
  source = "./modules/eks"

  project_name = var.project_name
  environment  = var.environment

  # 클러스터 설정
  cluster_name    = "${var.project_name}-${var.environment}-eks"
  cluster_version = "1.27"

  # 네트워크 설정
  vpc_id                    = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnet_ids
  control_plane_subnet_ids = module.vpc.private_subnet_ids

  # 보안 설정
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]  # 운영환경에서는 제한 필요

  # 로깅 설정
  cluster_enabled_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # 노드 그룹 설정
  node_groups = [
    {
      name           = "general-purpose"
      instance_types = ["t3.medium"]
      min_size       = 1
      max_size       = 3
      desired_size   = 2

      # 보안 설정
      remote_access = {
        ec2_ssh_key = var.ec2_key_pair_name
        source_security_group_ids = [aws_security_group.bastion.id]
      }

      # 라벨 및 태인트
      labels = {
        Environment = var.environment
        NodeGroup   = "general-purpose"
      }
    }
  ]

  # 추가 보안 그룹 규칙
  additional_security_group_rules = [
    {
      description = "RDS Access"
      type        = "egress"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
    },
    {
      description = "HTTPS Outbound"
      type        = "egress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Component = "Container-Platform"
  }
}

# =========================================
# Security Log Collectors Module
# =========================================
module "security_log_collectors" {
  source = "./modules/security-log-collectors"

  project_name = var.project_name
  environment  = var.environment

  # 필수 인자 추가
  s3_bucket_name = module.s3.logging_bucket_name
  kms_key_arn    = aws_kms_key.main.arn

  # VPC 설정
  vpc_id = module.vpc.vpc_id
  
  # CloudTrail 설정
  enable_cloudtrail = true
  
  # GuardDuty 설정
  enable_guardduty = true
  
  # Security Hub 설정
  enable_security_hub = true
  
  # AWS Config 설정
  enable_aws_config = true
  
  # VPC Flow Logs 설정
  enable_vpc_flow_logs = true

  common_tags = {
    Component = "Security-Monitoring"
  }
}

# =========================================
# SNS Topic for Security Alerts
# =========================================
resource "aws_sns_topic" "security_alerts" {
  name = "${var.project_name}-${var.environment}-security-alerts"

  tags = {
    Name      = "${var.project_name}-${var.environment}-security-alerts"
    Component = "Notifications"
  }
}

resource "aws_sns_topic_subscription" "email_alerts" {
  count     = length(var.alert_email_addresses)
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email_addresses[count.index]
}

# =========================================
# Bastion Host Security Group (EKS 접근용)
# =========================================
resource "aws_security_group" "bastion" {
  name_prefix = "${var.project_name}-${var.environment}-bastion"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for bastion host access"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.project_name}-${var.environment}-bastion-sg"
    Component = "Security"
  }
}

# =========================================
# CloudWatch Log Groups
# =========================================
resource "aws_cloudwatch_log_group" "application_logs" {
  name              = "/aws/application/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = {
    Name      = "${var.project_name}-${var.environment}-app-logs"
    Component = "Monitoring"
  }
}

resource "aws_cloudwatch_log_group" "security_logs" {
  name              = "/aws/security/${var.project_name}-${var.environment}"
  retention_in_days = 90

  tags = {
    Name      = "${var.project_name}-${var.environment}-security-logs"
    Component = "Monitoring"
  }
}

# =========================================
# KMS Key for Encryption
# =========================================
resource "aws_kms_key" "main" {
  description             = "KMS key for ${var.project_name} ${var.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow EKS Service"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name      = "${var.project_name}-${var.environment}-kms"
    Component = "Security"
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.main.key_id
}

# =========================================
# IAM Role for EKS Applications
# =========================================
resource "aws_iam_role" "eks_app_role" {
  name = "${var.project_name}-${var.environment}-eks-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = module.eks.cluster_oidc_issuer_arn
        }
        Condition = {
          StringEquals = {
            "${module.eks.cluster_oidc_issuer_url}:sub" = "system:serviceaccount:default:eks-app-service-account"
          }
        }
      }
    ]
  })

  tags = {
    Name      = "${var.project_name}-${var.environment}-eks-app-role"
    Component = "Security"
  }
}

# EKS 애플리케이션용 정책 연결
resource "aws_iam_role_policy" "eks_app_policy" {
  name = "eks-app-policy"
  role = aws_iam_role.eks_app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.s3.logging_bucket_arn,
          "${module.s3.logging_bucket_arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = module.dynamodb.table_arns["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}