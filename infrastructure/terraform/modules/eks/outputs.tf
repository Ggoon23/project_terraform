# infrastructure/terraform/modules/eks/outputs.tf
# EKS 모듈 출력값 정의

# 클러스터 기본 정보
output "cluster_id" {
  description = "EKS 클러스터 ID"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "EKS 클러스터 ARN"
  value       = aws_eks_cluster.main.arn
}

output "cluster_name" {
  description = "EKS 클러스터 이름"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS 클러스터 API 서버 엔드포인트"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "EKS 클러스터 버전"
  value       = aws_eks_cluster.main.version
}

output "cluster_platform_version" {
  description = "EKS 클러스터 플랫폼 버전"
  value       = aws_eks_cluster.main.platform_version
}

output "cluster_status" {
  description = "EKS 클러스터 상태"
  value       = aws_eks_cluster.main.status
}

# 클러스터 인증 정보
output "cluster_certificate_authority_data" {
  description = "EKS 클러스터 인증서 데이터 (base64 인코딩)"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_identity" {
  description = "EKS 클러스터 OIDC 정보"
  value       = aws_eks_cluster.main.identity
}

output "cluster_oidc_issuer_url" {
  description = "EKS 클러스터 OIDC Issuer URL"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# OIDC Provider 정보
output "oidc_provider_arn" {
  description = "OIDC Provider ARN (IRSA용)"
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.eks[0].arn : null
}

output "oidc_provider_url" {
  description = "OIDC Provider URL"
  value       = var.enable_irsa ? aws_iam_openid_connect_provider.eks[0].url : null
}

# 노드 그룹 정보
output "node_group_arn" {
  description = "EKS 노드 그룹 ARN"
  value       = aws_eks_node_group.main.arn
}

output "node_group_status" {
  description = "EKS 노드 그룹 상태"
  value       = aws_eks_node_group.main.status
}

output "node_group_capacity_type" {
  description = "노드 그룹 용량 타입"
  value       = aws_eks_node_group.main.capacity_type
}

output "node_group_instance_types" {
  description = "노드 그룹 인스턴스 타입"
  value       = aws_eks_node_group.main.instance_types
}

output "node_group_ami_type" {
  description = "노드 그룹 AMI 타입"
  value       = aws_eks_node_group.main.ami_type
}

output "node_group_scaling_config" {
  description = "노드 그룹 스케일링 설정"
  value       = aws_eks_node_group.main.scaling_config
}

# IAM 역할 정보
output "cluster_iam_role_arn" {
  description = "EKS 클러스터 IAM 역할 ARN"
  value       = aws_iam_role.cluster.arn
}

output "cluster_iam_role_name" {
  description = "EKS 클러스터 IAM 역할 이름"
  value       = aws_iam_role.cluster.name
}

output "node_group_iam_role_arn" {
  description = "EKS 노드 그룹 IAM 역할 ARN"
  value       = aws_iam_role.node_group.arn
}

output "node_group_iam_role_name" {
  description = "EKS 노드 그룹 IAM 역할 이름"
  value       = aws_iam_role.node_group.name
}

# 보안 그룹 정보
output "cluster_security_group_id" {
  description = "EKS 클러스터 보안 그룹 ID"
  value       = aws_security_group.cluster.id
}

output "node_group_security_group_id" {
  description = "EKS 노드 그룹 보안 그룹 ID"
  value       = aws_security_group.node_group.id
}

output "cluster_primary_security_group_id" {
  description = "EKS 클러스터 기본 보안 그룹 ID"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

# 암호화 정보
output "kms_key_id" {
  description = "EKS 암호화 KMS 키 ID"
  value       = aws_kms_key.eks.key_id
}

output "kms_key_arn" {
  description = "EKS 암호화 KMS 키 ARN"
  value       = aws_kms_key.eks.arn
}

output "kms_alias_name" {
  description = "EKS KMS 키 별칭"
  value       = aws_kms_alias.eks.name
}

# 로깅 정보
output "cloudwatch_log_group_name" {
  description = "EKS CloudWatch 로그 그룹 이름"
  value       = aws_cloudwatch_log_group.eks.name
}

output "cloudwatch_log_group_arn" {
  description = "EKS CloudWatch 로그 그룹 ARN"
  value       = aws_cloudwatch_log_group.eks.arn
}

output "cluster_enabled_log_types" {
  description = "활성화된 클러스터 로그 타입"
  value       = aws_eks_cluster.main.enabled_cluster_log_types
}

# EKS 애드온 정보
output "vpc_cni_addon_arn" {
  description = "VPC CNI 애드온 ARN"
  value       = var.enable_vpc_cni_addon ? aws_eks_addon.vpc_cni[0].arn : null
}

output "coredns_addon_arn" {
  description = "CoreDNS 애드온 ARN"
  value       = var.enable_coredns_addon ? aws_eks_addon.coredns[0].arn : null
}

output "kube_proxy_addon_arn" {
  description = "kube-proxy 애드온 ARN"
  value       = var.enable_kube_proxy_addon ? aws_eks_addon.kube_proxy[0].arn : null
}

# 네트워크 정보
output "cluster_vpc_config" {
  description = "EKS 클러스터 VPC 설정"
  value       = aws_eks_cluster.main.vpc_config
}

output "cluster_endpoint_config" {
  description = "클러스터 엔드포인트 설정 정보"
  value = {
    endpoint_private_access = aws_eks_cluster.main.vpc_config[0].endpoint_private_access
    endpoint_public_access  = aws_eks_cluster.main.vpc_config[0].endpoint_public_access
    public_access_cidrs     = aws_eks_cluster.main.vpc_config[0].public_access_cidrs
  }
}

# Kubectl 설정용 정보
output "kubeconfig" {
  description = "kubectl 설정용 정보"
  value = {
    cluster_name                     = aws_eks_cluster.main.name
    endpoint                        = aws_eks_cluster.main.endpoint
    certificate_authority_data      = aws_eks_cluster.main.certificate_authority[0].data
    region                         = data.aws_region.current.name
  }
}

# 데이터 소스
data "aws_region" "current" {}

# 클러스터 접근용 명령어
output "cluster_access_commands" {
  description = "클러스터 접근을 위한 AWS CLI 명령어"
  value = {
    update_kubeconfig = "aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${aws_eks_cluster.main.name}"
    get_token        = "aws eks get-token --cluster-name ${aws_eks_cluster.main.name}"
  }
}

# 보안 및 컴플라이언스 정보
output "security_compliance_info" {
  description = "보안 및 컴플라이언스 설정 정보"
  value = {
    secrets_encrypted               = true
    private_endpoint_enabled        = aws_eks_cluster.main.vpc_config[0].endpoint_private_access
    public_endpoint_restricted      = length(aws_eks_cluster.main.vpc_config[0].public_access_cidrs) < 2
    control_plane_logging_enabled   = length(aws_eks_cluster.main.enabled_cluster_log_types) > 0
    node_group_private_subnets      = true
    kms_encryption_enabled          = true
    iam_roles_configured           = true
  }
}

# 시작 템플릿 정보
output "launch_template_id" {
  description = "노드 그룹 시작 템플릿 ID"
  value       = var.create_launch_template ? aws_launch_template.node_group[0].id : null
}

output "launch_template_latest_version" {
  description = "시작 템플릿 최신 버전"
  value       = var.create_launch_template ? aws_launch_template.node_group[0].latest_version : null
}

# 태그 정보
output "cluster_tags" {
  description = "클러스터 태그"
  value       = aws_eks_cluster.main.tags
}

# 리소스 요약
output "eks_cluster_summary" {
  description = "EKS 클러스터 구성 요약"
  value = {
    cluster_name        = aws_eks_cluster.main.name
    cluster_version     = aws_eks_cluster.main.version
    cluster_status      = aws_eks_cluster.main.status
    node_group_name     = aws_eks_node_group.main.node_group_name
    node_group_status   = aws_eks_node_group.main.status
    instance_types      = aws_eks_node_group.main.instance_types
    capacity_type       = aws_eks_node_group.main.capacity_type
    scaling_config      = aws_eks_node_group.main.scaling_config
    enabled_addons = {
      vpc_cni    = var.enable_vpc_cni_addon
      coredns    = var.enable_coredns_addon
      kube_proxy = var.enable_kube_proxy_addon
    }
    irsa_enabled = var.enable_irsa
  }
}