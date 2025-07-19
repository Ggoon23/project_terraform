# 🗃️ RDS 모듈

AWS RDS(Relational Database Service) 구성을 위한 Terraform 모듈입니다.

## 📋 주요 특징

### 🔒 **보안 강화**
- **암호화**: KMS 키를 통한 저장 데이터 암호화
- **네트워크 격리**: VPC 내 프라이빗 서브넷 배치
- **보안 그룹**: 최소 권한 원칙 적용
- **삭제 보호**: 실수로 인한 데이터베이스 삭제 방지

### 📊 **ISMS-P 컴플라이언스**
- **Enhanced Monitoring**: 성능 지표 상세 모니터링
- **Performance Insights**: 데이터베이스 성능 분석
- **CloudWatch Logs**: 데이터베이스 로그 중앙화
- **백업 자동화**: 7일 백업 보관 (기본값)

### 🏗️ **고가용성**
- **Multi-AZ 배포**: 자동 장애 조치
- **읽기 전용 복제본**: 읽기 성능 향상 (선택사항)
- **자동 백업**: 설정 가능한 보관 기간

## 🚀 사용 방법

```hcl
module "rds" {
  source = "./modules/rds"

  # 필수 변수
  project_name         = "security-monitoring"
  vpc_id              = module.vpc.vpc_id
  database_subnet_ids = module.vpc.database_subnet_ids
  master_password     = var.db_password

  # 보안 설정
  allowed_security_groups = [module.eks.worker_security_group_id]
  allowed_cidr_blocks    = ["10.0.0.0/16"]

  # 인스턴스 설정
  instance_class     = "db.t3.small"
  allocated_storage  = 20
  engine            = "postgres"
  engine_version    = "13.13"

  # 고가용성
  multi_az              = true
  create_read_replica   = false

  # 모니터링 (ISMS-P)
  monitoring_interval              = 60
  performance_insights_enabled     = true
  enabled_cloudwatch_logs_exports  = ["postgresql"]

  # 태그
  common_tags = {
    Environment = "production"
    Project     = "security-monitoring"
    Owner       = "Team2"
  }
}
```

## 📁 파일 구조

```
modules/rds/
├── main.tf          # 메인 리소스 정의
├── variables.tf     # 입력 변수 정의
├── outputs.tf       # 출력값 정의
└── README.md        # 이 파일
```

## 🔧 구성 요소

### **핵심 리소스**
- `aws_db_instance` - RDS 데이터베이스 인스턴스
- `aws_db_subnet_group` - DB 서브넷 그룹
- `aws_security_group` - RDS 전용 보안 그룹
- `aws_db_parameter_group` - DB 파라미터 그룹

### **보안 & 암호화**
- `aws_kms_key` - 데이터 암호화용 KMS 키
- `aws_kms_alias` - KMS 키 별칭

### **모니터링 & 로깅**
- `aws_cloudwatch_log_group` - CloudWatch 로그 그룹
- `aws_iam_role` - Enhanced Monitoring IAM 역할

### **고가용성 (선택사항)**
- `aws_db_instance` (replica) - 읽기 전용 복제본

## 📊 주요 변수

| 변수명 | 설명 | 기본값 | 필수 |
|--------|------|--------|------|
| `project_name` | 프로젝트 이름 | - | ✅ |
| `vpc_id` | VPC ID | - | ✅ |
| `database_subnet_ids` | DB 서브넷 ID 목록 | - | ✅ |
| `master_password` | DB 마스터 비밀번호 | - | ✅ |
| `instance_class` | 인스턴스 클래스 | `db.t3.micro` | ❌ |
| `multi_az` | Multi-AZ 배포 | `true` | ❌ |
| `backup_retention_period` | 백업 보관 기간(일) | `7` | ❌ |

## 📤 주요 출력값

| 출력명 | 설명 |
|--------|------|
| `db_instance_endpoint` | 데이터베이스 연결 엔드포인트 |
| `db_instance_port` | 데이터베이스 포트 |
| `database_name` | 데이터베이스 이름 |
| `connection_info` | 연결 정보 객체 |
| `security_group_id` | RDS 보안 그룹 ID |

## 🛡️ 보안 설정

### **네트워크 보안**
- 프라이빗 서브넷에만 배치
- 지정된 보안 그룹/CIDR에서만 접근 허용
- 퍼블릭 접근 완전 차단

### **데이터 보호**
- 저장 데이터 KMS 암호화
- 전송 중 데이터 SSL/TLS 암호화
- 자동 백업 및 스냅샷

### **접근 제어**
- IAM 데이터베이스 인증 지원
- 세밀한 보안 그룹 규칙
- 삭제 보호 활성화

## 📈 모니터링 설정

### **ISMS-P 컴플라이언스**
- Enhanced Monitoring (60초 간격)
- Performance Insights 활성화
- CloudWatch Logs 수집
- 백업 및 복구 정책

### **수집되는 로그**
- PostgreSQL 로그
- 슬로우 쿼리 로그
- 에러 로그
- 연결 로그

## ⚙️ 고급 설정

### **성능 최적화**
```hcl
# 고성능 인스턴스
instance_class = "db.r5.xlarge"
storage_type  = "gp3"

# 읽기 전용 복제본
create_read_replica    = true
replica_instance_class = "db.r5.large"
```

### **개발 환경용**
```hcl
# 비용 최적화
instance_class          = "db.t3.micro"
multi_az               = false
deletion_protection    = false
skip_final_snapshot    = true
backup_retention_period = 1
```

## 🚨 주의사항

1. **비밀번호 관리**: `master_password`는 민감 정보로 관리
2. **Multi-AZ**: 운영 환경에서는 반드시 활성화
3. **백업**: 중요 데이터는 백업 보관 기간 연장 고려
4. **모니터링**: Enhanced Monitoring은 추가 비용 발생

## 📖 예제

### **운영 환경 설정**
```hcl
module "production_rds" {
  source = "./modules/rds"
  
  project_name = "prod-app"
  vpc_id       = module.vpc.vpc_id
  database_subnet_ids = module.vpc.database_subnet_ids
  
  # 고성능 설정
  instance_class     = "db.r5.large"
  allocated_storage  = 100
  multi_az          = true
  
  # 보안 강화
  deletion_protection     = true
  backup_retention_period = 30
  
  # 모니터링 강화
  monitoring_interval           = 15
  performance_insights_enabled = true
  
  master_password = var.production_db_password
}
```

### **개발 환경 설정**
```hcl
module "dev_rds" {
  source = "./modules/rds"
  
  project_name = "dev-app"
  vpc_id       = module.vpc.vpc_id
  database_subnet_ids = module.vpc.database_subnet_ids
  
  # 비용 최적화
  instance_class          = "db.t3.micro"
  multi_az               = false
  deletion_protection    = false
  skip_final_snapshot    = true
  
  master_password = var.dev_db_password
}
```

---

📝 **개발팀**: Team2 | 🏷️ **버전**: 1.0.0 | 📅 **업데이트**: 2025.01.19