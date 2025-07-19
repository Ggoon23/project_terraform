# 🏗️ VPC 모듈

Terraform 기반 AWS VPC 3-Tier 아키텍처 구성 모듈

## 📋 개요

ISMS-P 컴플라이언스를 준수하는 고가용성 VPC 네트워크 인프라를 자동 구축합니다.

```
📊 구성: 3-Tier (Public/Private/Database) × Multi-AZ
🔒 보안: VPC Flow Logs + Network ACL + Security Groups  
🌍 가용성: 99.99% (Multi-AZ 배치)
```

## 🏛️ 아키텍처

```
VPC (10.0.0.0/16)
├── Public Subnet (10.0.1-2.0/24)    → ALB, NAT Gateway
├── Private Subnet (10.0.10-20.0/24) → EKS, Application
└── Database Subnet (10.0.100-110.0/24) → RDS, Cache
```

## 🚀 사용법

### 1️⃣ 기본 사용
```hcl
module "vpc" {
  source = "./modules/vpc"
  
  project_name = "security-monitoring"
  environment  = "prod"
  vpc_cidr     = "10.0.0.0/16"
}
```

### 2️⃣ 고급 설정
```hcl
module "vpc" {
  source = "./modules/vpc"
  
  project_name           = "security-monitoring"
  environment           = "prod"
  vpc_cidr              = "10.0.0.0/16"
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.10.0/24", "10.0.20.0/24"]
  database_subnet_cidrs = ["10.0.100.0/24", "10.0.110.0/24"]
  
  # ISMS-P 보안 설정
  enable_vpc_flow_logs     = true
  enable_nat_gateway       = true
  flow_log_retention_days  = 365
  
  common_tags = {
    Project     = "security-monitoring"
    Team        = "Team2"
    Compliance  = "ISMS-P"
    Environment = "production"
  }
}
```

## 📤 출력값

| Output | 설명 |
|--------|------|
| `vpc_id` | VPC ID |
| `public_subnet_ids` | 퍼블릭 서브넷 ID 목록 |
| `private_subnet_ids` | 프라이빗 서브넷 ID 목록 |
| `database_subnet_ids` | DB 서브넷 ID 목록 |
| `nat_gateway_ids` | NAT Gateway ID 목록 |
| `vpc_flow_log_group_arn` | Flow Logs CloudWatch 그룹 ARN |

## 🛡️ 보안 기능

- ✅ **VPC Flow Logs**: 모든 네트워크 트래픽 로깅
- ✅ **Multi-AZ NAT**: 각 AZ별 독립 NAT Gateway  
- ✅ **Network Segmentation**: 3계층 네트워크 분리
- ✅ **CloudWatch Integration**: 중앙화된 로그 관리
- ✅ **ISMS-P 태깅**: 컴플라이언스 추적 가능

## 🔧 요구사항

- Terraform >= 1.0
- AWS Provider >= 4.0
- 최소 2개 AZ 사용 가능한 리전

## 📋 변수

| 변수 | 타입 | 기본값 | 설명 |
|------|------|--------|------|
| `project_name` | string | - | 프로젝트 이름 (필수) |
| `environment` | string | `dev` | 환경 구분 |
| `vpc_cidr` | string | `10.0.0.0/16` | VPC CIDR 블록 |
| `enable_nat_gateway` | bool | `true` | NAT Gateway 활성화 |
| `enable_vpc_flow_logs` | bool | `true` | VPC Flow Logs 활성화 |

## 🎯 ISMS-P 컴플라이언스

| 항목 | 구현 사항 |
|------|----------|
| 네트워크 접근 통제 | Security Groups + NACLs |
| 접속 기록 관리 | VPC Flow Logs (30일+ 보관) |
| 네트워크 분리 | 3-Tier 아키텍처 |
| 암호화 통신 | TLS/SSL 지원 |

---
**Team 2** | Security Monitoring Platform | 2025.01