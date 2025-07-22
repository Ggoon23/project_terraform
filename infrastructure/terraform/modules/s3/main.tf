# infrastructure/terraform/modules/s3/main.tf
# S3 버킷 구성을 위한 Terraform 모듈

# KMS 키 (S3 암호화용)
resource "aws_kms_key" "s3" {
  count                   = var.create_kms_key ? 1 : 0
  description             = "S3 Bucket Encryption Key - ${var.project_name}"
  deletion_window_in_days = var.kms_deletion_window

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-s3-kms-key"
    Use  = "S3 Bucket Encryption"
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_kms_alias" "s3" {
  count         = var.create_kms_key ? 1 : 0
  name          = "alias/${var.project_name}-s3"
  target_key_id = aws_kms_key.s3[0].key_id
}

# S3 버킷들
resource "aws_s3_bucket" "logs" {
  bucket        = "${var.project_name}-logs-${var.environment}-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-logs-bucket"
    Purpose = "Log Storage"
    Type    = "Security Logs"
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_s3_bucket" "artifacts" {
  count         = var.create_artifacts_bucket ? 1 : 0
  bucket        = "${var.project_name}-artifacts-${var.environment}-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-artifacts-bucket"
    Purpose = "Build Artifacts"
    Type    = "Application Data"
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_s3_bucket" "backups" {
  count         = var.create_backups_bucket ? 1 : 0
  bucket        = "${var.project_name}-backups-${var.environment}-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-backups-bucket"
    Purpose = "Database Backups"
    Type    = "Backup Data"
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
}

# 랜덤 ID (버킷 이름 충돌 방지)
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 버킷 암호화 설정 (ISMS-P 컴플라이언스)
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.create_kms_key ? aws_kms_key.s3[0].arn : var.kms_key_id
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  count  = var.create_artifacts_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.create_kms_key ? aws_kms_key.s3[0].arn : var.kms_key_id
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  count  = var.create_backups_bucket ? 1 : 0
  bucket = aws_s3_bucket.backups[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.create_kms_key ? aws_kms_key.s3[0].arn : var.kms_key_id
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# S3 버킷 버전 관리
resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  count  = var.create_artifacts_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_versioning" "backups" {
  count  = var.create_backups_bucket ? 1 : 0
  bucket = aws_s3_bucket.backups[0].id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Disabled"
  }
}

# S3 버킷 퍼블릭 액세스 차단 (보안 강화)
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  count  = var.create_artifacts_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "backups" {
  count  = var.create_backups_bucket ? 1 : 0
  bucket = aws_s3_bucket.backups[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 버킷 라이프사이클 정책
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "log_lifecycle"
    status = "Enabled"

    # 현재 버전 라이프사이클
    transition {
      days          = var.transition_to_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.transition_to_glacier_days
      storage_class = "GLACIER"
    }

    transition {
      days          = var.transition_to_deep_archive_days
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = var.log_retention_days
    }

    # 이전 버전 관리
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_transition {
      noncurrent_days = 60
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    # 불완전한 멀티파트 업로드 정리
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  count  = var.create_artifacts_bucket ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    id     = "artifact_lifecycle"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  count  = var.create_backups_bucket ? 1 : 0
  bucket = aws_s3_bucket.backups[0].id

  rule {
    id     = "backup_lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }

    # 백업은 더 오래 보관
    expiration {
      days = var.backup_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# S3 버킷 로깅 설정 (ISMS-P 컴플라이언스)
resource "aws_s3_bucket" "access_logs" {
  count         = var.enable_access_logging ? 1 : 0
  bucket        = "${var.project_name}-access-logs-${var.environment}-${random_id.bucket_suffix.hex}"
  force_destroy = var.force_destroy

  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-access-logs-bucket"
    Purpose = "S3 Access Logs"
    Type    = "Audit Logs"
  })
  lifecycle {
    ignore_changes = [tags_all]
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  count  = var.enable_access_logging ? 1 : 0
  bucket = aws_s3_bucket.access_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_logging" "logs" {
  count  = var.enable_access_logging ? 1 : 0
  bucket = aws_s3_bucket.logs.id

  target_bucket = aws_s3_bucket.access_logs[0].id
  target_prefix = "logs-bucket-access/"
}

resource "aws_s3_bucket_logging" "artifacts" {
  count  = var.create_artifacts_bucket && var.enable_access_logging ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  target_bucket = aws_s3_bucket.access_logs[0].id
  target_prefix = "artifacts-bucket-access/"
}

resource "aws_s3_bucket_logging" "backups" {
  count  = var.create_backups_bucket && var.enable_access_logging ? 1 : 0
  bucket = aws_s3_bucket.backups[0].id

  target_bucket = aws_s3_bucket.access_logs[0].id
  target_prefix = "backups-bucket-access/"
}

# S3 버킷 알림 설정 (CloudWatch Events 연동)
resource "aws_s3_bucket_notification" "logs_notification" {
  count  = var.enable_cloudwatch_events ? 1 : 0
  bucket = aws_s3_bucket.logs.id

  eventbridge = true
}

resource "aws_s3_bucket_notification" "artifacts_notification" {
  count  = var.create_artifacts_bucket && var.enable_cloudwatch_events ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  eventbridge = true
}

# S3 버킷 정책 (CloudTrail 등을 위한)
resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id

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
        Resource = aws_s3_bucket.logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/cloudtrail/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/aws-logs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid    = "AWSLogDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.logs.arn
      },
      {
        Sid    = "VPCFlowLogsDeliveryRolePolicy"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/vpc-flow-logs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# CloudWatch 메트릭 (S3 버킷 모니터링)
resource "aws_cloudwatch_metric_alarm" "s3_bucket_size" {
  count = var.enable_cloudwatch_monitoring ? length([
    aws_s3_bucket.logs.bucket,
    var.create_artifacts_bucket ? aws_s3_bucket.artifacts[0].bucket : "",
    var.create_backups_bucket ? aws_s3_bucket.backups[0].bucket : ""
  ]) : 0

  alarm_name          = "${var.project_name}-s3-bucket-size-${count.index}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "BucketSizeBytes"
  namespace           = "AWS/S3"
  period              = "86400"
  statistic           = "Average"
  threshold           = var.s3_size_alarm_threshold
  alarm_description   = "This metric monitors S3 bucket size"
  alarm_actions       = var.sns_topic_arn != null ? [var.sns_topic_arn] : []

  dimensions = {
    BucketName  = count.index == 0 ? aws_s3_bucket.logs.bucket : (count.index == 1 && var.create_artifacts_bucket ? aws_s3_bucket.artifacts[0].bucket : aws_s3_bucket.backups[0].bucket)
    StorageType = "StandardStorage"
  }

  tags = var.common_tags
}