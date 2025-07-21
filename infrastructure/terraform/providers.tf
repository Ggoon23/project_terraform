provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "terraform-project"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
