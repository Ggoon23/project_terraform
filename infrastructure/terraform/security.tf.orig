# =========================================
# Security Groups and Rules Configuration
# =========================================

# =========================================
# EKS 클러스터 추가 보안 그룹 규칙
# =========================================

# EKS 클러스터에서 RDS로의 접근 허용
resource "aws_security_group_rule" "eks_to_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.rds.db_security_group_id
  security_group_id        = module.eks.cluster_security_group_id
  description              = "EKS to RDS PostgreSQL access"
}

# EKS 클러스터에서 인터넷으로의 HTTPS 접근 허용
resource "aws_security_group_rule" "eks_https_egress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.eks.cluster_security_group_id
  description       = "EKS HTTPS outbound for package downloads"
}

# EKS 클러스터에서 인터넷으로의 HTTP 접근 허용 (패키지 다운로드용)
resource "aws_security_group_rule" "eks_http_egress" {
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.eks.cluster_security_group_id
  description       = "EKS HTTP outbound for package downloads"
}

# EKS 클러스터 노드 간 통신 허용
resource "aws_security_group_rule" "eks_node_to_node" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = module.eks.cluster_security_group_id
  security_group_id        = module.eks.cluster_security_group_id
  description              = "EKS node to node communication"
}

# =========================================
# RDS 보안 그룹 규칙
# =========================================

# EKS에서 RDS로의 접근 허용
resource "aws_security_group_rule" "rds_from_eks" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.eks.cluster_security_group_id
  security_group_id        = module.rds.db_security_group_id
  description              = "Allow EKS access to RDS"
}

# Lambda에서 RDS로의 접근 허용
resource "aws_security_group_rule" "rds_from_lambda" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.lambda.security_group_id
  security_group_id        = module.rds.db_security_group_id
  description              = "Allow Lambda access to RDS"
}

# Bastion에서 RDS로의 접근 허용 (관리 목적)
resource "aws_security_group_rule" "rds_from_bastion" {
  count                    = var.enable_bastion_host ? 1 : 0
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = module.rds.db_security_group_id
  description              = "Allow Bastion access to RDS for management"
}

# =========================================
# Lambda 보안 그룹 규칙
# =========================================

# Lambda에서 RDS로의 접근
resource "aws_security_group_rule" "lambda_to_rds" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.rds.db_security_group_id
  security_group_id        = module.lambda.security_group_id
  description              = "Lambda to RDS access"
}

# Lambda에서 인터넷으로의 HTTPS 접근 (AWS API 호출용)
resource "aws_security_group_rule" "lambda_https_egress" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.lambda.security_group_id
  description       = "Lambda HTTPS outbound for AWS API calls"
}

# =========================================
# Application Load Balancer 보안 그룹
# =========================================
resource "aws_security_group" "alb" {
  count       = var.enable_load_balancer ? 1 : 0
  name_prefix = "${var.project_name}-${var.environment}-alb"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for Application Load Balancer"

  # HTTP 접근 허용
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS 접근 허용
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 모든 outbound 트래픽 허용
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.project_name}-${var.environment}-alb-sg"
    Component = "LoadBalancer"
  }
}

# ALB에서 EKS로의 접근 허용
resource "aws_security_group_rule" "alb_to_eks" {
  count                    = var.enable_load_balancer ? 1 : 0
  type                     = "egress"
  from_port                = var.application_port
  to_port                  = var.application_port
  protocol                 = "tcp"
  source_security_group_id = module.eks.cluster_security_group_id
  security_group_id        = aws_security_group.alb[0].id
  description              = "ALB to EKS application access"
}

# EKS에서 ALB로부터의 접근 허용
resource "aws_security_group_rule" "eks_from_alb" {
  count                    = var.enable_load_balancer ? 1 : 0
  type                     = "ingress"
  from_port                = var.application_port
  to_port                  = var.application_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb[0].id
  security_group_id        = module.eks.cluster_security_group_id
  description              = "Allow ALB access to EKS applications"
}

# =========================================
# Bastion Host 보안 그룹 (조건부 생성)
# =========================================
resource "aws_security_group" "bastion_extended" {
  count       = var.enable_bastion_host ? 1 : 0
  name_prefix = "${var.project_name}-${var.environment}-bastion-ext"
  vpc_id      = module.vpc.vpc_id
  description = "Extended security group for bastion host"

  # 개발자 접근 CIDR에서 SSH 허용
  dynamic "ingress" {
    for_each = var.developer_access_cidrs
    content {
      description = "SSH from developer networks"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  # EKS API 서버로의 접근 허용
  egress {
    description = "EKS API server access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # 일반적인 outbound 접근
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.project_name}-${var.environment}-bastion-extended-sg"
    Component = "Bastion"
  }
}

# =========================================
# VPC Endpoint 보안 그룹
# =========================================
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "${var.project_name}-${var.environment}-vpc-endpoints"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for VPC endpoints"

  # VPC 내부에서 HTTPS 접근 허용
  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # DNS 쿼리 허용
  ingress {
    description = "DNS from VPC"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "DNS from VPC (UDP)"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name      = "${var.project_name}-${var.environment}-vpc-endpoints-sg"
    Component = "VPCEndpoints"
  }
}

# =========================================
# 모니터링 서비스 보안 그룹
# =========================================
resource "aws_security_group" "monitoring" {
  name_prefix = "${var.project_name}-${var.environment}-monitoring"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for monitoring services (Prometheus, Grafana etc.)"

  # Prometheus 접근
  ingress {
    description = "Prometheus"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Grafana 접근
  ingress {
    description = "Grafana"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Node Exporter 접근
  ingress {
    description = "Node Exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # 모든 outbound 트래픽 허용
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "${var.project_name}-${var.environment}-monitoring-sg"
    Component = "Monitoring"
  }
}

# =========================================
# 보안 정책 문서 생성
# =========================================
locals {
  security_policy_document = {
    vpc_security = {
      description = "VPC Security Configuration"
      rules = [
        "All traffic between subnets is controlled by security groups",
        "Database subnets are isolated from public internet",
        "Private subnets use NAT Gateway for outbound internet access",
        "VPC Flow Logs are enabled for network monitoring"
      ]
    }
    
    application_security = {
      description = "Application Security Configuration"
      rules = [
        "EKS clusters use private endpoints",
        "RDS instances are in private subnets only",
        "Lambda functions run in VPC for data access",
        "All communications use TLS/SSL encryption"
      ]
    }
    
    access_control = {
      description = "Access Control Configuration"
      rules = [
        "Bastion host required for administrative access",
        "Service-to-service communication via security groups",
        "Least privilege IAM roles for all services",
        "MFA required for sensitive operations"
      ]
    }
    
    monitoring_security = {
      description = "Security Monitoring Configuration"
      rules = [
        "CloudTrail enabled for all API calls",
        "GuardDuty active threat detection",
        "Security Hub centralized findings",
        "VPC Flow Logs for network analysis"
      ]
    }
  }
}

# 보안 정책을 SSM Parameter로 저장
resource "aws_ssm_parameter" "security_policy" {
  name  = "/${var.project_name}/${var.environment}/security/policy"
  type  = "String"
  value = jsonencode(local.security_policy_document)
  
  description = "Security policy document for ${var.project_name} ${var.environment}"
  
  tags = {
    Name      = "${var.project_name}-${var.environment}-security-policy"
    Component = "Security"
  }
}