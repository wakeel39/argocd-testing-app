variable "aws_region" {
  description = "AWS region (e.g. us-east-1 for N. Virginia; use us-east-1 for Boston-area / East Coast)"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "argocdnodejsapp-eks"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS (must match existing cluster or be one minor version higher; e.g. 1.29 → 1.30 only)"
  type        = string
  default     = "1.29"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS nodes (use Free Tier eligible e.g. t3.micro if your account restricts to Free Tier)"
  type        = list(string)
  default     = ["t3.micro"]
}

variable "enable_cluster_encryption" {
  description = "Enable envelope encryption for EKS secrets (KMS)"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Use private EKS API endpoint (recommended for production)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "install_aws_load_balancer_controller" {
  description = "Install AWS LB Controller via Helm (set to false on first apply, then run 'aws eks update-kubeconfig', then set true and apply again if you get 'cluster unreachable')"
  type        = bool
  default     = true
}
