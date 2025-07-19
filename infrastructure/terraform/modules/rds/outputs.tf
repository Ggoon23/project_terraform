# infrastructure/terraform/modules/rds/outputs.tf
# RDS 모듈 출력값 정의

# RDS 인스턴스 정보
output "db_instance_id" {
  description = "RDS 인스턴스 ID"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "RDS 인스턴스 ARN"
  value       = aws_db_instance.main.arn
}

output "db_instance_endpoint" {
  description = "RDS 인스턴스 엔드포인트"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_address" {
  description = "RDS 인스턴스 호스트 주소"
  value       = aws_db_instance.main.address
}

output "db_instance_port" {
  description = "RDS 인스턴스 포트"
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "데이터베이스 이름"
  value       = aws_db_instance.main.db_name
}

output "master_username" {
  description = "마스터 사용자 이름"
  value       = aws_db_instance.main.username
}

# 읽기 전용 복제본 정보
output "replica_instance_id" {
  description = "읽기 전용 복제본 인스턴스 ID"
  value       = var.create_read_replica ? aws_db_instance.replica[0].id : null
}

output "replica_instance_endpoint" {
  description = "읽기 전용 복제본 엔드포인트"
  value       = var.create_read_replica ? aws_db_instance.replica[0].endpoint : null
}

# 보안 그룹 정보
output "security_group_id" {
  description = "RDS 보안 그룹 ID"
  value       = aws_security_group.rds.id
}

output "security_group_arn" {
  description = "RDS 보안 그룹 ARN"
  value       = aws_security_group.rds.arn
}

# 서브넷 그룹 정보
output "db_subnet_group_name" {
  description = "DB 서브넷 그룹 이름"
  value       = aws_db_subnet_group.main.name
}

output "db_subnet_group_arn" {
  description = "DB 서브넷 그룹 ARN"
  value       = aws_db_subnet_group.main.arn
}

# 파라미터 그룹 정보
output "parameter_group_name" {
  description = "DB 파라미터 그룹 이름"
  value       = aws_db_parameter_group.main.name
}

output "parameter_group_arn" {
  description = "DB 파라미터 그룹 ARN"
  value       = aws_db_parameter_group.main.arn
}

# 옵션 그룹 정보
output "option_group_name" {
  description = "DB 옵션 그룹 이름"
  value       = var.create_option_group ? aws_db_option_group.main[0].name : null
}

output "option_group_arn" {
  description = "DB 옵션 그룹 ARN"
  value       = var.create_option_group ? aws_db_option_group.main[0].arn : null
}

# KMS 키 정보
output "kms_key_id" {
  description = "RDS 암호화 KMS 키 ID"
  value       = var.create_kms_key ? aws_kms_key.rds[0].key_id : var.kms_key_id
}

output "kms_key_arn" {
  description = "RDS 암호화 KMS 키 ARN"
  value       = var.create_kms_key ? aws_kms_key.rds[0].arn : null
}

output "kms_alias_name" {
  description = "KMS 키 별칭"
  value       = var.create_kms_key ? aws_kms_alias.rds[0].name : null
}

# 모니터링 정보
output "monitoring_role_arn" {
  description = "Enhanced Monitoring IAM 역할 ARN"
  value       = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null
}

output "cloudwatch_log_groups" {
  description = "CloudWatch 로그 그룹 정보"
  value = {
    for log_type in var.enabled_cloudwatch_logs_exports :
    log_type => {
      name = aws_cloudwatch_log_group.rds[log_type].name
      arn  = aws_cloudwatch_log_group.rds[log_type].arn
    }
  }
}

# 연결 정보 (애플리케이션용)
output "connection_info" {
  description = "데이터베이스 연결 정보"
  value = {
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    database = aws_db_instance.main.db_name
    username = aws_db_instance.main.username
  }
  sensitive = false
}

# JDBC/ODBC 연결 문자열
output "jdbc_connection_string" {
  description = "JDBC 연결 문자열"
  value       = "jdbc:postgresql://${aws_db_instance.main.endpoint}/${aws_db_instance.main.db_name}"
}

# 백업 정보
output "backup_info" {
  description = "백업 설정 정보"
  value = {
    retention_period = aws_db_instance.main.backup_retention_period
    backup_window   = aws_db_instance.main.backup_window
    maintenance_window = aws_db_instance.main.maintenance_window
  }
}

# 고가용성 정보
output "availability_info" {
  description = "가용성 설정 정보"
  value = {
    multi_az           = aws_db_instance.main.multi_az
    availability_zone  = aws_db_instance.main.availability_zone
    replica_enabled    = var.create_read_replica
  }
}

# 보안 및 컴플라이언스 정보
output "security_compliance_info" {
  description = "보안 및 컴플라이언스 정보"
  value = {
    encrypted                    = aws_db_instance.main.storage_encrypted
    performance_insights_enabled = aws_db_instance.main.performance_insights_enabled
    monitoring_enabled           = var.monitoring_interval > 0
    cloudwatch_logs_enabled      = length(var.enabled_cloudwatch_logs_exports) > 0
    deletion_protection         = aws_db_instance.main.deletion_protection
  }
}

# 리소스 상태 정보
output "db_instance_status" {
  description = "RDS 인스턴스 상태"
  value       = aws_db_instance.main.status
}

output "db_instance_class" {
  description = "RDS 인스턴스 클래스"
  value       = aws_db_instance.main.instance_class
}

output "engine_info" {
  description = "데이터베이스 엔진 정보"
  value = {
    engine         = aws_db_instance.main.engine
    engine_version = aws_db_instance.main.engine_version
    parameter_group = aws_db_instance.main.parameter_group_name
  }
}

# 스토리지 정보
output "storage_info" {
  description = "스토리지 설정 정보"
  value = {
    allocated_storage     = aws_db_instance.main.allocated_storage
    max_allocated_storage = aws_db_instance.main.max_allocated_storage
    storage_type         = aws_db_instance.main.storage_type
    storage_encrypted    = aws_db_instance.main.storage_encrypted
  }
}