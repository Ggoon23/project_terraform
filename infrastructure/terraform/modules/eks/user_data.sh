#!/bin/bash
# infrastructure/terraform/modules/eks/user_data.sh
# EKS 노드 초기화 스크립트 (보안 강화)

set -o xtrace

# 변수 설정
CLUSTER_NAME="${cluster_name}"
CLUSTER_ENDPOINT="${cluster_endpoint}"
CLUSTER_CA="${cluster_ca}"

# 시스템 업데이트
yum update -y

# CloudWatch 에이전트 설치 (ISMS-P 컴플라이언스)
yum install -y amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# SSM 에이전트 설치 (원격 관리용)
yum install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Docker 보안 설정
cat <<EOF > /etc/docker/daemon.json
{
  "log-driver": "awslogs",
  "log-opts": {
    "awslogs-group": "/aws/eks/${cluster_name}/docker",
    "awslogs-region": "$(curl -s http://169.254.169.254/latest/meta-data/placement/region)"
  },
  "live-restore": true,
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5,
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

# Docker 서비스 재시작
systemctl restart docker

# kubelet 보안 설정
cat <<EOF > /etc/kubernetes/kubelet/kubelet-config.json
{
  "kind": "KubeletConfiguration",
  "apiVersion": "kubelet.config.k8s.io/v1beta1",
  "address": "0.0.0.0",
  "port": 10250,
  "readOnlyPort": 0,
  "cgroupDriver": "systemd",
  "hairpinMode": "hairpin-veth",
  "serializeImagePulls": false,
  "featureGates": {
    "RotateKubeletServerCertificate": true
  },
  "protectKernelDefaults": true,
  "makeIPTablesUtilChains": true,
  "eventRecordQPS": 0,
  "tlsCipherSuites": [
    "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256",
    "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
    "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305",
    "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384",
    "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305",
    "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
  ]
}
EOF

# 보안 강화: 불필요한 서비스 비활성화
systemctl disable nfs-client.target
systemctl disable remote-fs.target

# 보안 강화: 커널 파라미터 설정
cat <<EOF >> /etc/sysctl.conf
# 네트워크 보안
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1

# IPv6 비활성화 (필요시)
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

# 커널 보안
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1
EOF

sysctl -p

# 파일 시스템 보안 설정
echo "tmpfs /tmp tmpfs defaults,rw,nosuid,nodev,noexec,relatime 0 0" >> /etc/fstab
echo "tmpfs /var/tmp tmpfs defaults,rw,nosuid,nodev,noexec,relatime 0 0" >> /etc/fstab

# CloudWatch 로그 그룹 생성 (Docker 로그용)
aws logs create-log-group --log-group-name "/aws/eks/${cluster_name}/docker" --region $(curl -s http://169.254.169.254/latest/meta-data/placement/region) || true

# EKS 노드 부트스트랩
/etc/eks/bootstrap.sh "${cluster_name}" \
  --container-runtime docker \
  --kubelet-extra-args '--node-labels=node.kubernetes.io/lifecycle=normal' \
  --b64-cluster-ca "${cluster_ca}" \
  --apiserver-endpoint "${cluster_endpoint}"

# 로그 수집 설정 (ISMS-P 컴플라이언스)
cat <<EOF > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "cwagent"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/eks/${cluster_name}/system",
            "log_stream_name": "{instance_id}/messages"
          },
          {
            "file_path": "/var/log/secure",
            "log_group_name": "/aws/eks/${cluster_name}/security",
            "log_stream_name": "{instance_id}/secure"
          },
          {
            "file_path": "/var/log/audit/audit.log",
            "log_group_name": "/aws/eks/${cluster_name}/audit",
            "log_stream_name": "{instance_id}/audit"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "EKS/NodeMetrics",
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          "used_percent"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "diskio": {
        "measurement": [
          "io_time"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "netstat": {
        "measurement": [
          "tcp_established",
          "tcp_time_wait"
        ],
        "metrics_collection_interval": 60
      },
      "swap": {
        "measurement": [
          "swap_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# CloudWatch 에이전트 재시작
systemctl restart amazon-cloudwatch-agent

# 보안 감사: 파일 권한 설정
chmod 600 /etc/kubernetes/kubelet/kubelet-config.json
chmod 644 /etc/docker/daemon.json
chmod 600 /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# 시스템 정보 로깅 (디버깅용)
echo "EKS Node Bootstrap completed for cluster: ${cluster_name}" > /var/log/eks-bootstrap.log
echo "Timestamp: $(date)" >> /var/log/eks-bootstrap.log
echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id)" >> /var/log/eks-bootstrap.log
echo "Instance Type: $(curl -s http://169.254.169.254/latest/meta-data/instance-type)" >> /var/log/eks-bootstrap.log
echo "Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)" >> /var/log/eks-bootstrap.log

# 완료 신호
echo "User data script completed successfully" >> /var/log/eks-bootstrap.log