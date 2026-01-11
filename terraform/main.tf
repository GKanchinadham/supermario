# ═══════════════════════════════════════════════════════════════════════════
# Opsera Unified AWS Container Deployment - Terraform Main
# Tenant: GKOrg2 | Region: eu-west-2
# ═══════════════════════════════════════════════════════════════════════════

terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend configured via CLI (Learning #114)
  backend "s3" {}
}

provider "aws" {
  region = var.region
  
  default_tags {
    tags = {
      Tenant      = var.tenant_name
      Environment = var.cluster_env
      ManagedBy   = "terraform"
      Project     = "opsera-eks-deployment"
    }
  }
}

# ═══════════════════════════════════════════════════════════════════════════
# Variables
# ═══════════════════════════════════════════════════════════════════════════

variable "tenant_name" {
  description = "Tenant/Organization name"
  type        = string
  default     = "gkorg2"
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-2"
}

variable "cluster_env" {
  description = "Cluster environment (nonprod or prod)"
  type        = string
  default     = "nonprod"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
  default     = "opsera-vpc"
}

variable "argocd_cluster_name" {
  description = "ArgoCD EKS cluster name"
  type        = string
  default     = "argocd-euw2"
}

variable "workload_cluster_name" {
  description = "Workload EKS cluster name"
  type        = string
  default     = "gkorg2-euw2-np"
}

variable "eks_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.28"
}

# ═══════════════════════════════════════════════════════════════════════════
# Modules
# ═══════════════════════════════════════════════════════════════════════════

module "vpc" {
  source = "./modules/vpc"
  
  vpc_name            = var.vpc_name
  vpc_cidr            = var.vpc_cidr
  region              = var.region
  argocd_cluster      = var.argocd_cluster_name
  workload_cluster    = var.workload_cluster_name
}

module "eks_argocd" {
  source = "./modules/eks"
  
  cluster_name    = var.argocd_cluster_name
  cluster_version = var.eks_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  
  node_group_name     = "argocd-nodes"
  node_instance_types = ["t3.medium"]
  node_desired_size   = 2
  node_min_size       = 1
  node_max_size       = 3
  
  depends_on = [module.vpc]
}

module "eks_workload" {
  source = "./modules/eks"
  
  cluster_name    = var.workload_cluster_name
  cluster_version = var.eks_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  
  node_group_name     = "workload-nodes"
  node_instance_types = ["t3.medium"]
  node_desired_size   = 2
  node_min_size       = 1
  node_max_size       = 4
  
  depends_on = [module.vpc]
}

module "oidc_argocd" {
  source = "./modules/oidc"
  
  cluster_name = var.argocd_cluster_name
  
  depends_on = [module.eks_argocd]
}

module "oidc_workload" {
  source = "./modules/oidc"
  
  cluster_name = var.workload_cluster_name
  
  depends_on = [module.eks_workload]
}

module "ecr" {
  source = "./modules/ecr"
  
  repository_name = "gkorg2/gkorgapp2"
}

# ═══════════════════════════════════════════════════════════════════════════
# Outputs
# ═══════════════════════════════════════════════════════════════════════════

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "argocd_cluster_endpoint" {
  description = "ArgoCD EKS cluster endpoint"
  value       = module.eks_argocd.cluster_endpoint
}

output "workload_cluster_endpoint" {
  description = "Workload EKS cluster endpoint"
  value       = module.eks_workload.cluster_endpoint
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}
