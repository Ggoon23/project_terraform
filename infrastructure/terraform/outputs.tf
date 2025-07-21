output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "eks_cluster_id" {
  description = "EKS Cluster ID"
  value       = module.eks.cluster_id
}

output "eks_node_group_role" {
  description = "IAM role ARN for EKS node group"
  value       = module.eks.node_group_iam_role_arn
}

output "rds_endpoint" {
  description = "RDS 인스턴스 엔드포인트"
  value       = module.rds.db_instance_endpoint
}

output "rds_instance_id" {
  description = "ID of the RDS instance"
  value       = module.rds.db_instance_id
}
