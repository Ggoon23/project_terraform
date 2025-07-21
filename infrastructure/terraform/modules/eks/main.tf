# infrastructure/terraform/modules/eks/main.tf
# EKS 클러스터 구성을 위한 Terraform 모듈

# KMS 키 (EKS 시크릿 암호화용)
resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key - ${var.cluster_name}"
  deletion_window_in_days = var.kms_deletion_window

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-eks-kms-key"
    Use  = "EKS Secret Encryption"
  })
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-eks"
  target_key_id = aws_kms_key.eks.key_id
}

# CloudWatch 로그 그룹 (EKS 제어 플레인 로그용)
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-eks-cluster-logs"
  })
}

# EKS 클러스터 서비스 역할
resource "aws_iam_role" "cluster" {
  name = "${var.cluster_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# EKS 클러스터 정책 연결
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

# EKS 클러스터 보안 그룹
resource "aws_security_group" "cluster" {
  name_prefix = "${var.cluster_name}-eks-cluster-"
  vpc_id      = var.vpc_id
  description = "Security group for EKS cluster control plane"

  # HTTPS 통신 (EKS API)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.cluster_endpoint_private_access_cidrs
    description = "HTTPS access to EKS API"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-eks-cluster-sg"
    Type = "EKS Cluster Security Group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Splunk 통신 포트 추가 (기존 security group에 추가)
resource "aws_security_group_rule" "splunk_forwarder_ports" {
  type              = "ingress"
  from_port         = 9997
  to_port           = 9997
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]  # VPC CIDR 범위로 조정
  security_group_id = aws_security_group.node_group.id
  description       = "Splunk forwarder communication"
}

resource "aws_security_group_rule" "splunk_web_interface" {
  type              = "ingress"
  from_port         = 8089
  to_port           = 8089
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]  # 관리 네트워크만 허용
  security_group_id = aws_security_group.node_group.id
  description       = "Splunk management interface"
}

# EKS 클러스터
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.cluster_endpoint_private_access
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
    security_group_ids      = [aws_security_group.cluster.id]
  }

  # 제어 플레인 로깅 (ISMS-P 컴플라이언스)
  enabled_cluster_log_types = var.cluster_enabled_log_types

  # 시크릿 암호화 (ISMS-P 컴플라이언스)
  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = ["secrets"]
  }

  tags = merge(var.common_tags, {
    Name = var.cluster_name
    Type = "EKS Cluster"
  })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
    aws_cloudwatch_log_group.eks
  ]
}

# EKS 노드 그룹 IAM 역할
resource "aws_iam_role" "node_group" {
  name = "${var.cluster_name}-eks-node-group-role"

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

  tags = var.common_tags
}

# EKS 노드 그룹 정책 연결
resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# 추가 정책: CloudWatch 및 로깅
resource "aws_iam_role_policy_attachment" "node_group_CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.node_group.name
}

# EKS 노드 그룹 보안 그룹
resource "aws_security_group" "node_group" {
  name_prefix = "${var.cluster_name}-eks-node-group-"
  vpc_id      = var.vpc_id
  description = "Security group for EKS node group"

  # ❌ 클러스터와 통신 부분 제거 (source_security_group_id는 여기서 사용 금지)
  # -> 아래에서 aws_security_group_rule로 분리

  # 노드간 통신
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    description = "Communication between nodes"
  }

  # SSH 접근 (선택사항)
  dynamic "ingress" {
    for_each = var.enable_ssh_access ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_access_cidrs
      description = "SSH access"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-eks-node-group-sg"
    Type = "EKS Node Group Security Group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# 클러스터에서 노드 그룹으로 통신 허용
resource "aws_security_group_rule" "node_group_from_cluster" {
  type                     = "ingress"
  from_port               = 0
  to_port                 = 65535
  protocol                = "tcp"
  security_group_id       = aws_security_group.node_group.id
  source_security_group_id = aws_security_group.cluster.id
  description             = "Communication with EKS cluster"
}


# 시작 템플릿 (노드 그룹용)
resource "aws_launch_template" "node_group" {
  count = var.create_launch_template ? 1 : 0

  name_prefix = "${var.cluster_name}-eks-node-"
  image_id    = var.ami_id
  instance_type = var.instance_types[0]
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.node_group.id]

  # 사용자 데이터 (보안 강화)
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    cluster_name = var.cluster_name
    cluster_endpoint = aws_eks_cluster.main.endpoint
    cluster_ca = aws_eks_cluster.main.certificate_authority[0].data
  }))

  # EBS 최적화 및 암호화
  ebs_optimized = true

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_type = var.ebs_volume_type
      volume_size = var.ebs_volume_size
      encrypted   = true
      kms_key_id  = aws_kms_key.eks.arn
    }
  }

  # 메타데이터 서비스 설정 (보안 강화)
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 1
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.common_tags, {
      Name = "${var.cluster_name}-eks-node"
      Type = "EKS Worker Node"
    })
  }

  tags = var.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

