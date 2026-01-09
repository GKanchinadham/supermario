# ============================================
# Luigi App - AWS EKS Infrastructure
# Tenant: luigi
# Region: eu-west-2
# ============================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }

  backend "s3" {
    bucket         = "luigi-terraform-state"
    key            = "eks/eu-west-2/terraform.tfstate"
    region         = "eu-west-2"
    encrypt        = true
    dynamodb_table = "luigi-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Tenant      = var.tenant_name
      Environment = var.cluster_env
      ManagedBy   = "terraform"
      Project     = "luigi-app"
    }
  }
}

# ============================================
# Variables
# ============================================

variable "tenant_name" {
  description = "Tenant/Organization name"
  type        = string
  default     = "luigi"
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-2"
}

variable "cluster_env" {
  description = "Cluster environment (nonprod or prod)"
  type        = string
  default     = "nonprod"
}

variable "kubernetes_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.29"
}

locals {
  workload_cluster_name = "${var.tenant_name}-${var.aws_region}-${var.cluster_env}"
  argocd_cluster_name   = "argocd-${var.aws_region}"
  ecr_repo_name         = "${var.tenant_name}/luigi-app"
  
  common_tags = {
    Tenant      = var.tenant_name
    Environment = var.cluster_env
    Region      = var.aws_region
  }
}

# ============================================
# Data Sources
# ============================================

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# ============================================
# VPC for EKS
# ============================================

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.workload_cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = var.cluster_env == "nonprod"
  enable_dns_hostnames   = true
  enable_dns_support     = true

  public_subnet_tags = {
    "kubernetes.io/role/elb"                              = 1
    "kubernetes.io/cluster/${local.workload_cluster_name}" = "owned"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                      = 1
    "kubernetes.io/cluster/${local.workload_cluster_name}" = "owned"
  }

  tags = local.common_tags
}

# ============================================
# EKS Workload Cluster
# ============================================

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = local.workload_cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # EKS Managed Node Groups
  eks_managed_node_groups = {
    general = {
      name           = "${local.workload_cluster_name}-general"
      instance_types = var.cluster_env == "prod" ? ["t3.large"] : ["t3.medium"]

      min_size     = var.cluster_env == "prod" ? 2 : 1
      max_size     = var.cluster_env == "prod" ? 10 : 5
      desired_size = var.cluster_env == "prod" ? 3 : 2

      labels = {
        Environment = var.cluster_env
        Tenant      = var.tenant_name
      }

      tags = local.common_tags
    }
  }

  # Cluster Add-ons
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent = true
    }
  }

  # Enable IRSA
  enable_irsa = true

  tags = local.common_tags
}

# ============================================
# ECR Repository
# ============================================

resource "aws_ecr_repository" "app" {
  name                 = local.ecr_repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(local.common_tags, {
    Name = local.ecr_repo_name
  })
}

resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 30 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ============================================
# Outputs
# ============================================

output "cluster_name" {
  description = "EKS Cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS Cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for cluster auth"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.app.repository_url
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}
