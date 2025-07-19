# ⚙️ EKS 모듈

AWS EKS(Elastic Kubernetes Service) 클러스터 구성을 위한 Terraform 모듈입니다.

## 🎯 주요 특징

### 🔒 **보안 강화**
- **시크릿 암호화**: KMS 키를 통한 Kubernetes 시크릿 암호화
- **프라이빗 엔드포인트**: API 서버 프라이빗 접근 기본 설정
- **EBS 암호화**: 노드 디스크 전체 암호화
- **IMDSv2 강제**: 메타데이터 서비스 보안 강화

### 📊 **ISMS-P 컴플라이언스**
- **제어 플레인 로깅**: API, Audit, Authenticator 로그 수집
- **노드 모니터링**: CloudWatch를 통한 실시간 메트릭
- **보안 감사**: 시스템/보안/감사 로그 중앙화
- **접근 제어**: RBAC 및 네트워크 정책 지원

### 🏗️ **고가용성**
- **Multi-AZ 배포**: 여러 가용영역에 노드 분산
- **Managed 애드온**: VPC CNI, CoreDNS, kube-proxy 자동 관리
- **Auto Scaling**: 워크로드 기반 자동 확장
- **Spot 인스턴스**: 비용 최적화 옵션

## 🚀 기본 사용법

```hcl
module "eks" {
  source = "./modules/eks"

  # 필수 설정
  cluster_name        = "my-eks-cluster"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.eks_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  # 노드 그룹 설정
  instance_types = ["t3.medium"]
  desired_size   = 2
  max_size      = 4
  min_size      = 1

  # 보안 설정
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  common_tags = {
    Environment = "dev"
    Project     = "security-monitoring"
  }
}
```

## ⚡ 고급 설정 예시

```hcl
module "eks_production" {
  source = "./modules/eks"

  cluster_name = "prod-cluster"
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.eks_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids

  # 프로덕션 설정
  cluster_version = "1.28"
  instance_types  = ["m5.large", "m5.xlarge"]
  capacity_type   = "ON_DEMAND"
  
  # 스케일링
  desired_size = 3
  max_size     = 10
  min_size     = 3

  # 보안 강화
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false
  enable_irsa = true
  
  # 로깅 (ISMS-P 컴플라이언스)
  cluster_enabled_log_types = [
    "api", "audit", "authenticator", 
    "controllerManager", "scheduler"
  ]
  log_retention_days = 90

  # 애드온
  enable_vpc_cni_addon    = true
  enable_coredns_addon    = true
  enable_kube_proxy_addon = true

  # SSH 접근 (비상시만)
  enable_ssh_access = false
  
  common_tags = {
    Environment = "production"
    Compliance  = "ISMS-P"
    Backup      = "required"
  }
}
```

## 📋 주요 변수

| 변수 | 설명 | 기본값 | 필수 |
|------|------|--------|------|
| `cluster_name` | EKS 클러스터 이름 | - | ✅ |
| `vpc_id` | VPC ID | - | ✅ |
| `subnet_ids` | 클러스터용 서브넷 ID 목록 | - | ✅ |
| `private_subnet_ids` | 노드용 프라이빗 서브넷 ID | - | ✅ |
| `cluster_version` | EKS 버전 | `"1.28"` | ❌ |
| `instance_types` | 노드 인스턴스 타입 | `["t3.medium"]` | ❌ |
| `desired_size` | 노드 원하는 개수 | `2` | ❌ |
| `cluster_endpoint_private_access` | 프라이빗 API 접근 | `true` | ❌ |
| `enable_irsa` | IRSA 활성화 | `true` | ❌ |

## 📤 출력값

```hcl
# 클러스터 정보
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_name" {
  value = module.eks.cluster_name
}

# 인증 정보
output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

# IRSA용 OIDC Provider
output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

# kubectl 설정 명령어
output "update_kubeconfig_command" {
  value = module.eks.cluster_access_commands.update_kubeconfig
}
```

## 🔧 kubectl 연결

```bash
# kubeconfig 업데이트
aws eks update-kubeconfig --region ap-northeast-2 --name my-eks-cluster

# 클러스터 상태 확인
kubectl get nodes
kubectl get pods --all-namespaces
```

## 🛡️ 보안 기능

### **암호화**
- ✅ Kubernetes 시크릿 KMS 암호화
- ✅ EBS 볼륨 암호화
- ✅ 전송 중 데이터 암호화 (TLS)

### **네트워크 보안**
- ✅ 프라이빗 API 엔드포인트
- ✅ 보안 그룹 최소 권한
- ✅ 네트워크 정책 지원

### **접근 제어**
- ✅ IAM 역할 기반 접근
- ✅ RBAC 권한 제어
- ✅ IRSA (Service Account IAM 역할)

### **모니터링**
- ✅ 제어 플레인 로깅
- ✅ CloudWatch 메트릭
- ✅ 보안 감사 로그

## 🔍 트러블슈팅

### **일반적인 문제**

**1. 노드가 클러스터에 조인되지 않는 경우**
```bash
# 노드 그룹 상태 확인
aws eks describe-nodegroup --cluster-name my-cluster --nodegroup-name main

# CloudWatch 로그 확인
aws logs describe-log-groups --log-group-name-prefix "/aws/eks/my-cluster"
```

**2. kubectl 연결 실패**
```bash
# AWS CLI 설정 확인
aws sts get-caller-identity

# kubeconfig 재설정
aws eks update-kubeconfig --region ap-northeast-2 --name my-cluster --profile your-profile
```

**3. IRSA 권한 문제**
```bash
# OIDC Provider 확인
aws eks describe-cluster --name my-cluster --query "cluster.identity.oidc.issuer"

# Service Account 확인
kubectl describe sa your-service-account -n your-namespace
```

## 📚 참고 문서

- [AWS EKS 사용자 가이드](https://docs.aws.amazon.com/eks/latest/userguide/)
- [Kubernetes 공식 문서](https://kubernetes.io/docs/)
- [ISMS-P 인증 기준](https://isms.kisa.or.kr/)
- [EKS 보안 모범 사례](https://aws.github.io/aws-eks-best-practices/)

## 🏷️ 태그 예시

```hcl
common_tags = {
  Terraform    = "true"
  Environment  = "production"
  Project      = "security-monitoring"
  Team         = "platform"
  Owner        = "team2@company.com"
  Compliance   = "ISMS-P"
  Backup       = "required"
  Monitoring   = "enabled"
}
```

---

> 💡 **팁**: 프로덕션 환경에서는 `cluster_endpoint_public_access = false`로 설정하여 보안을 강화하세요!