# EKS 매니지드 노드 그룹
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = var.private_subnet_ids

  # 인스턴스 타입
  instance_types = var.instance_types
  capacity_type  = var.capacity_type
  ami_type       = var.ami_type
  disk_size      = var.disk_size

  # 스케일링 설정
  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  # 업데이트 설정
  update_config {
    max_unavailable_percentage = var.max_unavailable_percentage
  }

  # 원격 액세스 설정
  dynamic "remote_access" {
    for_each = var.enable_ssh_access ? [1] : []
    content {
      ec2_ssh_key               = var.key_name
      source_security_group_ids = [aws_security_group.node_group.id]
    }
  }

  # 시작 템플릿 설정
  dynamic "launch_template" {
    for_each = var.create_launch_template ? [1] : []
    content {
      id      = aws_launch_template.node_group[0].id
      version = aws_launch_template.node_group[0].latest_version
    }
  }

  # 테인트 설정 (선택사항)
  dynamic "taint" {
    for_each = var.node_group_taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-node-group"
    Type = "EKS Managed Node Group"
  })

  depends_on = [
    aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_group_CloudWatchAgentServerPolicy
  ]

  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }
}

# EKS 애드온들
resource "aws_eks_addon" "vpc_cni" {
  count = var.enable_vpc_cni_addon ? 1 : 0

  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "vpc-cni"
  addon_version            = var.vpc_cni_addon_version
  resolve_conflicts        = "OVERWRITE"
  service_account_role_arn = aws_iam_role.vpc_cni[0].arn

  tags = var.common_tags

  depends_on = [aws_eks_node_group.main]
}

resource "aws_eks_addon" "coredns" {
  count = var.enable_coredns_addon ? 1 : 0

  cluster_name      = aws_eks_cluster.main.name
  addon_name        = "coredns"
  addon_version     = var.coredns_addon_version
  resolve_conflicts = "OVERWRITE"

  tags = var.common_tags

  depends_on = [aws_eks_node_group.main]
}

resource "aws_eks_addon" "kube_proxy" {
  count = var.enable_kube_proxy_addon ? 1 : 0

  cluster_name      = aws_eks_cluster.main.name
  addon_name        = "kube-proxy"
  addon_version     = var.kube_proxy_addon_version
  resolve_conflicts = "OVERWRITE"

  tags = var.common_tags

  depends_on = [aws_eks_node_group.main]
}

# VPC CNI를 위한 IAM 역할
resource "aws_iam_role" "vpc_cni" {
  count = var.enable_vpc_cni_addon ? 1 : 0
  name  = "${var.cluster_name}-vpc-cni-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks[0].url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-node"
            "${replace(aws_iam_openid_connect_provider.eks[0].url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  count      = var.enable_vpc_cni_addon ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni[0].name
}

# OIDC Identity Provider
data "tls_certificate" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  count = var.enable_irsa ? 1 : 0

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(var.common_tags, {
    Name = "${var.cluster_name}-oidc-provider"
  })
}