module "vpc" {
  source              = "./modules/vpc"
  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnets
}

module "eks" {
  source             = "./modules/eks"
  cluster_name       = var.cluster_name
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "rds" {
  source              = "./modules/rds"
  project_name        = var.project_name
  vpc_id              = module.vpc.vpc_id
  database_subnet_ids = module.vpc.private_subnet_ids

  database_name   = var.db_name
  master_username = var.db_user
  master_password = var.db_password
}
