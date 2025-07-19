# infrastructure/terraform/modules/vpc/outputs.tf
# VPC 모듈 출력값 정의

# VPC 정보
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR 블록"
  value       = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = "VPC ARN"
  value       = aws_vpc.main.arn
}

# 인터넷 게이트웨이
output "internet_gateway_id" {
  description = "인터넷 게이트웨이 ID"
  value       = aws_internet_gateway.main.id
}

# 서브넷 정보
output "public_subnet_ids" {
  description = "퍼블릭 서브넷 ID 목록"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "프라이빗 서브넷 ID 목록"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "데이터베이스 서브넷 ID 목록"
  value       = aws_subnet.database[*].id
}

output "public_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR 목록"
  value       = aws_subnet.public[*].cidr_block
}

output "private_subnet_cidrs" {
  description = "프라이빗 서브넷 CIDR 목록"
  value       = aws_subnet.private[*].cidr_block
}

output "database_subnet_cidrs" {
  description = "데이터베이스 서브넷 CIDR 목록"
  value       = aws_subnet.database[*].cidr_block
}

# 가용 영역 정보
output "availability_zones" {
  description = "사용된 가용 영역 목록"
  value       = data.aws_availability_zones.available.names
}

# NAT Gateway 정보
output "nat_gateway_ids" {
  description = "NAT Gateway ID 목록"
  value       = aws_nat_gateway.main[*].id
}

output "nat_public_ips" {
  description = "NAT Gateway 퍼블릭 IP 목록"
  value       = aws_eip.nat[*].public_ip
}

# 라우팅 테이블 정보
output "public_route_table_id" {
  description = "퍼블릭 라우팅 테이블 ID"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "프라이빗 라우팅 테이블 ID 목록"
  value       = aws_route_table.private[*].id
}

output "database_route_table_id" {
  description = "데이터베이스 라우팅 테이블 ID"
  value       = aws_route_table.database.id
}

# 보안 모니터링 관련
output "vpc_flow_log_id" {
  description = "VPC Flow Log ID"
  value       = var.enable_vpc_flow_logs ? aws_flow_log.vpc[0].id : null
}

output "vpc_flow_log_group_name" {
  description = "VPC Flow Log CloudWatch 로그 그룹 이름"
  value       = var.enable_vpc_flow_logs ? aws_cloudwatch_log_group.vpc_flow_log[0].name : null
}

output "vpc_flow_log_group_arn" {
  description = "VPC Flow Log CloudWatch 로그 그룹 ARN"
  value       = var.enable_vpc_flow_logs ? aws_cloudwatch_log_group.vpc_flow_log[0].arn : null
}

# 네트워크 정보 (다른 모듈에서 사용)
output "vpc_default_security_group_id" {
  description = "VPC 기본 보안 그룹 ID"
  value       = aws_vpc.main.default_security_group_id
}

output "vpc_main_route_table_id" {
  description = "VPC 메인 라우팅 테이블 ID"
  value       = aws_vpc.main.main_route_table_id
}

output "vpc_default_network_acl_id" {
  description = "VPC 기본 네트워크 ACL ID"
  value       = aws_vpc.main.default_network_acl_id
}

# 서브넷 그룹 (RDS용)
output "database_subnet_group_name" {
  description = "데이터베이스 서브넷 그룹 이름 (RDS에서 사용)"
  value       = "${var.project_name}-db-subnet-group"
}

# EKS 클러스터용 서브넷 정보
output "eks_subnet_ids" {
  description = "EKS 클러스터용 서브넷 ID (퍼블릭 + 프라이빗)"
  value       = concat(aws_subnet.public[*].id, aws_subnet.private[*].id)
}

# 보안 컴플라이언스 정보
output "compliance_info" {
  description = "ISMS-P 컴플라이언스 관련 정보"
  value = {
    vpc_flow_logs_enabled = var.enable_vpc_flow_logs
    nat_gateway_enabled   = var.enable_nat_gateway
    multi_az_deployment   = length(aws_subnet.public) >= 2
    environment          = var.environment
  }
}

# 네트워크 구성 요약
output "network_summary" {
  description = "네트워크 구성 요약 정보"
  value = {
    vpc_id                = aws_vpc.main.id
    vpc_cidr             = aws_vpc.main.cidr_block
    public_subnets_count  = length(aws_subnet.public)
    private_subnets_count = length(aws_subnet.private)
    database_subnets_count = length(aws_subnet.database)
    availability_zones    = length(data.aws_availability_zones.available.names)
    nat_gateways_count   = length(aws_nat_gateway.main)
  }
}