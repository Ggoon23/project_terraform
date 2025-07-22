# infrastructure/terraform/modules/rds/main.tf
# RDS 데이터베이스 구성을 위한 Terraform 모듈

# RDS 서브넷 그룹 생성
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.database_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-db-subnet-group"
    Type = "Database"
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
}

# RDS 파라미터 그룹
resource "aws_db_parameter_group" "main" {
  family = var.db_family
  name   = "${var.project_name}-db-parameter-group"

  # 보안 강화 파라미터
  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  # ISMS-P 컴플라이언스: 로그 설정
  parameter {
  name  = "slow_query_log"
  value = "1"
  } 

  parameter {
    name  = "long_query_time"
    value = "1"
  }

  parameter {
    name  = "general_log"
    value = "1"
  }

  tags = var.common_tags
}

# RDS 옵션 그룹
resource "aws_db_option_group" "main" {
  count                    = var.create_option_group ? 1 : 0
  name                     = "${var.project_name}-db-option-group"
  option_group_description = "Option group for ${var.project_name}"
  engine_name              = var.engine
  major_engine_version     = var.major_engine_version

  tags = var.common_tags
}

# KMS 키 (데이터베이스 암호화용)
resource "aws_kms_key" "rds" {
  count                   = var.create_kms_key ? 1 : 0
  description             = "KMS key for RDS encryption - ${var.project_name}"
  deletion_window_in_days = var.kms_deletion_window

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-rds-kms-key"
    Use  = "RDS Encryption"
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_kms_alias" "rds" {
  count         = var.create_kms_key ? 1 : 0
  name          = "alias/${var.project_name}-rds"
  target_key_id = aws_kms_key.rds[0].key_id
}

# 보안 그룹
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-rds-"
  vpc_id      = var.vpc_id
  description = "Security group for RDS instance"

  # 데이터베이스 포트 접근 허용 (프라이빗 서브넷에서만)
  ingress {
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
    cidr_blocks     = var.allowed_cidr_blocks
    description     = "Database access from allowed sources"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-rds-sg"
    Type = "Database Security Group"
  })

  lifecycle {
    create_before_destroy = true
    ignore_changes = [tags_all]
  }

}

# RDS 인스턴스
resource "aws_db_instance" "main" {
  # 기본 설정
  identifier     = var.db_identifier
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # 스토리지 설정
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true
  kms_key_id           = var.create_kms_key ? aws_kms_key.rds[0].arn : var.kms_key_id

  # 데이터베이스 설정
  db_name  = var.database_name
  username = var.master_username
  password = var.master_password
  port     = var.port

  # 네트워크 및 보안
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  parameter_group_name   = aws_db_parameter_group.main.name
  option_group_name      = var.create_option_group ? aws_db_option_group.main[0].name : null

  # 백업 및 유지보수
  backup_retention_period   = var.backup_retention_period
  backup_window            = var.backup_window
  maintenance_window       = var.maintenance_window
  delete_automated_backups = var.delete_automated_backups

  # 고가용성 설정
  multi_az               = var.multi_az
  publicly_accessible    = false
  availability_zone      = var.multi_az ? null : var.availability_zone

  # 모니터링 설정
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  # Performance Insights (ISMS-P 컴플라이언스)
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_retention_period
  performance_insights_kms_key_id      = var.create_kms_key ? aws_kms_key.rds[0].arn : null

  # 로그 설정 (ISMS-P 컴플라이언스)
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # 삭제 보호
  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.db_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # 기타 설정
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately         = var.apply_immediately
  allow_major_version_upgrade = var.allow_major_version_upgrade

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-rds-instance"
    Type = "Database"
  })

  depends_on = [aws_cloudwatch_log_group.rds]
}

# CloudWatch 로그 그룹 (RDS 로그용)
resource "aws_cloudwatch_log_group" "rds" {
  for_each          = toset(var.enabled_cloudwatch_logs_exports)
  name              = "/aws/rds/instance/${var.db_identifier}/${each.value}"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-rds-${each.value}-logs"
  })
}

# IAM Role for Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0
  name  = "${var.project_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count      = var.monitoring_interval > 0 ? 1 : 0
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# RDS 읽기 전용 복제본 (선택사항)
resource "aws_db_instance" "replica" {
  count = var.create_read_replica ? 1 : 0

  identifier             = "${var.db_identifier}-replica"
  replicate_source_db    = aws_db_instance.main.id
  instance_class         = var.replica_instance_class
  publicly_accessible    = false
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # 모니터링
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  # Performance Insights
  performance_insights_enabled = var.performance_insights_enabled

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-rds-replica"
    Type = "Database Replica"
  })
}