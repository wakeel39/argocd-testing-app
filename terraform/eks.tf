# EKS cluster and node group
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" { state = "available" }

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Cluster endpoint access (security: restrict in prod)
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = var.enable_private_endpoint

  # Envelope encryption for Kubernetes secrets (security)
  create_kms_key = var.enable_cluster_encryption
  enable_kms_key_rotation = var.enable_cluster_encryption

  # Enable IRSA (IAM Roles for Service Accounts)
  enable_irsa = true

  # Node group
  eks_managed_node_groups = {
    main = {
      name            = "main"
      instance_types  = var.node_instance_types
      min_size        = var.node_min_size
      max_size        = var.node_max_size
      desired_size    = var.node_desired_size

      # Security: use IMDSv2 only, restrict to HTTPS
      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required" # IMDSv2
        http_put_response_hop_limit = 2
      }

      labels = {
        role = "general"
      }

      tags = var.tags
    }
  }

  tags = var.tags
}

# Data source for auth (kubectl/Helm)
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}
